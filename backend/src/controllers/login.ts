import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../../index';

const controllers_L = express();
const SECRET_KEY = process.env.SECRET_KEY || '1234'; 

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
    const users = await query(
      "SELECT * FROM moneylab.users WHERE (username=? OR email=?)",
      [username, username]
    );

    if (users.length === 0) {
      return res.status(401).send({ message: 'Invalid username/email or password', status: false });
    }

    const user = users[0];

    // ใช้ password_hash ตาม table
    const isPasswordValid = bcrypt.compareSync(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).send({ message: 'Invalid username/email or password', status: false });
    }

    await query('UPDATE users SET last_login_at = NOW() WHERE user_id = ?',[user.user_id]);

    const token = jwt.sign(
      { user_id: user.user_id, username: user.username, role: user.role },
      SECRET_KEY,
      { expiresIn: '1h' }
    );

    res.send({
      user_id: user.user_id,
      username: user.username,
      email: user.email,
      token,
      message: 'Login successful',
      status: true
    });

  } catch (err) {
    next(err);
  }
});

export default controllers_L;
