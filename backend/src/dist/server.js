"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a, _b, _c, _d;
Object.defineProperty(exports, "__esModule", { value: true });
exports.query = query;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const mysql2_1 = __importDefault(require("mysql2"));
const dotenv_1 = __importDefault(require("dotenv"));
const express_validator_1 = require("express-validator");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const sendEmail_1 = require("./sendEmail/sendEmail");
const path_1 = __importDefault(require("path"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const reset_password_1 = __importDefault(require("./routes/reset_password"));
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, 'C:/Users/UNS/Desktop/Project-MoneyLab/backend/api/.env') });
const app = (0, express_1.default)();
const PORT = process.env.PORT || 4000;
const SECRET_KEY = process.env.SECRET_KEY || 'your_secret_key';
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
app.use((0, cors_1.default)());
const dbTimezone = process.env.DB_TIMEZONE || '+00:00';
// MySQL Connection
const db = mysql2_1.default.createConnection({
    host: (_a = process.env.DB_HOST) !== null && _a !== void 0 ? _a : '',
    user: (_b = process.env.DB_USER) !== null && _b !== void 0 ? _b : '',
    password: (_c = process.env.DB_PASSWORD) !== null && _c !== void 0 ? _c : '',
    database: (_d = process.env.DB_NAME) !== null && _d !== void 0 ? _d : '',
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
function query(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.query(sql, params, (err, results) => {
            if (err)
                return reject(err);
            resolve(results);
        });
    });
}
/**
 * USERS CRUD
 */
// CREATE - เพิ่ม user ใหม่
app.post('/api/users', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { username, email, phone, password } = req.body;
        const salt = yield bcryptjs_1.default.genSalt(10);
        const password_hash = yield bcryptjs_1.default.hash(password, salt);
        const sql = `INSERT INTO users (username, email, phone, password_hash) VALUES (?, ?, ?, ?)`;
        yield query(sql, [username, email, phone, password_hash]);
        res.json({ status: true, message: 'User created successfully' });
    }
    catch (err) {
        res.status(500).json({ status: false, message: 'Failed to create user', error: err.message });
    }
}));
// READ - ดึง users ทั้งหมด
app.get('/api/users', (_req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const sql = `SELECT id, username, email, phone, created_at, updated_at, last_login_at FROM users`;
        const users = yield query(sql);
        res.json({ status: true, message: 'Users fetched successfully', data: users });
    }
    catch (err) {
        res.status(500).json({ status: false, message: 'Failed to fetch users', error: err.message });
    }
}));
// READ (by ID)
app.get('/api/users/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const sql = `SELECT id, username, email, phone, created_at, updated_at, last_login_at FROM users WHERE id = ?`;
        const results = yield query(sql, [id]);
        if (results.length === 0) {
            return res.status(404).json({ status: false, message: 'User not found' });
        }
        res.json({ status: true, message: 'User fetched successfully', data: results[0] });
    }
    catch (err) {
        res.status(500).json({ status: false, message: 'Failed to fetch user', error: err.message });
    }
}));
// UPDATE - แก้ไข user
app.put('/api/users/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const { username, email, phone, password } = req.body;
        let sql, params;
        if (password) {
            const salt = yield bcryptjs_1.default.genSalt(10);
            const password_hash = yield bcryptjs_1.default.hash(password, salt);
            sql = `UPDATE users SET username = ?, email = ?, phone = ?, password_hash = ? WHERE id = ?`;
            params = [username, email, phone, password_hash, id];
        }
        else {
            sql = `UPDATE users SET username = ?, email = ?, phone = ? WHERE id = ?`;
            params = [username, email, phone, id];
        }
        const result = yield query(sql, params);
        if (result.affectedRows === 0) {
            return res.status(404).json({ status: false, message: 'User not found' });
        }
        res.json({ status: true, message: 'User updated successfully' });
    }
    catch (err) {
        res.status(500).json({ status: false, message: 'Failed to update user', error: err.message });
    }
}));
// DELETE - ลบ user
app.delete('/api/users/:id', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const sql = `DELETE FROM users WHERE id = ?`;
        const result = yield query(sql, [id]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ status: false, message: 'User not found' });
        }
        res.json({ status: true, message: 'User deleted successfully' });
    }
    catch (err) {
        res.status(500).json({ status: false, message: 'Failed to delete user', error: err.message });
    }
}));
/**
 * REGISTER (with validation)
 */
app.post('/api/register', [
    (0, express_validator_1.body)('username').isString().notEmpty().withMessage('Username is required'),
    (0, express_validator_1.body)('password').isLength({ min: 4 }).withMessage('Password must be at least 4 characters'),
    (0, express_validator_1.body)('email').isEmail().withMessage('Invalid email format'),
    (0, express_validator_1.body)('phone').optional().isMobilePhone('any').withMessage('Invalid phone number'),
], (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        return res.status(400).send({ message: 'Validation errors', errors: errors.array(), status: false });
    }
    const { username, password, email, phone } = req.body;
    try {
        const existingUser = yield query('SELECT * FROM users WHERE username=? OR email=? OR phone=?', [
            username,
            email,
            phone || null,
        ]);
        if (existingUser.length > 0) {
            return res.status(409).send({ message: 'User already exists (username/email/phone)', status: false });
        }
        const salt = yield bcryptjs_1.default.genSalt(10);
        const password_hash = yield bcryptjs_1.default.hash(password, salt);
        yield query('INSERT INTO users (username, email, phone, password_hash) VALUES (?, ?, ?, ?)', [
            username,
            email,
            phone || null,
            password_hash,
        ]);
        yield (0, sendEmail_1.sendEmail)(email, 'Welcome to MoneyLab 🎉', `Hello ${username}, thank you for registering!`, `<h1>Hello ${username}</h1><p>Thank you for registering at MoneyLab 🚀</p>`);
        res.send({ message: 'Registration successful', status: true });
    }
    catch (err) {
        next(err);
    }
}));
// Login 
app.post('/api/login', [
    (0, express_validator_1.body)('username').isString().notEmpty().withMessage('Username or email is required'),
    (0, express_validator_1.body)('password').isString().notEmpty().withMessage('Password is required')
], (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        return res.status(400).send({ message: 'Validation errors', errors: errors.array(), status: false });
    }
    const { username, password } = req.body;
    try {
        // SQL ถูกต้อง
        const customer = yield query("SELECT * FROM test.users WHERE (username=? OR email=?)", [username, username]);
        if (customer.length === 0) {
            return res.status(401).send({ message: 'Invalid username/email or password', status: false });
        }
        // ใช้ password_hash ตาม table
        const isPasswordValid = bcryptjs_1.default.compareSync(password, customer[0].password_hash);
        if (!isPasswordValid) {
            return res.status(401).send({ message: 'Invalid username/email or password', status: false });
        }
        const token = jsonwebtoken_1.default.sign({ custID: customer[0].id, username: customer[0].username }, SECRET_KEY, { expiresIn: '1h' });
        res.send({
            custID: customer[0].id,
            username: customer[0].username,
            email: customer[0].email,
            token,
            message: 'Login successful',
            status: true
        });
    }
    catch (err) {
        next(err);
    }
}));
app.use('/api', reset_password_1.default);
app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
});
