import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Enum สำหรับรูปแบบการจัดสรร
enum AllocationStyle { balanced, saver, flexible }

class AllocationRecommendationCard extends StatefulWidget {
  final double dailyBudget;

  const AllocationRecommendationCard({
    super.key,
    required this.dailyBudget,
  });

  @override
  State<AllocationRecommendationCard> createState() => _AllocationRecommendationCardState();
}

class _AllocationRecommendationCardState extends State<AllocationRecommendationCard> {
  // ตั้งค่ารูปแบบเริ่มต้นเป็น 'สมดุล'
  AllocationStyle _selectedStyle = AllocationStyle.balanced;

  // ฟังก์ชันสำหรับคำนวณการจัดสรรตามรูปแบบที่เลือก
  Map<String, double> _calculateAllocation() {
    if (widget.dailyBudget <= 0) {
      return {'needs': 0, 'wants': 0, 'savings': 0};
    }

    switch (_selectedStyle) {
      case AllocationStyle.saver: // เน้นออม
        return {
          'needs': widget.dailyBudget * 0.5,
          'wants': widget.dailyBudget * 0.2,
          'savings': widget.dailyBudget * 0.3,
        };
      case AllocationStyle.flexible: // ยืดหยุ่น
        return {
          'needs': widget.dailyBudget * 0.6,
          'wants': widget.dailyBudget * 0.25,
          'savings': widget.dailyBudget * 0.15,
        };
      case AllocationStyle.balanced: // สมดุล (50/30/20)
      default:
        return {
          'needs': widget.dailyBudget * 0.5,
          'wants': widget.dailyBudget * 0.3,
          'savings': widget.dailyBudget * 0.2,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocation = _calculateAllocation();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'แนะนำการจัดสรรเงินรายวัน',
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF223248),
            ),
          ),
          const SizedBox(height: 16),
          // ปุ่มเลือกรูปแบบ
          ToggleButtons(
            isSelected: [
              _selectedStyle == AllocationStyle.balanced,
              _selectedStyle == AllocationStyle.saver,
              _selectedStyle == AllocationStyle.flexible,
            ],
            onPressed: (index) {
              setState(() {
                _selectedStyle = AllocationStyle.values[index];
              });
            },
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: const Color(0xFF14B8A6),
            color: const Color(0xFF14B8A6),
            borderColor: const Color(0xFF14B8A6),
            selectedBorderColor: const Color(0xFF14B8A6),
            children: [
              _buildToggleButton('สมดุล', Icons.balance),
              _buildToggleButton('เน้นออม', Icons.savings),
              _buildToggleButton('ยืดหยุ่น', Icons.shuffle),
            ],
          ),
          const SizedBox(height: 20),
          // ส่วนแสดงผลการจัดสรร
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAllocationItem('ใช้จ่ายจำเป็น', allocation['needs']!, Colors.blue.shade700),
              _buildAllocationItem('ของที่อยากได้', allocation['wants']!, Colors.orange.shade700),
              _buildAllocationItem('เงินออม/ลงทุน', allocation['savings']!, Colors.green.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '~${amount.toInt()} ฿',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}