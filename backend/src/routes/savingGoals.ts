import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';
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
    body('contribution_amount').isFloat({ gt: 0 }), // 🔄 เปลี่ยนชื่อ field
    body('frequency').isIn(['daily', 'weekly', 'monthly', 'one-time']),
    body('start_date').optional().isDate().withMessage('รูปแบบวันที่ไม่ถูกต้อง (YYYY-MM-DD)'),
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
      goal_name,
      target_amount,
      contribution_amount,
      frequency,
      start_date,
      next_deduction_date,
    } = req.body;

    try {
      // ตรวจสอบว่ามี goal ชื่อนี้อยู่แล้วไหม
      const existing = await query(
        'SELECT * FROM saving_goals WHERE user_id = ? AND goal_name = ? AND status != "completed"',
        [userId, goal_name]
      );

      if (existing.length > 0) {
        await logActivity({
            user_id: userId,
            actor_id: userId,
            actor_type: actor.role,
            action: 'CREATE_GOAL_FAIL_EXISTS',
            table_name: 'saving_goals',
            description: `User ${userId} failed to create goal: '${goal_name}' already exists.`,
            req: req,
            new_value: req.body
        });
        return res.status(409).json({
          status: false,
          message: 'มีเป้าหมายนี้อยู่แล้วในระบบ',
        });
      }

      // ตรวจสอบหรือสร้าง wallet
      let walletId: number | null = null;
      const walletRows = await query(
        'SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1',
        [userId]
      );

      if (walletRows.length === 0) {
        const createWallet = await query(
          'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
          [userId, 'Main Wallet', 'THB']
        );
        walletId = createWallet.insertId;
      } else {
        walletId = walletRows[0].wallet_id;
      }

      const dateToUse = start_date || new Date().toISOString().slice(0, 10);

      let nextDate: Date | null = null;
      const now = new Date();
      if (frequency === 'daily') nextDate = new Date(now.setDate(now.getDate() + 1));
      else if (frequency === 'weekly') nextDate = new Date(now.setDate(now.getDate() + 7));
      else if (frequency === 'monthly') nextDate = new Date(now.setMonth(now.getMonth() + 1));
      else if (frequency === 'one-time') nextDate = null;

      // 🟢 เพิ่มเป้าหมายใหม่ (ตาม schema ใหม่)
      const result: any = await query(
        `INSERT INTO saving_goals 
         (user_id, wallet_id, goal_name, target_amount, contribution_amount, frequency, start_date, next_deduction_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, // 👈 (8 ?)
        [
          userId,
          walletId,
          goal_name,
          target_amount,
          contribution_amount,
          frequency,
          start_date || new Date(),
          nextDate,
        ]
      );
      const newGoalId = result.insertId;

      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role,
          action: 'CREATE_SAVING_GOAL',
          table_name: 'saving_goals',
          record_id: newGoalId,
          description: `User ${userId} created new goal: '${goal_name}' (ID: ${newGoalId}).`,
          req: req,
          new_value: req.body
      });

      res.json({ status: true, message: 'สร้างเป้าหมายออมเงินสำเร็จ' });
    } catch (err: any) {
      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: 'system',
          action: 'CREATE_GOAL_EXCEPTION',
          table_name: 'saving_goals',
          description: `Failed to create goal. Error: ${err.message}`,
          req: req,
          new_value: { error: err.stack }
      });
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

/* ================================================
   📄 READ: ดึงรายการเป้าหมายออมทั้งหมดของผู้ใช้
================================================ */
routerG.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }

    const userId = actor.user_id;

  try {
    const goals = await query(
      `SELECT goal_id, goal_name, target_amount, current_amount, contribution_amount,
              frequency, status, start_date, next_deduction_date,
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
routerG.get('/:id', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }

  const userId = actor.user_id;
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
    body('contribution_amount').optional().isFloat({ gt: 0 }),
    body('frequency').optional().isIn(['daily', 'weekly', 'monthly', 'one-time']),
    body('next_deduction_date').optional().isISO8601().toDate(),
  ],
  async (req: AuthRequest, res: Response) => {
    const actor = req.user;
  if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }

    const userId = actor.user_id;
    const goalId = req.params.id;

    const fields = req.body;
    const setClause = Object.keys(fields)
      .map((key) => `${key} = ?`)
      .join(', ');
    const values = [...Object.values(fields), goalId, userId];

    if (Object.keys(fields).length === 0) {
      return res.status(400).json({ status: false, message: 'ไม่มีข้อมูลที่จะแก้ไข' });
    }

    try {
      const [oldGoal] = await query("SELECT * FROM saving_goals WHERE goal_id = ? AND user_id = ?", [goalId, userId]);

      if (!oldGoal) {
          return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายนี้' });
      }
      await query(
        `UPDATE saving_goals SET ${setClause}, updated_at = NOW() WHERE goal_id = ? AND user_id = ?`,
        values
      );

      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role,
          action: 'UPDATE_SAVING_GOAL',
          table_name: 'saving_goals',
          record_id: goalId,
          description: `User ${userId} updated goal: '${oldGoal.goal_name}' (ID: ${goalId}).`,
          req: req,
          old_value: oldGoal,
          new_value: req.body
      });

      res.json({ status: true, message: 'อัปเดตเป้าหมายเรียบร้อย' });
    } catch (err: any) {
      console.error(err);
      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: 'system',
          action: 'UPDATE_GOAL_EXCEPTION',
          table_name: 'saving_goals',
          record_id: goalId,
          description: `Failed to update goal (ID: ${goalId}). Error: ${err.message}`,
          req: req,
          new_value: { error: err.stack }
      });
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

