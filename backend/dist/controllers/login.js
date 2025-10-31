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
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const index_1 = require("../../index");
const controllers_L = (0, express_1.default)();
const SECRET_KEY = process.env.SECRET_KEY || '1234';
// Login 
controllers_L.post('/login', [
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
        const users = yield (0, index_1.query)("SELECT * FROM moneylab.users WHERE (username=? OR email=?)", [username, username]);
        if (users.length === 0) {
            return res.status(401).send({ message: 'Invalid username/email or password', status: false });
        }
        const user = users[0];
        // ใช้ password_hash ตาม table
        const isPasswordValid = bcryptjs_1.default.compareSync(password, user.password_hash);
        if (!isPasswordValid) {
            return res.status(401).send({ message: 'Invalid username/email or password', status: false });
        }
        yield (0, index_1.query)('UPDATE users SET last_login_at = NOW() WHERE user_id = ?', [user.user_id]);
        const token = jsonwebtoken_1.default.sign({ user_id: user.user_id, username: user.username, role: user.role }, SECRET_KEY, { expiresIn: '1h' });
        res.send({
            user_id: user.user_id,
            username: user.username,
            email: user.email,
            token,
            message: 'Login successful',
            status: true
        });
    }
    catch (err) {
        next(err);
    }
}));
exports.default = controllers_L;
