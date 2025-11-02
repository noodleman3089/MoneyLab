import { Router } from 'express';
import { generateRecommendationsController, getRecommendationsByGoalController } from '../controllers/recommendation.controller';
import { authenticateToken } from '../middlewares/authMiddleware';
const router = Router();

// POST /api/recommendations/generate
router.post('/generate', authenticateToken, generateRecommendationsController);

// GET /api/recommendations/goals/:goalId
router.get('/goals/:goalId', authenticateToken, getRecommendationsByGoalController);

export default router;

