import express, { Request, Response, NextFunction } from 'express';
import 'dotenv/config';
import recommendationRoutes from './src/routes/recommendation.routes';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware สำหรับ parse JSON body
app.use(express.json());

// --- Routes ---
app.use('/api/recommendations', recommendationRoutes);

// --- Basic Error Handler ---
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(" An error occurred:", err.stack);
  res.status(500).json({
    message: "An internal server error occurred.",
    error: err.message,
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});