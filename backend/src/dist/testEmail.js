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
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, 'C:/Users/UNS/Desktop/Project-MoneyLab/backend/api/.env') });
const sendEmail_1 = require("./sendEmail/sendEmail");
console.log('EMAIL_HOST =', process.env.EMAIL_HOST);
(() => __awaiter(void 0, void 0, void 0, function* () {
    try {
        yield (0, sendEmail_1.sendEmail)('munkhrim@gmail.com', 'Test Email from MoneyLab', 'This is a plain text test email', '<h1>This is a test email in <b>HTML</b></h1>');
        console.log('Email test finished ✅');
    }
    catch (err) {
        console.error('Test email failed ❌', err);
    }
}))();
