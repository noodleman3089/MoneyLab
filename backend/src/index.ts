import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import mysql from 'mysql2';
import dotenv from 'dotenv';
import path from 'path';
import './cronJobs';
//Routes
import  recommendationRoutes  from './routes/recommendation.routes';
import resetPasswordRoutes from './routes/reset_password';
import profileRoutes from './routes/profile';
import transactionRoutes from './routes/transactions';
import transactionsOCR from './routes/transactions_ocr';
import DailyBudgetrouter from "./routes/daily_budget";
import savingGoalsRoutes from './routes/savingGoals';
import walletRouter from './routes/wallet';
import savingTransactionRoutes from './routes/saving_transactions';
import surveyRouter from './routes/survey';
import notificationRoutes from './routes/notifications'; // 👈 เพิ่มบรรทัดนี้
//Controllers
import registerControllers from './controllers/register';
import loginControllers from './controllers/login';
import AdminControllers from './controllers/admin';
import dailyBudgetRoutes from './routes/daily_budget';
import savingGoalRoutes from './routes/savingGoals';
import walletRoutes from './routes/wallet';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

console.log('ENV:', {
  DB_USER: process.env.DB_USER,
  DB_PASSWORD: process.env.DB_PASSWORD,
  DB_NAME: process.env.DB_NAME,
});

const app = express();
const PORT = process.env.PORT || 5000; // ใช้ Port 5000 ตาม .env

// --- Middlewares ---
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads'))); // ทำให้เข้าถึงไฟล์ใน uploads ได้

const dbTimezone = process.env.DB_TIMEZONE || '+07:00';
// MySQL Connection
const db = mysql.createConnection({
  host: process.env.DB_HOST ?? '',
  user: process.env.DB_USER ?? '',
  password: process.env.DB_PASSWORD ?? '',
  database: process.env.DB_NAME ?? '',
  port: Number(process.env.DB_PORT) || 3306,
  timezone: dbTimezone,
});
db.connect(err => {
  if (err) {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  }
  console.log('Database connected successfully');
});

export function query(sql: string, params: any[] = []): Promise<any> {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, results) => {
      if (err) return reject(err);
      resolve(results);
    });
  });
}

// --- [THE FIX] จัดการ Routes ทั้งหมดให้เป็นระเบียบ ---
app.use('/api', [loginControllers, registerControllers, resetPasswordRoutes, AdminControllers]);
app.use('/api/profile', profileRoutes);
app.use('/api/transactions-ocr', transactionsOCR); // แก้ Path ให้ถูกต้อง
app.use('/api/transactions', transactionRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/survey', surveyRouter);
app.use('/api/notifications', notificationRoutes); // เพิ่ม notificationRoutes
app.use('/api/saving-goals', savingGoalRoutes);
app.use('/api/saving-transactions', savingTransactionRoutes);
app.use('/api/daily-budget', DailyBudgetrouter); // ใช้ชื่อตัวแปรที่ import มา
app.use('/api/wallet', walletRouter);

// Start Web server
app.listen(PORT, () => {
  console.log(`🚀 Node.js Server is running on http://localhost:${PORT}`);
});

// --- Basic Error Handler (ควรอยู่ท้ายสุดก่อน app.listen) ---
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error("❌ An error occurred:", err.stack);
  res.status(500).json({
    message: "An internal server error occurred.",
    error: err.message,
  });
});