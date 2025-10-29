import express, { Request, Response } from 'express';
import cors from 'cors';
import mysql from 'mysql2';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import path from 'path';
//Routes
import resetPasswordRoutes from './routes/reset_password';
import profileRoutes from './routes/profile';
import transactionRoutes from './routes/transactions';
import transactionsOCR from './routes/transactions_ocr';
import DailyBudgetrouter from "./routes/daily_budget";
import savingGoalsRoutes from './routes/savingGoals';
import walletRouter from './routes/wallet';
import savingTransactionRoutes from './routes/saving_transactions';
//Controllers
import registerControllers from './controllers/register';
import loginControllers from './controllers/login';
//Middlewares
import { verifyAdmin } from './middlewares/authMiddleware';

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

/**
 * USERS CRUD
 */

// CREATE - เพิ่ม user ใหม่
app.post('/api/users', async (req: Request, res: Response) => {
  try {
    const { username, email, phone_number, password } = req.body;
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const sql = `INSERT INTO users (username, email, phone_number, password_hash) VALUES (?, ?, ?, ?)`;
    await query(sql, [username, email, phone_number, password_hash]);

    res.json({ status: true, message: 'User created successfully' });
  } catch (err: any) {
    res.status(500).json({ status: false, message: 'Failed to create user', error: err.message });
  }
});

// READ - ดึง users ทั้งหมด
app.get('/api/users', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const limit = Number(req.query.limit) || 50;
    const offset = Number(req.query.offset) || 0;
    const role = req.query.role ? String(req.query.role).trim() : null;

    const safeLimit = Math.min(limit, 100);
    const params: any[] = [];
    let whereClause = '';

    if (role) {
      whereClause = 'WHERE users.role = ?';
      params.push(role);
    }

    const sql = `
      SELECT users.user_id, users.username, users.email, users.phone_number,
             users.last_login_at, users.created_at, users.updated_at, users.role
      FROM users
      ${whereClause}
      ORDER BY users.created_at DESC
      LIMIT ? OFFSET ?
    `;
    params.push(safeLimit, offset);
    const users = await query(sql, params);

    const totalSql = `SELECT COUNT(*) AS total FROM users ${whereClause}`;
    const totalResult = await query(totalSql, role ? [role] : []);
    const total = totalResult[0].total;

    res.json({
      status: true,
      message: 'Users fetched successfully',
      data: users,
      pagination: {
        total,
        limit: safeLimit,
        offset,
        nextOffset: offset + safeLimit < total ? offset + safeLimit : null,
        prevOffset: offset - safeLimit >= 0 ? offset - safeLimit : null
      },
      filter: role ? { role } : null
    });
  } catch (err: any) {
    res.status(500).json({ status: false, message: 'Failed to fetch users', error: err.message });
  }
});

// Routes
app.use('/api', profileRoutes);

app.use('/api', loginControllers);

app.use('/api/transactions', transactionRoutes);

app.use('/api/transactions/ocr', transactionsOCR);

app.use("/api/daily-budget", DailyBudgetrouter);

app.use('/api/saving-goals', savingGoalsRoutes);

app.use('/api/wallet', walletRouter);

app.use('/api/saving-transactions', savingTransactionRoutes);

//Controllers
app.use('/api', registerControllers);

app.use('/api', resetPasswordRoutes);

// Start Web servert
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
