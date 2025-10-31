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
        'SELECT target_amount, current_amount, status FROM saving_goals WHERE goal_id = ? AND user_id = ?',
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

      // ✅ 2. หา wallet_id ของ user (ถ้าไม่มีให้สร้าง)
      let walletId: number | null = null;
      const walletRows = await query(
        'SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1',
        [userId]
      );

      if (walletRows.length === 0) {
        // 🆕 ถ้ายังไม่มี wallet → สร้างใหม่ชื่อ Main Wallet
        const createWallet = await query(
          'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
          [userId, 'Main Wallet', 'THB']
        );
        walletId = createWallet.insertId;
        console.log(`🆕 สร้าง wallet ใหม่สำหรับ user_id=${userId} → wallet_id=${walletId}`);
      } else {
        walletId = walletRows[0].wallet_id;
      }

      // ✅ 3. เพิ่มข้อมูลใน saving_transactions (ใช้ NOW() จาก DB)
      await query(
        `INSERT INTO saving_transactions 
         (user_id, goal_id, wallet_id, amount, transaction_date, status)
         VALUES (?, ?, ?, ?, NOW(), 'completed')`,
        [userId, goal_id, walletId, amount]
      );

      // ✅ 4. อัปเดตยอด current_amount
      const newAmount = parseFloat(goal.current_amount) + parseFloat(amount);

      // ✅ 5. คำนวณ progress (%)
      const progress = Math.min((newAmount / goal.target_amount) * 100, 100).toFixed(2);

      // ✅ 6. อัปเดตสถานะ goal ถ้าถึงเป้าหมายแล้ว
      const newStatus = newAmount >= goal.target_amount ? 'completed' : goal.status;

      await query(
        `UPDATE saving_goals
         SET current_amount = ?, status = ?, updated_at = NOW(),
             completed_at = CASE WHEN ? = 'completed' THEN NOW() ELSE completed_at END
         WHERE goal_id = ?`,
        [newAmount, newStatus, newStatus, goal_id]
      );

      // ✅ 7. อัปเดตยอดใน wallet (จำลองลดเงินออกจาก wallet เมื่อออม)
      await query(
        `UPDATE wallet 
         SET balance = balance - ?, updated_at = NOW()
         WHERE wallet_id = ?`,
        [amount, walletId]
      );

      res.json({
        status: true,
        message: 'เพิ่มยอดออมสำเร็จ',
        data: {
          goal_id,
          new_amount: newAmount,
          target_amount: goal.target_amount,
          progress_percent: progress,
          status: newStatus,
          wallet_id: walletId,
          transaction_date: new Date().toISOString(),
        },
      });
    } catch (err) {
      console.error('❌ saving-transactions error:', err);
      res.status(500).json({ status: false, message: 'Server error' });
    }
  }
);

export default routerSavingTx;
