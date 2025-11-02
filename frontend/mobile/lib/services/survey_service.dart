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

  // TODO: เพิ่มฟังก์ชันสำหรับส่งคำตอบ (submitSurveyAnswers) ในอนาคต
}