import 'package:flutter/foundation.dart';

/// การตั้งค่า API Configuration
/// เปลี่ยน URL ที่ _baseUrl ตามสภาพแวดล้อมที่ใช้งาน
class ApiConfig {
  // 1. กำหนด Base URL หลักสำหรับ Backend (Node.js)
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000'; // สำหรับรันบน Web Browser
    } else {
      // สำหรับรันบน Mobile (โดยเฉพาะ Android Emulator)
      return 'http://10.0.2.2:5000';
    }
  }

  // 2. สร้าง Endpoint หลักๆ
  static String get baseUrl => _baseUrl;
  static String get apiUrl => '$_baseUrl/api';

  // --- Authentication Endpoints ---
  static String get loginUrl => '$apiUrl/login';
  static String get registerUrl => '$apiUrl/auth/register';
  static String get verifyOtpUrl => '$apiUrl/auth/verify-otp';
  static String get forgotPasswordUrl => '$apiUrl/forgotpassword';
  static String get resetPasswordUrl => '$apiUrl/resetpassword';

  // --- Profile Endpoint ---
  static String get profileUrl => '$apiUrl/profile';

  // --- Survey Endpoint ---
  static String get surveyQuestionsUrl => '$apiUrl/survey/questions';

  // TODO: เพิ่ม Endpoints อื่นๆ ที่นี่ เช่น transactions, goals, etc.
}