import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class DailySummaryCard extends StatelessWidget {
  final double dailyGoal;
  final double currentSpending;
  final double walletBalance;
  final double progress;
  final VoidCallback onEditBudget;
  final VoidCallback onResetWallet; // 👈 1. เพิ่ม Callback สำหรับการรีเซ็ต

  const DailySummaryCard({
    super.key,
    required this.dailyGoal,
    required this.currentSpending,
    required this.walletBalance,
    required this.progress,
    required this.onEditBudget,
    required this.onResetWallet, // 👈 2. เพิ่มใน constructor
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allow widgets to be drawn outside the bounds
      children: [
        // The main card content
        Container(
          margin: const EdgeInsets.only(top: 30), // Make space for the wallet balance card
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Semicircle Section with Progress
              Container(
                padding: const EdgeInsets.fromLTRB(30, 50, 30, 30), // Adjust padding
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Semicircle with progress
                    CustomPaint(
                      size: const Size(280, 140),
                      painter: SemiCircleProgressPainter(
                        progress: progress.clamp(0.0, 1.0),
                        progressColor: const Color(0xFF14B8A6),
                        backgroundColor: const Color(0xFFC7DCDE),
                      ),
                    ),
                    // Goal Text
                    Positioned(
                      top: 40,
                      child: Column(
                        children: [
                          Text(
                            'เป้าหมายการใช้จ่าย',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center, // จัดให้อยู่กลางแนวตั้ง
                            children: [
                              Flexible( // 👈 1. ครอบ Text ด้วย Flexible
                                child: Text(
                                  '${dailyGoal.toInt()} บาท / วัน',
                                  textAlign: TextAlign.center, // จัดให้อยู่กลางถ้าขึ้นบรรทัดใหม่
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF14B8A6),
                                  ),
                                  softWrap: true, // อนุญาตให้ขึ้นบรรทัดใหม่
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF666666), size: 24),
                                onPressed: onEditBudget,
                                tooltip: 'ตั้งงบประมาณรายวัน',
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Info section
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
                  ],
                ),
              ),
            ],
          ),
        ),
        // Wallet Balance Card positioned on top
        Positioned(
          top: 0,
          left: 20,
          child: _buildWalletBalanceCard(walletBalance, onResetWallet), // 👈 3. ส่งค่าและฟังก์ชันไป
        ),
      ],
    );
  }
}

// Custom Painter for Semicircle with Progress
class SemiCircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  SemiCircleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Draw background semicircle
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // Draw progress semicircle
    canvas.drawArc(rect, math.pi, math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

Widget _buildWalletBalanceCard(double walletBalance, VoidCallback onReset) {
  // 👈 4. รับค่า walletBalance และ onReset
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เงินคงเหลือใน Wallet',
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
            Text(
              '${walletBalance.toInt()} ฿',
              style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // 👈 5. เพิ่มปุ่มรีเซ็ต
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          onPressed: onReset,
          tooltip: 'รีเซ็ตยอดเงินใน Wallet',
          splashRadius: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        )
      ],
    ),
  );
}