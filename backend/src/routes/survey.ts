import express, { Request, Response } from 'express';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';

const routerSurvey = express.Router();

/**
 * 📋 GET /api/survey/questions
 * ดึงคำถามทั้งหมดจาก DB
 */
routerSurvey.get('/questions', authenticateToken, async (req: Request, res: Response) => {
  try {
    const questions = await query(`
      SELECT question_id, question_text, question_type, options
      FROM survey_question
      ORDER BY question_id
    `);

    const formatted = questions.map((q: any) => ({
      ...q,
      options:
        typeof q.options === 'string'
          ? JSON.parse(q.options)
          : q.options
    }));

    res.json({ status: true, data: formatted });
  } catch (err) {
    console.error('❌ Fetch survey questions error:', err);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch survey questions',
      error: err instanceof Error ? err.message : err,
    });
  }
});

routerSurvey.post('/answers', authenticateToken, async (req: Request, res: Response) => {
  const userId = (req as any).user.user_id;
  const { answers } = req.body;

  if (!Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({
      status: false,
      message: 'กรุณาส่งข้อมูล answers ในรูปแบบ array'
    });
  }

  try {
    for (const ans of answers) {
      if (!ans.question_id) continue;

      const value = Array.isArray(ans.answer_value)
        ? JSON.stringify(ans.answer_value)
        : String(ans.answer_value);

      // ตรวจสอบว่ามีคำตอบเก่าหรือไม่
      const existing = await query(
        `SELECT answer_id FROM survey_answer WHERE user_id = ? AND question_id = ? LIMIT 1`,
        [userId, ans.question_id]
      );

      if (existing.length > 0) {
        // update คำตอบเดิม
        await query(
          `UPDATE survey_answer
           SET answer_value = ?, updated_at = NOW()
           WHERE answer_id = ?`,
          [value, existing[0].answer_id]
        );
      } else {
        // insert คำตอบใหม่
        await query(
          `INSERT INTO survey_answer (user_id, question_id, answer_value)
           VALUES (?, ?, ?)`,
          [userId, ans.question_id, value]
        );
      }
    }

    res.json({
      status: true,
      message: 'บันทึกคำตอบสำเร็จ'
    });
  } catch (err) {
    console.error('❌ Save survey answers error:', err);
    res.status(500).json({
      status: false,
      message: 'Server error while saving answers'
    });
  }
});

export default routerSurvey;
