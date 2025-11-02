import express, { Request, Response } from 'express';
import { query } from '../index';
import { verifyAdmin } from '../middlewares/authMiddleware';
import * as crypto from 'crypto';

const routerA = express.Router();
/**
 * USERS CRUD
 */

// READ - ดึง users ทั้งหมด
routerA.get('/api/users', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const limit = Number(req.query.limit) || 50;
    const offset = Number(req.query.offset) || 0;
    const role = req.query.role ? String(req.query.role).trim() : null;

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
    res.status(500).json({ status: false, message: 'Failed to fetch users', error: err.message });
  }
});

// DELETE - ลบ user
routerA.delete('api/users/:id', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const sql = `DELETE FROM users WHERE user_id = ?`;
    const result = await query(sql, [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }
    res.json({ status: true, message: 'User deleted successfully' });
  } catch (err: any) {
    res.status(500).json({ status: false, message: 'Failed to delete user', error: err.message });
  }
});

routerA.delete('/api/users/soft/:id', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // ตรวจสอบว่าผู้ใช้อยู่จริง
    const existing = await query('SELECT user_id FROM users WHERE user_id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }

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
    console.error('❌ Delete (hash) user error:', err);
    res.status(500).json({
      status: false,
      message: 'Failed to hash user data',
      error: err.message,
    });
  }
});

export default routerA;