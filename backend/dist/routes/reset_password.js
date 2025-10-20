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
const index_1 = require("../../index");
const sendEmail_1 = require("../sendEmail/sendEmail");
const moment_timezone_1 = __importDefault(require("moment-timezone"));
const routerR = (0, express_1.Router)();
/**
 * 1) Forgot Password (รองรับ email หรือ username)
 */
routerR.post('/forgot-password', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { identifier } = req.body;
    // identifier = email หรือ username ก็ได้
    try {
        let user;
        // เช็คว่าเป็น email หรือไม่
        if (identifier.includes('@')) {
            user = yield (0, index_1.query)("SELECT user_id, email, username FROM users WHERE email = ?", [identifier]);
        }
        else {
            user = yield (0, index_1.query)("SELECT user_id, email, username FROM users WHERE username = ?", [identifier]);
        }
        if (user.length === 0) {
            return res.status(404).send({ message: 'User not found', status: false });
        }
        const userId = user[0].user_id;
        const email = user[0].email; // ใช้ email จริงที่เก็บใน DB เพื่อส่งลิงก์
        // ✅ สร้าง token + hash
        const resetToken = crypto_1.default.randomBytes(32).toString('hex'); // plain token (ส่งให้ user)
        const resetTokenHash = crypto_1.default.createHash('sha256').update(resetToken).digest(); // hash เก็บใน DB
        const expireTimeStr = (0, moment_timezone_1.default)().tz("Asia/Bangkok").add(30, 'minutes').format("YYYY-MM-DD HH:mm:ss");
        // ลบ token เก่า
        yield (0, index_1.query)("DELETE FROM password_reset_tokens WHERE user_id = ?", [userId]);
        // Insert token ใหม่
        yield (0, index_1.query)("INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)", [userId, resetTokenHash, expireTimeStr]);
        const resetLink = `http://localhost:4000/api/reset-password?token=${resetToken}`;
        // ส่ง email
        yield (0, sendEmail_1.sendEmail)(email, 'Password Reset', `Hello ${user[0].username}, click this link: ${resetLink}`, `<p>Hello <b>${user[0].username}</b>,<br>Click <a href="${resetLink}">here</a> to reset your password</p>`);
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
routerR.get('/verify-reset-token', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { token } = req.query;
    if (!token) {
        return res.status(400).send({ message: 'Token required', status: false });
    }
    try {
        const tokenHash = crypto_1.default.createHash('sha256').update(token).digest();
        const rows = yield (0, index_1.query)("SELECT * FROM password_reset_tokens WHERE token_hash = ? AND expires_at > NOW() AND used_at IS NULL", [tokenHash]);
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
 * 3) Reset Password (เช็ค newPassword + confirmPassword)
 */
routerR.post('/reset-password', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { token, newPassword, confirmPassword } = req.body;
    if (!token || !newPassword || !confirmPassword) {
        return res.status(400).send({ message: 'Token, newPassword, and confirmPassword are required', status: false });
    }
    // ✅ เช็คว่ารหัสผ่านตรงกันไหม
    if (newPassword !== confirmPassword) {
        return res.status(400).send({ message: 'Passwords do not match', status: false });
    }
    try {
        const tokenHash = crypto_1.default.createHash('sha256').update(token).digest();
        const rows = yield (0, index_1.query)("SELECT * FROM password_reset_tokens WHERE token_hash = ? AND expires_at > NOW() AND used_at IS NULL", [tokenHash]);
        if (rows.length === 0) {
            return res.status(400).send({ message: 'Invalid or expired token', status: false });
        }
        const userId = rows[0].user_id;
        const hashedPassword = bcryptjs_1.default.hashSync(newPassword, 10);
        // ✅ อัปเดตรหัสผ่านใหม่
        yield (0, index_1.query)("UPDATE users SET password_hash = ? WHERE user_id = ?", [hashedPassword, userId]);
        // ✅ Mark token as used
        yield (0, index_1.query)("UPDATE password_reset_tokens SET used_at = NOW() WHERE token_hash = ?", [tokenHash]);
        res.send({ message: 'Password reset successful', status: true });
    }
    catch (err) {
        console.error(err);
        res.status(500).send({ message: 'Server error', status: false });
    }
}));
exports.default = routerR;
