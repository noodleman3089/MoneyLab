import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../add_transaction_page.dart';

class AddExpenseOptionSheet extends StatelessWidget {
  const AddExpenseOptionSheet({super.key});

  // ฟังก์ชันสำหรับนำทางไปยังหน้าเพิ่มรายการแบบกรอกเอง
  Future<dynamic> _navigateToAddTransaction(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(transactionType: 'expense'),
        fullscreenDialog: true,
      ),
    );
  }

  // ฟังก์ชันสำหรับแสดง "เร็วๆ นี้"
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์อัปโหลดรูปภาพ (เร็วๆ นี้)', style: GoogleFonts.beVietnamPro()),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกวิธีการเพิ่มรายจ่าย',
            style: GoogleFonts.beVietnamPro(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF223248),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit_note, color: Color(0xFF14B8A6), size: 32),
            title: Text('กรอกข้อมูลเอง', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text('เพิ่มรายการด้วยการกรอกตัวเลขและรายละเอียด', style: GoogleFonts.beVietnamPro()),
            onTap: () {
              Navigator.pop(context, 'manual'); // ปิด Bottom Sheet และส่งค่ากลับ
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF14B8A6), size: 32),
            title: Text('อัปโหลดสลิป/ใบเสร็จ', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text('ระบบจะดึงข้อมูลจากรูปภาพให้ (เร็วๆ นี้)', style: GoogleFonts.beVietnamPro()),
            onTap: () {
              Navigator.pop(context, 'upload'); // ปิด Bottom Sheet และส่งค่ากลับ
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}