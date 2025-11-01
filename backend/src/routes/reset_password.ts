import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { query } from '../index';
import { sendEmail } from '../sendEmail/sendEmail';
import moment from 'moment-timezone';

const routerR = Router();

/* ==========================================================
   1️⃣ ส่งลิงก์ Reset Password ไปยังอีเมล (ไม่ส่ง token ตรง)
========================================================== */
routerR.post('/forgot-password', async (req: Request, res: Response) => {
  const { identifier } = req.body; // email หรือ username

  try {
    let user;

    if (identifier.includes('@')) {
      user = await query("SELECT user_id, email, username FROM users WHERE email = ?", [identifier]);
    } else {
      user = await query("SELECT user_id, email, username FROM users WHERE username = ?", [identifier]);
    }

    if (user.length === 0) {
      return res.status(404).json({ message: 'User not found', status: false });
    }

    const userId = user[0].user_id;
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

    // ✅ สร้างลิงก์ Reset Password หน้าเว็บ
    const resetLink = `https://yourfrontend.com/reset-password?token=${resetToken}`; // เปลี่ยนเป็น URL หน้ารีเซ็ตรหัสผ่านจริง

    // ส่งอีเมล
    await sendEmail(
      email,
      '🔒 Reset your MoneyLab password',
      `สวัสดี ${user[0].username}, กดลิงก์นี้เพื่อรีเซ็ตรหัสผ่านของคุณ: ${resetLink}`,
      `<h2>สวัสดี ${user[0].username},</h2>
      <p>คุณได้ขอรีเซ็ตรหัสผ่าน MoneyLab</p>
      <p>กดลิงก์ด้านล่างเพื่อเปลี่ยนรหัสผ่านใหม่ (ลิงก์จะหมดอายุใน 10 นาที)</p>
      <p><a href="${resetLink}" target="_blank" style="color:#0066cc">🔗 เปลี่ยนรหัสผ่านที่นี่</a></p>`
    );

    res.json({ status: true, message: 'ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลแล้ว' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error', status: false });
  }
});

/* ==========================================================
   2️⃣ รีเซ็ตรหัสผ่าน (ตรวจซ้ำ, ความยาว, ใช้ token เดิม)
========================================================== */
routerR.post('/reset-password', async (req: Request, res: Response) => {
  const { token, newPassword, confirmPassword } = req.body;

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
      return res.status(400).json({
        status: false,
        message: 'Token ไม่ถูกต้อง หรือหมดอายุแล้ว',
      });
    }

    const userId = rows[0].user_id;

    // ✅ ดึง password เดิมเพื่อตรวจว่าซ้ำไหม
    const oldPasswordRow: any = await query(
      "SELECT password_hash FROM users WHERE user_id = ?",
      [userId]
    );

    const oldHash = oldPasswordRow[0]?.password_hash;

    // ตรวจว่ารหัสผ่านใหม่เหมือนของเดิมไหม
    const isSame = oldHash ? await bcrypt.compare(newPassword, oldHash) : false;
    if (isSame) {
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

    res.json({ status: true, message: 'เปลี่ยนรหัสผ่านสำเร็จ' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error', status: false });
  }
});

export default routerR;
