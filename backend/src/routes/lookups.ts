import express, { Request, Response } from 'express';
import { query } from '../index';

const router = express.Router();

/**
 * 📋 GET /api/lookups
 * ดึงข้อมูล Lookup ทั้งหมด (occupations, income_periods)
 * ไม่ต้อง authenticate เพราะเป็นข้อมูลพื้นฐานที่ทุกคนเข้าถึงได้
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    // ดึงข้อมูลอาชีพทั้งหมด
    const occupations = await query(
      'SELECT occupation_id, occupation_name FROM occupation ORDER BY occupation_id',
      []
    );

    // ดึงข้อมูลความถี่รายได้ทั้งหมด
    const incomePeriods = await query(
      'SELECT period_id, name_th, code FROM income_period ORDER BY period_id',
      []
    );

    res.json({
      status: true,
      data: {
        occupations,
        income_periods: incomePeriods
      }
    });
  } catch (error: any) {
    console.error('Error fetching lookups:', error);
    res.status(500).json({
      status: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล',
      error: error.message
    });
  }
});

export default router;
