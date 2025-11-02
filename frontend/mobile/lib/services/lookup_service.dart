import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Service สำหรับดึงข้อมูล Lookup ต่างๆ เช่น occupation, income_period
class LookupService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// ดึงข้อมูล Lookups ทั้งหมด (occupations + income_periods)
  ///
  /// คืนค่า [Map<String, dynamic>] ที่มี keys:
  /// - 'occupations': List<Map<String, dynamic>>
  /// - 'income_periods': List<Map<String, dynamic>>
  ///
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<Map<String, dynamic>> fetchAllLookups() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.lookupsUrl),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch lookups. Status code: ${response.statusCode}');
      }

      final Map<String, dynamic> result = jsonDecode(response.body);

      // ตรวจสอบว่า response มีข้อมูลที่ต้องการ
      if (result['status'] == true && result['data'] != null) {
        return result['data'];
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch lookup data');
      }
    } catch (e) {
      debugPrint('LookupService fetchAllLookups Error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// ดึงเฉพาะข้อมูล Occupations
  ///
  /// คืนค่า [List<Map<String, dynamic>>] ที่มี occupation_id และ occupation_name
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<List<Map<String, dynamic>>> fetchOccupations() async {
    try {
      final data = await fetchAllLookups();
      final occupations = data['occupations'] as List;
      return occupations.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('LookupService fetchOccupations Error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลอาชีพได้');
    }
  }

  /// ดึงเฉพาะข้อมูล Income Periods
  ///
  /// คืนค่า [List<Map<String, dynamic>>] ที่มี period_id, name_th, และ code
  /// หรือโยน [Exception] ถ้า API ล้มเหลว
  Future<List<Map<String, dynamic>>> fetchIncomePeriods() async {
    try {
      final data = await fetchAllLookups();
      final periods = data['income_periods'] as List;
      return periods.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('LookupService fetchIncomePeriods Error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลความถี่รายได้ได้');
    }
  }
}