/* ================================================
   🟡 PATCH: เปลี่ยนสถานะเป้าหมาย
================================================ */
routerG.patch('/:id/status', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }

  const userId = actor.user_id;
  const goalId = req.params.id;
  const { status } = req.body;

  const allowed = ['active', 'paused', 'completed', 'cancelled'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ status: false, message: 'สถานะไม่ถูกต้อง' });
  }

  try {
    const [oldGoal] = await query("SELECT status, goal_name FROM saving_goals WHERE goal_id = ? AND user_id = ?", [goalId, userId]);

    if (!oldGoal) {
        return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายนี้' });
    }
    await query(
      `UPDATE saving_goals SET status = ?, updated_at = NOW() WHERE goal_id = ? AND user_id = ?`,
      [status, goalId, userId]
    );

    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'UPDATE_GOAL_STATUS',
        table_name: 'saving_goals',
        record_id: goalId,
        description: `User ${userId} changed goal '${oldGoal.goal_name}' status to '${status}'.`,
        req: req,
        old_value: oldGoal,
        new_value: { status }
    });

    res.json({ status: true, message: `อัปเดตสถานะเป็น ${status}` });
  } catch (err: any) {
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'UPDATE_GOAL_STATUS_EXCEPTION',
        table_name: 'saving_goals',
        record_id: goalId,
        description: `Failed to update goal status (ID: ${goalId}). Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ================================================
   ❌ DELETE: ลบเป้าหมายออมเงิน
================================================ */
routerG.delete('/:id', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }

  const userId = actor.user_id;
  const goalId = req.params.id;

  try {const [oldGoal] = await query("SELECT * FROM saving_goals WHERE goal_id = ? AND user_id = ?", [goalId, userId]);

    if (!oldGoal) {
      // 14. 🔽 Log (ไม่พบ)
      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role,
          action: 'DELETE_GOAL_FAIL_NOT_FOUND',
          table_name: 'saving_goals',
          record_id: goalId,
          description: `User ${userId} failed to delete goal (ID: ${goalId}): Not found.`,
          req: req
      });
      return res.status(404).json({ status: false, message: 'ไม่พบเป้าหมายนี้' });
    }
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'DELETE_SAVING_GOAL',
        table_name: 'saving_goals',
        record_id: goalId,
        description: `User ${userId} deleted goal: '${oldGoal.goal_name}' (ID: ${goalId}).`,
        req: req,
        old_value: oldGoal // 👈 บันทึกข้อมูลที่ถูกลบ
    });
    await query('DELETE FROM saving_goals WHERE goal_id = ? AND user_id = ?', [
        goalId,
        userId,
      ]);

    res.json({ status: true, message: 'ลบเป้าหมายเรียบร้อย' });
  } catch (err: any) {
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'DELETE_GOAL_EXCEPTION',
        table_name: 'saving_goals',
        record_id: goalId,
        description: `Failed to delete goal (ID: ${goalId}). Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerG;