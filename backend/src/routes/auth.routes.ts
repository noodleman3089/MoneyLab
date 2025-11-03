import { Router } from 'express';
import { handleLogout } from '../controllers/logout.controller';
import { authenticateToken } from '../middlewares/authMiddleware';
const router = Router();

router.post('/logout', authenticateToken, handleLogout);

export default router;