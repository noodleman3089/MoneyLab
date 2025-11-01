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
        user_id: 0, // -1 หรือ null เพราะเป็นการกระทำต่อ "หลายคน"
        actor_id: actor.user_id,
        actor_type: 'admin',
        action: 'VIEW_ALL_USERS',
        table_name: 'users',
        record_id: actor.user_id,
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
      user_id: 0,
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

// DELETE - ลบ user
routerA.delete('/users/:id', verifyAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const actor = req.user;

    // 1. ตรวจสอบ Actor (เหมือนเดิม)
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid admin token data' });
    }

    // 2. 🔽 ตรวจสอบว่าผู้ใช้มีอยู่จริง (เพิ่มส่วนนี้)
    const existing = await query('SELECT user_id, username FROM users WHERE user_id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ status: false, message: 'User not found' });
    }
    const targetUsername = existing[0].username;

    // 3. 🔽 บันทึก Log ก่อน (ย้ายขึ้นมา)
    //    (ตอนนี้ Log จะทำงานสำเร็จ เพราะ user_id = id ยังคงอยู่)
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

    // 4. 🔽 ลบผู้ใช้ (ย้ายลงมา)
    const sql = `DELETE FROM users WHERE user_id = ?`;
    await query(sql, [id]); // ไม่ต้องเช็ค affectedRows แล้ว เพราะเรารู้ว่ามีอยู่จริง

    res.json({ status: true, message: 'User deleted successfully' });

  } catch (err: any) {
    // 5. บันทึก Log เมื่อเกิด Error (เหมือนเดิม)
    const actor = req.user;
    const { id } = req.params;

    await logActivity({
      user_id: Number(id) || 0, // (ใช้ 0 ตามที่เราตกลงกัน)
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
      actor_id: actor?.user_id,
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