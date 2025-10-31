import { Router } from 'express';
import { generateRecommendationsController, getRecommendationsByGoalController } from '../controllers/recommendation.controller';

const router = Router();

// POST /api/recommendations/generate
router.post('/generate', generateRecommendationsController);

// GET /api/recommendations/goals/:goalId
router.get('/goals/:goalId', getRecommendationsByGoalController);

export default router;

