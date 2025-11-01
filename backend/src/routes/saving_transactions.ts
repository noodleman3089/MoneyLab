import express, { Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';

const routerSavingTx = express.Router();

/**
 * ✅ POST /saving-transactions
 * เพิ่มยอดออม (deposit) เข้า goal และอัปเดต progress
 * ใช้เวลาปัจจุบันของเซิร์ฟเวอร์เป็น transaction_date
 * ✅ ผูกกับ wallet_id ของ user โดยอัตโนมัติ
 * ✅ ตรวจสอบยอดเงินใน wallet ว่าพอหรือไม่
 * ✅ อัปเดต completed_at เมื่อออมครบเป้าหมาย
 */
routerSavingTx.post(
  '/',
  authenticateToken,
  [
    body('goal_id').isInt({ gt: 0 }).withMessage('goal_id ต้องเป็นตัวเลข'),
    body('amount').isFloat({ gt: 0 }).withMessage('amount ต้องมากกว่า 0'),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ status: false, errors: errors.array() });
    }

    const userId = (req as any).user.user_id;
    const { goal_id, amount } = req.body;

    try {
      // ✅ 1. ตรวจสอบว่า goal มีอยู่จริงและ active
      const goalRows = await query(
        'SELECT target_amount, current_amount, status, wallet_id FROM saving_goals WHERE goal_id = ? AND user_id = ?',
        [goal_id, userId]
      );

      if (goalRows.length === 0) {
        return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายออมเงินนี้' });
      }

      const goal = goalRows[0];
      if (goal.status !== 'active') {
        return res.status(400).json({
          status: false,
          message: 'ไม่สามารถออมเพิ่มได้ เพราะสถานะ goal ไม่ใช่ active',
        });
      }

      // ✅ 2. หา wallet ของ user (ถ้าไม่มีให้สร้าง)
      let walletId: number | null = goal.wallet_id || null;
      if (!walletId) {
        const walletRows = await query('SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1', [userId]);
        if (walletRows.length === 0) {
          const createWallet = await query(
            'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
            [userId, 'Main Wallet', 'THB']
          );
          walletId = createWallet.insertId;
        } else {
          walletId = walletRows[0].wallet_id;
        }

        // อัปเดต goal ให้มี wallet_id ด้วย
        await query('UPDATE saving_goals SET wallet_id = ? WHERE goal_id = ?', [walletId, goal_id]);
      }

      // ✅ 3. ตรวจสอบยอดเงินใน wallet ก่อนออม
      const wallet = await query('SELECT balance FROM wallet WHERE wallet_id = ?', [walletId]);
      if (wallet.length === 0) {
        return res.status(400).json({ status: false, message: 'ไม่พบกระเป๋าเงินของผู้ใช้' });
      }

      const walletBalance = parseFloat(wallet[0].balance);
      if (walletBalance < parseFloat(amount)) {
        return res.status(400).json({
          status: false,
          message: `ยอดเงินใน wallet ไม่เพียงพอ (มี ${walletBalance} ต้องการ ${amount})`,
        });
      }

      // ✅ 4. เพิ่มข้อมูลใน saving_transactions
      await query(
        `INSERT INTO saving_transactions 
         (user_id, goal_id, wallet_id, amount, transaction_date, status)
         VALUES (?, ?, ?, ?, NOW(), 'completed')`,
        [userId, goal_id, walletId, amount]
      );

      // ✅ 5. อัปเดตยอด current_amount
      const newAmount = parseFloat(goal.current_amount) + parseFloat(amount);
      const progress = Math.min((newAmount / goal.target_amount) * 100, 100).toFixed(2);

      // ✅ 6. อัปเดตสถานะ goal (พร้อม completed_at)
      const newStatus = newAmount >= goal.target_amount ? 'completed' : goal.status;
      await query(
        `UPDATE saving_goals
         SET current_amount = ?, status = ?, updated_at = NOW(),
             completed_at = CASE WHEN ? = 'completed' THEN NOW() ELSE completed_at END
         WHERE goal_id = ?`,
        [newAmount, newStatus, newStatus, goal_id]
      );

      // ✅ 7. อัปเดตยอดใน wallet (ลดเงินเมื่อออม)
      await query(
        `UPDATE wallet 
         SET balance = balance - ?, updated_at = NOW()
         WHERE wallet_id = ?`,
        [amount, walletId]
      );

      // ✅ 8. ตอบกลับ client
      res.json({
        status: true,
        message: 'เพิ่มยอดออมสำเร็จ',
        data: {
          goal_id,
          wallet_id: walletId,
          amount: parseFloat(amount),
          new_amount: newAmount,
          target_amount: goal.target_amount,
          progress_percent: progress,
          status: newStatus,
          transaction_date: new Date().toISOString(),
        },
      });
    } catch (err) {
      console.error('❌ saving-transactions error:', err);
      res.status(500).json({ status: false, message: 'Server error' });
    }
  }
);

