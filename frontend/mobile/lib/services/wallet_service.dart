import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'wallet.dart';

// 3. เปลี่ยนเป็น ChangeNotifier
class WalletService extends ChangeNotifier {
  
  Wallet? _wallet;
  Wallet? get wallet => _wallet;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // (สันนิษฐานว่าคุณใช้ http.Client เหมือน GoalService)
  final http.Client client;
  WalletService({http.Client? client}) : client = client ?? http.Client() {
    fetchWallet(); // 👈 4. เรียกตอนเริ่มต้น
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token not found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 5. เปลี่ยนชื่อฟังก์ชัน (และเปลี่ยนเป็น void)
  Future<void> fetchWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse(ApiConfig.walletUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['wallet'] != null) {
          // 6. เก็บ State ทั้ง object
          _wallet = Wallet.fromJson(body['wallet']);
        } else {
          throw Exception(body['message'] ?? 'Failed to fetch wallet data');
        }
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners(); // 7. แจ้งเตือน UI
  }

  /// รีเซ็ตยอดเงินใน Wallet (และ fetch ใหม่)
  Future<String> resetWallet() async {
    final headers = await _getHeaders();

    final response = await client.post(
      Uri.parse('${ApiConfig.walletUrl}/reset'),
      headers: headers,
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['status'] == true) {
      await fetchWallet(); // 👈 8. fetch ข้อมูลใหม่หลังรีเซ็ต
      return responseData['message'] ?? 'Wallet reset successfully';
    } else {
      throw Exception(responseData['message'] ?? 'Failed to reset wallet');
    }
  }
}