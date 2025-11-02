import express, { Response } from 'express';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';

const routerWallet = express.Router();

routerWallet.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  
  const userId = actor.user_id;
  let walletId: number = 0;

  try {
    // 1) ดึง wallet (1 wallet โดยสมมติ)
    const wallets = await query(
      'SELECT wallet_id, wallet_name, currency, balance, last_reset_at FROM wallet WHERE user_id = ? LIMIT 1',
      [userId]
    );
    let wallet = wallets?.[0];

    // ถ้าไม่มี wallet ให้สร้างใหม่
    if (!wallet) {
      const result: any = await query(
        'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
        [userId, 'Main Wallet', 'THB']
      );
      walletId = result.insertId;

      return res.json({
        status: true,
        wallet: { wallet_name: 'Main Wallet', currency: 'THB', balance: 0 }
      });
    }

    walletId = wallet.wallet_id;
    const resetDate = wallet.last_reset_at || '1970-01-01';

    // 2) ดึง totals จาก transactions
    const txns = await query(
      `SELECT
          COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0) AS total_income,
          COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0) AS total_expense
        FROM transactions
        WHERE user_id = ? AND transaction_date >= ?`, // 👈 เพิ่มเงื่อนไข
      [userId, resetDate] // 👈 เพิ่มตัวแปร
    );

    // 3) ดึง saving_transactions (ฝากออกจาก wallet)
    const savings = await query(
      `SELECT COALESCE(SUM(amount), 0) AS total_saving_out
        FROM saving_transactions
        WHERE user_id = ? AND status = 'completed' AND transaction_date >= ?`, // 👈 เพิ่มเงื่อนไข
      [userId, resetDate] // 👈 เพิ่มตัวแปร
    );

    // 4) ดึงยอดจาก saving_goals.current_amount (ถ้าต้องการ)
    const goals = await query(
      `SELECT COALESCE(SUM(current_amount), 0) AS total_goal_amount
       FROM saving_goals
       WHERE user_id = ?`,
      [userId]
    );

    // --- แปลงผลลัพธ์เป็น number อย่างปลอดภัย ---
    const totalIncome = parseFloat(txns[0]?.total_income ?? 0) || 0;
    const totalExpense = parseFloat(txns[0]?.total_expense ?? 0) || 0;
    const totalSavingOut = parseFloat(savings[0]?.total_saving_out ?? 0) || 0;
    const totalGoalAmount = parseFloat(goals[0]?.total_goal_amount ?? 0) || 0;

    // Debug log (สำคัญตอนพัฒนา)
    console.log('wallet debug:', {
      db_balance: wallet.balance,
      totalIncome, totalExpense, totalSavingOut
    });

    // คำนวณ newBalance เป็น number
    // ตัวอย่างสูตร: balance = income - expense - savingOut (ปรับตามนโยบายของคุณ)
    let newBalance = totalIncome - totalExpense - totalSavingOut;

    // ป้องกัน NaN หรือค่าที่แปลก ๆ
    if (!isFinite(newBalance) || Number.isNaN(newBalance)) {
      newBalance = 0;
    }

    // ปัดเป็น 2 ตำแหน่ง
    const newBalanceRounded = Math.round(newBalance * 100) / 100; // number
    const newBalanceDisplay = newBalanceRounded.toFixed(2); // string for display

    // อัปเดต wallet.balance ใน DB (ถาต้องการ persistent)
    await query('UPDATE wallet SET balance = ?, updated_at = NOW() WHERE wallet_id = ?', [
      newBalanceRounded,
      wallet.wallet_id
    ]);

    res.json({
      status: true,
      wallet: {
        wallet_id: wallet.wallet_id,
        wallet_name: wallet.wallet_name,
        currency: wallet.currency,
        balance: parseFloat(newBalanceDisplay),
        raw_balance_display: newBalanceDisplay,
        totals: {
          totalIncome,
          totalExpense,
          totalSavingOut,
          totalGoalAmount
        }
      }
    });
  } catch (err) {
    console.error('💥 Wallet error:', err);
    res.status(500).json({ status: false, message: 'Server error' });
  }
});

routerWallet.post('/reset', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) { // 👈 (แก้ไข)
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;
  let walletId: number = 0;

  try {
    // ตรวจว่ามีกระเป๋าหรือไม่
    const wallets = await query('SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1', [userId]);
    const wallet = wallets[0];

    if (!wallet) {
      await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role || 'user',
        action: 'RESET_WALLET_FAIL_NOT_FOUND',
        table_name: 'wallet',
        description: `User ${userId} failed to reset wallet: Not found.`,
        req: req
      });
      return res.status(404).json({ status: false, message: 'Wallet not found' });
    }

    // รีเซ็ตยอดเงินกลับเป็น 0 และบันทึกเวลา reset ล่าสุด
    await query(
      'UPDATE wallet SET balance = 0, last_reset_at = NOW(), updated_at = NOW() WHERE wallet_id = ?',
      [wallet.wallet_id]
    );

    await logActivity({
      user_id: userId,
      actor_id: userId,
      actor_type: actor.role || 'user',
      action: 'RESET_WALLET_SUCCESS',
      table_name: 'wallet',
      record_id: wallet.wallet_id,
      description: `User ${userId} reset wallet (ID: ${wallet.wallet_id}) balance to 0.`,
      req: req,
      new_value: { balance: 0 }
    });

    res.json({
      status: true,
      message: 'Wallet balance reset to 0 successfully',
      wallet_id: wallet.wallet_id,
    });
  } catch (err: any) {
    console.error('💥 Reset wallet error:', err);
    await logActivity({
      user_id: userId,
      actor_id: userId,
      actor_type: 'system',
      action: 'RESET_WALLET_EXCEPTION',
      table_name: 'wallet',
      record_id: walletId || 0,
      description: `Failed to reset wallet. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });
    res.status(500).json({ status: false, message: 'Server error' });
  }
});

export default routerWallet;