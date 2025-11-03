// create_goal_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/saving_goal.dart';

class CreateGoalSheet extends StatefulWidget {
  final Function(SavingGoal) onCreateGoal;
  final String Function(String) unitLabel;
  final int Function(String) unitDays;
  final int Function(double, double, double) calculateDuration;

  const CreateGoalSheet({
    super.key,
    required this.onCreateGoal,
    required this.unitLabel,
    required this.unitDays,
    required this.calculateDuration,
  });

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _perPeriodController = TextEditingController();
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
                              controller: _perPeriodController,
                              style: GoogleFonts.beVietnamPro(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'ออมครั้งละ (บาท)',
                                labelStyle: GoogleFonts.beVietnamPro(),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF4FB7B3), width: 2),
                                ),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกจำนวนเงินที่ออม' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _unit,
                              style: GoogleFonts.beVietnamPro(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'ออมทุก',
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
      final perPeriod = double.parse(_perPeriodController.text);
      final duration = widget.calculateDuration(target, 0, perPeriod);
      final perDay = (perPeriod / widget.unitDays(_unit)).ceilToDouble();

      final newGoal = SavingGoal(
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