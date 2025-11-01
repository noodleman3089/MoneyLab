import express from 'express';
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
//Controllers
import registerControllers from './controllers/register';
import loginControllers from './controllers/login';
import AdminControllers from './controllers/admin';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

console.log('ENV:', {
  DB_USER: process.env.DB_USER,
  DB_PASSWORD: process.env.DB_PASSWORD,
  DB_NAME: process.env.DB_NAME,
});

const app = express();
const PORT = process.env.PORT || 4000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

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

// Routes
app.use('/api', profileRoutes);

app.use('/api/transactions', transactionRoutes);

app.use('/api/transactions/ocr', transactionsOCR);

app.use("/api/daily-budget", DailyBudgetrouter);

app.use('/api/saving-goals', savingGoalsRoutes);

app.use('/api/wallet', walletRouter);

app.use('/api/saving-transactions', savingTransactionRoutes);

app.use('/api/survey', surveyRouter);

app.use('/api/recommendations', recommendationRoutes);


//Controllers
app.use('/api', registerControllers);

app.use('/api', resetPasswordRoutes);

app.use('/api', loginControllers);

app.use('/api', AdminControllers);

// Start Web server
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
