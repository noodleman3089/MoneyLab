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
const sendEmail_1 = require("../sendEmail/sendEmail");
const index_1 = require("../../index");
const controllers_R = (0, express_1.default)();
controllers_R.post('/register', [
    (0, express_validator_1.body)('username').isString().notEmpty().withMessage('Username is required'),
    (0, express_validator_1.body)('password').isLength({ min: 4 }).withMessage('Password must be at least 4 characters'),
    (0, express_validator_1.body)('confirmPassword').custom((value, { req }) => {
        if (value !== req.body.password) {
            throw new Error('Password confirmation does not match password');
        }
        return true;
    }),
    (0, express_validator_1.body)('email').isEmail().withMessage('Invalid email format'),
    (0, express_validator_1.body)('phone_number').optional().isMobilePhone('any').withMessage('Invalid phone number'),
], (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        return res.status(400).send({ message: 'Validation errors', errors: errors.array(), status: false });
    }
    const { username, password, email, phone_number } = req.body;
    try {
        const existingUser = yield (0, index_1.query)('SELECT * FROM users WHERE username=? OR email=? OR phone_number=?', [
            username,
            email,
            phone_number || null,
        ]);
        if (existingUser.length > 0) {
            return res.status(409).send({ message: 'User already exists (username/email/phone_number)', status: false });
        }
        const salt = yield bcryptjs_1.default.genSalt(10);
        const password_hash = yield bcryptjs_1.default.hash(password, salt);
        yield (0, index_1.query)('INSERT INTO users (username, email, phone_number, password_hash) VALUES (?, ?, ?, ?)', [
            username,
            email,
            phone_number || null,
            password_hash,
        ]);
        yield (0, sendEmail_1.sendEmail)(email, 'Welcome to MoneyLab 🎉', `Hello ${username}, thank you for registering!`, `<h1>Hello ${username}</h1><p>Thank you for registering at MoneyLab 🚀</p>`);
        res.send({ message: 'Registration successful', status: true });
    }
    catch (err) {
        next(err);
    }
}));
exports.default = controllers_R;
