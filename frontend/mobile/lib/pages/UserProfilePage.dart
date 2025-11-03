import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // 👈 [NEW] 1. Import dart:convert
import 'package:shared_preferences/shared_preferences.dart'; // 👈 [NEW] 2. Import SharedPreferences

import '../services/profile_service.dart';
// ⭐️ [NEW] 3. Import หน้า Login/Service (สำหรับเด้งกลับ/Logout)
import '../services/authe_service.dart';
import 'authentication/login.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AutheService _authService =
      AutheService(); // 👈 [NEW] 4. เพิ่ม AutheService

  // 👈 5. [FIXED] แยก State ของข้อมูล 2 ส่วนออกจากกัน
  Map<String, dynamic> profileData = {
    'main_income_amount': '0',
    'side_income_amount': '0',
  };
  Map<String, dynamic> userData = {'username': 'กำลังโหลด...'}; // 👈 [NEW]

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // 👈 6. [FIXED] เรียกฟังก์ชันโหลดข้อมูลทั้ง 2 ส่วน
    _loadAllUserData();
  }

  // 👈 7. [FIXED] สร้างฟังก์ชัน "แม่" สำหรับโหลดข้อมูล
  Future<void> _loadAllUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // โหลด User Data จาก SharedPreferences ก่อน
      await _loadUserDataFromPrefs();

      // จากนั้น โหลด Profile Data จาก API
      final result = await _profileService.fetchUserProfile();

      if (result['status'] == true && mounted) {
        setState(() {
          profileData = result['data'];
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch profile data');
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst("Exception: ", "");

      // ⭐️ จัดการ Error "token not found"
      if (errorMsg.contains('Authentication token not found')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาล็อกอินเพื่อเข้าสู่ระบบ'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        setState(() {
          errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 👈 8. [NEW] ฟังก์ชันสำหรับโหลด User Data จาก SharedPreferences
  Future<void> _loadUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(
      'user',
    ); // (ที่ 'authe_service' บันทึกไว้)

    if (userString != null) {
      setState(() {
        userData = jsonDecode(userString);
      });
    } else {
      // ถ้าไม่เจอข้อมูล user (ไม่ควรเกิดขึ้นถ้า login ถูกต้อง)
      throw Exception('User data not found in session.');
    }
  }

  double get totalMonthlyIncome {
    // 👈 9. [FIXED] อ้างอิงจาก profileData
    double main =
        double.tryParse(profileData['main_income_amount']?.toString() ?? '0') ??
        0;
    double extra =
        double.tryParse(profileData['side_income_amount']?.toString() ?? '0') ??
        0;
    return main + extra;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4DB6AC),
      appBar: AppBar(
        // ... (ส่วน AppBar เหมือนเดิม) ...
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: Text(
          'โปรไฟล์ผู้ใช้',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // 👈 ลบปุ่ม Back
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // ... (โค้ด SnackBar) ...
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage != null
          ? Center(
              // ... (ส่วนแสดง Error) ...
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'เกิดข้อผิดพลาด: $errorMessage',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadAllUserData,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with User Icon and Name
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Stack(
                            // ... (ส่วน Stack ไอคอนโปรไฟล์ เหมือนเดิม) ...
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Color(0xFF26A69A),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF26A69A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            // 👈 10. [FIXED] อ้างอิงจาก userData
                            userData['username'] ?? 'ผู้ใช้งาน',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            // ... (ส่วนป้าย 'สมาชิกทั่วไป' เหมือนเดิม) ...
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26A69A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'สมาชิกทั่วไป',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Personal Information Card
                    _buildInfoCard(
                      title: 'ข้อมูลส่วนตัว',
                      icon: Icons.person_outline,
                      children: [
                        _buildInfoRow(
                          Icons.email_outlined,
                          'อีเมล',
                          // 👈 [FIXED] อ้างอิงจาก userData
                          userData['email'] ?? 'ไม่ระบุ',
                        ),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'เบอร์โทรศัพท์',
                          // 👈 [FIXED] อ้างอิงจาก userData
                          userData['phone_number'] ?? 'ไม่ระบุ',
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'สมัครใช้งานวันที่',
                          // 👈 [FIXED] อ้างอิงจาก userData
                          _formatDate(userData['created_at']),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Monthly Income Card
                    _buildInfoCard(
                      title: 'รายรับต่อเดือน',
                      icon: Icons.account_balance_wallet_outlined,
                      children: [
                        _buildIncomeRow(
                          'รายรับหลัก',
                          // 👈 [FIXED] อ้างอิงจาก profileData
                          profileData['main_income_amount']?.toString() ??
                              '0.00',
                          Colors.green.shade700,
                        ),
                        _buildIncomeRow(
                          'รายรับเสริม',
                          // 👈 [FIXED] อ้างอิงจาก profileData
                          profileData['side_income_amount']?.toString() ??
                              '0.00',
                          Colors.blue.shade700,
                        ),
                        const Divider(
                          color: Colors.white70,
                          thickness: 1,
                          height: 30,
                        ),
                        _buildIncomeRow(
                          'รวมต่อเดือน',
                          totalMonthlyIncome.toStringAsFixed(2),
                          Colors.orange.shade700,
                          isBold: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ... (โค้ดส่วนที่เหลือ _formatDate, _buildInfoCard, _buildInfoRow,
  // _buildIncomeRow, _buildActionButton เหมือนเดิมทั้งหมด) ...

  String _formatDate(String? dateString) {
    if (dateString == null) return 'ไม่ระบุ';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF26A69A), size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF26A69A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(
    String label,
    String amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: isBold ? 17 : 16,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '฿ $amount',
              style: TextStyle(
                fontSize: isBold ? 18 : 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👈 11. [FIXED] เปิดใช้งานปุ่ม Logout (และตั้งค่า)
  Widget _buildActionButtons() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.settings,
            label: 'ตั้งค่าบัญชี',
            color: const Color(0xFF26A69A),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟีเจอร์ตั้งค่า (เร็วๆ นี้)')),
              );
            },
          ),
          const SizedBox(height: 10), // 👈 [NEW]
          _buildActionButton(
            // 👈 [NEW]
            icon: Icons.logout,
            label: 'ออกจากระบบ',
            color: Colors.red.shade600,
            onTap: () {
              _showLogoutDialog(); // 👈 [NEW]
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 15),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // 👈 12. [NEW] ฟังก์ชัน Logout Dialog (เหมือนใน Additional.dart)
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'ออกจากระบบ',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.beVietnamPro(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // เรียกใช้ logout()
                await _authService.logout();

                if (!mounted) return;
                Navigator.pop(dialogContext); // ปิด Dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
                Navigator.pop(dialogContext); // ปิด Dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ออกจากระบบ',
              style: GoogleFonts.beVietnamPro(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
