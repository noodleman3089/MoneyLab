import express, { Response } from 'express';
import { query } from '../index';
import { verifyAdmin, AuthRequest } from '../middlewares/authMiddleware';
import * as crypto from 'crypto';
import { logActivity } from '../services/log.service';

const routerA = express.Router();
/**
 * USERS CRUD
 */

// READ - ดึง users ทั้งหมด
routerA.get('/users', verifyAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const limit = Number(req.query.limit) || 50;
    const offset = Number(req.query.offset) || 0;
    const role = req.query.role ? String(req.query.role).trim() : null;
    const actor = req.user;

    const safeLimit = Math.min(limit, 100);
    const params: any[] = [];
    let whereClause = '';

    if (role) {
      whereClause = 'WHERE users.role = ?';
      params.push(role);
    }

    const sql = `
      SELECT users.user_id, users.username, users.email, users.phone_number,
             users.last_login_at, users.created_at, users.updated_at, users.role
      FROM users
      ${whereClause}
      ORDER BY users.created_at DESC
      LIMIT ? OFFSET ?
    `;
    params.push(safeLimit, offset);
    const users = await query(sql, params);

    const totalSql = `SELECT COUNT(*) AS total FROM users ${whereClause}`;
    const totalResult = await query(totalSql, role ? [role] : []);
    const total = totalResult[0].total;

    if (actor) {
      await logActivity({
        user_id: null, // 👈 [THE FIX] เปลี่ยนจาก 0 เป็น null
        actor_id: actor.user_id,
        actor_type: 'admin',
        action: 'VIEW_ALL_USERS',
        table_name: 'users', // ระบุตารางที่เกี่ยวข้อง
        record_id: null, // ไม่ได้เจาะจง record ใด
        description: `Admin ${actor.username} fetched user list (Limit: ${safeLimit}, Offset: ${offset}, Role: ${role || 'all'}).`,
        req: req
      });
    }

    res.json({
      status: true,
      message: 'Users fetched successfully',
      data: users,
      pagination: {
        total,
        limit: safeLimit,
        offset,
        nextOffset: offset + safeLimit < total ? offset + safeLimit : null,
        prevOffset: offset - safeLimit >= 0 ? offset - safeLimit : null
      },
      filter: role ? { role } : null
    });
  } catch (err: any) {
    const actor = req.user; // ดึง actor จาก req
    
    await logActivity({
      user_id: null, // 👈 [THE FIX] เปลี่ยนจาก 0 เป็น null
      actor_id: actor?.user_id || 0, // 👈 ใช้ ?. ป้องกัน actor เป็น undefined
      actor_type: 'system',
      action: 'VIEW_ALL_USERS_EXCEPTION',
      description: `Failed to fetch users. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack } // 👈 เก็บ stack trace ไว้เลย
    });

    res.status(500).json({ status: false, message: 'Failed to fetch users', error: err.message });
  }
});

// READ - ดึงข้อมูลผู้ใช้คนเดียวแบบละเอียด (สำหรับหน้า User Detail)
routerA.get('/users/:id', verifyAdmin, async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const actor = req.user;
  try {
    if (!actor) { // 👈 เพิ่ม Guard Clause
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }

    // 1. ดึงข้อมูลหลักจากตาราง users
    const userSql = `SELECT user_id, username, email, phone_number, role, created_at, last_login_at FROM users WHERE user_id = ?`;
    const [user] = await query(userSql, [id]);

    if (!user) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }

    // 2. ดึงข้อมูลโปรไฟล์ (อาชีพ, รายได้) จากตาราง profile
    const profileSql = `SELECT * FROM profile WHERE user_id = ?`;
    const [profile] = await query(profileSql, [id]);

    // 3. ดึงข้อมูลหนี้สินทั้งหมด จากตาราง debt
    const debtsSql = `SELECT * FROM debt d JOIN profile p ON d.profile_id = p.profile_id WHERE p.user_id = ?`;
    const debts = await query(debtsSql, [id]);

    // 4. ดึงธุรกรรมล่าสุด 20 รายการ จากตาราง transactions
    const transactionsSql = `SELECT * FROM transactions WHERE user_id = ? ORDER BY transaction_date DESC LIMIT 20`;
    const transactions = await query(transactionsSql, [id]);

    await logActivity({
      user_id: Number(id),
      actor_id: actor.user_id,
      actor_type: 'admin',
      action: 'VIEW_USER_DETAIL',
      table_name: 'users',
      record_id: id,
      description: `Admin ${actor.username} viewed details for user ID: ${id}.`,
      req: req
    });

    res.json({
      status: true,
      data: {
        user,
        profile: profile || null,
        debts,
        transactions,
      }
    });
  } catch (err: any) {
    await logActivity({
      user_id: Number(id) || 0,
      actor_id: actor?.user_id || 0,
      actor_type: 'system',
      action: 'VIEW_USER_DETAIL_EXCEPTION',
      description: `Failed to fetch user details for ID: ${id}. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });
    res.status(500).json({ status: false, message: 'Failed to fetch user details', error: err.message });
  }
});

