import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../index';
import { logActivity } from '../services/log.service';
import { ActorRoleType } from '../middlewares/authMiddleware';

const controllers_L = express();
const SECRET_KEY = process.env.SECRET_KEY;

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

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isPasswordValid) {
      await logActivity({
        user_id: user.user_id, // User ที่พยายาม Login
        actor_id: user.user_id,
        actor_type: user.role, // 'user' หรือ 'admin'
        action: 'LOGIN_FAIL',
        table_name: 'users',
        record_id: user.user_id,
        description: `Failed login attempt for ${user.username}.`,
        req: req // 👈 ส่ง req object ไปด้วย
      });
      return res.status(401).send({ message: 'Invalid password', status: false });
    }

    await query('UPDATE users SET last_login_at = NOW() WHERE user_id = ?',[user.user_id]);

    await logActivity({
      user_id: user.user_id,
      actor_id: user.user_id,
      actor_type: user.role,
      action: 'LOGIN_SUCCESS',
      table_name: 'users',
      record_id: user.user_id,
      description: `User ${user.username} logged in.`,
      req: req
    });

    const dbRole: string = user.role;
    const tokenRole: ActorRoleType = (dbRole === 'admin' || dbRole === 'system' || dbRole === 'api') 
                                      ? dbRole 
                                      : 'user';

    const token = jwt.sign(
      { user_id: user.user_id, username: user.username, role: tokenRole },
      SECRET_KEY!,
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

  } catch (err: any) {
    await logActivity({
        user_id: 0, // หรือ user_id จาก req.body ถ้าพยายาม parse ได้
        actor_id: 0,
        actor_type: 'system',
        action: 'LOGIN_EXCEPTION',
        description: `Login process failed with error: ${err.message}`,
        req: req,
        new_value: { error: err.stack } // เก็บ stack trace
      });
    next(err);
  }
});

export default controllers_L;
