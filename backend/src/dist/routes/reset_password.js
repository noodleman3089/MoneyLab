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
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const crypto_1 = __importDefault(require("crypto"));
const index_1 = require("../server");
const sendEmail_1 = require("../sendEmail/sendEmail");
const router = (0, express_1.Router)();
/**
 * 1) Forgot Password
 */
router.post('/forgot-password', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email } = req.body;
    try {
        const user = yield (0, index_1.query)("SELECT * FROM users WHERE email = ?", [email]);
        if (user.length === 0) {
            return res.status(404).send({ message: 'Email not found', status: false });
        }
        // สร้าง token
        const resetToken = crypto_1.default.randomBytes(32).toString('hex');
        const expireTime = new Date(Date.now() + 1000 * 60 * 30); // 30 นาที
        const offset = expireTime.getTimezoneOffset() * 60000; // timezone offset ของ Node.js (ms)
        const localTime = new Date(expireTime.getTime() - offset); // ปรับให้เป็น local
        const expireTimeStr = localTime.toISOString().slice(0, 19).replace('T', ' ');
        console.log('Generated token:', resetToken);
        console.log('Token expires_at (MySQL local):', expireTimeStr);
        // ลบ token เก่า
        yield (0, index_1.query)("DELETE FROM password_resets WHERE user_id = ?", [user[0].id]);
        // Insert token ใหม่
        yield (0, index_1.query)("INSERT INTO password_resets (user_id, token, expires_at) VALUES (?, ?, ?)", [user[0].id, resetToken, expireTimeStr]);
        const resetLink = `http://localhost:4000/api/reset-password?token=${resetToken}`;
        // ส่ง email
        yield (0, sendEmail_1.sendEmail)(email, 'Password Reset', `Click this link: ${resetLink}`, `<p>Click <a href="${resetLink}">here</a> to reset your password</p>`);
        res.send({ message: 'Password reset link sent to your email', status: true });
    }
    catch (err) {
        console.error(err);
        res.status(500).send({ message: 'Server error', status: false });
    }
}));
/**
 * 2) Verify Token
 */
router.get('/verify-reset-token', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { token } = req.query;
    console.log('Token from request:', token);
    try {
        const rows = yield (0, index_1.query)("SELECT * FROM password_resets WHERE token = ? AND expires_at > NOW()", [token]);
        console.log('Rows from DB:', rows);
        if (rows.length === 0) {
            return res.status(400).send({ message: 'Invalid or expired token', status: false });
        }
        res.send({ message: 'Token is valid', status: true });
    }
    catch (err) {
        console.error(err);
        res.status(500).send({ message: 'Server error', status: false });
    }
}));
/**
 * 3) Reset Password
 */
router.post('/reset-password', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { token, password } = req.body;
    try {
        const rows = yield (0, index_1.query)("SELECT * FROM password_resets WHERE token = ? AND expires_at > NOW()", [token]);
        console.log('Rows from DB (reset):', rows);
        if (rows.length === 0) {
            return res.status(400).send({ message: 'Invalid or expired token', status: false });
        }
        const userId = rows[0].user_id;
        const hashedPassword = bcryptjs_1.default.hashSync(password, 10);
        yield (0, index_1.query)("UPDATE users SET password_hash = ? WHERE id = ?", [hashedPassword, userId]);
        // ลบ token หลังใช้งาน
        yield (0, index_1.query)("DELETE FROM password_resets WHERE user_id = ?", [userId]);
        res.send({ message: 'Password reset successful', status: true });
    }
    catch (err) {
        console.error(err);
        res.status(500).send({ message: 'Server error', status: false });
    }
}));
exports.default = router;
