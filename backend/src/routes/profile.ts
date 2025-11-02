import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';

const routerP = express.Router();

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

    const actor = req.user;
    
    if (!actor) {
      return res.status(401).json({ status: false, message: 'Invalid token data' });
    }

    const userId = actor.user_id;
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

      await logActivity({
        user_id: userId, // User ที่สร้าง Profile
        actor_id: userId,
        actor_type: actor.role || 'user',
        action: 'CREATE_PROFILE',
        table_name: 'profile',
        record_id: result.insertId, // 👈 ID ของแถวที่ถูกสร้าง
        new_value: req.body, // 👈 บันทึกข้อมูลใหม่
        description: `User ${userId} created profile.`,
        req: req
      });

      res.json({ status: true, message: 'Profile inserted successfully', profile_id: result.insertId });
    } catch (err: any) {
      await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role || 'user',
        action: 'CREATE_PROFILE_EXCEPTION',
        table_name: 'profile',
        record_id: 0,
        new_value: req.body,
        description: `Failed to create profile for User ${userId}.Error: ${err.message}`,
        req: req
      });
      
      console.error(err);
      res.status(500).json({ status: false, message: 'Database error' });
    }
  }
);

export default routerP;