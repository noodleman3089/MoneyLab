import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/saving_goal.dart';
import 'package:provider/provider.dart';
import '../../services/wallet_service.dart';

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
      // 1. ใช้ Consumer<WalletService> เพื่อ "เฝ้าดู" การเปลี่ยนแปลง
      builder: (context) => Consumer<WalletService>(
        builder: (context, walletService, child) {
          // 2. ดึงค่า balance ล่าสุดจาก walletService ที่ Consumer ส่งมาให้
          final currentBalance = walletService.wallet?.balance ?? 0.0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'ใส่เงินออมเข้าด้วยตัวเอง',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. ส่วนนี้จะ rebuild อัตโนมัติเมื่อค่า balance เปลี่ยน
                Text(
                  'เงินใน Wallet: ${currentBalance.toInt()} บาท',
                  style: GoogleFonts.beVietnamPro(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
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
              ],
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
                  if (amount == null || amount <= 0) {
                    return;
                  }
                  if (amount > currentBalance) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ยอดเงินใน Wallet ไม่เพียงพอ!',
                            style: GoogleFonts.beVietnamPro()),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  onAddContribution(amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เพิ่มเงินออม ${amount.toInt()} บาท สำเร็จ!',
                          style: GoogleFonts.beVietnamPro()),
                      backgroundColor: const Color(0xFF4FB7B3),
                    ),
                  );
                },
                child: Text('เพิ่ม', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}