// DELETE - ลบ user
routerA.delete('/users/:id', verifyAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const actor = req.user;

    // 1. ตรวจสอบ Actor
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }

    // 2. ตรวจสอบว่าผู้ใช้มีอยู่จริง
    const existing = await query('SELECT user_id, username FROM users WHERE user_id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }
    const targetUsername = existing[0].username;

    // 3.  บันทึก Log 
    await logActivity({
      user_id: Number(id),
      actor_id: actor.user_id,
      actor_type: 'admin',
      action: 'DELETE_USER',
      table_name: 'users',
      record_id: id,
      description: `Admin ${actor.username} (ID: ${actor.user_id}) deleted user ${targetUsername} (ID: ${id}).`,
      req: req
    });

    // 4. ลบผู้ใช้
    const sql = `DELETE FROM users WHERE user_id = ?`;
    await query(sql, [id]);

    res.json({ status: true, message: 'User deleted successfully' });

  } catch (err: any) {
    // 5. บันทึก Log เมื่อเกิด Error
    const actor = req.user;
    const { id } = req.params;

    await logActivity({
      user_id: Number(id) || 0,
      actor_id: actor?.user_id || 0,
      actor_type: 'system',
      action: 'DELETE_USER_EXCEPTION',
      description: `Failed to delete user ID: ${id}. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });

    res.status(500).json({ status: false, message: 'Failed to delete user', error: err.message });
  }
});

// UPDATE - ระงับบัญชีผู้ใช้ (Suspend)
routerA.put('/users/:id/suspend', verifyAdmin, async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const actor = req.user;

  try {
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }
    // เราจะเปลี่ยน role ของ user เป็น 'user' และล้าง password_hash เพื่อให้ล็อกอินไม่ได้
    // นี่เป็นวิธีหนึ่งในการ "ระงับ" บัญชี
    // หรือถ้าคุณมีคอลัมน์ status ENUM('active', 'suspended') ก็จะดีกว่า
    const sql = `
      UPDATE users 
      SET 
        password_hash = NULL, -- ทำให้ล็อกอินด้วยรหัสผ่านไม่ได้
        updated_at = NOW()
      WHERE user_id = ?
    `;
    const result = await query(sql, [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }

    await logActivity({
      user_id: Number(id),
      actor_id: actor.user_id,
      actor_type: 'admin',
      action: 'SUSPEND_USER',
      table_name: 'users',
      record_id: id,
      description: `Admin ${actor.username} suspended user ID: ${id}.`,
      req: req
    });

    res.json({ status: true, message: 'User suspended successfully' });

  } catch (err: any) {
    await logActivity({
      user_id: Number(id) || 0,
      actor_id: actor?.user_id || 0,
      actor_type: 'system',
      action: 'SUSPEND_USER_EXCEPTION',
      description: `Failed to suspend user ID: ${id}. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });

    res.status(500).json({ status: false, message: 'Failed to suspend user', error: err.message });
  }
});

/**
 * DASHBOARD APIs
 */

