import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class DailySummaryCard extends StatelessWidget {
  final double dailyGoal;
  final double currentSpending;
  final double walletBalance;
  final double progress;
  final VoidCallback onEditBudget;

  const DailySummaryCard({
    super.key,
    required this.dailyGoal,
    required this.currentSpending,
    required this.walletBalance,
    required this.progress,
    required this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.symmetric(vertical: 30),
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
                // Wallet Balance
                Positioned(
                  top: 10,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เงินคงเหลือ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      Text(
                        '${walletBalance.toInt()} ฿',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF223248),
                        ),
                      ),
                    ],
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
                        children: [
                          Text(
                            '${dailyGoal.toInt()} บาท / วัน',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF14B8A6),
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