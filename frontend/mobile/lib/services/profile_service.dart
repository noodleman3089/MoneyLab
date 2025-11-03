import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart'; // 👈 1. Import config ใหม่

class ProfileService {
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
        Uri.parse(ApiConfig.profileUrl), // 👈 [THE FIX]
        headers: headers,
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      return result;
    } catch (e) {
      debugPrint('ProfileService fetchUserProfile Error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลโปรไฟล์ได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// สร้างหรืออัปเดตข้อมูลโปรไฟล์ของผู้ใช้
  ///
  /// รับ [profileData] ซึ่งเป็น Map ของข้อมูลโปรไฟล์
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(ApiConfig.profileUrl), // 👈 ใช้ URL จาก Config
        headers: headers,
        body: jsonEncode(profileData),
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      if (response.statusCode >= 400) {
         throw Exception(result['message'] ?? 'Failed to update profile');
      }

      return result;
    } catch (e) {
      debugPrint('ProfileService updateUserProfile Error: $e');
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// เพิ่มข้อมูลหนี้สินของผู้ใช้
  ///
  /// รับ [debtData] ซึ่งเป็น Map ของข้อมูลหนี้
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> addDebtInfo(Map<String, dynamic> debtData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(ApiConfig.addDebtUrl), // 👈 ใช้ URL ใหม่จาก Config
        headers: headers,
        body: jsonEncode(debtData),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('ProfileService addDebtInfo Error: $e');
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// ดึงข้อมูลสำหรับ Dropdowns ทั้งหมด (เช่น อาชีพ, ความถี่รายได้)
  ///
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> fetchLookups() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.lookupsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        throw Exception(result['message'] ?? 'Failed to fetch lookup data');
      }
      return result;
    } catch (e) {
      debugPrint('ProfileService fetchLookups Error: $e');
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}