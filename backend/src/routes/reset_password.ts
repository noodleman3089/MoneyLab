import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { query } from '../../index';
import { sendEmail } from '../sendEmail/sendEmail';
import moment from 'moment-timezone';

const routerR = Router();

/**
 * 1) Forgot Password (รองรับ email หรือ username)
 */
routerR.post('/forgot-password', async (req: Request, res: Response) => {
  const { identifier } = req.body; 
  // identifier = email หรือ username ก็ได้

  try {
    let user;

    // เช็คว่าเป็น email หรือไม่
    if (identifier.includes('@')) {
      user = await query("SELECT user_id, email, username FROM users WHERE email = ?", [identifier]);
    } else {
      user = await query("SELECT user_id, email, username FROM users WHERE username = ?", [identifier]);
    }

    if (user.length === 0) {
      return res.status(404).send({ message: 'User not found', status: false });
    }

    const userId = user[0].user_id;
    const email = user[0].email; // ใช้ email จริงที่เก็บใน DB เพื่อส่งลิงก์

    // ✅ สร้าง token + hash
    const resetToken = crypto.randomBytes(32).toString('hex'); // plain token (ส่งให้ user)
    const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest(); // hash เก็บใน DB

    const expireTimeStr = moment().tz("Asia/Bangkok").add(30, 'minutes').format("YYYY-MM-DD HH:mm:ss");

    // ลบ token เก่า
    await query("DELETE FROM password_reset_tokens WHERE user_id = ?", [userId]);

    // Insert token ใหม่
    await query(
      "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)",
      [userId, resetTokenHash, expireTimeStr]
    );

    const resetLink = `http://localhost:4000/api/reset-password?token=${resetToken}`;

    // ส่ง email
    await sendEmail(
      email,
      'Password Reset',
      `Hello ${user[0].username}, click this link: ${resetLink}`,
      `<p>Hello <b>${user[0].username}</b>,<br>Click <a href="${resetLink}">here</a> to reset your password</p>`
    );

    res.send({ message: 'Password reset link sent to your email', status: true });
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: 'Server error', status: false });
  }
});

/**
 * 2) Verify Token
 */
routerR.get('/verify-reset-token', async (req: Request, res: Response) => {
  const { token } = req.query as { token?: string };

  if (!token) {
    return res.status(400).send({ message: 'Token required', status: false });
  }

  try {
    const tokenHash = crypto.createHash('sha256').update(token).digest();

    const rows = await query(
      "SELECT * FROM password_reset_tokens WHERE token_hash = ? AND expires_at > NOW() AND used_at IS NULL",
      [tokenHash]
    );

    if (rows.length === 0) {
      return res.status(400).send({ message: 'Invalid or expired token', status: false });
    }

    res.send({ message: 'Token is valid', status: true });
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: 'Server error', status: false });
  }
});

/**
 * 3) Reset Password (เช็ค newPassword + confirmPassword)
 */
routerR.post('/reset-password', async (req: Request, res: Response) => {
  const { token, newPassword, confirmPassword } = req.body;

  if (!token || !newPassword || !confirmPassword) {
    return res.status(400).send({ message: 'Token, newPassword, and confirmPassword are required', status: false });
  }

  // ✅ เช็คว่ารหัสผ่านตรงกันไหม
  if (newPassword !== confirmPassword) {
    return res.status(400).send({ message: 'Passwords do not match', status: false });
  }

  try {
    const tokenHash = crypto.createHash('sha256').update(token).digest();

    const rows = await query(
      "SELECT * FROM password_reset_tokens WHERE token_hash = ? AND expires_at > NOW() AND used_at IS NULL",
      [tokenHash]
    );

    if (rows.length === 0) {
      return res.status(400).send({ message: 'Invalid or expired token', status: false });
    }

    const userId = rows[0].user_id;
    const hashedPassword = bcrypt.hashSync(newPassword, 10);

    // ✅ อัปเดตรหัสผ่านใหม่
    await query("UPDATE users SET password_hash = ? WHERE user_id = ?", [hashedPassword, userId]);

    // ✅ Mark token as used
    await query("UPDATE password_reset_tokens SET used_at = NOW() WHERE token_hash = ?", [tokenHash]);

    res.send({ message: 'Password reset successful', status: true });
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: 'Server error', status: false });
  }
});

export default routerR;
