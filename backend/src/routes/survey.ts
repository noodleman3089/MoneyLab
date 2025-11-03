import express, { Response } from 'express';
import { query } from '../index';
import { authenticateToken, AuthRequest } from '../middlewares/authMiddleware';
import { logActivity } from '../services/log.service';
const routerSurvey = express.Router();

/**
 * 📋 GET /api/survey/questions
 * ดึงคำถามทั้งหมดจาก DB
 */
routerSurvey.get('/questions', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;
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
  } catch (err: any) {
    console.error('❌ Fetch survey questions error:', err);
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: 'system',
        action: 'FETCH_SURVEY_QUESTIONS_EXCEPTION',
        table_name: 'survey_question',
        description: `Failed to fetch survey questions. Error: ${err.message}`,
        req: req,
        new_value: { error: err.stack }
    });
    res.status(500).json({
      status: false,
      message: 'Failed to fetch survey questions',
      error: err instanceof Error ? err.message : err,
    });
  }
});

/**
 * 💾 POST /api/survey/submit
 * รับคำตอบจากแบบสอบถามที่ผู้ใช้ส่งมา
 */
routerSurvey.post('/submit', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  const userId = actor?.user_id;

  // ดึงข้อมูล answers จาก request body
  // Frontend ส่งมาในรูปแบบ: { "answers": { "1": ["A"], "4": ["STOCK", "FUND"] } }
  const { answers } = req.body;

  // --- Input Validation ---
  if (!userId) {
    return res.status(401).json({ status: false, message: 'Invalid token, user not found.' });
  }
  if (!answers || typeof answers !== 'object' || Object.keys(answers).length === 0) {
    return res.status(400).json({ status: false, message: 'Answers data is missing or invalid.' });
  }

  try {
    // วนลูปเพื่อบันทึกแต่ละคำตอบลงในตาราง survey_answer
    for (const questionIdStr in answers) {
      const questionId = parseInt(questionIdStr, 10);
      const answerValues = answers[questionIdStr]; // นี่คือ Array เช่น ['A'] หรือ ['STOCK', 'FUND']

      // แปลง Array เป็น String เพื่อเก็บในคอลัมน์ answer_value (TEXT)
      // เราจะใช้ JSON.stringify เพื่อให้เก็บโครงสร้าง Array ไว้ได้
      const answerValueToStore = JSON.stringify(answerValues);

      const sql = `
        INSERT INTO survey_answer (user_id, question_id, answer_value, answered_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE answer_value = VALUES(answer_value), answered_at = NOW();
      `;
      
      await query(sql, [userId, questionId, answerValueToStore]);
    }

    await logActivity({
      user_id: userId,
      actor_id: userId,
      action: 'SUBMIT_SURVEY',
      description: `User ID ${userId} submitted survey answers.`,
      req: req,
    });

    res.status(201).json({ status: true, message: 'บันทึกข้อมูลแบบสอบถามเรียบร้อยแล้ว' });

  } catch (error: any) {
    console.error('Error submitting survey:', error);
    res.status(500).json({ status: false, message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล', error: error.message });
  }
});

routerSurvey.post('/answers', authenticateToken, async (req: AuthRequest, res: Response) => {
  const actor = req.user;
  if (!actor) {
    return res.status(401).json({ status: false, message: 'Invalid token data' });
  }
  const userId = actor.user_id;
  const { answers } = req.body;

  if (!Array.isArray(answers) || answers.length === 0) {
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'SUBMIT_SURVEY_FAIL_INVALID_INPUT',
        table_name: 'survey_answer',
        description: 'Survey submission failed: answers was not a valid array or was empty.',
        req: req,
        new_value: req.body
    });
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
    await logActivity({
        user_id: userId,
        actor_id: userId,
        actor_type: actor.role,
        action: 'SUBMIT_SURVEY_SUCCESS',
        table_name: 'survey_answer',
        description: `User ${userId} submitted/updated ${answers.length} survey answers.`,
        req: req,
        new_value: req.body
    });

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