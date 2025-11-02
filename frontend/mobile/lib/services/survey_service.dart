import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SurveyService {
  /// ดึงคำถามและตัวเลือกทั้งหมดสำหรับแบบสอบถาม
  ///
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> fetchSurveyQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(ApiConfig.surveyQuestionsUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // จัดการกับ HTTP error status codes
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load questions');
      }
    } catch (e) {
      debugPrint('SurveyService fetchSurveyQuestions Error: $e');
      // โยน Exception ต่อเพื่อให้ UI จัดการ
      throw Exception(
          e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// ส่งคำตอบของแบบสอบถามไปยังเซิร์ฟเวอร์
  ///
  /// รับ [answers] ซึ่งเป็น Map ของคำตอบ
  /// คืนค่า [Map<String, dynamic>] ที่ได้จาก JSON response
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> submitSurveyAnswers(
      Map<int, List<String>> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // แปลง Map<int, List<String>> เป็น Map<String, List<String>> สำหรับ JSON
      final body = jsonEncode({
        'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
      });

      final response = await http.post(
        Uri.parse(ApiConfig.submitSurveyUrl), // 👈 ใช้ URL จาก Config
        headers: headers,
        body: body,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('SurveyService submitSurveyAnswers Error: $e');
      throw Exception('ไม่สามารถส่งแบบสอบถามได้ กรุณาลองใหม่อีกครั้ง');
    }
  }
}