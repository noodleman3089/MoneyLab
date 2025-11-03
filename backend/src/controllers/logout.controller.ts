// controllers/logout.controller.ts (ไฟล์ใหม่)
import { query } from '../index';
import { AuthRequest } from '../middlewares/authMiddleware';
import { Response } from 'express';
import jwt from 'jsonwebtoken';

export const handleLogout = async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  const token = req.token; // (ต้องแก้ไข authMiddleware ให้ส่ง req.token มาด้วย)

  if (!actor || !token) {
    return res.status(401).json({ status: false, message: 'No token provided' });
  }

  try {
    // 1. ดึงข้อมูล JTI และ EXP (วันหมดอายุ) จาก Token
    const decoded = jwt.decode(token) as { jti: string, exp: number };
    if (!decoded || !decoded.jti || !decoded.exp) {
      return res.status(400).json({ status: false, message: 'Invalid token' });
    }
    
    const jti = decoded.jti;
    const expiresAt = new Date(decoded.exp * 1000); // แปลง Unix time เป็น Date

    // 2. เพิ่ม Token ID นี้ลงใน Blocklist
    await query(
      "INSERT INTO token_blocklist (token_jti, user_id, expires_at) VALUES (?, ?, ?)",
      [jti, actor.user_id, expiresAt]
    );

    res.json({ status: true, message: 'Logged out successfully' });
  } catch (err) {
    res.status(500).json({ status: false, message: 'Server error' });
  }
};