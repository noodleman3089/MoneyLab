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
const express_1 = __importDefault(require("express"));
const express_validator_1 = require("express-validator");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const index_1 = require("../../index");
const routerP = express_1.default.Router();
const SECRET_KEY = process.env.SECRET_KEY || '1234';
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token)
        return res.status(401).json({ status: false, message: 'No token provided' });
    jsonwebtoken_1.default.verify(token, SECRET_KEY, (err, decoded) => {
        if (err)
            return res.status(403).json({ status: false, message: 'Invalid token' });
        req.user = decoded;
        next();
    });
};
routerP.post('/profile', authenticateToken, [
    (0, express_validator_1.body)('main_income_amount').optional().isFloat({ min: 0 }),
    (0, express_validator_1.body)('side_income_amount').optional().isFloat({ min: 0 }),
    (0, express_validator_1.body)('occupation_id').optional().isInt(),
    (0, express_validator_1.body)('occupation_other').optional().isString()
], (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ status: false, errors: errors.array() });
    }
    const userId = req.user.user_id;
    const { occupation_id, occupation_other, main_income_amount, main_income_period_id, side_income_amount, side_income_period_id, } = req.body;
    try {
        // 🟢 ถ้าเลือก "อื่นๆ" แต่ไม่กรอกข้อความ
        if (occupation_id) {
            const occ = yield (0, index_1.query)("SELECT name_th FROM occupation WHERE occupation_id = ?", [occupation_id]);
            if (occ.length > 0 && occ[0].name_th === 'อื่นๆ' && !occupation_other) {
                return res.status(400).json({
                    status: false,
                    message: "กรุณากรอกข้อความอาชีพเมื่อเลือก 'อื่นๆ'"
                });
            }
        }
        // 🟢 INSERT แถวใหม่เสมอ
        const result = yield (0, index_1.query)(`INSERT INTO profile 
           (user_id, occupation_id, occupation_other, main_income_amount, main_income_period_id, 
            side_income_amount, side_income_period_id, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`, [
            userId,
            occupation_id || null,
            occupation_other || null,
            main_income_amount || 0,
            main_income_period_id || null,
            side_income_amount || 0,
            side_income_period_id || null
        ]);
        res.json({ status: true, message: 'Profile inserted successfully', profile_id: result.insertId });
    }
    catch (err) {
        console.error(err);
        res.status(500).json({ status: false, message: 'Database error' });
    }
}));
exports.default = routerP;
