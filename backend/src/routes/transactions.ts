import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { sendEmail } from '../sendEmail/sendEmail';
import { logActivity } from '../services/log.service';
import moment from 'moment-timezone';

const routes_T = express.Router();

/* ------------------ GET: ดึงข้อมูลสรุปรายวัน ------------------ */
routes_T.get(
  '/daily',
  authenticateToken,
  async (req: AuthRequest, res: Response) => {
    const actor = req.user;
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }
    const userId = actor.user_id;

    // 1. รับวันที่จาก query string (เช่น '2025-11-03')
    const dateQuery = req.query.date as string;
    if (!dateQuery || !/^\d{4}-\d{2}-\d{2}$/.test(dateQuery)) {
      return res.status(400).json({ status: false, message: 'Invalid or missing date query parameter. Use YYYY-MM-DD format.' });
    }

    try {
      // 2. ดึงงบประมาณรายวัน (Daily Goal)
      const budgetResult = await query(
        'SELECT target_spend FROM daily_budget WHERE user_id = ? AND budget_date = ? LIMIT 1',
        [userId, dateQuery]
      );
      const dailyGoal = parseFloat(budgetResult[0]?.target_spend || '0');

      // 3. คำนวณยอดใช้จ่ายรวมของวันนั้น (Current Spending)
      const spendingResult = await query(
        `SELECT COALESCE(SUM(amount), 0) AS total_spent 
         FROM transactions 
         WHERE user_id = ? AND type = 'expense' AND DATE(transaction_date) = ?`,
        [userId, dateQuery]
      );
      const currentSpending = parseFloat(spendingResult[0]?.total_spent || '0');

      // 4. ดึงรายการธุรกรรมทั้งหมดของวันนั้น
      const transactionsResult = await query(
        `SELECT 
           t.transaction_id,
           t.receiver_name,
           t.sender_name,
           c.category_name,
           t.amount,
           t.type,
           t.transaction_date
         FROM transactions t
         LEFT JOIN category c ON t.category_id = c.category_id
         WHERE t.user_id = ? AND DATE(t.transaction_date) = ?
         ORDER BY t.transaction_date DESC`,
        [userId, dateQuery]
      );

      // 👈 [THE FIX] แปลงค่า amount ในแต่ละ transaction ให้เป็นตัวเลข
      const formattedTransactions = transactionsResult.map((tx: any) => ({
        ...tx,
        amount: parseFloat(tx.amount || '0'),
      }));

      // 5. ประกอบข้อมูลส่งกลับให้ Frontend
      res.json({
        status: true,
        data: {
          daily_goal: dailyGoal,
          current_spending: currentSpending,
          transactions: formattedTransactions, // 👈 ส่งข้อมูลที่แปลงค่าแล้วกลับไป
        },
      });

    } catch (err: any) {
      console.error('Error fetching daily summary:', err);
      logActivity({ user_id: userId, actor_id: userId, actor_type: 'system', action: 'FETCH_DAILY_SUMMARY_EXCEPTION', description: `Error: ${err.message}`, req });
      res.status(500).json({ status: false, message: 'Database error while fetching daily summary.' });
    }
  }
);

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
    body('transaction_date').optional().isISO8601().withMessage('รูปแบบวันที่ไม่ถูกต้อง (YYYY-MM-DD)').toDate(),
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

    let walletId: number = 0;

    try {
      // ✅ ดึง category_type จาก category_id
      const cat = await query('SELECT category_type FROM category WHERE category_id = ?', [category_id]);
      if (cat.length === 0) {
        await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role, // (สันนิษฐานว่า role ถูกต้องจาก Middleware)
          action: 'CREATE_TRANSACTION_FAIL_CATEGORY',
          table_name: 'transactions',
          description: `Failed to create transaction: Category ID ${category_id} not found.`,
          req: req,
          new_value: req.body
        });
        return res.status(400).json({
          status: false,
          message: 'ไม่พบ category_id นี้ในระบบ',
        });
      }

      const type = cat[0].category_type;

      // ✅ ตรวจสอบหรือสร้าง wallet
      const wallet = await query('SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1', [userId]);
      if (wallet.length === 0) {
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
            description: `User ${userId} auto-created 'Main Wallet' during transaction.`,
            req: req
        });
        console.log(`🆕 สร้าง wallet ใหม่สำหรับ user_id=${userId} → wallet_id=${walletId}`);
      } else {
        walletId = wallet[0].wallet_id;
      }

      // ✅ ถ้าไม่มี transaction_date → ใช้ NOW()
      const dateToUse = transaction_date? moment(transaction_date).tz("Asia/Bangkok").format("YYYY-MM-DD HH:mm:ss"): moment().tz("Asia/Bangkok").format("YYYY-MM-DD HH:mm:ss");

      // ✅ บันทึกข้อมูลลง transactions
      const result: any = await query(
        `INSERT INTO transactions
           (user_id, wallet_id, category_id, type, amount, fee, sender_name, receiver_name,
            reference_id, payment_source, data_source, confidence, transaction_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId, walletId, category_id, type, amount, fee,
          sender_name || null,
          receiver_name || null,
          reference_id || null,
          payment_source || null,
          data_source,
          confidence,
          dateToUse,
        ]
      );
      const newTransactionId = result.insertId;

      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role,
          action: type === 'income' ? 'CREATE_INCOME' : 'CREATE_EXPENSE',
          table_name: 'transactions',
          record_id: newTransactionId,
          description: `User ${userId} created transaction ID ${newTransactionId} (Type: ${type}, Amount: ${amount}).`,
          req: req,
          new_value: req.body
      });

      // ✅ ตรวจเฉพาะ transaction ที่เป็นรายจ่ายเท่านั้น
      if (type === 'expense') {
        const today = moment().tz("Asia/Bangkok").format("YYYY-MM-DD");

        // 🔹 ดึงงบรายวันของวันนี้ (ถ้ามี)
        const [budget]: any = await query(
          `SELECT budget_id, target_spend, 
             (SELECT COALESCE(SUM(amount),0) 
              FROM transactions 
              WHERE user_id = ? AND type = 'expense' AND DATE(transaction_date) = ?) AS total_spent
           FROM daily_budget 
           WHERE user_id = ? AND budget_date = ? 
           LIMIT 1`,
          [userId, today, userId, today] // 👈 แก้ไขเป็น 4 params
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

            await logActivity({
                user_id: userId,
                actor_id: 0, // 👈 (ใช้ 0 เพราะเป็น System Action)
                actor_type: 'system',
                action: 'BUDGET_NOTIFICATION_SENT',
                table_name: 'notifications',
                description: `Sent budget alert (Type: ${notifyType}) to user ${userId}.`,
                req: req,
                new_value: { title, message }
            });

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
    } catch (err: any) {
      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: 'system',
          action: 'CREATE_TRANSACTION_EXCEPTION',
          table_name: 'transactions',
          record_id: 0,
          description: `Failed to create transaction. Error: ${err.message}`,
          req: req,
          new_value: { error: err.stack }
      });
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

export default routes_T;