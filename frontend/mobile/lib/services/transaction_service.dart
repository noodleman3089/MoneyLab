import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'transaction_models.dart'; // แก้ไข path
import '../config/api_config.dart'; // 👈 1. Import ApiConfig

class TransactionService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ดึงข้อมูลสรุปรายวัน (เป้าหมาย, ยอดใช้จ่าย, รายการ)
  Future<DailySummary> fetchDailySummary(DateTime date) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    // หมายเหตุ: Endpoint นี้เป็นการคาดการณ์จากโครงสร้าง Backend ที่ควรจะเป็น
    // คุณอาจจะต้องสร้าง Endpoint นี้ใน Backend เพิ่มเติม
    final response = await http.get(
      Uri.parse('${ApiConfig.apiUrl}/transactions/daily?date=$formattedDate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == true) {
        return DailySummary.fromJson(body['data']);
      } else {
        throw Exception(body['message'] ?? 'Failed to fetch daily summary');
      }
    } else {
      throw Exception('Failed to load daily summary. Status code: ${response.statusCode}');
    }
  }

  /// เพิ่มธุรกรรมใหม่ (รายรับ/รายจ่าย)
  Future<Map<String, dynamic>> addTransaction({
    required double amount,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final body = {
      'amount': amount,
      'category_id': categoryId,
      // Backend จะใช้ receiver_name เป็น description หลัก
      'receiver_name': description, 
      if (transactionDate != null)
        'transaction_date': transactionDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/transactions'), // 👈 2. ใช้ ApiConfig
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final result = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && result['status'] == true) {
      return result;
    } else {
      throw Exception(result['message'] ?? 'Failed to add transaction');
    }
  }

  /// ดึงรายการหมวดหมู่ตามประเภท
  Future<List<Map<String, dynamic>>> fetchCategories(String type) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.categoriesUrl}?type=$type'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == true) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
    // ถ้าล้มเหลว ให้คืนค่าว่าง หรือโยน Exception ตามต้องการ
    throw Exception('Failed to load categories');
  }

  /// อัปโหลดใบเสร็จเพื่อทำ OCR
  Future<Map<String, dynamic>> uploadReceipt(String imagePath) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.ocrUrl), // 👈 ใช้ Endpoint ใหม่
    );

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