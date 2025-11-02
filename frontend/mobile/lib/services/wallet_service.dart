import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class WalletService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ดึงข้อมูล Wallet (รวมถึงยอดเงินคงเหลือ)
  Future<double> fetchWalletBalance() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.walletUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == true && body['wallet'] != null) {
        // ดึงค่า balance จาก response
        return (body['wallet']['balance'] as num?)?.toDouble() ?? 0.0;
      } else {
        throw Exception(body['message'] ?? 'Failed to fetch wallet data');
      }
    } else {
      throw Exception('Failed to load wallet. Status code: ${response.statusCode}');
    }
  }
}