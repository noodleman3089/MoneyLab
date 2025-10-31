import express, { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';

const routerP = express.Router();

interface JwtPayload {
  user_id: number;
  username: string;
}

interface AuthRequest extends Request {
  user?: JwtPayload;
}

routerP.post(
  '/profile',
  authenticateToken,
  [
    body('main_income_amount').optional().isFloat({ min: 0 }),
    body('side_income_amount').optional().isFloat({ min: 0 }),
    body('occupation_id').optional().isInt(),
    body('occupation_other').optional().isString()
  ],
  async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ status: false, errors: errors.array() });
    }

    const userId = req.user!.user_id;
    const {
      occupation_id,
      occupation_other,
      main_income_amount,
      main_income_period_id,
      side_income_amount,
      side_income_period_id,
    } = req.body;

    try {
      // 🟢 ถ้าเลือก "อื่นๆ" แต่ไม่กรอกข้อความ
      if (occupation_id) {
        const occ = await query("SELECT occupation_name FROM occupation WHERE occupation_id = ?", [occupation_id]);
        if (occ.length > 0 && occ[0].occupation_name === 'อาชีพอื่นๆ' && !occupation_other) {
          return res.status(400).json({ 
            status: false, 
            message: "กรุณากรอกข้อความอาชีพเมื่อเลือก 'อาชีพอื่นๆ'" 
          });
        }
      }

      // 🟢 INSERT แถวใหม่เสมอ
      const result: any = await query(
        `INSERT INTO profile 
           (user_id, occupation_id, occupation_other, main_income_amount, main_income_period_id, 
            side_income_amount, side_income_period_id, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
        [
          userId,
          occupation_id || null,
          occupation_other || null,
          main_income_amount || 0,
          main_income_period_id || null,
          side_income_amount || 0,
          side_income_period_id || null
        ]
      );

      res.json({ status: true, message: 'Profile inserted successfully', profile_id: result.insertId });
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

export default routerP;