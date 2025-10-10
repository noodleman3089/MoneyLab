import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import bcrypt from 'bcryptjs';
import { sendEmail } from '../sendEmail/sendEmail';
import { query } from '../../index';

const controllers_R = express();

controllers_R.post('/register',
  [
    body('username').isString().notEmpty().withMessage('Username is required'),
    body('password').isLength({ min: 4 }).withMessage('Password must be at least 4 characters'),
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
      const existingUser = await query('SELECT * FROM users WHERE username=? OR email=? OR phone_number=?', [
        username,
        email,
        phone_number || null,
      ]);
      if (existingUser.length > 0) {
        return res.status(409).send({ message: 'User already exists (username/email/phone_number)', status: false });
      }

      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);

      await query('INSERT INTO users (username, email, phone_number, password_hash) VALUES (?, ?, ?, ?)', [
        username,
        email,
        phone_number || null,
        password_hash,
      ]);

      await sendEmail(
        email,
        'Welcome to MoneyLab 🎉',
        `Hello ${username}, thank you for registering!`,
        `<h1>Hello ${username}</h1><p>Thank you for registering at MoneyLab 🚀</p>`
      );

      res.send({ message: 'Registration successful', status: true });
    } catch (err) {
      next(err);
    }
  }
);
export default controllers_R;