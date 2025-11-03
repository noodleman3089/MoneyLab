import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AutheService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// พยายามล็อกอินผู้ใช้
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: _headers,
        body: jsonEncode({'username': username, 'password': password}),
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      // --- ⭐️ [FIXED] นี่คือ "ศูนย์กลาง" ที่คุณต้องการ ⭐️ ---
      if (result['status'] == true &&
          result['token'] != null &&
          result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();

        // 1. บันทึก Token
        await prefs.setString('token', result['token']);

        // 2. บันทึกข้อมูล User (ในรูปแบบ String JSON)
        await prefs.setString('user', jsonEncode(result['user']));

        debugPrint('✅ Token and User data saved successfully!');
      }
      // --- (จบส่วนแก้ไข) ---

      return result;
    } catch (e) {
      debugPrint('AutheService Login Error: $e');
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  // ... (ฟังก์ชัน register, verifyOtp, forgotPassword, resetPassword เหมือนเดิม) ...

  /// พยายามลงทะเบียนผู้ใช้ใหม่ (ส่ง OTP)
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String email,
    String? phoneNumber,
  }) async {
    // ... (โค้ดเหมือนเดิม) ...
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          'confirmPassword': confirmPassword,
          'email': email,
          'phone_number': phoneNumber,
        }),
      );
      final Map<String, dynamic> result = jsonDecode(response.body);
      return result;
    } catch (e) {
      debugPrint('AutheService Register Error: $e');
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// พยายามยืนยัน OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    // ... (โค้ดเหมือนเดิม) ...
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtpUrl),
        headers: _headers,
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      // --- ⭐️ [FIXED] บันทึก Token และ User ที่นี่ด้วย ⭐️ ---
      if (result['status'] == true &&
          result['token'] != null &&
          result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token']);
        await prefs.setString('user', jsonEncode(result['user']));
        debugPrint('✅ OTP verified. Token and User saved successfully!');
      }

      return result;
    } catch (e) {
      debugPrint('AutheService VerifyOtp Error: $e');
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// ส่งคำขอลืมรหัสผ่าน
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    // ... (โค้ดเหมือนเดิม) ...
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
        headers: _headers,
        body: jsonEncode({'identifier': identifier}),
      );
      final Map<String, dynamic> result = jsonDecode(response.body);
      return result;
    } catch (e) {
      debugPrint('AutheService ForgotPassword Error: $e');
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// ส่งคำขอตั้งรหัสผ่านใหม่
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    // ... (โค้ดเหมือนเดิม) ...
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordUrl),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );
      final Map<String, dynamic> result = jsonDecode(response.body);
      return result;
    } catch (e) {
      debugPrint('AutheService ResetPassword Error: $e');
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// ล็อกเอาท์ผู้ใช้โดยการลบ Token และ User ออกจากเครื่อง
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      // ⭐️ [FIXED] ลบข้อมูล user ออกด้วย
      await prefs.remove('user');
      debugPrint('✅ Token and User removed. User logged out.');
    } catch (e) {
      debugPrint('AutheService Logout Error: $e');
      throw Exception('เกิดข้อผิดพลาดระหว่างการล็อกเอาท์');
    }
  }
}
