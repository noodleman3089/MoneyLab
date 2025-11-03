import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';

class DailyBudgetService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ตั้ง/อัปเดตงบประมาณรายวัน
  /// POST /api/daily-budget/set
  Future<Map<String, dynamic>> setDailyBudget({
    required double amount,
    required DateTime date,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final body = {
      'target_spend': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };

    final response = await http.post(
      Uri.parse(ApiConfig.setDailyBudgetUrl),
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
      throw Exception(result['message'] ?? 'Failed to set daily budget');
    }
  }

  /// ดึงข้อมูลสรุปงบประมาณและยอดใช้จ่ายของวันนี้
  /// GET /api/daily-budget/today
  Future<Map<String, dynamic>> getTodayBudgetSummary() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.getTodayBudgetUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Backend อาจจะคืน status: false ถ้ายังไม่ตั้งงบ ซึ่งถือเป็นเคสปกติ
      // เราจึงส่งข้อมูลกลับไปให้ UI จัดการต่อได้เลย
      return result;
    } else {
      throw Exception(result['message'] ?? 'Failed to get today\'s budget summary');
    }
  }
}