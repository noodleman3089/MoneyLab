import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../../index';
import { authenticateToken } from '../middlewares/authMiddleware';

interface AuthRequest extends Request {
  user?: { user_id: number; role: string };
}

const routes_T = express.Router();

/* ------------------ POST: เพิ่มรายการใหม่ ------------------ */
routes_T.post(
  '/',
  authenticateToken,
  [
    body('type').isIn(['income', 'expense', 'transfer']).withMessage('ประเภทไม่ถูกต้อง'),
    body('amount').isFloat({ gt: 0 }).withMessage('จำนวนเงินต้องมากกว่า 0'),
    body('fee').optional().isFloat({ min: 0 }).withMessage('ค่าธรรมเนียมต้องไม่ติดลบ'),
    body('category_id').optional().isInt({ gt: 0 }),
    body('sender_name').optional().isString(),
    body('receiver_name').optional().isString(),
    body('reference_id').optional().isString(),
    body('payment_source').optional().isString(),
    body('transaction_date').isDate().withMessage('กรุณาระบุวันที่ให้ถูกต้อง (YYYY-MM-DD)'),
  ],
  async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ status: false, errors: errors.array() });
    }

    const userId = req.user!.user_id;
    const {
      type,
      amount,
      fee = 0,
      category_id,
      sender_name,
      receiver_name,
      reference_id,
      payment_source,
      transaction_date,
      data_source = 'manual',
      confidence = null
    } = req.body;

    try {
      // ✅ ตรวจสอบว่า category_id ถูกต้องและตรงกับ type
      if (category_id) {
        const cat = await query(
          'SELECT * FROM category WHERE category_id = ? AND category_type = ?',
          [category_id, type]
        );
        if (cat.length === 0) {
          return res.status(400).json({
            status: false,
            message: 'category_id ไม่ตรงกับประเภทของรายการ (type)',
          });
        }
      }

      await query(
        `INSERT INTO transactions
          (user_id, category_id, type, amount, fee, sender_name, receiver_name,
           reference_id, payment_source, data_source, confidence, transaction_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          category_id || null,
          type,
          amount,
          fee,
          sender_name || null,
          receiver_name || null,
          reference_id || null,
          payment_source || null,
          data_source,
          confidence,
          transaction_date,
        ]
      );

      res.json({ status: true, message: 'Transaction created successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

export default routes_T;