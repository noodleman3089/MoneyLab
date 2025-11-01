import express, { Request, Response } from 'express';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';

const routerN = express.Router();

// 🧩 GET /api/notifications — ดึงรายการแจ้งเตือนทั้งหมด
routerN.get('/', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;

  try {
    const notifications = await query(
      `SELECT notification_id, type, title, message, reference_type, reference_id, 
              is_read, created_at, read_at
       FROM notifications
       WHERE user_id = ?
       ORDER BY created_at DESC`,
      [userId]
    );

    res.json({ status: true, data: notifications });
  } catch (err) {
    console.error('❌ Fetch notifications error:', err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

// ✅ PATCH /api/notifications/:id/read — เปลี่ยนสถานะเป็นอ่านแล้ว
routerN.patch('/:id/read', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;
  const { id } = req.params;

  try {
    await query(
      `UPDATE notifications 
       SET is_read = 1, read_at = NOW()
       WHERE notification_id = ? AND user_id = ?`,
      [id, userId]
    );

    res.json({ status: true, message: 'Notification marked as read' });
  } catch (err) {
    console.error('❌ Update notification error:', err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerN;