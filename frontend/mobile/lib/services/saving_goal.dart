// saving_goal.dart

import 'dart:convert';

class SavingGoal {
  String? id;
  String name;
  String emoji;
  double saved;
  double target;
  int duration;
  String unit; 
  String plan;
  String investMode;
  String symbols;
  double progress;
  double perPeriod;
  double perDay;
  
  // 1. เพิ่มฟิลด์ที่ Backend มี แต่ Frontend ไม่มี
  String status;
  
  // [ ⭐️ แก้ไขจุดที่ 1 ]
  List<dynamic> recommendations; // สำหรับเก็บคำแนะนำการลงทุน

  SavingGoal({
    this.id,
    required this.name,
    required this.emoji,
    required this.saved,
    required this.target,
    required this.duration,
    required this.unit,
    required this.plan,
    required this.investMode,
    this.symbols = '',
    required this.progress,
    required this.perPeriod,
    required this.perDay,
    this.status = 'active', // 2. เพิ่ม status
    
    // [ ⭐️ แก้ไขจุดที่ 2 ]
    this.recommendations = const [], // กำหนดค่าเริ่มต้นเป็น List ว่าง
  });

  // 3. แก้ไข 'fromJson' ให้เป็น "ล่าม" จาก Backend
  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    // แปลง unit/frequency
    String unit = 'month';
    if (json['frequency'] == 'daily') unit = 'day';
    if (json['frequency'] == 'weekly') unit = 'week';
    if (json['frequency'] == 'yearly') unit = 'year';

    // (เราจะคำนวณ duration, perDay, plan, emoji ใน Service)

    final String planType = json['plan_type'] ?? 'ประจำวัน';
    
    return SavingGoal(
      id: json['goal_id'].toString(), // 👈 แปลง
      name: json['goal_name'],        // 👈 แปลง
      target: (double.tryParse(json['target_amount'].toString()) ?? 0.0),
      saved: (double.tryParse(json['current_amount'].toString()) ?? 0.0),
      perPeriod: (double.tryParse(json['contribution_amount'].toString()) ?? 0.0),
      progress: (double.tryParse(json['progress_percent'].toString()) ?? 0.0), // 👈 แปลง
      status: json['status'] ?? 'active',
      unit: unit,
      
      // ฟิลด์เหล่านี้ UI ต้องใช้ แต่ Backend ไม่มี
      // เราจะใส่ค่าเริ่มต้น หรือคำนวณทีหลังใน Service
      emoji: '💰', // (จะคำนวณใน Service)
      plan: planType, // (จะคำนวณใน Service)
      duration: 0, // (จะคำนวณใน Service)
      perDay: 0, // (จะคำนวณใน Service)
      investMode: 'none',
      symbols: '',

      // [ ⭐️ แก้ไขจุดที่ 3 ]
      // ดึงข้อมูล 'recommendations' จาก API (ถ้ามี)
      recommendations: json['recommendations'] ?? [],
    );
  }

  // 4. แก้ไข 'toJson' ให้เป็น "ล่าม" ส่งไป Backend
  // (ส่งเฉพาะสิ่งที่ Backend รู้จัก)
  Map<String, dynamic> toCreateJson(String frequency) {
    return {
      'goal_name': name,
      'target_amount': target,
      'current_amount': saved,
      'contribution_amount': perPeriod,
      'frequency': frequency, 
      'status': 'active',
      
      // ⭐️ ส่งข้อมูลแผนการลงทุนไปด้วย
      'plan_type': plan, 
      'invest_mode': investMode,
      'symbols': symbols,
    };
  }
  
  Map<String, dynamic> toUpdateJson(String frequency) {
    return {
      'goal_name': name,
      'target_amount': target,
      'contribution_amount': perPeriod,
      'frequency': frequency,
      'status': status,
      
      'plan_type': plan,
      'invest_mode': investMode,
      'symbols': symbols,
    };
  }
}