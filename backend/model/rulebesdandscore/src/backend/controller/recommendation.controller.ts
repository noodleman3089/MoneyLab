
import { Request, Response } from 'express';
import mysql from 'mysql2/promise';

// --- 1. IMPORT TYPES AND SERVICES ---
import { UserFinancialInput } from '../type';
import { dbConfig, fetchAssetsFromDb, saveRecommendationsToDb } from '../services/database.service';
import { calculateRiskProfile } from '../services/risk-profile.service';
import { getFinancialRecommendations } from '../services/recommendation.service';

// --- 2. CONTROLLER FUNCTION ---

export const generateRecommendationsController = async (req: Request, res: Response) => {
  let connection: mysql.Connection | null = null;
  try {
    // --- Input Validation ---
    const { userInput, goalId }: { userInput: UserFinancialInput, goalId: number } = req.body;
    if (!userInput || !goalId) {
      return res.status(400).json({ error: 'Missing required fields: userInput and goalId' });
    }

    // --- Database Connection ---
    connection = await mysql.createConnection(dbConfig);

    // --- Step 1: Fetch assets from DB ---
    const allAssetsFromDb = await fetchAssetsFromDb(connection);
    if (allAssetsFromDb.length === 0) {
      console.warn('Warning: No assets found in the database.');
    }

    // --- Step 2: Run the recommendation logic ---
    const riskProfileResult = calculateRiskProfile(userInput);
    const { generalAdvice, investmentsToSave } = getFinancialRecommendations(
      userInput,
      riskProfileResult,
      allAssetsFromDb,
      goalId
    );

    // --- Step 3: Save the investment recommendations to the DB ---
    await saveRecommendationsToDb(connection, investmentsToSave);
    console.log(`✅ Successfully saved ${investmentsToSave.length} investment recommendations to the database for goal_id: ${goalId}.`);

    // --- Step 4: Send the response back to the client ---
    res.status(200).json({
      riskProfile: riskProfileResult,
      recommendations: {
        generalAdvice,
        investmentsToSave,
      },
    });

  } catch (error) {
    console.error('❌ API Error:', error);
    res.status(500).json({ error: 'An internal server error occurred.' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
};
