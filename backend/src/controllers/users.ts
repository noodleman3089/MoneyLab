import express, { Request, Response, NextFunction } from 'express';
import { query } from '../index';
import { authenticateToken, isAdmin } from '../middlewares/authMiddleware';

const usersController = express.Router();

/**
 * Route: PATCH /api/users/:userId/promote
 * Description: เลื่อนขั้นผู้ใช้ธรรมดาให้เป็น Admin
 * Access: Admin Only
 */
usersController.patch(
  '/users/:userId/promote',
  authenticateToken, // 1. ตรวจสอบว่าล็อกอินหรือยัง
  isAdmin,           // 2. ตรวจสอบว่าเป็น Admin หรือไม่
  async (req: Request, res: Response, next: NextFunction) => {
    const userIdToPromote = req.params.userId;

    try {
      // ตรวจสอบว่ามีผู้ใช้นี้อยู่จริงหรือไม่ และสถานะปัจจุบันเป็น 'user'
      const [user] = await query('SELECT role FROM users WHERE user_id = ?', [userIdToPromote]);

      if (!user) {
        return res.status(404).json({ status: false, message: 'User not found' });
      }
      if (user.role === 'admin') {
        return res.status(400).json({ status: false, message: 'User is already an admin' });
      }

      // อัปเดต role เป็น 'admin'
      await query("UPDATE users SET role = 'admin' WHERE user_id = ?", [userIdToPromote]);

      res.json({ status: true, message: 'User has been promoted to admin successfully' });
    } catch (error) {
      next(error);
    }
  }
);

export default usersController;