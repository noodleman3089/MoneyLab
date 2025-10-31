import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

// DailyManagementPage Widget (renamed from GoalPage)
class DailyManagementPage extends StatefulWidget {
  const DailyManagementPage({super.key});

  @override
  State<DailyManagementPage> createState() => _DailyManagementPageState();
}

class _DailyManagementPageState extends State<DailyManagementPage> {
  double dailyGoal = 500;
  double currentSpending = 150;
  List<Map<String, dynamic>> dailyTransactions = [];

  @override
  Widget build(BuildContext context) {
    double progress = currentSpending / dailyGoal;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14B8A6), Color(0xFFC7DCDE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text (
                    'จัดการรายวัน',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF223248),
                    ),
                  ),
                ),
              ),
              // Body Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Goal Semicircle Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Semicircle Section
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Semicircle background
                                  CustomPaint(
                                    size: const Size(280, 140),
                                    painter: SemiCirclePainter(
                                      color: const Color(0xFF14B8A6),
                                      backgroundColor: const Color(0xFFC7DCDE),
                                    ),
                                  ),
                                  // Text content
                                  Positioned(
                                    top: 40,
                                    child: Column(
                                      children: [
                                        Text(
                                          'เป้าหมายการออมเงิน',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF223248),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${dailyGoal.toInt()} บาท / วัน',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF14B8A6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress bar section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F9F8),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ยอดใช้จ่ายวันนี้',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF223248),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        currentSpending.toInt().toString(),
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF14B8A6),
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        ' / ${dailyGoal.toInt()} บาท',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 14,
                                      backgroundColor: Colors.white,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF14B8A6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'คงเหลือ ${(dailyGoal - currentSpending).toInt()} บาท',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      color: const Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Daily Transactions Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'การใช้จ่ายประจำวันนี้',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                                      onPressed: () {
                                        _showAddTransactionDialog(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Transaction List
                            dailyTransactions.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0F9F8),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long_outlined,
                                            size: 64,
                                            color: Color(0xFF14B8A6),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'ยังไม่มีรายการใช้จ่ายวันนี้',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 16,
                                            color: const Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'เพิ่มรายการเพื่อติดตามการใช้จ่าย',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 14,
                                            color: const Color(0xFF999999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: dailyTransactions.length,
                                    separatorBuilder: (context, index) => const Divider(
                                      height: 1,
                                      color: Color(0xFFF0F0F0),
                                    ),
                                    itemBuilder: (context, index) {
                                      final transaction = dailyTransactions[index];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        leading: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            _getCategoryIcon(transaction['category']),
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        title: Text(
                                          transaction['description'],
                                          style: GoogleFonts.beVietnamPro(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: const Color(0xFF223248),
                                          ),
                                        ),
                                        subtitle: Text(
                                          transaction['category'],
                                          style: GoogleFonts.beVietnamPro(
                                            color: const Color(0xFF999999),
                                            fontSize: 14,
                                          ),
                                        ),
                                        trailing: Text(
                                          '${transaction['amount']} ฿',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF14B8A6),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'อาหาร':
        return Icons.restaurant;
      case 'ช้อปปิ้ง':
        return Icons.shopping_bag;
      case 'เดินทาง':
        return Icons.directions_car;
      case 'บันเทิง':
        return Icons.movie;
      default:
        return Icons.payment;
    }
  }

  void _showAddTransactionDialog(BuildContext context) {
    final TextEditingController descController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String selectedCategory = 'อาหาร';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'เพิ่มรายการใช้จ่าย',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF223248),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'หมวดหมู่',
                      labelStyle: GoogleFonts.beVietnamPro(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                      ),
                    ),
                    items: ['อาหาร', 'ช้อปปิ้ง', 'เดินทาง', 'บันเทิง', 'อื่นๆ']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: GoogleFonts.beVietnamPro()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    style: GoogleFonts.beVietnamPro(),
                    decoration: InputDecoration(
                      labelText: 'รายละเอียด',
                      labelStyle: GoogleFonts.beVietnamPro(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    style: GoogleFonts.beVietnamPro(),
                    decoration: InputDecoration(
                      labelText: 'จำนวนเงิน',
                      labelStyle: GoogleFonts.beVietnamPro(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                      ),
                      suffixText: 'บาท',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                if (descController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  setState(() {
                    dailyTransactions.add({
                      'category': selectedCategory,
                      'description': descController.text,
                      'amount': double.parse(amountController.text),
                    });
                    currentSpending += double.parse(amountController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'เพิ่ม',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom Painter for Semicircle
class SemiCirclePainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;

  SemiCirclePainter({
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background semicircle
    canvas.drawArc(rect, 3.14, 3.14, false, bgPaint);

    // Draw border semicircle
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
