import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // 👈 1. Import dart:convert
import '../config/api_config.dart';
import 'saving_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalService extends ChangeNotifier {
  List<SavingGoal> _goals = [];
  List<SavingGoal> get goals => _goals;

  // เพิ่ม State สำหรับ Loading และ Error
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final http.Client client;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  GoalService({http.Client? client}) : client = client ?? http.Client() {
    fetchGoals();
  }

  String _unitToFrequency(String unit) {
    switch (unit) {
      case 'day': return 'daily';
      case 'week': return 'weekly';
      case 'month': return 'monthly';
      case 'year': return 'yearly'; // (Backend ไม่มี 'yearly' แต่มี 'one-time')
      default: return 'monthly';
    }
  }

  Future<void> fetchGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await client.get(Uri.parse(ApiConfig.savingGoalsUrl),
      headers: headers,);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['goals'];

        _goals = data.map((json) {
          // 1. แปลง JSON พื้นฐาน
          final goal = SavingGoal.fromJson(json);

          // 2. คำนวณฟิลด์ที่เหลือที่ UI ต้องใช้
          goal.duration = calculateDuration(goal.target, goal.saved, goal.perPeriod);
          goal.perDay = (goal.perPeriod / unitDays(goal.unit)).ceilToDouble();
          
          return goal;
        }).toList();

      } else {
        // 3. จัดการ Error กรณี API ไม่สำเร็จ
        _errorMessage = 'Failed to load goals (Code: ${response.statusCode})'; // 👈 ✅ นี่คือที่ที่ถูกต้อง
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- CRUD METHODS (แก้ไขให้เรียก API) ---

  // 5. แก้ไข ADDGOAL ให้เป็น async และเรียก http.post
  Future<void> addGoal(SavingGoal newGoal) async {
    try {
      final frequency = _unitToFrequency(newGoal.unit);
      final body = jsonEncode(newGoal.toCreateJson(frequency));

      final headers = await _getHeaders();
      final response = await client.post(
        Uri.parse(ApiConfig.savingGoalsUrl),
        headers: headers,
        //headers: {'Content-Type': 'application/json'},
        body: body, // ใช้ toJson() ที่เราสร้างไว้
      );

      if (response.statusCode == 200 || response.statusCode == 201) { // 👈 Backend ตอบ 200
        // Backend ไม่ได้ส่ง Goal ที่สร้างกลับมา (ตามโค้ด .ts)
        // เราจึงต้อง fetch ใหม่ทั้งหมดเพื่อให้ได้ ID ที่ถูกต้อง
        await fetchGoals(); // 👈 ง่ายที่สุดคือโหลดใหม่
        // (หรือจะอัปเดต newGoal.id แล้ว add เข้า _goals ตรงๆ ก็ได้ถ้า Backend ตอบกลับมา)
      } else {
        // TODO: จัดการ Error (เช่น แสดง SnackBar)
      }
    } catch (e) {
      // TODO: จัดการ Error
    }
  }

  // 6. แก้ไข DELETEGOAL ให้เรียก http.delete
  Future<void> deleteGoal(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.delete(
        Uri.parse('${ApiConfig.savingGoalsUrl}/$id'), // เช่น /api/saving-goals/123
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _goals.removeWhere((g) => g.id == id);
        notifyListeners();
      } else {
        // TODO: จัดการ Error
      }
    } catch (e) {
      // TODO: จัดการ Error
    }
  }

  // 7. แก้ไข UPDATEGOAL ให้เรียก http.put
  Future<void> updateGoal(SavingGoal updatedGoal) async {    
    try {
      final frequency = _unitToFrequency(updatedGoal.unit);
      final body = jsonEncode(updatedGoal.toUpdateJson(frequency));

      final headers = await _getHeaders();
      final response = await client.put(
        Uri.parse('${ApiConfig.savingGoalsUrl}/${updatedGoal.id}'),
        headers: headers,
        //headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (response.statusCode == 200) {
        // (คำนวณค่าใหม่ใน UI ก่อน)
        updatedGoal.progress = calculateProgress(updatedGoal.saved, updatedGoal.target);
        updatedGoal.duration = calculateDuration(updatedGoal.target, updatedGoal.saved, updatedGoal.perPeriod);
        updatedGoal.perDay = (updatedGoal.perPeriod / unitDays(updatedGoal.unit)).ceilToDouble();
        
        final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
        if (index != -1) {
          _goals[index] = updatedGoal;
          notifyListeners();
        }
      } else {
        // TODO: จัดการ Error
      }
    } catch (e) {
       // TODO: จัดการ Error
    }
  }

  Future<void> addContribution(String goalId, double amount) async {
    final headers = await _getHeaders();

    try {
      // Backend (saving_transactions.ts) คาดหวัง 'goal_id' เป็น int
      final goalIdInt = int.tryParse(goalId);
      if (goalIdInt == null) {
        throw Exception('Invalid Goal ID format');
      }

      final response = await client.post(
        Uri.parse(ApiConfig.savingTransactionsUrl), // 👈 4. ใช้ URL ใหม่
        headers: headers,
        body: jsonEncode({
          'goal_id': goalIdInt,
          'amount': amount,
        }),
      );

      final body = jsonDecode(response.body);

      // 5. ตรวจสอบ response จาก Backend
      if (response.statusCode == 200 && body['status'] == true) {
        // สำเร็จ! Backend จะส่งข้อมูลที่อัปเดตแล้วกลับมา
        final data = body['data'];
        final index = _goals.indexWhere((g) => g.id == goalId);
        
        if (index != -1) {
          final goal = _goals[index];
          
          // อัปเดต Goal ในแอปด้วยข้อมูลใหม่จากเซิร์ฟเวอร์
          goal.saved = (data['new_amount'] as num).toDouble();
          goal.progress = (double.tryParse(data['progress_percent'].toString()) ?? 0.0);
          goal.status = data['status'];
          
          // คำนวณค่าที่ UI ใช้อีกครั้ง
          goal.duration = calculateDuration(goal.target, goal.saved, goal.perPeriod);
          goal.perDay = (goal.perPeriod / unitDays(goal.unit)).ceilToDouble();

          _goals[index] = goal;
          notifyListeners(); // แจ้งเตือน UI ให้อัปเดต
        }
      } else {
        // 6. ถ้าล้มเหลว (เช่น เงินไม่พอ) ให้โยน Error ที่ Backend ส่งมา
        throw Exception(body['message'] ?? 'Failed to add contribution');
      }
    } catch (e) {
      // โยน Error ต่อไปให้ UI (เช่น SnackBar) แสดง
      throw Exception(e.toString());
    }
  }

  String unitLabel(String unit) {
    switch (unit) {
      case 'day': return 'วัน';
      case 'week': return 'สัปดาห์';
      case 'month': return 'เดือน';
      case 'year': return 'ปี';
      default: return 'เดือน';
    }
  }

  int unitDays(String unit) {
    switch (unit) {
      case 'day': return 1;
      case 'week': return 7;
      case 'month': return 30;
      case 'year': return 365;
      default: return 30;
    }
  }

  double calculateProgress(double saved, double target) {
    if (target <= 0) return 0;
    return (saved / target * 100).clamp(0.0, 100.0);
  }

  int calculateDuration(double target, double saved, double perPeriod) {
    if (perPeriod <= 0) return 0;
    final remain = (target - saved).clamp(0.0, double.infinity);
    return (remain / perPeriod).ceil();
  }
  int get totalGoals => _goals.length;
  
  double get totalSaved => _goals.fold(0.0, (sum, g) => sum + g.saved);
  
  double get totalTarget => _goals.fold(0.0, (sum, g) => sum + g.target);
  
  int get overallProgress {
    if (totalTarget <= 0) return 0;
    return ((totalSaved / totalTarget) * 100).round();
  }

}