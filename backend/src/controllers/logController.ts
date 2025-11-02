import express, { Request, Response, NextFunction } from 'express';
import { query } from '../index';
import { authenticateToken, verifyAdmin } from '../middlewares/authMiddleware';

const logController = express.Router();

/**
 * Route: GET /api/logs
 * Description: ดึงข้อมูล Log ทั้งหมดพร้อม Pagination
 * Access: Admin Only
 */
logController.get(
  '/logs',
  authenticateToken, // 1. ตรวจสอบ Token
  verifyAdmin,       // 2. ตรวจสอบว่าเป็น Admin (แก้ไขชื่อฟังก์ชัน)
  async (req: Request, res: Response, next: NextFunction) => {
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    try {
      // ดึงข้อมูล Log ตาม limit และ offset
      const logs = await query(
        `SELECT 
          log_id, actor_id, actor_type, action, table_name, record_id, 
          description, INET6_NTOA(ip_address) as ip_address, user_agent, 
          created_at, old_value, new_value 
         FROM log 
         ORDER BY created_at DESC 
         LIMIT ? OFFSET ?`,
        [limit, offset]
      );

      // ดึงจำนวน Log ทั้งหมดเพื่อทำ Pagination
      // [THE FIX] เปลี่ยนวิธีการ Destructuring ให้ถูกต้อง
      const totalResult = await query('SELECT COUNT(*) as total FROM log');
      const total = totalResult[0].total;

      const nextOffset = offset + limit < total ? offset + limit : null;
      const prevOffset = offset - limit >= 0 ? offset - limit : null;

      res.json({
        status: true,
        data: logs,
        pagination: {
          total,
          limit,
          offset,
          nextOffset,
          prevOffset,
        },
      });
    } catch (error) {
      console.error('Failed to fetch logs:', error);
      next(error);
    }
  }
);

export default logController;