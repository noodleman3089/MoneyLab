import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ⭐️ 1. Import service และหน้า Login
import '../services/authe_service.dart';
import 'authentication/login.dart'; // (หรือ path ที่ถูกต้องไปยังหน้า LoginPage)

// ⭐️ 2. แปลงเป็น StatefulWidget
class AdditionalPage extends StatefulWidget {
  const AdditionalPage({super.key});

  @override
  State<AdditionalPage> createState() => _AdditionalPageState();
}

// ⭐️ 3. สร้างคลาส State
class _AdditionalPageState extends State<AdditionalPage> {
  // ⭐️ 4. สร้าง instance ของ service
  final AutheService _authService = AutheService();

  @override
  Widget build(BuildContext context) {
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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'บัญชี',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF223248),
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // บัญชีผู้ใช้ Section
                      _buildSectionHeader('บัญชีผู้ใช้'),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        context,
                        title: 'อัพเดตอีเมล',
                        icon: Icons.email_outlined,
                        onTap: () {
                          _showComingSoonDialog(context, 'อัพเดตอีเมล');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        context,
                        title: 'เปลี่ยนรหัสผ่าน',
                        icon: Icons.lock_outline,
                        onTap: () {
                          _showComingSoonDialog(context, 'เปลี่ยนรหัสผ่าน');
                        },
                      ),

                      const SizedBox(height: 24),
                      // การแจ้งเตือน Section
                      _buildSectionHeader('การแจ้งเตือน'),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        context,
                        title: 'เปิด/ปิดการแจ้งเตือนเมื่อใช้เงินเกิน',
                        icon: Icons.notifications_outlined,
                        onTap: () {
                          _showComingSoonDialog(context, 'การแจ้งเตือน');
                        },
                      ),
                      const SizedBox(height: 24),
                      // ตั้งค่าทั่วไป Section
                      _buildSectionHeader('ออกจากระบบ'),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        context,
                        title: 'ออกจากระบบ',
                        icon: Icons.logout,
                        isLogout: true,
                        onTap: () {
                          // ⭐️ 5. เรียกใช้ฟังก์ชัน _showLogoutDialog (ซึ่งตอนนี้อยู่ใน State)
                          _showLogoutDialog(context);
                        },
                      ),
                      const SizedBox(height: 24),
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

  // ⭐️ 6. ย้าย Helper methods ทั้งหมดเข้ามาในคลาส State
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF223248),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isLogout ? const Color(0xFFFFE5E5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ⭐️ (แก้ไข Error) .withValues ➜ .withOpacity
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isLogout
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isLogout
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF223248),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isLogout
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction,
                  size: 48,
                  color: Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'กำลังพัฒนา',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF223248),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ฟีเจอร์ "$feature" กำลังอยู่ในระหว่างการพัฒนา',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'เข้าใจแล้ว',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ⭐️ 7. แก้ไขฟังก์ชัน Logout ให้เชื่อมต่อกับ Service
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // ⭐️ ใช้ dialogContext
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  size: 48,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ออกจากระบบ',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF223248),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณต้องการออกจากระบบใช่หรือไม่?',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext), // ⭐️
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF14B8A6)),
                      ),
                    ),
                    child: Text(
                      'ยกเลิก',
                      style: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF14B8A6),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // ⭐️ 8. เปลี่ยนเป็น async และเรียกใช้ service
                    onPressed: () async {
                      try {
                        // เรียกใช้ logout()
                        await _authService.logout();

                        if (!mounted) return;

                        // ปิด Dialog
                        Navigator.pop(dialogContext);

                        // เด้งไปหน้า Login และล้างทุกหน้า
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'ออกจากระบบสำเร็จ',
                              style: GoogleFonts.beVietnamPro(),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        // ถ้า Error
                        Navigator.pop(dialogContext); // ปิด Dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'เกิดข้อผิดพลาด: ${e.toString()}',
                              style: GoogleFonts.beVietnamPro(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'ออกจากระบบ',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
