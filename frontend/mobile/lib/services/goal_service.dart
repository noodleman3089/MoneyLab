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

  // 8. แก้ไข ADDCONTRIBUTION ให้เรียก http.post (หรือ http.patch)
  // นี่เป็นตัวอย่าง (API อาจแตกต่างกัน)
  Future<void> addContribution(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = _goals[index];
    goal.saved += amount;

    // เราจะเรียก updateGoal ปกติ ให้มันส่งข้อมูลทั้งก้อนไปอัปเดต
    // (เพราะ Backend ไม่มี endpoint สำหรับ contribute โดยเฉพาะ)
    // *** หมายเหตุ: Backend ของคุณไม่ได้อัปเดต current_amount ใน PUT นะครับ ***
    // *** คุณต้องไปแก้ Backend ให้รับ 'current_amount' ใน Whitelist ของ PUT ด้วย ***
    await updateGoal(goal); 
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