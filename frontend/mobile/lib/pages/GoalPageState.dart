import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

// SavingGoal Model
class SavingGoal {
  String id;
  String name;
  String emoji;
  double saved;
  double target;
  int duration;
  String unit; // 'day', 'week', 'month', 'year'
  String plan; // 'ประจำวัน', 'ลงทุน'
  String investMode; // 'recommend', 'custom', 'none'
  String symbols;
  double progress;
  double perPeriod;
  double perDay;

  SavingGoal({
    required this.id,
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
  });
}

// GoalPage Widget
class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  List<SavingGoal> goals = [];

  @override
  void initState() {
    super.initState();
    // Initialize with sample data
    goals = [
      SavingGoal(
        id: '1',
        name: 'ทริปทะเลภูเก็ต',
        emoji: '🏖️',
        saved: 6000,
        target: 15000,
        duration: 2,
        unit: 'month',
        plan: 'ประจำวัน',
        investMode: 'none',
        progress: 40,
        perPeriod: 4500,
        perDay: 150,
      ),
      SavingGoal(
        id: '2',
        name: 'โทรศัพท์ใหม่',
        emoji: '📱',
        saved: 3400,
        target: 10000,
        duration: 4,
        unit: 'week',
        plan: 'ประจำวัน',
        investMode: 'none',
        progress: 34,
        perPeriod: 1650,
        perDay: 237,
      ),
      SavingGoal(
        id: '3',
        name: 'ค่าเทอม',
        emoji: '📈',
        saved: 3000,
        target: 5000,
        duration: 20,
        unit: 'day',
        plan: 'ลงทุน',
        investMode: 'recommend',
        progress: 60,
        perPeriod: 100,
        perDay: 100,
      ),
    ];
  }

  // Helper functions
  String unitLabel(String unit) {
    switch (unit) {
      case 'day':
        return 'วัน';
      case 'week':
        return 'สัปดาห์';
      case 'month':
        return 'เดือน';
      case 'year':
        return 'ปี';
      default:
        return 'เดือน';
    }
  }

  int unitDays(String unit) {
    switch (unit) {
      case 'day':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'year':
        return 365;
      default:
        return 30;
    }
  }

  double calculateProgress(double saved, double target) {
    if (target <= 0) return 0;
    return (saved / target * 100).clamp(0.0, 100.0);
  }

  double calculatePerPeriod(double target, double saved, int duration) {
    final remain = (target - saved).clamp(0.0, double.infinity);
    return duration > 0 ? (remain / duration).ceilToDouble() : remain;
  }

  void _showCreateGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGoalSheet(
        onCreateGoal: (newGoal) {
          setState(() {
            goals.insert(0, newGoal);
          });
        },
        unitLabel: unitLabel,
        unitDays: unitDays,
        calculatePerPeriod: calculatePerPeriod,
      ),
    );
  }

  void _showGoalDetail(SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalDetailSheet(
        goal: goal,
        unitLabel: unitLabel,
        unitDays: unitDays,
        onAddContribution: (amount) {
          setState(() {
            final index = goals.indexWhere((g) => g.id == goal.id);
            if (index != -1) {
              goals[index].saved += amount;
              goals[index].progress = calculateProgress(goals[index].saved, goals[index].target);
              goals[index].perPeriod = calculatePerPeriod(
                goals[index].target,
                goals[index].saved,
                goals[index].duration,
              );
              goals[index].perDay = (goals[index].perPeriod / unitDays(goals[index].unit)).ceilToDouble();
            }
          });
        },
        onEditGoal: () {
          Navigator.pop(context);
          _showEditGoalDialog(goal);
        },
      ),
    );
  }

  void _showEditGoalDialog(SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGoalSheet(
        goal: goal,
        unitLabel: unitLabel,
        onSave: (updatedGoal) {
          setState(() {
            final index = goals.indexWhere((g) => g.id == goal.id);
            if (index != -1) {
              goals[index] = updatedGoal;
              goals[index].progress = calculateProgress(updatedGoal.saved, updatedGoal.target);
              goals[index].perPeriod = calculatePerPeriod(
                updatedGoal.target,
                updatedGoal.saved,
                updatedGoal.duration,
              );
              goals[index].perDay = (goals[index].perPeriod / unitDays(updatedGoal.unit)).ceilToDouble();
            }
          });
        },
      ),
    );
  }

  void _deleteGoal(String id) {
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
              setState(() {
                goals.removeWhere((g) => g.id == id);
              });
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
    // Calculate summary
    final totalGoals = goals.length;
    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.saved);
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.target);
    final overallProgress = totalTarget > 0 ? ((totalSaved / totalTarget) * 100).round() : 0;

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
                          onPressed: _showCreateGoalDialog,
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
                    // Summary Bar
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
              // Goals List
              Expanded(
                child: goals.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          return _buildGoalCard(goal);
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

  Widget _buildGoalCard(SavingGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () => _showGoalDetail(goal),
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
                          'เก็บแล้ว ${goal.saved.toInt()} / ${goal.target.toInt()} บาท • เหลือ ${goal.duration} ${unitLabel(goal.unit)}',
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
                          Future.delayed(Duration.zero, () => _showEditGoalDialog(goal));
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
                          Future.delayed(Duration.zero, () => _deleteGoal(goal.id));
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
                    'ตัดออมทุก: ${unitLabel(goal.unit)} • ~ ${goal.perPeriod.toInt()} บาท/${unitLabel(goal.unit)}',
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

// Create Goal Sheet
class CreateGoalSheet extends StatefulWidget {
  final Function(SavingGoal) onCreateGoal;
  final String Function(String) unitLabel;
  final int Function(String) unitDays;
  final double Function(double, double, int) calculatePerPeriod;

  const CreateGoalSheet({
    super.key,
    required this.onCreateGoal,
    required this.unitLabel,
    required this.unitDays,
    required this.calculatePerPeriod,
  });

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _symbolsController = TextEditingController();

  String _unit = 'month';
  String _plan = 'ประจำวัน';
  String _investMode = 'recommend';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'สร้างเป้าหมายออมเงิน',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.beVietnamPro(),
                        decoration: InputDecoration(
                          labelText: 'เป้าหมาย',
                          labelStyle: GoogleFonts.beVietnamPro(),
                          hintText: 'เช่น ทริปญี่ปุ่น / กองทุนฉุกเฉิน',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกเป้าหมาย' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              style: GoogleFonts.beVietnamPro(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'จำนวนเงิน (บาท)',
                                labelStyle: GoogleFonts.beVietnamPro(),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                                ),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกจำนวนเงิน' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              style: GoogleFonts.beVietnamPro(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'ระยะเวลา',
                                labelStyle: GoogleFonts.beVietnamPro(),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                                ),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกระยะเวลา' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _unit,
                              style: GoogleFonts.beVietnamPro(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'ระยะเวลา',
                                labelStyle: GoogleFonts.beVietnamPro(),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                                ),
                              ),
                              items: ['day', 'week', 'month', 'year']
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(widget.unitLabel(u)),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _unit = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('แผน', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('ประจำวัน', style: GoogleFonts.beVietnamPro(fontSize: 14)),
                              value: 'ประจำวัน',
                              groupValue: _plan,
                              activeColor: const Color(0xFF4FB7B3),
                              onChanged: (value) => setState(() => _plan = value!),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('ลงทุน', style: GoogleFonts.beVietnamPro(fontSize: 14)),
                              value: 'ลงทุน',
                              groupValue: _plan,
                              activeColor: const Color(0xFF4FB7B3),
                              onChanged: (value) => setState(() => _plan = value!),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      if (_plan == 'ลงทุน') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('แนะนำ', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                                value: 'recommend',
                                groupValue: _investMode,
                                activeColor: const Color(0xFF4FB7B3),
                                onChanged: (value) => setState(() => _investMode = value!),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('มีตัวเลือกอยู่แล้ว', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                                value: 'custom',
                                groupValue: _investMode,
                                activeColor: const Color(0xFF4FB7B3),
                                onChanged: (value) => setState(() => _investMode = value!),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        if (_investMode == 'custom') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _symbolsController,
                            style: GoogleFonts.beVietnamPro(),
                            decoration: InputDecoration(
                              labelText: 'สัญลักษณ์หรือชื่อ',
                              labelStyle: GoogleFonts.beVietnamPro(),
                              hintText: 'เช่น SET:PTT, SET:BBL',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('ยกเลิก', style: GoogleFonts.beVietnamPro()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleCreate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4FB7B3),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'สร้าง',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate()) {
      final target = double.parse(_amountController.text);
      final duration = int.parse(_durationController.text);
      final perPeriod = widget.calculatePerPeriod(target, 0, duration);
      final perDay = (perPeriod / widget.unitDays(_unit)).ceilToDouble();

      final newGoal = SavingGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        emoji: _plan == 'ลงทุน' ? '📈' : '💰',
        saved: 0,
        target: target,
        duration: duration,
        unit: _unit,
        plan: _plan,
        investMode: _plan == 'ลงทุน' ? _investMode : 'none',
        symbols: _plan == 'ลงทุน' && _investMode == 'custom' ? _symbolsController.text : '',
        progress: 0,
        perPeriod: perPeriod,
        perDay: perDay,
      );

      widget.onCreateGoal(newGoal);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างเป้าหมายสำเร็จ!', style: GoogleFonts.beVietnamPro()),
          backgroundColor: const Color(0xFF4FB7B3),
        ),
      );
    }
  }
}

