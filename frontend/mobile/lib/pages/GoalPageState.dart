import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
// import 'Navbar.dart' as navbar;

// GoalPage Widget
class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  double dailyGoal = 500;
  double currentSpending = 150;
  List<Map<String, dynamic>> dailyTransactions = [];

  @override
  Widget build(BuildContext context) {
    double progress = currentSpending / dailyGoal;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'เป้าหมายการออมเงิน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1a7f7f),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Goal Semicircle Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                            color: const Color(0xFF1a7f7f),
                            backgroundColor: Colors.grey[200]!,
                          ),
                        ),
                        // Text content
                        Positioned(
                          top: 40,
                          child: Column(
                            children: [
                              const Text(
                                'เป้าหมายการออมเงิน',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1a7f7f),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${dailyGoal.toInt()} บาท : วัน',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a7f7f),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8D8D8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ยอดใช้จ่ายวนี้',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currentSpending.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a7f7f),
                                height: 1,
                              ),
                            ),
                            Text(
                              ' / ${dailyGoal.toInt()} บาท',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1a7f7f),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Daily Transactions Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1a7f7f),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'การใช้จ่ายประจำวันนี้',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                          onPressed: () {
                            _showAddTransactionDialog(context);
                          },
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
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยังไม่มีรายการใช้จ่ายวันนี้',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dailyTransactions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final transaction = dailyTransactions[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a7f7f).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoryIcon(transaction['category']),
                                  color: const Color(0xFF1a7f7f),
                                ),
                              ),
                              title: Text(
                                transaction['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                transaction['category'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Text(
                                '${transaction['amount']} ฿',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a7f7f),
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
          title: const Text('เพิ่มรายการใช้จ่าย'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'หมวดหมู่',
                      border: OutlineInputBorder(),
                    ),
                    items: ['อาหาร', 'ช้อปปิ้ง', 'เดินทาง', 'บันเทิง', 'อื่นๆ']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
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
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียด',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนเงิน',
                      border: OutlineInputBorder(),
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
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a7f7f),
                foregroundColor: Colors.white,
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
              child: const Text('เพิ่ม'),
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
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background semicircle
    canvas.drawArc(rect, 3.14, 3.14, false, bgPaint);

    // Draw border semicircle
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
