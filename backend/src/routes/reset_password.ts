import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { query } from '../index';
import { sendEmail } from '../sendEmail/sendEmail';
import moment from 'moment-timezone';
import { logActivity } from '../services/log.service';

const routerR = Router();

/* ==========================================================
   1️⃣ ส่งลิงก์ Reset Password ไปยังอีเมล (ไม่ส่ง token ตรง)
========================================================== */
routerR.post('/forgotpassword', async (req: Request, res: Response) => {
  const { identifier } = req.body; // email หรือ username
  let userId: number = 0;

  try {
    let user;

    if (identifier.includes('@')) {
      user = await query("SELECT user_id, email, username FROM users WHERE email = ?", [identifier]);
    } else {
      user = await query("SELECT user_id, email, username FROM users WHERE username = ?", [identifier]);
    }

    if (user.length === 0) {
      await logActivity({
        user_id: 0,
        actor_id: 0,
        actor_type: 'user',
        action: 'RESET_PASSWORD_REQUEST_FAIL',
        description: `Forgot password attempt for unknown user: ${identifier}.`,
        req: req,
        new_value: { identifier }
      });
      return res.status(404).json({ message: 'User not found', status: false });
    }

    userId = user[0].user_id;
    const email = user[0].email;

    // ✅ สร้าง token + hash
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest();
    const expireTimeStr = moment().tz("Asia/Bangkok").add(10, 'minutes').format("YYYY-MM-DD HH:mm:ss");

    // ลบ token เก่า
    await query("DELETE FROM password_reset_tokens WHERE user_id = ?", [userId]);

    // Insert token ใหม่
    await query(
      "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)",
      [userId, resetTokenHash, expireTimeStr]
    );

    // ✅ [THE FIX] สร้างลิงก์ 2 รูปแบบ: สำหรับ Web และ Mobile (Deep Link)
    const webResetLink = `${process.env.FRONTEND_WEB_URL || 'http://localhost:3000'}/page/reset-password?token=${resetToken}`;
    const mobileResetLink = `moneylab://reset-password?token=${resetToken}`;

    // ส่งอีเมล
    await sendEmail(
      email,
      '🔒 Reset your MoneyLab password',
      `สวัสดี ${user[0].username}, กดลิงก์นี้เพื่อรีเซ็ตรหัสผ่านของคุณ: ${webResetLink}`,
      `<h2>สวัสดี ${user[0].username},</h2>
      <p>คุณได้ขอรีเซ็ตรหัสผ่าน MoneyLab</p>
      <p>กดลิงก์ด้านล่างเพื่อเปลี่ยนรหัสผ่านใหม่ (ลิงก์จะหมดอายุใน 10 นาที)</p>
      <p><strong>หากคุณใช้งานบนคอมพิวเตอร์:</strong></p>
      <p><a href="${webResetLink}" target="_blank" style="color:#0066cc; font-weight:bold;">🔗 คลิกที่นี่เพื่อรีเซ็ตรหัสผ่านบนเว็บไซต์</a></p>
      <p><strong>หากคุณใช้งานบนมือถือ:</strong></p>
      <p><a href="${mobileResetLink}" style="color:#008000; font-weight:bold;">📱 คลิกที่นี่เพื่อเปิดแอป MoneyLab และรีเซ็ตรหัสผ่าน</a></p>`
    );

    await logActivity({
      user_id: userId,
      actor_id: userId,
      actor_type: 'user',
      action: 'RESET_PASSWORD_REQUEST_SUCCESS',
      table_name: 'password_reset_tokens',
      record_id: userId, 
      description: `User ${user[0].username} (ID: ${userId}) requested a password reset.`,
      req: req
    });

    res.json({ status: true, message: 'ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลแล้ว' });
  } catch (err: any) {
    await logActivity({
      user_id: userId, // 👈 (ถ้าหา user เจอก่อน Error ก็จะมี ID, ถ้าไม่เจอจะเป็น 0)
      actor_id: userId,
      actor_type: 'system',
      action: 'RESET_PASSWORD_REQUEST_EXCEPTION',
      description: `Forgot password exception for ${identifier}. Error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });
    console.error(err);
    res.status(500).json({ message: 'Server error', status: false });
  }
});

/* ==========================================================
   2️⃣ รีเซ็ตรหัสผ่าน (ตรวจซ้ำ, ความยาว, ใช้ token เดิม)
========================================================== */
routerR.post('/resetpassword', async (req: Request, res: Response) => {
  const { token, newPassword, confirmPassword } = req.body;
  let userId: number = 0;

  if (!token || !newPassword || !confirmPassword) {
    return res.status(400).json({
      status: false,
      message: 'Token, newPassword, and confirmPassword are required',
    });
  }

  // ✅ ตรวจสอบความยาวรหัสผ่าน
  if (newPassword.length < 8) {
    return res.status(400).json({
      status: false,
      message: 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร',
    });
  }

  // ✅ เช็ครหัสผ่านซ้ำ
  if (newPassword !== confirmPassword) {
    return res.status(400).json({
      status: false,
      message: 'รหัสผ่านใหม่และยืนยันรหัสผ่านไม่ตรงกัน',
    });
  }

  try {
    const tokenHash = crypto.createHash('sha256').update(token).digest();

    // ✅ ตรวจสอบ token ว่ายังใช้ได้อยู่ไหม
    const rows: any = await query(
      "SELECT * FROM password_reset_tokens WHERE token_hash = ? AND expires_at > NOW() AND used_at IS NULL",
      [tokenHash]
    );

    if (rows.length === 0) {
      await logActivity({
        user_id: 0,
        actor_id: 0,
        actor_type: 'user',
        action: 'RESET_PASSWORD_FAIL_INVALID_TOKEN',
        description: 'Password reset attempt with invalid or expired token.',
        req: req
      });
      return res.status(400).json({
        status: false,
        message: 'Token ไม่ถูกต้อง หรือหมดอายุแล้ว',
      });
    }

    userId = rows[0].user_id;

    // ✅ ดึง password เดิมเพื่อตรวจว่าซ้ำไหม
    const oldPasswordRow: any = await query(
      "SELECT password_hash FROM users WHERE user_id = ?",
      [userId]
    );

    const oldHash = oldPasswordRow[0]?.password_hash;

    // ตรวจว่ารหัสผ่านใหม่เหมือนของเดิมไหม
    const isSame = oldHash ? await bcrypt.compare(newPassword, oldHash) : false;
    if (isSame) {
      await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'user',
        action: 'RESET_PASSWORD_FAIL_SAME_PASSWORD',
        table_name: 'users',
        record_id: userId,
        description: `User ${userId} attempted to reset password to the same old password.`,
        req: req
      });
      return res.status(400).json({
        status: false,
        message: 'รหัสผ่านใหม่ต้องไม่เหมือนกับรหัสผ่านเดิม',
      });
    }

    // ✅ เข้ารหัสรหัสผ่านใหม่
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // ✅ อัปเดตรหัสผ่าน
    await query("UPDATE users SET password_hash = ? WHERE user_id = ?", [hashedPassword, userId]);

    // ✅ mark token ว่าใช้แล้ว
    await query("UPDATE password_reset_tokens SET used_at = NOW() WHERE token_hash = ?", [tokenHash]);

    await logActivity({
      user_id: userId,
      actor_id: userId,
      actor_type: 'user',
      action: 'RESET_PASSWORD_SUCCESS',
      table_name: 'users',
      record_id: userId,
      description: `User ${userId} successfully reset their password.`,
      req: req
    });

    res.json({ status: true, message: 'เปลี่ยนรหัสผ่านสำเร็จ' });
  } catch (err: any) {
    await logActivity({
      user_id: userId, // 👈 (ถ้าหา user เจอก่อน Error ก็จะมี ID, ถ้าไม่เจอจะเป็น 0)
      actor_id: userId,
      actor_type: 'system',
      action: 'RESET_PASSWORD_EXCEPTION',
      description: `Password reset failed with error: ${err.message}`,
      req: req,
      new_value: { error: err.stack }
    });
    console.error(err);
    res.status(500).json({ message: 'Server error', status: false });
  }
});

export default routerR;