import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export type ActorRoleType = 'user' | 'admin' | 'system' | 'api';
// 1. 🚨 แก้ไขเรื่องความปลอดภัย (ใช้ SECRET_KEY จาก .env และ Fail-Fast)
const SECRET_KEY = process.env.SECRET_KEY;

if (!SECRET_KEY) {
  console.error("FATAL ERROR: SECRET_KEY is not defined in .env file.");
  process.exit(1); // หยุดเซิร์ฟเวอร์ทันทีถ้าไม่มี Key
}

// 2. ⌨️ สร้าง Interface สำหรับ Payload ใน JWT
interface JwtPayload {
  user_id: number;
  username: string;
  role: ActorRoleType;
}

// 3. ⌨️ สร้าง Interface สำหรับ Request ที่มี user
// (วิธีนี้ดีกว่าการใช้ (req as any))
export interface AuthRequest extends Request {
  user?: JwtPayload;
}

// ✅ (แก้ไขเล็กน้อย) ใช้ AuthRequest
export const verifyAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ status: false, message: 'Unauthorized: Missing or invalid Bearer token' });
  }

  const token = authHeader.split(' ')[1];
  try {
    // 1. 🚨 ใช้ SECRET_KEY ที่ปลอดภัย (ไม่ต้องใช้ !) เพราะเราเช็คด้านบนแล้ว
    const decoded = jwt.verify(token, SECRET_KEY) as JwtPayload;

    if (decoded.role !== 'admin') {
      return res.status(403).json({ status: false, message: 'Forbidden: Admins only' });
    }

    req.user = decoded; // ✅ ตอนนี้ TypeScript รู้จัก req.user แล้ว
    next();

  } catch (err) {
    return res.status(401).json({ status: false, message: 'Invalid or expired token' });
  }
};

// ✅ (แก้ไขใหม่) ใช้รูปแบบเดียวกับ verifyAdmin (try...catch)
export const authenticateToken = (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ status: false, message: 'Unauthorized: Missing or invalid Bearer token' });
  }

  const token = authHeader.split(' ')[1];
  try {
    // 1. 🚨 ใช้ SECRET_KEY ที่ปลอดภัย
    const decoded = jwt.verify(token, SECRET_KEY) as JwtPayload;

    req.user = decoded; // ✅ TypeScript รู้จัก
    next();

  } catch (err) {
    return res.status(401).json({ status: false, message: 'Invalid or expired token' });
  }
};