import express, { Response } from 'express';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';

const routerN = express.Router();

// 🧩 GET /api/notifications — ดึงรายการแจ้งเตือนทั้งหมด
routerN.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;

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
  } catch (err: any) {
    console.error('❌ Fetch notifications error:', err);
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'FETCH_NOTIFICATIONS_EXCEPTION',
        table_name: 'notifications',
        description: `Failed to fetch notifications. Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

// ✅ PATCH /api/notifications/:id/read — เปลี่ยนสถานะเป็นอ่านแล้ว
routerN.patch('/:id/read', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;
  const { id } = req.params;

  try {
    const [oldNotif] = await query(
      "SELECT * FROM notifications WHERE notification_id = ? AND user_id = ?",
      [id, userId]
    );
    
    if (!oldNotif) {
      // 6. 🔽 Log (ไม่พบ)
      await logActivity({
          user_id: userId,
          actor_id: userId,
          actor_type: actor.role,
          action: 'MARK_NOTIFICATION_READ_FAIL_NOT_FOUND',
          table_name: 'notifications',
          record_id: id,
          description: `User ${userId} failed to mark notification ${id} as read: Not found.`,
          req: req
      });
      return res.status(404).json({ status: false, message: 'Notification not found' });
    }
    await query(
      `UPDATE notifications 
       SET is_read = 1, read_at = NOW()
       WHERE notification_id = ? AND user_id = ?`,
      [id, userId]
    );

    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'MARK_NOTIFICATION_READ_SUCCESS',
        table_name: 'notifications',
        record_id: id,
        description: `User ${userId} marked notification ${id} as read. Title: ${oldNotif.title}`,
        req: req,
        old_value: { is_read: oldNotif.is_read },
        new_value: { is_read: 1 }
    });

    res.json({ status: true, message: 'Notification marked as read' });
  } catch (err: any) {
    console.error('❌ Update notification error:', err);
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'MARK_NOTIFICATION_READ_EXCEPTION',
        table_name: 'notifications',
        record_id: id,
        description: `Failed to mark notification ${id} as read. Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerN;