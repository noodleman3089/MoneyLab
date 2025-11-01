import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint

class AuthService {
  // ⭐️ หมายเหตุ: URL สำหรับเชื่อมต่อ API
  // ถ้าทดสอบบน Web/Desktop: ใช้ 'http://localhost:4000/api'
  // ถ้าทดสอบบน Android Emulator: ต้องใช้ 'http://10.0.2.2:4000/api'
  static const String _baseUrl = 'http://localhost:4000/api';

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
        Uri.parse('$_baseUrl/login'), // ชี้ไปที่ endpoint /login
        headers: _headers,
        body: jsonEncode({'username': username, 'password': password}),
      );

      // ถอดรหัส JSON ที่ได้กลับมา
      final Map<String, dynamic> result = jsonDecode(response.body);

      // ส่งค่ากลับไปให้ UI (ไม่ว่า status จะ true หรือ false)
      // เพราะ UI (login.dart) จะเป็นคนจัดการแสดง SnackBar เอง
      return result;
    } catch (e) {
      // จัดการข้อผิดพลาด
      // เช่น: ต่อเน็ตไม่ได้, Server ปิด, หรือ JSON ผิดรูปแบบ
      debugPrint('AuthService Login Error: $e');

      // โยน Exception เพื่อให้ UI (try...catch) รับไปจัดการต่อ
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  // --- คุณสามารถเพิ่มฟังก์ชันอื่นๆ ที่นี่ได้ในอนาคต ---

  // Future<Map<String, dynamic>> register(String username, String email, String password) async {
  //   // TODO: สร้าง logic สำหรับการลงทะเบียน
  //   throw UnimplementedError();
  // }

  // Future<Map<String, dynamic>> forgotPassword(String email) async {
  //   // TODO: สร้าง logic สำหรับการลืมรหัสผ่าน
  //   throw UnimplementedError();
  // }
}
