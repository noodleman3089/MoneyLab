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

      if (result['status'] == true &&
          result['token'] != null &&
          result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();

        // 1. บันทึก Token
        await prefs.setString('token', result['token']);

        // 2. บันทึกข้อมูล User (ในรูปแบบ String JSON)
        await prefs.setString('user', jsonEncode(result['user']));

        debugPrint('✅ Token and User data saved successfully (from OTP)!');
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl), // 👈 (ต้องเพิ่ม logoutUrl ใน ApiConfig)
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // ไม่ต้องหยุดการทำงาน แม้ว่า API จะล่ม
        // เพราะการลบ Token ออกจากเครื่องสำคัญที่สุด
        debugPrint('Failed to send logout request to server: $e');
      }
    }

    // 4. (เหมือนเดิม) ลบ Token และ User ออกจากเครื่อง
    try {
      await prefs.remove('token');
      await prefs.remove('user');
      debugPrint('✅ Token and User removed. User logged out locally.');
    } catch (e) {
      debugPrint('AutheService Logout Error: $e');
      throw Exception('เกิดข้อผิดพลาดระหว่างการล็อกเอาท์');
    }
  }

  Future<bool> validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      // ยิง API ไปที่ /profile (ซึ่งต้องใช้ Token)
      // ถ้าสำเร็จ (200) แปลว่า Token ยังใช้ได้
      final response = await http.get(
        Uri.parse(ApiConfig.profileUrl), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('validateToken Error: $e');
      return false;
    }
  }

  /// [ใหม่] ตรวจสอบว่ามี Token ในเครื่องหรือไม่ (เร็ว แต่ไม่ชัวร์ว่าหมดอายุหรือยัง)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }
}
