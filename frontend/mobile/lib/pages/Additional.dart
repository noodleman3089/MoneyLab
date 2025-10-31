import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalPage extends StatelessWidget {
  const AdditionalPage({super.key});

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
                      _buildSectionHeader('ตั้งค่าทั่วไป'),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        context,
                        title: 'เปลี่ยนภาษา (ไทย / อังกฤษ)',
                        icon: Icons.language,
                        onTap: () {
                          _showLanguageDialog(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        context,
                        title: 'ออกจากระบบ',
                        icon: Icons.logout,
                        isLogout: true,
                        onTap: () {
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
                color: Colors.black.withValues(alpha: 0.08),
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
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isLogout ? const Color(0xFFD32F2F) : const Color(0xFF223248),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isLogout ? const Color(0xFFD32F2F) : const Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'เลือกภาษา',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF223248),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                title: 'ไทย',
                subtitle: 'Thai',
                flag: '🇹🇭',
                isSelected: true,
              ),
              const SizedBox(height: 8),
              _buildLanguageOption(
                context,
                title: 'English',
                subtitle: 'อังกฤษ',
                flag: '🇬🇧',
                isSelected: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ปิด',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFF14B8A6),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เปลี่ยนภาษาเป็น $title แล้ว',
              style: GoogleFonts.beVietnamPro(),
            ),
            backgroundColor: const Color(0xFF14B8A6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F7F4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF14B8A6) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF223248),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF14B8A6),
                size: 24,
              ),
          ],
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
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F4),
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

  void _showLogoutDialog(BuildContext context) {
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
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
