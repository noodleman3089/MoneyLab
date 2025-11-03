import express, { Response } from 'express';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';

const routerCat = express.Router();

/**
 * GET /api/categories
 * ดึงรายการหมวดหมู่ทั้งหมด โดยสามารถกรองตามประเภทได้ (income, expense)
 * Query Params:
 *  - type: 'income' | 'expense' (optional)
 */
routerCat.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  const { type } = req.query;

  try {
    let sql = 'SELECT category_id, category_name, category_type FROM category';
    const params: string[] = [];

    // ถ้ามีการระบุ type ใน query string ให้เพิ่มเงื่อนไข WHERE
    if (type && (type === 'income' || type === 'expense')) {
      sql += ' WHERE category_type = ?';
      params.push(type as string);
    }

    sql += ' ORDER BY category_id ASC';

    const categories = await query(sql, params);

    res.json({
      status: true,
      data: categories,
    });

  } catch (err: any) {
    console.error('Error fetching categories:', err);
    res.status(500).json({ status: false, message: 'Database error' });
  }
});

export default routerCat;