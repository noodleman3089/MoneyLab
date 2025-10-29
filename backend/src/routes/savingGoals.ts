import express, { Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';

const routerG = express.Router();

/* ================================================
   🟢 CREATE: สร้างเป้าหมายออมเงินใหม่
================================================ */
routerG.post(
  '/',
  authenticateToken,
  [
    body('goal_name').isString().notEmpty(),
    body('target_amount').isFloat({ gt: 0 }),
    body('monthly_contribution').isFloat({ gt: 0 }),
    body('duration_months').isInt({ gt: 0 }),
    body('frequency').isIn(['daily', 'weekly', 'monthly', 'one-time']),
  ],
  async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ status: false, errors: errors.array() });
    }

    const userId = (req as any).user.user_id;
    const {
      goal_name,
      target_amount,
      monthly_contribution,
      duration_months,
      frequency,
      start_date,
    } = req.body;

    try {
      // ตรวจสอบว่ามี goal ชื่อนี้อยู่แล้วไหม
      const existing = await query(
        'SELECT * FROM saving_goals WHERE user_id = ? AND goal_name = ? AND status != "completed"',
        [userId, goal_name]
      );

      if (existing.length > 0) {
        return res.status(409).json({
          status: false,
          message: 'มีเป้าหมายนี้อยู่แล้วในระบบ',
        });
      }

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

      // เพิ่มเป้าหมายใหม่
      await query(
        `INSERT INTO saving_goals 
        (user_id, wallet_id, goal_name, target_amount, monthly_contribution, duration_months, frequency, start_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          walletId,
          goal_name,
          target_amount,
          monthly_contribution,
          duration_months,
          frequency,
          start_date || new Date(),
        ]
      );

      res.json({ status: true, message: 'สร้างเป้าหมายออมเงินสำเร็จ' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

/* ================================================
   📄 READ: ดึงรายการเป้าหมายออมทั้งหมดของผู้ใช้
================================================ */
routerG.get('/', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;

  try {
    const goals = await query(
      `SELECT goal_id, goal_name, target_amount, current_amount, monthly_contribution,
              duration_months, frequency, status, start_date,
              ROUND((current_amount / target_amount) * 100, 2) AS progress_percent
       FROM saving_goals WHERE user_id = ? ORDER BY created_at DESC`,
      [userId]
    );

    res.json({ status: true, goals });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ================================================
   🔍 READ ONE: ดึงรายละเอียดเป้าหมายออมเงิน
================================================ */
routerG.get('/:id', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;
  const goalId = req.params.id;

  try {
    const [goal]: any = await query(
      `SELECT *, ROUND((current_amount / target_amount) * 100, 2) AS progress_percent
       FROM saving_goals WHERE goal_id = ? AND user_id = ?`,
      [goalId, userId]
    );

    if (!goal) {
      return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายนี้' });
    }

    res.json({ status: true, goal });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ================================================
   ✏️ UPDATE: แก้ไขข้อมูลเป้าหมายออมเงิน
================================================ */
routerG.put(
  '/:id',
  authenticateToken,
  [
    body('goal_name').optional().isString(),
    body('target_amount').optional().isFloat({ gt: 0 }),
    body('monthly_contribution').optional().isFloat({ gt: 0 }),
    body('duration_months').optional().isInt({ gt: 0 }),
    body('frequency').optional().isIn(['daily', 'weekly', 'monthly', 'one-time']),
  ],
  async (req: Request, res: Response) => {
    const userId = (req as any).user.user_id;
    const goalId = req.params.id;

    const fields = req.body;
    const setClause = Object.keys(fields)
      .map((key) => `${key} = ?`)
      .join(', ');
    const values = [...Object.values(fields), goalId, userId];

    if (!setClause) {
      return res.status(400).json({ status: false, message: 'ไม่มีข้อมูลที่จะแก้ไข' });
    }

    try {
      const result = await query(
        `UPDATE saving_goals SET ${setClause}, updated_at = NOW() WHERE goal_id = ? AND user_id = ?`,
        values
      );

      if ((result as any).affectedRows === 0) {
        return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายนี้' });
      }

      res.json({ status: true, message: 'อัปเดตเป้าหมายเรียบร้อย' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

/* ================================================
   🟡 PATCH: เปลี่ยนสถานะเป้าหมาย
================================================ */
routerG.patch('/:id/status', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;
  const goalId = req.params.id;
  const { status } = req.body;

  const allowed = ['active', 'paused', 'completed', 'cancelled'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ status: false, message: 'สถานะไม่ถูกต้อง' });
  }

  try {
    await query(
      `UPDATE saving_goals SET status = ?, updated_at = NOW() WHERE goal_id = ? AND user_id = ?`,
      [status, goalId, userId]
    );

    res.json({ status: true, message: `อัปเดตสถานะเป็น ${status}` });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ================================================
   ❌ DELETE: ลบเป้าหมายออมเงิน
================================================ */
routerG.delete('/:id', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;
  const goalId = req.params.id;

  try {
    const result = await query('DELETE FROM saving_goals WHERE goal_id = ? AND user_id = ?', [
      goalId,
      userId,
    ]);

    if ((result as any).affectedRows === 0) {
      return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายนี้' });
    }

    res.json({ status: true, message: 'ลบเป้าหมายเรียบร้อย' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerG;
