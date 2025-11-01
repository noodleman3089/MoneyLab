import express, { Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';
import { sendEmail } from '../sendEmail/sendEmail';

interface AuthRequest extends Request {
  user?: { user_id: number; role: string };
}

const routes_T = express.Router();

/* ------------------ POST: เพิ่มรายการใหม่ ------------------ */
routes_T.post(
  '/',
  authenticateToken,
  [
    // 🟢 ไม่ต้องมี type แล้ว
    body('amount').isFloat({ gt: 0 }).withMessage('จำนวนเงินต้องมากกว่า 0'),
    body('fee').optional().isFloat({ min: 0 }).withMessage('ค่าธรรมเนียมต้องไม่ติดลบ'),
    body('category_id').isInt({ gt: 0 }).withMessage('กรุณาระบุ category_id ที่ถูกต้อง'),
    body('sender_name').optional().isString(),
    body('receiver_name').optional().isString(),
    body('reference_id').optional().isString(),
    body('payment_source').optional().isString(),
    // 🟡 ทำให้ transaction_date optional ได้
    body('transaction_date').optional().isDate().withMessage('รูปแบบวันที่ไม่ถูกต้อง (YYYY-MM-DD)'),
  ],
  async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ status: false, errors: errors.array() });
    }

    const userId = req.user!.user_id;
    const {
      amount,
      fee = 0,
      category_id,
      sender_name,
      receiver_name,
      reference_id,
      payment_source,
      transaction_date, // อาจจะ undefined
      data_source = 'manual',
      confidence = null
    } = req.body;

    try {
      // ✅ ดึง category_type จาก category_id
      const cat = await query('SELECT category_type FROM category WHERE category_id = ?', [category_id]);
      if (cat.length === 0) {
        return res.status(400).json({
          status: false,
          message: 'ไม่พบ category_id นี้ในระบบ',
        });
      }

      const type = cat[0].category_type;

      // ✅ ตรวจสอบหรือสร้าง wallet
      let walletId: number | null = null;
      const wallet = await query('SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1', [userId]);
      if (wallet.length === 0) {
        const createWallet = await query(
          'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
          [userId, 'Main Wallet', 'THB']
        );
        walletId = createWallet.insertId;
        console.log(`🆕 สร้าง wallet ใหม่สำหรับ user_id=${userId} → wallet_id=${walletId}`);
      } else {
        walletId = wallet[0].wallet_id;
      }

      // ✅ ถ้าไม่มี transaction_date → ใช้ NOW()
      const dateToUse = transaction_date || new Date().toISOString().slice(0, 10);

      // ✅ บันทึกข้อมูลลง transactions
      await query(
        `INSERT INTO transactions
          (user_id, wallet_id, category_id, type, amount, fee, sender_name, receiver_name,
           reference_id, payment_source, data_source, confidence, transaction_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          walletId,
          category_id,
          type,
          amount,
          fee,
          sender_name || null,
          receiver_name || null,
          reference_id || null,
          payment_source || null,
          data_source,
          confidence,
          dateToUse,
        ]
      );

      // ✅ ตรวจเฉพาะ transaction ที่เป็นรายจ่ายเท่านั้น
      if (type === 'expense') {
        const today = new Date().toISOString().slice(0, 10);

        // 🔹 ดึงงบรายวันของวันนี้ (ถ้ามี)
        const [budget]: any = await query(
          `SELECT budget_id, target_spend, 
                  (SELECT COALESCE(SUM(amount),0) 
                  FROM transactions 
                  WHERE user_id = ? AND type = 'expense' 
                  AND DATE(transaction_date) = ?) AS total_spent
          FROM daily_budget 
          WHERE user_id = ? AND budget_date = ? 
          LIMIT 1`,
          [userId, today] //  userId, today ลบไปเพราะซ้ำ
        );

        if (budget) {
          const {budget_id} = budget;
          const target_spend = parseFloat(budget.target_spend ?? 0);
          const total_spent = parseFloat(budget.total_spent ?? 0);
          const percentUsed = target_spend > 0 ? (total_spent / target_spend) * 100 : 0;

          let shouldNotify = false;
          let notifyType: 'warning' | 'error' | null = null;
          let title = '';
          let message = '';

          if (percentUsed >= 100) {
            shouldNotify = true;
            notifyType = 'error';
            title = 'งบวันนี้หมดแล้ว!';
            message = `คุณใช้จ่ายครบงบประจำวันที่ ${today} แล้ว (${total_spent.toFixed(2)} / ${target_spend.toFixed(2)} บาท)`;
          } else if (percentUsed >= 50) {
            shouldNotify = true;
            notifyType = 'warning';
            title = 'ใกล้เต็มงบวันนี้แล้ว!';
            message = `คุณใช้จ่ายไปแล้ว ${percentUsed.toFixed(0)}% ของงบวันนี้ (${total_spent.toFixed(2)} / ${target_spend.toFixed(2)} บาท)`;
          }

          if (shouldNotify && notifyType) {
            // ✅ บันทึกการแจ้งเตือนลงตาราง notifications
            await query(
              `INSERT INTO notifications 
              (user_id, type, title, message, reference_type, reference_id)
              VALUES (?, ?, ?, ?, 'daily_budget', ?)`,
              [userId, notifyType, title, message, budget_id]
            );

            // ✅ ดึงอีเมลของผู้ใช้เพื่อส่งแจ้งเตือน
            const [userInfo]: any = await query(
              `SELECT email, username FROM users WHERE user_id = ? LIMIT 1`,
              [userId]
            );

            if (userInfo?.email) {
              await sendEmail(
                userInfo.email,
                title,
                message,
                `
                  <div style="font-family:sans-serif;line-height:1.6">
                    <h3>${title}</h3>
                    <p>สวัสดีคุณ ${userInfo.username || ''},</p>
                    <p>${message}</p>
                    <hr/>
                    <small>ระบบแจ้งเตือนจาก MoneyLab</small>
                  </div>
                `
              );
              console.log(`📧 Budget alert sent to ${userInfo.email}`);
            }
          }
        }
      }

      res.json({
        status: true,
        message: `Transaction created successfully (type=${type}, date=${dateToUse})`,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

export default routes_T;