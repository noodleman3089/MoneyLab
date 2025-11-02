import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';

const routerP = express.Router();
const profileRoutes = routerP; // ใช้ชื่อใหม่เพื่อความชัดเจน

/**
 * 👤 GET /api/profile
 * ดึงข้อมูลโปรไฟล์ของผู้ใช้ที่ล็อกอินอยู่
 */
profileRoutes.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;

  try {
    const [profile] = await query(
      `SELECT 
        p.profile_id, p.occupation_id, p.occupation_other, 
        p.main_income_amount, p.main_income_period_id, 
        p.side_income_amount, p.side_income_period_id,
        o.occupation_name,
        ip_main.name_th as main_income_period_name,
        ip_side.name_th as side_income_period_name
       FROM profile p
       LEFT JOIN occupation o ON p.occupation_id = o.occupation_id
       LEFT JOIN income_period ip_main ON p.main_income_period_id = ip_main.period_id
       LEFT JOIN income_period ip_side ON p.side_income_period_id = ip_side.period_id
       WHERE p.user_id = ?`,
      [userId]
    );

    if (!profile) {
      return res.status(404).json({ status: false, message: 'Profile not found for this user.' });
    }

    res.json({ status: true, data: profile });
  } catch (error: any) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ status: false, message: 'เกิดข้อผิดพลาดในการดึงข้อมูลโปรไฟล์', error: error.message });
  }
});

/**
 * 💾 POST /api/profile
 * สร้างหรืออัปเดตข้อมูลโปรไฟล์ของผู้ใช้ (สำหรับหน้า Onboarding)
 */
profileRoutes.post(
  '/',
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
      debts // รับข้อมูลหนี้มาด้วย (เผื่ออนาคต)
    } = req.body;

    try {
      // 🟢 ถ้าเลือก "อื่นๆ" แต่ไม่กรอกข้อความ
      if (occupation_id && Number.isInteger(occupation_id)) { // 👈 [THE FIX] ตรวจสอบว่าเป็นตัวเลขด้วย
        const occ = await query("SELECT occupation_name FROM occupation WHERE occupation_id = ?", [occupation_id]);
        if (occ.length > 0 && occ[0].occupation_name === 'อาชีพอื่นๆ' && !occupation_other) {
          return res.status(400).json({ 
            status: false, 
            message: "กรุณากรอกข้อความอาชีพเมื่อเลือก 'อาชีพอื่นๆ'" 
          });
        }
      }

      // ✨ [THE FIX] ใช้ INSERT ... ON DUPLICATE KEY UPDATE เพื่อสร้างหรืออัปเดตโปรไฟล์
      const profileSql = `
        INSERT INTO profile (user_id, occupation_id, occupation_other, main_income_amount, main_income_period_id, side_income_amount, side_income_period_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          occupation_id = VALUES(occupation_id),
          occupation_other = VALUES(occupation_other),
          main_income_amount = VALUES(main_income_amount),
          main_income_period_id = VALUES(main_income_period_id),
          side_income_amount = VALUES(side_income_amount),
          side_income_period_id = VALUES(side_income_period_id);
      `;
      const profileResult = await query(profileSql, [userId, occupation_id, occupation_other, main_income_amount, main_income_period_id, side_income_amount || 0, side_income_period_id]);
      const profileId = profileResult.insertId;

      await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role || 'user',
        action: 'UPDATE_FINANCIAL_PROFILE',
        table_name: 'profile',
        record_id: profileId,
        new_value: req.body,
        description: `User ID ${userId} updated their financial profile.`,
        req: req
      });

      res.status(201).json({ status: true, message: 'บันทึกข้อมูลโปรไฟล์สำเร็จ' });
    } catch (err: any) {
      await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role || 'user',
        action: 'UPDATE_PROFILE_EXCEPTION',
        table_name: 'profile',
        record_id: 0,
        new_value: req.body,
        description: `Failed to update profile for User ${userId}. Error: ${err.message}`,
        req: req
      });
      
      console.error(err);
      res.status(500).json({ status: false, message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูลโปรไฟล์', error: err.message });
    }
  }
);

/**
 * 💾 POST /api/profile/debts
 * เพิ่มข้อมูลหนี้สินให้กับโปรไฟล์ของผู้ใช้
 */
profileRoutes.post('/debts', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  const userId = actor?.user_id;

  if (!userId) {
    return res.status(401).json({ status: false, message: 'Invalid token, user not found.' });
  }

  // ดึงข้อมูลหนี้จาก request body
  const { debt_type, debt_amount, debt_monthly_payment, debt_interest_rate } = req.body;

  // --- Input Validation ---
  if (!debt_type || !debt_amount || !debt_monthly_payment) {
    return res.status(400).json({ status: false, message: 'Missing required debt data (type, amount, monthly_payment).' });
  }

  try {
    // 1. ค้นหา profile_id ของผู้ใช้คนนี้ก่อน
    const [profile] = await query('SELECT profile_id FROM profile WHERE user_id = ?', [userId]);

    if (!profile) {
      return res.status(404).json({ status: false, message: 'Profile not found for this user. Cannot add debt.' });
    }
    const profileId = profile.profile_id;

    // 2. บันทึกข้อมูลหนี้ลงในตาราง debt
    const debtSql = `
      INSERT INTO debt (profile_id, debt_type, debt_amount, debt_monthly_payment, debt_interest_rate)
      VALUES (?, ?, ?, ?, ?);
    `;
    await query(debtSql, [profileId, debt_type, debt_amount, debt_monthly_payment, debt_interest_rate || 0]);

    await logActivity({
      user_id: userId,
      action: 'ADD_DEBT_INFO',
      description: `User ID ${userId} added a new debt: ${debt_type}.`,
      req: req,
    });

    res.status(201).json({ status: true, message: 'บันทึกข้อมูลหนี้สินสำเร็จ' });

  } catch (error: any) {
    await logActivity({
      user_id: userId,
      action: 'ADD_DEBT_EXCEPTION',
      description: `Failed to add debt for User ID ${userId}. Error: ${error.message}`,
      req: req,
    });
    console.error('Error adding debt:', error);
    res.status(500).json({ status: false, message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูลหนี้สิน', error: error.message });
  }
});

export default profileRoutes;