// Goal Detail Sheet
class GoalDetailSheet extends StatelessWidget {
  final SavingGoal goal;
  final String Function(String) unitLabel;
  final int Function(String) unitDays;
  final Function(double) onAddContribution;
  final VoidCallback onEditGoal;

  const GoalDetailSheet({
    super.key,
    required this.goal,
    required this.unitLabel,
    required this.unitDays,
    required this.onAddContribution,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFC7DCDE),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF14B8A6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('ยอดเป้าหมาย', '${goal.target.toInt()} บาท'),
                        _buildDetailRow('ออมแล้ว', '${goal.saved.toInt()} บาท'),
                        _buildDetailRow('ความคืบหน้า', '${goal.progress.toInt()} %'),
                        _buildDetailRow('ช่วงตัดออม', '${goal.duration} ${unitLabel(goal.unit)}'),
                        _buildDetailRow('ยอดตัดออมต่อช่วง', '${goal.perPeriod.toInt()} บาท/${unitLabel(goal.unit)}'),
                        _buildDetailRow('แผน', goal.plan),
                        if (goal.plan == 'ลงทุน') ...[
                          _buildDetailRow(
                            'โหมดการลงทุน',
                            goal.investMode == 'recommend' ? 'ระบบแนะนำ' : 'ผู้ใช้กำหนดเอง',
                          ),
                          if (goal.investMode == 'custom' && goal.symbols.isNotEmpty)
                            _buildDetailRow('รายการที่ระบุ', goal.symbols),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FB7B3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      goal.progress >= 100
                          ? 'เยี่ยมมาก! เป้าหมายนี้สำเร็จแล้ว 🎉'
                          : 'เหลือ ${(goal.target - goal.saved).toInt()} บาท (${goal.duration * unitDays(goal.unit)} วัน) แนะนำตัดออม ~ ${goal.perPeriod.toInt()} บาท/ต่อ ${unitLabel(goal.unit)}',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddContributionDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: Text('ใส่เงินออม', style: GoogleFonts.beVietnamPro()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEditGoal,
                    icon: const Icon(Icons.edit),
                    label: Text('แก้ไข', style: GoogleFonts.beVietnamPro(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FB7B3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              color: const Color(0xFF666666),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              color: const Color(0xFF223248),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContributionDialog(BuildContext context) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ใส่เงินออมเข้าด้วยตัวเอง',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.beVietnamPro(),
          decoration: InputDecoration(
            labelText: 'จำนวนเงิน (บาท)',
            labelStyle: GoogleFonts.beVietnamPro(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FB7B3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                onAddContribution(amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เพิ่มเงินออม ${amount.toInt()} บาท สำเร็จ!',
                        style: GoogleFonts.beVietnamPro()),
                    backgroundColor: const Color(0xFF4FB7B3),
                  ),
                );
              }
            },
            child: Text('เพิ่ม', style: GoogleFonts.beVietnamPro(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Edit Goal Sheet
class EditGoalSheet extends StatefulWidget {
  final SavingGoal goal;
  final String Function(String) unitLabel;
  final Function(SavingGoal) onSave;

  const EditGoalSheet({
    super.key,
    required this.goal,
    required this.unitLabel,
    required this.onSave,
  });

  @override
  State<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<EditGoalSheet> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _durationController;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _targetController = TextEditingController(text: widget.goal.target.toInt().toString());
    _durationController = TextEditingController(text: widget.goal.duration.toString());
    _unit = widget.goal.unit;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'แก้ไขเป้าหมาย',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.beVietnamPro(),
                      decoration: InputDecoration(
                        labelText: 'ชื่อเป้าหมาย',
                        labelStyle: GoogleFonts.beVietnamPro(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetController,
                      style: GoogleFonts.beVietnamPro(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ยอดเป้าหมาย (บาท)',
                        labelStyle: GoogleFonts.beVietnamPro(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            style: GoogleFonts.beVietnamPro(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'ระยะเวลา',
                              labelStyle: GoogleFonts.beVietnamPro(),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            style: GoogleFonts.beVietnamPro(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'หน่วย',
                              labelStyle: GoogleFonts.beVietnamPro(),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                              ),
                            ),
                            items: ['day', 'week', 'month', 'year']
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(widget.unitLabel(u)),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _unit = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('ยกเลิก', style: GoogleFonts.beVietnamPro()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final updatedGoal = SavingGoal(
                                id: widget.goal.id,
                                name: _nameController.text,
                                emoji: widget.goal.emoji,
                                saved: widget.goal.saved,
                                target: double.parse(_targetController.text),
                                duration: int.parse(_durationController.text),
                                unit: _unit,
                                plan: widget.goal.plan,
                                investMode: widget.goal.investMode,
                                symbols: widget.goal.symbols,
                                progress: widget.goal.progress,
                                perPeriod: widget.goal.perPeriod,
                                perDay: widget.goal.perDay,
                              );
                              widget.onSave(updatedGoal);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('แก้ไขเป้าหมายสำเร็จ!', style: GoogleFonts.beVietnamPro()),
                                  backgroundColor: const Color(0xFF4FB7B3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FB7B3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'บันทึก',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
