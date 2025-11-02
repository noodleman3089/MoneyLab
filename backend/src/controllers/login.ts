import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../index';

const controllers_L = express.Router(); // 👈 1. [FIX] เปลี่ยนเป็น Router()
const JWT_SECRET = process.env.JWT_SECRET || '1234';

// Login
controllers_L.post('/login',
[
  body('username').isString().notEmpty().withMessage('Username or email is required'),
  body('password').isString().notEmpty().withMessage('Password is required')
], async (req: Request, res: Response, next: NextFunction) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).send({ message: 'Validation errors', errors: errors.array(), status: false });
  }

  const { username, password } = req.body;
  try {
    // SQL ถูกต้อง
    const [user] = await query(
      "SELECT user_id, username, email, password_hash, role FROM users WHERE (username=? OR email=?)", // 👈 2. [OPTIMIZED] ดึงข้อมูลที่จำเป็น
      [username, username]
    );

    if (!user) {
      return res.status(401).json({ status: false, message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' });
    }

    // 👈 3. [FIX] เปลี่ยนไปใช้ bcrypt.compare แบบ async
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ status: false, message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' });
    }

    await query('UPDATE users SET last_login_at = NOW() WHERE user_id = ?',[user.user_id]);

    // 👈 4. [FIX] สร้าง Token ให้มีข้อมูล role
    const token = jwt.sign(
      { user_id: user.user_id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '1h' }
    );

    // 👈 5. [THE FIX] ส่งข้อมูลกลับในรูปแบบที่ Frontend ต้องการ
    res.json({
      status: true,
      message: 'เข้าสู่ระบบสำเร็จ',
      token: token,
      user: { // <-- สร้าง object user ที่ซ้อนอยู่ข้างใน
        user_id: user.user_id,
        username: user.username,
        role: user.role // <-- ส่ง role กลับไปด้วย
      }
    });

  } catch (err) {
    next(err);
  }
});

export default controllers_L;
