import { Request, Response, NextFunction } from 'express';
import mysql from 'mysql2/promise';
import { pool, fetchUserAnswers, fetchAssetsFromDb, saveRecommendationsToDb, fetchRecommendationsByGoalId, fetchAndCalculateGoalInfo } from '../services/database.service';
import { calculateRiskProfile } from '../services/risk-profile.service';
import { getFinancialRecommendations } from '../services/recommendation.service';
import { UserFinancialInput, GoalInfo } from '../type/type';

export const generateRecommendationsController = async (req: Request, res: Response, next: NextFunction) => {
  let connection: mysql.PoolConnection | null = null; // แก้ไข Type ตรงนี้

  try {
    // --- 1. รับ Input จาก Client ---
    // โฟลว์ใหม่: เราจะรับ userId และข้อมูลการเงิน แต่ไม่รับ answers
    const { userId, goalId, main_income_amount, side_income_amount, debts } = req.body;

    // --- ตรวจสอบ Input พื้นฐาน ---
    if (!userId || !goalId || main_income_amount === undefined || side_income_amount === undefined || !debts) {
      return res.status(400).json({
        message: "Invalid input. Required fields: userId, goalId, main_income_amount, side_income_amount, debts",
      });
    }

    // --- 2. เชื่อมต่อฐานข้อมูล ---
    connection = await pool.getConnection(); // ดึง connection จาก pool

    // --- 3. ดึงข้อมูลที่จำเป็นจากฐานข้อมูล ---
    // ดึงคำตอบของผู้ใช้จากตาราง survey_answer
    const answersFromDb = await fetchUserAnswers(connection, userId);
    if (answersFromDb.length === 0) {
      return res.status(404).json({
        message: `No survey answers found for user_id: ${userId}.`,
      });
    }

    // ดึงข้อมูลเป้าหมายและคำนวณระยะเวลา
    const goalInfo = await fetchAndCalculateGoalInfo(connection, goalId);
    if (!goalInfo) {
      return res.status(404).json({
        message: `Goal with id: ${goalId} not found.`,
      });
    }

    // ดึงข้อมูลสินทรัพย์ทั้งหมด
    const allAssetsFromDb = await fetchAssetsFromDb(connection);

    // --- 4. ประกอบร่าง Input ที่สมบูรณ์ ---
    const fullUserInput: UserFinancialInput = {
      userId: userId,
      answers: answersFromDb, // <-- ใช้คำตอบจาก DB
      main_income_amount: main_income_amount,
      side_income_amount: side_income_amount,
      debts: debts,
    };

    // --- 5. ประมวลผลด้วย Rule-Based Engine ---
    // คำนวณ Risk Profile
    const riskProfileResult = calculateRiskProfile(fullUserInput);

    // สร้างคำแนะนำ
    const { generalAdvice, investmentsToSave } = getFinancialRecommendations(
      fullUserInput,
      riskProfileResult,
      allAssetsFromDb,
      goalId,
      goalInfo // <-- ส่งข้อมูลเป้าหมายที่คำนวณแล้วเข้าไปด้วย
    );

    // --- 6. บันทึกผลลัพธ์การลงทุนลงฐานข้อมูล ---
    if (investmentsToSave.length > 0) {
      await saveRecommendationsToDb(connection, investmentsToSave);
    }

    // --- 7. ส่งผลลัพธ์กลับให้ Client ---
    res.status(200).json({
      message: "Recommendations generated successfully.",
      riskProfile: riskProfileResult,
      generalAdvice: generalAdvice,
      // เราอาจจะไม่ต้องส่ง investmentsToSave กลับไปก็ได้ เพราะมันถูกบันทึกแล้ว
      // แต่ส่งไปเพื่อให้เห็นผลลัพธ์ทันที
      savedInvestments: investmentsToSave,
    });

  } catch (error) {
    // ส่งต่อไปให้ Error Handler Middleware (ถ้ามี)
    next(error);
  } finally {
    // ปิดการเชื่อมต่อเสมอ
    if (connection) {
      connection.release(); // คืน connection กลับเข้า pool
    }
  }
};

export const getRecommendationsByGoalController = async (req: Request, res: Response, next: NextFunction) => {
  let connection: mysql.PoolConnection | null = null; // แก้ไข Type ตรงนี้

  try {
    // --- 1. รับ Input จาก Client (URL parameter) ---
    const goalId = parseInt(req.params.goalId, 10);

    // --- ตรวจสอบ Input ---
    if (isNaN(goalId)) {
      return res.status(400).json({ message: "Invalid goalId. It must be a number." });
    }

    // --- 2. เชื่อมต่อฐานข้อมูล ---
    connection = await pool.getConnection(); // ดึง connection จาก pool

    // --- 3. ดึงข้อมูลคำแนะนำที่บันทึกไว้ ---
    const recommendations = await fetchRecommendationsByGoalId(connection, goalId);

    // --- 4. ส่งผลลัพธ์กลับให้ Client ---
    res.status(200).json(recommendations);

  } catch (error) {
    // ส่งต่อไปให้ Error Handler Middleware
    next(error);
  } finally {
    // ปิดการเชื่อมต่อเสมอ
    if (connection) {
      connection.release();
    }
  }
};