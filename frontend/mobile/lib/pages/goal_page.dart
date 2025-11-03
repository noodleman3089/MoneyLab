// goal_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider

import '../services/goal_service.dart'; 
import 'widgets/create_goal_sheet.dart'; 
import 'widgets/goal_detail_sheet.dart'; 
import 'widgets/edit_goal_sheet.dart'; 
import '../services/saving_goal.dart';

// เปลี่ยนเป็น StatelessWidget
class GoalPage extends StatelessWidget {
  const GoalPage({super.key});

  // ไม่ต้องมี State, initState, หรือ helper functions ที่ย้ายไป service แล้ว

  // ย้ายเมธอดที่ต้องใช้ 'context' มาไว้ข้างนอก build
  // แต่ต้องส่ง GoalService เข้ามาด้วย

  void _showCreateGoalDialog(BuildContext context, GoalService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGoalSheet(
        onCreateGoal: (newGoal) {
          // ** ไม่ต้อง setState **
          // เรียก Service ให้ทำงานแทน
          service.addGoal(newGoal);
        },
        // ส่ง functions จาก service ไปแทน
        unitLabel: service.unitLabel,
        unitDays: service.unitDays,
        calculateDuration: service.calculateDuration,
      ),
    );
  }

  void _showGoalDetail(BuildContext context, GoalService service, SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalDetailSheet(
        goal: goal,
        unitLabel: service.unitLabel,
        unitDays: service.unitDays,
        onAddContribution: (amount) {
          // ** ไม่ต้อง setState **
          service.addContribution(goal.id!, amount);
        },
        onEditGoal: () {
          Navigator.pop(context);
          _showEditGoalDialog(context, service, goal);
        },
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, GoalService service, SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGoalSheet(
        goal: goal,
        unitLabel: service.unitLabel,
        onSave: (updatedGoal) {
          // ** ไม่ต้อง setState **
          service.updateGoal(updatedGoal);
        },
      ),
    );
  }

  void _deleteGoal(BuildContext context, GoalService service, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ยืนยันการลบ', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบเป้าหมายนี้หรือไม่?', style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // ** ไม่ต้อง setState **
              service.deleteGoal(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ลบเป้าหมายสำเร็จ', style: GoogleFonts.beVietnamPro()),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('ลบ', style: GoogleFonts.beVietnamPro(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ** นี่คือส่วนสำคัญ **
    // 1. 'watch' service: UI นี้จะ rebuild อัตโนมัติเมื่อ service.notifyListeners()
    final goalService = context.watch<GoalService>();

    // 2. ดึงข้อมูลล่าสุดจาก service มาใช้
    final goals = goalService.goals;
    final totalGoals = goalService.totalGoals;
    final totalSaved = goalService.totalSaved;
    final totalTarget = goalService.totalTarget;
    final overallProgress = goalService.overallProgress;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14B8A6), Color(0xFFF0F9F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Saving Goals',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF223248),
                              ),
                            ),
                            Text(
                              'ตั้งเป้าหมายออมเงิน เห็นความคืบหน้า',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: const Color(0xFF223248),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          // เรียก helper โดยส่ง service ไปด้วย
                          onPressed: () => _showCreateGoalDialog(context, goalService),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF223248),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                'สร้าง',
                                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary Bar (ใช้ข้อมูลจาก service getters)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8D4D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('รวม $totalGoals เป้าหมาย'),
                          _buildSummaryItem('ออมแล้ว ${totalSaved.toInt()} / ${totalTarget.toInt()}'),
                          _buildSummaryItem('สำเร็จ ~ $overallProgress%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Goals List (ใช้ list จาก service)
              Expanded(
                child: Consumer<GoalService>( // เปลี่ยนมาใช้ Consumer เพื่อให้ชัดเจน
                  builder: (context, goalService, child) {
                    
                    // 1. ตรวจสอบสถานะ Loading
                    if (goalService.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // 2. ตรวจสอบ Error
                    if (goalService.errorMessage != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'เกิดข้อผิดพลาด: ${goalService.errorMessage}\nกรุณาลองใหม่อีกครั้ง',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.beVietnamPro(color: Colors.red[700]),
                          ),
                        ),
                      );
                    }

                    // 3. แสดงผลเมื่อสำเร็จและไม่มีข้อมูล
                    if (goalService.goals.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.savings_outlined, size: 80, color: Color(0xFF14B8A6)),
                            const SizedBox(height: 16),
                            Text(
                              'ยังไม่มีเป้าหมายออมเงิน',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'กดปุ่ม "สร้าง" เพื่อเพิ่มเป้าหมายใหม่',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 4. แสดงผลเมื่อสำเร็จและมีข้อมูล (โค้ดเดิมของคุณ)
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: goalService.goals.length,
                      itemBuilder: (context, index) {
                        final goal = goalService.goals[index];
                        // ส่ง service ไปให้ _buildGoalCard ด้วย
                        return _buildGoalCard(context, goalService, goal);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF223248),
        ),
      ),
    );
  }

  // _buildGoalCard ต้องรับ context และ service เพิ่ม
  Widget _buildGoalCard(BuildContext context, GoalService service, SavingGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () => _showGoalDetail(context, service, goal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          // เรียกใช้ unitLabel จาก service
                          'เก็บแล้ว ${goal.saved.toInt()} / ${goal.target.toInt()} บาท • เหลือ ${goal.duration} ${service.unitLabel(goal.unit)}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20, color: Color(0xFF14B8A6)),
                            const SizedBox(width: 8),
                            Text('แก้ไข', style: GoogleFonts.beVietnamPro()),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () => _showEditGoalDialog(context, service, goal));
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('ลบ', style: GoogleFonts.beVietnamPro()),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () => _deleteGoal(context, service, goal.id!));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress / 100,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFC7DCDE),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4FB7B3)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ตัดออมทุก: ${service.unitLabel(goal.unit)} • ~ ${goal.perPeriod.toInt()} บาท/${service.unitLabel(goal.unit)}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    '~ ${goal.perDay.toInt()} บาท/วัน',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}