routerSavingTx.post('/auto-deduct', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;

  try {
    // 🧭 1) ดึงเป้าหมายที่ active และถึงรอบหัก
    const goals: any[] = await query(
      `SELECT g.goal_id, g.user_id, g.wallet_id, g.goal_name, g.contribution_amount,
              g.current_amount, g.target_amount, g.frequency, g.next_deduction_date,
              g.status,
              w.balance AS wallet_balance
       FROM saving_goals g
       JOIN wallet w ON g.wallet_id = w.wallet_id
       WHERE g.user_id = ? 
         AND g.status = 'active'
         AND (g.next_deduction_date IS NULL OR g.next_deduction_date <= CURDATE())`,
      [userId]
    );

    if (goals.length === 0) {
      return res.json({ status: true, message: 'ไม่มีรายการที่ถึงรอบหักเงินวันนี้' });
    }

    // 🧮 2) ประมวลผลแต่ละ goal
    for (const goal of goals) {
      const {
        goal_id,
        wallet_id,
        wallet_balance,
        contribution_amount,
        frequency,
        current_amount,
        target_amount,
      } = goal;

      // ✅ ตรวจสอบยอดเงินเพียงพอไหม
      if (wallet_balance < contribution_amount) {
        console.warn(`❌ wallet_id=${wallet_id} เงินไม่พอหัก contribution_amount=${contribution_amount}`);
        continue;
      }

      // ✅ หักเงินจาก wallet 
      await query(
        `UPDATE wallet 
         SET balance = balance - ?, 
             updated_at = NOW()
         WHERE wallet_id = ?`,
        [contribution_amount, wallet_id]
      );

      // ✅ เพิ่ม record ลงใน saving_transactions
      await query(
        `INSERT INTO saving_transactions 
         (user_id, goal_id, wallet_id, amount, transaction_date, status)
         VALUES (?, ?, ?, ?, NOW(), 'completed')`,
        [userId, goal_id, wallet_id, contribution_amount]
      );

      // ✅ บวกเงินใน goal
      const newAmount = parseFloat(current_amount) + parseFloat(contribution_amount);
      let newStatus = goal.status;
      let completedAt: Date | null = null;

      if (newAmount >= target_amount) {
        newStatus = 'completed';
        completedAt = new Date();
      }

      // ✅ คำนวณวันถัดไปตาม frequency
      let nextDate: Date | null = null;
      const now = new Date();
      if (frequency === 'daily') nextDate = new Date(now.setDate(now.getDate() + 1));
      else if (frequency === 'weekly') nextDate = new Date(now.setDate(now.getDate() + 7));
      else if (frequency === 'monthly') nextDate = new Date(now.setMonth(now.getMonth() + 1));
      else if (frequency === 'one-time') nextDate = null;

      // ✅ อัปเดตสถานะ goal
      await query(
        `UPDATE saving_goals 
         SET current_amount = ?, 
             status = ?, 
             next_deduction_date = ?, 
             completed_at = CASE WHEN ? = 'completed' THEN NOW() ELSE completed_at END,
             updated_at = NOW()
         WHERE goal_id = ?`,
        [newAmount, newStatus, nextDate, newStatus, goal_id]
      );
    }

    res.json({ status: true, message: 'ดำเนินการหักเงินตามรอบสำเร็จ' });
  } catch (err) {
    console.error('💥 Auto-deduct error:', err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerSavingTx;