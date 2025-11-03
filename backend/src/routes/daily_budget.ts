import express, { Response } from 'express';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';

const routerD = express.Router();

/* ------------------ 1️⃣ POST: ตั้งงบรายวัน ------------------ */
routerD.post('/set', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;

  const { target_spend, date } = req.body;
  const budgetDate = date || new Date().toISOString().split('T')[0]; // YYYY-MM-DD

  try {
    await query(`
      INSERT INTO daily_budget (user_id, budget_date, target_spend)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE target_spend = VALUES(target_spend), updated_at = NOW()
    `, [userId, budgetDate, target_spend]);

    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'SET_DAILY_BUDGET',
        table_name: 'daily_budget',
        description: `User ${userId} set budget for ${budgetDate} to ${target_spend}.`,
        req: req,
        new_value: { budgetDate, target_spend }
    });

    res.json({
      status: true,
      message: `ตั้งงบรายวันเรียบร้อย`,
      data: { budgetDate, target_spend }
    });
  } catch (err: any) {
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'SET_DAILY_BUDGET_EXCEPTION',
        table_name: 'daily_budget',
        description: `Failed to set budget for ${budgetDate}. Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ------------------ 2️⃣ GET: ดูงบรายวันของวันนี้ ------------------ */
routerD.get('/today', authenticateToken, async (req: AuthRequest, res: Response) => {
 const actor = req.user;
 if (!actor) {
   return res.status(401).json({ status: false, message: 'Invalid token data' });
 }
 const userId = actor.user_id;

  try {
    const [budget] = await query(`
      SELECT * FROM daily_budget WHERE user_id = ? AND budget_date = CURDATE()
    `, [userId]);

    const [spend] = await query(`
      SELECT COALESCE(SUM(amount), 0) AS total_spend
      FROM transactions
      WHERE user_id = ? AND type = 'expense' AND DATE(transaction_date) = CURDATE()
    `, [userId]);

    if (!budget) {
      return res.json({
        status: false,
        message: 'ยังไม่ได้ตั้งงบสำหรับวันนี้',
        total_spend: spend.total_spend
      });
    }

    res.json({
      status: true,
      budget_date: budget.budget_date,
      target_spend: budget.target_spend,
      total_spend: spend.total_spend,
      remaining: budget.target_spend - spend.total_spend,
      over_budget: spend.total_spend > budget.target_spend
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ------------------ 3️⃣ PUT: อัปเดตงบรายวัน ------------------ */
routerD.put('/update', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;

  const { target_spend, date } = req.body;
  const budgetDate = date || new Date().toISOString().split('T')[0];

  try {
    const [oldBudget] = await query(
      "SELECT target_spend FROM daily_budget WHERE user_id = ? AND budget_date = ?",
      [userId, budgetDate]
    );

    if (!oldBudget) {
      await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'UPDATE_BUDGET_FAIL_NOT_FOUND',
        table_name: 'daily_budget',
        description: `User ${userId} failed to update budget for ${budgetDate}: Not found.`,
        req: req,
        new_value: { budgetDate, target_spend }
      });
      return res.status(404).json({ status: false, message: 'ไม่พบนงบของวันดังกล่าว' });
    }

    const old_target_spend = oldBudget.target_spend;

    await query(`
      UPDATE daily_budget
      SET target_spend = ?, updated_at = NOW()
      WHERE user_id = ? AND budget_date = ?
    `, [target_spend, userId, budgetDate]);

    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'UPDATE_DAILY_BUDGET',
        table_name: 'daily_budget',
        description: `User ${userId} updated budget for ${budgetDate}.`,
        req: req,
        old_value: { target_spend: old_target_spend },
        new_value: { target_spend: target_spend }
    });

    res.json({ status: true, message: 'อัปเดตงบรายวันสำเร็จ' });
  } catch (err: any) {
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'UPDATE_BUDGET_EXCEPTION',
        table_name: 'daily_budget',
        description: `Failed to update budget for ${budgetDate}. Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ------------------ 4️⃣ GET: สรุปย้อนหลังรายวัน ------------------ */
routerD.get('/summary', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;

  const { start_date, end_date } = req.query;

  try {
    const summary = await query(`
      SELECT 
        d.budget_date,
        d.target_spend,
        COALESCE(SUM(t.amount), 0) AS total_spend,
        (d.target_spend - COALESCE(SUM(t.amount), 0)) AS remaining,
        CASE 
          WHEN COALESCE(SUM(t.amount), 0) > d.target_spend THEN 'over'
          WHEN COALESCE(SUM(t.amount), 0) = d.target_spend THEN 'exact'
          ELSE 'under'
        END AS status
      FROM daily_budget d
      LEFT JOIN transactions t
        ON t.user_id = d.user_id
        AND DATE(t.transaction_date) = d.budget_date
        AND t.type = 'expense'
      WHERE d.user_id = ?
        AND d.budget_date BETWEEN ? AND ?
      GROUP BY d.budget_date, d.target_spend
      ORDER BY d.budget_date DESC
    `, [userId, start_date, end_date]);

    res.json({ status: true, summary });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

/* ------------------ 5️⃣ GET: ตรวจสอบสถานะงบวันนี้ ------------------ */
routerD.get('/check', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;

  try {
    const [row] = await query(`
      SELECT 
        d.budget_date,
        d.target_spend,
        COALESCE(SUM(t.amount), 0) AS total_spend,
        CASE 
          WHEN COALESCE(SUM(t.amount), 0) > d.target_spend THEN 'over_budget'
          WHEN COALESCE(SUM(t.amount), 0) = d.target_spend THEN 'on_target'
          ELSE 'under_budget'
        END AS status
      FROM daily_budget d
      LEFT JOIN transactions t
        ON t.user_id = d.user_id
        AND DATE(t.transaction_date) = d.budget_date
        AND t.type = 'expense'
      WHERE d.user_id = ? AND d.budget_date = CURDATE()
      GROUP BY d.budget_date, d.target_spend
    `, [userId]);

    if (!row) {
      return res.json({ status: false, message: 'ยังไม่ได้ตั้งงบรายวัน' });
    }

    res.json({
      status: true,
      data: row
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerD;