import 'package:flutter/foundation.dart';

/// การตั้งค่า API Configuration
/// เปลี่ยน URL ที่ _baseUrl ตามสภาพแวดล้อมที่ใช้งาน
class ApiConfig {
  // 1. กำหนด Base URL หลักสำหรับ Backend (Node.js)
  // 🔴 ใช้ 'localhost' สำหรับ iOS Simulator หรือ Android Emulator
  // 🟢 ใช้ IP Address ของคอมพิวเตอร์สำหรับอุปกรณ์จริง (Physical Device)
  // static const String _baseUrl = 'http://localhost:5000';
  static const String _baseUrl = 'http://10.192.86.76:5000'; // 👈 ❗️❗️ แก้ไขตรงนี้ ❗️❗️


  // 2. สร้าง Endpoint หลักๆ
  static const String apiUrl = '$_baseUrl/api';

  // --- Authentication Endpoints ---
  static String get loginUrl => '$apiUrl/login';
  static String get registerUrl => '$apiUrl/auth/register';
  static String get verifyOtpUrl => '$apiUrl/auth/verify-otp';
  static String get forgotPasswordUrl => '$apiUrl/forgotpassword';
  static String get resetPasswordUrl => '$apiUrl/resetpassword';

  // --- Profile Endpoint ---
  static String get profileUrl => '$apiUrl/profile';
  static String get addDebtUrl => '$apiUrl/profile/debts'; // 👈 เพิ่มบรรทัดนี้

  // --- Survey Endpoint ---
  static String get surveyQuestionsUrl => '$apiUrl/survey/questions';
  static String get submitSurveyUrl => '$apiUrl/survey/submit'; // 👈 เพิ่มบรรทัดนี้

  // --- Lookup Data Endpoint ---
  static String get lookupsUrl => '$apiUrl/lookups';

  // --- Daily Budget Endpoint ---
  static String get setDailyBudgetUrl => '$apiUrl/daily-budget/set';
  static String get getTodayBudgetUrl => '$apiUrl/daily-budget/today';
  
  // Categories
  static const String categoriesUrl = '$apiUrl/categories';

  // OCR Endpoint
  static String get ocrUrl => '$apiUrl/transactions-ocr';

  // --- Wallet Endpoint ---
  static String get walletUrl => '$apiUrl/wallet';
  // ไม่ต้องเพิ่มอะไรที่นี่ เพราะเราจะใช้ walletUrl + '/reset'

  // TODO: เพิ่ม Endpoints อื่นๆ ที่นี่ เช่น transactions, goals, etc.
}