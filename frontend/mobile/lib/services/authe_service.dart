import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint
import 'package:shared_preferences/shared_preferences.dart'; // 👈 1. Import SharedPreferences
import '../config/api_config.dart'; // 👈 1. Import config ใหม่

class AutheService {

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// พยายามล็อกอินผู้ใช้
  ///
  /// รับ [username] และ [password]
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl), // 👈 [THE FIX]
        headers: _headers,
        body: jsonEncode({'username': username, 'password': password}),
      );

      // ถอดรหัส JSON ที่ได้กลับมา
      final Map<String, dynamic> result = jsonDecode(response.body);

      // --- ✨ ส่วนที่เพิ่มเข้ามา: การจัดการ Token ---
      if (result['status'] == true && result['token'] != null) {
        // 2. ถ้าล็อกอินสำเร็จและมี token ให้บันทึกลง SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token']);
        debugPrint('✅ Token saved successfully!');
      }

      // ส่งค่ากลับไปให้ UI (ไม่ว่า status จะ true หรือ false)
      // เพราะ UI (login.dart) จะเป็นคนจัดการแสดง SnackBar เอง
      return result;
    } catch (e) {
      // จัดการข้อผิดพลาด
      // เช่น: ต่อเน็ตไม่ได้, Server ปิด, หรือ JSON ผิดรูปแบบ
      debugPrint('AutheService Login Error: $e');

      // โยน Exception เพื่อให้ UI (try...catch) รับไปจัดการต่อ
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// พยายามลงทะเบียนผู้ใช้ใหม่ (ส่ง OTP)
  ///
  /// รับ [username], [password], [confirmPassword], [email], [phoneNumber]
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl), // 👈 [THE FIX]
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
          'confirmPassword': confirmPassword,
          'email': email,
          'phone_number': phoneNumber,
        }),
      );

      // ถอดรหัส JSON ที่ได้กลับมา
      final Map<String, dynamic> result = jsonDecode(response.body);

      // ส่งค่ากลับไปให้ UI
      return result;
    } catch (e) {
      // จัดการข้อผิดพลาด
      debugPrint('AutheService Register Error: $e');

      // โยน Exception เพื่อให้ UI (try...catch) รับไปจัดการต่อ
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// พยายามยืนยัน OTP
  ///
  /// รับ [email] และ [otp]
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtpUrl), // 👈 [THE FIX]
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      // ถอดรหัส JSON ที่ได้กลับมา
      final Map<String, dynamic> result = jsonDecode(response.body);

      // --- ✨ [ย้ายมาที่นี่] การจัดการ Token หลังยืนยัน OTP สำเร็จ ---
      if (result['status'] == true && result['token'] != null) {
        // ถ้า OTP ถูกต้อง และ API ส่ง token กลับมา ให้บันทึกลงเครื่อง
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token']);
        debugPrint('✅ OTP verified. Token saved successfully!');
      }

      // ส่งค่ากลับไปให้ UI
      return result;
    } catch (e) {
      // จัดการข้อผิดพลาด
      debugPrint('AutheService VerifyOtp Error: $e');

      // โยน Exception เพื่อให้ UI (try...catch) รับไปจัดการต่อ
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// ส่งคำขอลืมรหัสผ่าน
  ///
  /// รับ [identifier] ซึ่งอาจเป็น email หรือ username
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl), // 👈 [THE FIX]
        headers: _headers,
        body: jsonEncode({
          'identifier': identifier,
        }),
      );

      // ถอดรหัส JSON ที่ได้กลับมา
      final Map<String, dynamic> result = jsonDecode(response.body);

      // ส่งค่ากลับไปให้ UI
      return result;
    } catch (e) {
      // จัดการข้อผิดพลาด
      debugPrint('AutheService ForgotPassword Error: $e');
      // โยน Exception เพื่อให้ UI (try...catch) รับไปจัดการต่อ
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// ส่งคำขอตั้งรหัสผ่านใหม่
  ///
  /// รับ [token], [password], [confirmPassword]
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordUrl), // 👈 [THE FIX]
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

  /// ล็อกเอาท์ผู้ใช้โดยการลบ Token ออกจากเครื่อง
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      // อาจจะลบข้อมูลอื่น ๆ ที่เกี่ยวกับ user session ด้วยก็ได้
      // await prefs.remove('user_id');
      debugPrint('✅ Token removed. User logged out.');
    } catch (e) {
      debugPrint('AutheService Logout Error: $e');
      throw Exception('เกิดข้อผิดพลาดระหว่างการล็อกเอาท์');
    }
  }
}
