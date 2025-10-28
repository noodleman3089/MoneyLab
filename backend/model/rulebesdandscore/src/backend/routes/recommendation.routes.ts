
import { Router } from 'express';
import { generateRecommendationsController } from '../controller/recommendation.controller';

const router = Router();

// Define the route for generating recommendations
router.post('/generate-recommendations', generateRecommendationsController);

export default router;
