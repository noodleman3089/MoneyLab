import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import { sendEmail } from '../sendEmail/sendEmail';
import { query } from '../index';
import moment from 'moment-timezone';

const controllers_R = express();

/* =============================
   1️⃣ สมัครสมาชิก (ส่ง OTP)
   ============================= */
controllers_R.post('/register',
  [
    body('username').isString().notEmpty().withMessage('Username is required'),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('confirmPassword').custom((value, { req }) => {
      if (value !== req.body.password) {
        throw new Error('Password confirmation does not match password');
      }
      return true;
    }),
    body('email').isEmail().withMessage('Invalid email format'),
    body('phone_number').optional().isMobilePhone('any').withMessage('Invalid phone number'),
  ],
  async (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).send({ message: 'Validation errors', errors: errors.array(), status: false });
    }

    const { username, password, email, phone_number } = req.body;
    try {
      // ✅ ตรวจสอบว่ามีผู้ใช้ซ้ำไหม
      const existingUser = await query(
        'SELECT * FROM users WHERE username=? OR email=? OR phone_number=?',
        [username, email, phone_number || null]
      );

      if (existingUser.length > 0) {
        return res.status(409).send({ message: 'User already exists (username/email/phone_number)', status: false });
      }

      // ✅ สร้างรหัส OTP
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = moment().tz("Asia/Bangkok").add(5, 'minutes').format("YYYY-MM-DD HH:mm:ss");

      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);

      // ✅ บันทึก OTP ลง DB (ยังไม่สร้าง user จริง)
      await query(
        `INSERT INTO otp_verification (email, otp_code, username, phone_number, password_hash, expires_at)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [email, otpCode, username, phone_number || null, password_hash, expiresAt]
      );

      // ✅ ส่งอีเมล OTP
      await sendEmail(
        email,
        'ยืนยันการสมัครสมาชิก - MoneyLab 🧾',
        `สวัสดี ${username}, รหัสยืนยันของคุณคือ ${otpCode}`,
        `<h2>ยืนยันการสมัครสมาชิก</h2><p>รหัส OTP ของคุณคือ <b>${otpCode}</b> (หมดอายุใน 5 นาที)</p>`
      );

      res.send({
        status: true,
        message: 'OTP has been sent to your email',
        email
      });
    } catch (err) {
      console.error(err);
      next(err);
    }
  }
);

/* =============================
   2️⃣ ยืนยัน OTP (สร้างบัญชีจริง)
   ============================= */
controllers_R.post('/verify-otp',
  [
    body('email').isEmail().withMessage('Invalid email'),
    body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
  ],
  async (req: Request, res: Response) => {
    const { email, otp } = req.body;

    try {
      const [record] = await query(
        'SELECT * FROM otp_verification WHERE email = ? AND otp_code = ? AND verified = 0',
        [email, otp]
      );

      if (!record) {
        return res.status(400).json({ status: false, message: 'Invalid OTP or already verified' });
      }

      if (new Date(record.expires_at) < new Date()) {
        return res.status(400).json({ status: false, message: 'OTP expired' });
      }

      // ✅ บันทึก user จริงใน users table
      await query(
        'INSERT INTO users (username, email, phone_number, password_hash) VALUES (?, ?, ?, ?)',
        [record.username, record.email, record.phone_number, record.password_hash]
      );

      // ✅ อัปเดตสถานะว่า OTP ถูกใช้แล้ว
      await query('UPDATE otp_verification SET verified = 1 WHERE id = ?', [record.id]);

      res.json({ status: true, message: 'Account verified and created successfully' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

export default controllers_R;