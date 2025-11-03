import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'transaction_models.dart';
import '../config/api_config.dart';

class TransactionService {
  // --- (Helper Functions: _getToken, _getAuthHeaders) ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ⭐️ [NEW] ฟังก์ชันสำหรับหน้า SpendingSummary
  Future<Map<String, dynamic>> fetchSpendingSummary() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.transactionSummaryUrl), // 👈 ใช้ URL ใหม่
        headers: headers,
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        throw Exception(result['message'] ?? 'Failed to fetch summary data');
      }
      return result; // ส่ง data ทั้งก้อนกลับไป (เช่น {status: true, data: {...}})
    } catch (e) {
      debugPrint('TransactionService fetchSpendingSummary Error: $e');
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// ดึงข้อมูลสรุปรายวัน (เป้าหมาย, ยอดใช้จ่าย, รายการ)
  Future<DailySummary> fetchDailySummary(DateTime date) async {
    final headers = await _getAuthHeaders();
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // 👈 [FIXED] ใช้ transactionsUrl
    final response = await http.get(
      Uri.parse('${ApiConfig.transactionsUrl}/daily?date=$formattedDate'),
      headers: headers,
    );
    // ... (logic เดิม) ...
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == true) {
        return DailySummary.fromJson(body['data']);
      } else {
        throw Exception(body['message'] ?? 'Failed to fetch daily summary');
      }
    } else {
      throw Exception(
        'Failed to load daily summary. Status code: ${response.statusCode}',
      );
    }
  }

  /// เพิ่มธุรกรรมใหม่ (รายรับ/รายจ่าย)
  Future<Map<String, dynamic>> addTransaction({
    required double amount,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) async {
    final headers = await _getAuthHeaders();
    final body = {
      'amount': amount,
      'category_id': categoryId,
      'receiver_name': description,
      if (transactionDate != null)
        'transaction_date': transactionDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse(ApiConfig.transactionsUrl), // 👈 [FIXED]
      headers: headers,
      body: jsonEncode(body),
    );
    // ... (logic เดิม) ...
    final result = jsonDecode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['status'] == true) {
      return result;
    } else {
      throw Exception(result['message'] ?? 'Failed to add transaction');
    }
  }

  /// ดึงรายการหมวดหมู่ตามประเภท
  Future<List<Map<String, dynamic>>> fetchCategories(String type) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.categoriesUrl}?type=$type'),
      headers: headers,
    );
    // ... (logic เดิม) ...
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == true) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
    throw Exception('Failed to load categories');
  }

  /// อัปโหลดใบเสร็จเพื่อทำ OCR
  Future<Map<String, dynamic>> uploadReceipt(String imagePath) async {
    final token = await _getToken(); // 👈 [FIXED] ต้องดึง Token มาใช้
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.ocrUrl));

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('receipt', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final result = jsonDecode(response.body);

    if (response.statusCode == 200 && result['status'] == true) {
      return result;
    } else {
      throw Exception(result['message'] ?? 'Failed to upload receipt');
    }
  }
}
