// edit_goal_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/saving_goal.dart';

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
  late TextEditingController _perPeriodController;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _targetController = TextEditingController(text: widget.goal.target.toInt().toString());
    _perPeriodController = TextEditingController(text: widget.goal.perPeriod.toInt().toString());
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
                              final target = double.parse(_targetController.text);
                              final perPeriod = double.parse(_perPeriodController.text);
                              final perDay = (perPeriod / (
                                _unit == 'day' ? 1 :
                                _unit == 'week' ? 7 :
                                _unit == 'month' ? 30 : 365
                              )).ceilToDouble();

                              final updatedGoal = SavingGoal(
                                id: widget.goal.id,
                                name: _nameController.text,
                                emoji: widget.goal.emoji,
                                saved: widget.goal.saved,
                                target: target,
                                duration: widget.goal.duration,
                                unit: _unit,
                                plan: widget.goal.plan,
                                investMode: widget.goal.investMode,
                                symbols: widget.goal.symbols,
                                progress: widget.goal.progress,
                                perPeriod: perPeriod,
                                perDay: perDay,
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