// GET /api/dashboard/summary - ดึงข้อมูลตัวเลขสรุปทั้งหมด
routerA.get('/dashboard/summary', verifyAdmin, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  try {
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }

    const [totalUsers] = await query("SELECT COUNT(*) as count FROM users");
    const [totalTransactions] = await query("SELECT COUNT(*) as count FROM transactions");
    const [totalIncome] = await query("SELECT SUM(amount) as total FROM transactions WHERE type = 'income'");
    const [totalExpense] = await query("SELECT SUM(amount) as total FROM transactions WHERE type = 'expense'");
    const [newUsersToday] = await query("SELECT COUNT(*) as count FROM users WHERE DATE(created_at) = CURDATE()");

    await logActivity({
      user_id: null,
      actor_id: actor.user_id,
      actor_type: 'admin',
      action: 'VIEW_DASHBOARD_SUMMARY',
      table_name: 'transactions',
      description: `Admin ${actor.username} viewed dashboard summary.`,
      req: req
    });

    res.json({
      status: true,
      data: {
        total_users: totalUsers.count,
        total_transactions: totalTransactions.count,
        total_income: parseFloat(totalIncome.total) || 0,
        total_expense: parseFloat(totalExpense.total) || 0,
        new_users_today: newUsersToday.count,
      }
    });
  } catch (err: any) {
    await logActivity({
      user_id: null,
      actor_id: actor?.user_id || 0,
      actor_type: 'admin',
      action: 'VIEW_DASHBOARD_SUMMARY_EXCEPTION',
      description: `Failed to view dashboard summary. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });

    res.status(500).json({ status: false, message: 'Failed to fetch dashboard summary', error: err.message });
  }
});

// GET /api/dashboard/expense-chart - ดึงข้อมูลสำหรับกราฟแท่งรายจ่าย
routerA.get('/dashboard/expense-chart', verifyAdmin, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  try {
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }
    // ดึงข้อมูลรายจ่ายรวมย้อนหลัง 6 เดือน
    const sql = `
      SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month, SUM(amount) AS total_expense
      FROM transactions
      WHERE type = 'expense' AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
      GROUP BY month
      ORDER BY month ASC;
    `;
    const data = await query(sql, []);

    await logActivity({
      user_id: null,
      actor_id: actor.user_id,
      actor_type: 'admin',
      action: 'VIEW_DASHBOARD_EXPENSE_CHART',
      table_name: 'transactions',
      description: `Admin ${actor.username} viewed dashboard expense chart.`,
      req: req
    });

    res.json({ status: true, data });
  } catch (err: any) {
    await logActivity({
      user_id: null,
      actor_id: actor?.user_id || 0,
      actor_type: 'admin',
      action: 'VIEW_DASHBOARD_EXPENSE_CHART_EXCEPTION',
      description: `Failed to view dashboard expense chart. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });
    res.status(500).json({ status: false, message: 'Failed to fetch expense chart data', error: err.message });
  }
});

// GET /api/dashboard/income-chart - ดึงข้อมูลสำหรับกราฟวงกลมรายรับ
routerA.get('/dashboard/income-chart', verifyAdmin, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  try {
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }
    const sql = `
      SELECT c.category_name, SUM(t.amount) AS total_amount
      FROM transactions t
      JOIN category c ON t.category_id = c.category_id
      WHERE t.type = 'income'
      GROUP BY c.category_name
      ORDER BY total_amount DESC;
    `;
    const data = await query(sql, []);
    await logActivity({
      user_id: null,
      actor_id: actor.user_id,
      actor_type: 'admin',
      action: 'VIEW_DASHBOARD_INCOME_CHART',
      table_name: 'transactions',
      description: `Admin ${actor.username} viewed dashboard income chart.`,
      req: req
    });

    res.json({ status: true, data });
  } catch (err: any) {
    await logActivity({
      user_id: null,
      actor_id: actor?.user_id || 0,
      actor_type: 'admin',
      action: 'VIEW_DASHBOARD_INCOME_CHART_EXCEPTION',
      description: `Failed to view dashboard income chart. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });
    res.status(500).json({ status: false, message: 'Failed to fetch income chart data', error: err.message });
  }
});

routerA.delete('/users/soft/:id', verifyAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const actor = req.user;

    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }

    // ตรวจสอบว่าผู้ใช้อยู่จริง
    const existing = await query('SELECT user_id FROM users WHERE user_id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }

    await logActivity({
      user_id: Number(id) || 0,        // 👈 User ที่ "ถูกลบ"
      actor_id: actor.user_id,  // 👈 Admin ที่ "เป็นคนลบ"
      actor_type: 'admin',
      action: 'SOFT_DELETE_USER',
      table_name: 'users',
      record_id: id,
      description: `Admin ${actor.username} (ID: ${actor.user_id}) soft-deleted user ID: ${id}.`,
      req: req
    });

    // สร้าง hash สำหรับแทนข้อมูลส่วนตัว
    const hash = crypto.createHash('sha256').update(`deleted-${id}-${Date.now()}`).digest('hex');

    // อัปเดต user ให้ไม่สามารถใช้งานได้ และ hash ข้อมูลส่วนตัว
    await query(
      `UPDATE users 
       SET 
         username = CONCAT('deleted_', ?),
         email = NULL,
         phone_number = NULL,
         password_hash = NULL,
         role = 'user',
         updated_at = NOW()
       WHERE user_id = ?`,
      [hash.substring(0, 12), id]
    );

    // ถ้าคุณมีฟิลด์ is_active หรือ is_deleted:
    // await query('UPDATE users SET is_active = 0, deleted_at = NOW() WHERE user_id = ?', [id]);

    res.json({
      status: true,
      message: 'User data hashed and account deactivated successfully',
    });
  } catch (err: any) {
    const actor = req.user;
    const { id } = req.params;

    await logActivity({
      user_id: Number(id) || 0,
      actor_id: actor?.user_id || 0,
      actor_type: 'system',
      action: 'SOFT_DELETE_USER_EXCEPTION',
      description: `Failed to soft-delete user ID: ${id}. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });

    res.status(500).json({
      status: false,
      message: 'Failed to hash user data',
      error: err.message,
    });
  }
});

export default routerA;