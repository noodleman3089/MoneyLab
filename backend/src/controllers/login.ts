import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../index';
import { logActivity } from '../services/log.service';
import { ActorRoleType } from '../middlewares/authMiddleware';
import { v4 as uuidv4 } from 'uuid';

const controllers_L = express();
const SECRET_KEY = process.env.SECRET_KEY;

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
    
    const [user] = await query(
      "SELECT user_id, username, email, password_hash, role FROM users WHERE (username=? OR email=?)",
      [username, username]
    );

    if (!user) {
      return res.status(401).json({ status: false, message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' });
    }

    if (!user.password_hash) {
      await logActivity({
          user_id: user.user_id,
          actor_id: user.user_id,
          actor_type: 'user',
          action: 'LOGIN_FAIL_SUSPENDED',
          table_name: 'users',
          record_id: user.user_id,
          description: `Login attempt by suspended user: ${user.username}.`,
          req: req
      });
      
      return res.status(403).send({ message: 'บัญชีนี้ถูกระงับการใช้งาน', status: false }); 
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    const dbRole: string = user.role;
    const tokenRole: ActorRoleType = (dbRole === 'admin' || dbRole === 'system' || dbRole === 'api') 
                                      ? dbRole 
                                      : 'user';

    if (!isPasswordValid) {
      await logActivity({
        user_id: user.user_id,
        actor_id: user.user_id,
        actor_type: user.role,
        action: 'LOGIN_FAIL',
        table_name: 'users',
        record_id: user.user_id,
        description: `Failed login attempt for ${user.username}.`,
        req: req
      });
      return res.status(401).send({ message: 'Invalid password', status: false });
    }

    await query('UPDATE users SET last_login_at = NOW() WHERE user_id = ?',[user.user_id]);

    await logActivity({
      user_id: user.user_id,
      actor_id: user.user_id,
      actor_type: tokenRole,
      action: 'LOGIN_SUCCESS',
      table_name: 'users',
      record_id: user.user_id,
      description: `User ${user.username} logged in.`,
      req: req
    });

    const jti = uuidv4();
    const token = jwt.sign(
      { user_id: user.user_id, username: user.username, role: tokenRole },
      SECRET_KEY!,
      { 
        expiresIn: '30d',
        jwtid: jti // 3. เพิ่ม JTI (JWT ID) เข้าไปใน Token
      }
    );

    const [surveyCheck] = await query(
      'SELECT EXISTS(SELECT 1 FROM survey_answer WHERE user_id = ?) AS has_answered',
      [user.user_id]
    );
    const surveyCompleted = surveyCheck.has_answered === 1;

    res.json({
      status: true,
      message: 'เข้าสู่ระบบสำเร็จ',
      token: token,
      user: { 
        user_id: user.user_id,
        username: user.username,
        role: user.role, 
        survey_completed: surveyCompleted
      }
    });

  } catch (err: any) {
    await logActivity({
        user_id: null, 
        actor_id: null,
        actor_type: 'system',
        action: 'LOGIN_EXCEPTION',
        description: `Login exception for attempt [${username || 'N/A'}]. Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
      });
    next(err);
  }
});

export default controllers_L;