import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';

const routerSavingTx = express.Router();

routerSavingTx.post(
  '/',
  authenticateToken,
  [
    body('goal_id').isInt({ gt: 0 }).withMessage('goal_id ต้องเป็นตัวเลข'),
    body('amount').isFloat({ gt: 0 }).withMessage('amount ต้องมากกว่า 0'),
  ],
  async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ status: false, errors: errors.array() });
    }

    const actor = req.user;
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }
    const userId = actor.user_id;
    const { goal_id, amount } = req.body;
    let walletId: number = 0;

    try {
      // ✅ 1. ตรวจสอบว่า goal มีอยู่จริงและ active
      const goalRows = await query(
        'SELECT target_amount, current_amount, status, wallet_id FROM saving_goals WHERE goal_id = ? AND user_id = ?',
        [goal_id, userId]
      );

      if (goalRows.length === 0) {
        await logActivity({
            user_id: userId,
            actor_id: userId,
            actor_type: actor.role,
            action: 'DEPOSIT_FAIL_GOAL_NOT_FOUND',
            table_name: 'saving_goals',
            record_id: goal_id,
            description: `User ${userId} failed deposit: Goal ${goal_id} not found.`,
            req: req
        });
        return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายออมเงินนี้' });
      }

      const goal = goalRows[0];
      if (goal.status !== 'active') {
        await logActivity({
            user_id: userId,
            actor_id: userId,
            actor_type: actor.role,
            action: 'DEPOSIT_FAIL_GOAL_INACTIVE',
            table_name: 'saving_goals',
            record_id: goal_id,
            description: `User ${userId} failed deposit: Goal ${goal_id} is not active.`,
            req: req
        });
        return res.status(400).json({
          status: false,
          message: 'ไม่สามารถออมเพิ่มได้ เพราะสถานะ goal ไม่ใช่ active',
        });
      }

      // ✅ 2. หา wallet ของ user (ถ้าไม่มีให้สร้าง)
      walletId = goal.wallet_id || 0;
      if (!walletId) {
        const walletRows = await query('SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1', [userId]);
        if (walletRows.length === 0) {
          const createWallet = await query(
            'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
            [userId, 'Main Wallet', 'THB']
          );
          walletId = createWallet.insertId;
          await logActivity({
              user_id: userId,
              actor_id: userId,
              actor_type: actor.role,
              action: 'CREATE_WALLET',
              table_name: 'wallet',
              record_id: walletId,
              description: `User ${userId} auto-created 'Main Wallet' during deposit.`,
              req: req
          });
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
        await logActivity({
            user_id: userId,
            actor_id: userId,
            actor_type: actor.role,
            action: 'DEPOSIT_FAIL_INSUFFICIENT_FUNDS',
            table_name: 'wallet',
            record_id: walletId,
            description: `User ${userId} failed deposit: Insufficient funds (Wallet: ${walletBalance}, Need: ${amount}).`,
            req: req
        });
        return res.status(400).json({
          status: false,
          message: `ยอดเงินใน wallet ไม่เพียงพอ (มี ${walletBalance} ต้องการ ${amount})`,
        });
      }

      // ✅ 4. เพิ่มข้อมูลใน saving_transactions
      const result: any = await query(
        `INSERT INTO saving_transactions 
         (user_id, goal_id, wallet_id, amount, transaction_date, status)
         VALUES (?, ?, ?, ?, NOW(), 'completed')`,
        [userId, goal_id, walletId, amount]
      );
      const newTransactionId = result.insertId;

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

      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role,
          action: 'CREATE_SAVING_DEPOSIT',
          table_name: 'saving_transactions',
          record_id: newTransactionId,
          description: `User ${userId} deposited ${amount} to goal ${goal_id} (New total: ${newAmount}).`,
          req: req,
          new_value: { goal_id, amount, newAmount, newStatus }
      });

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
    } catch (err: any) {
      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: 'system',
          action: 'DEPOSIT_EXCEPTION',
          table_name: 'saving_transactions',
          record_id: goal_id,
          description: `Failed to deposit to goal ${goal_id}. Error: ${err.message}`,
          req: req,
          new_value: { error: err.stack }
      });
      console.error('❌ saving-transactions error:', err);
      res.status(500).json({ status: false, message: 'Server error' });
    }
  }
);

export default routerSavingTx;