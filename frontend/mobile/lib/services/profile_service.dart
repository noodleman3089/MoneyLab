import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  // ⭐️ หมายเหตุ: URL สำหรับเชื่อมต่อ API
  // ถ้าทดสอบบน Web/Desktop: ใช้ 'http://localhost:5000/api'
  // ถ้าทดสอบบน Android Emulator: ต้องใช้ 'http://10.0.2.2:5000/api'
  static const String _baseUrl = 'http://localhost:5000/api';

  /// ดึงข้อมูลโปรไฟล์ของผู้ใช้ที่ล็อกอินอยู่
  ///
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว หรือไม่พบ Token
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      // 1. ดึง Token จาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      // 2. สร้าง Header พร้อม Token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 3. เรียก API
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'), // ชี้ไปที่ endpoint /profile
        headers: headers,
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      return result;
    } catch (e) {
      debugPrint('ProfileService fetchUserProfile Error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลโปรไฟล์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }
}