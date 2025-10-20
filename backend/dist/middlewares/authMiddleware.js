"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyAdmin = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || '1234';
// ✅ ตรวจสอบว่ามี JWT และเป็น admin หรือไม่
const verifyAdmin = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ status: false, message: 'Unauthorized: Missing token' });
    }
    const token = authHeader.split(' ')[1];
    try {
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        // ✅ ตรวจสอบ role
        if (decoded.role !== 'admin') {
            return res.status(403).json({ status: false, message: 'Forbidden: Admins only' });
        }
        // ✅ เก็บข้อมูลผู้ใช้ไว้ใน req เพื่อใช้ต่อ
        req.user = decoded;
        next();
    }
    catch (err) {
        return res.status(401).json({ status: false, message: 'Invalid or expired token' });
    }
};
exports.verifyAdmin = verifyAdmin;
