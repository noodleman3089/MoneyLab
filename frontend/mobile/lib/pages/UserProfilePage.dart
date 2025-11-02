import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 👈 1. Import service ที่สร้างขึ้นมาใหม่
import '../services/profile_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // 👈 2. สร้าง instance ของ service
  final ProfileService _profileService = ProfileService();

  // 👈 3. [REFACTORED] เปลี่ยน userData เป็น nullable และจัดการ state
  Map<String, dynamic> userData = {
    'user': {'username': 'กำลังโหลด...'},
    'profile': {'main_income_amount': '0', 'side_income_amount': '0'}
  };
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // 👈 4. [IMPLEMENTED] เรียก API เพื่อดึงข้อมูลผู้ใช้
    _fetchUserData();
  }

  // 👈 5. [IMPLEMENTED] ฟังก์ชันสำหรับดึงข้อมูลผู้ใช้จาก API
  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await _profileService.fetchUserProfile();
      if (result['status'] == true && mounted) {
        setState(() {
          userData = result['data'];
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch profile data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  double get totalMonthlyIncome {
    // 👈 6. [REFACTORED] ปรับให้ตรงกับโครงสร้างข้อมูลจาก API
    double main = double.tryParse(userData['profile']?['main_income_amount']?.toString() ?? '0') ?? 0;
    double extra = double.tryParse(userData['profile']?['side_income_amount']?.toString() ?? '0') ?? 0;
    return main + extra;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4DB6AC),
      appBar: AppBar(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // TODO: นำไปหน้าแก้ไขข้อมูล
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ฟีเจอร์แก้ไขข้อมูล (เร็วๆ นี้)',
                    style: GoogleFonts.beVietnamPro(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('เกิดข้อผิดพลาด: $errorMessage', style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 16), textAlign: TextAlign.center,),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _fetchUserData, child: const Text('ลองอีกครั้ง'))
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
                            // 👈 7. [REFACTORED] ปรับให้ตรงกับโครงสร้างข้อมูลจาก API
                            userData['user']?['username'] ?? 'ผู้ใช้งาน',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
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
                          userData['user']?['email'] ?? 'ไม่ระบุ',
                        ),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'เบอร์โทรศัพท์',
                          userData['user']?['phone_number'] ?? 'ไม่ระบุ',
                        ),
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'สมัครใช้งานวันที่',
                          _formatDate(userData['user']?['created_at']),
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
                          userData['profile']?['main_income_amount']?.toString() ?? '0.00',
                          Colors.green.shade700,
                        ),
                        _buildIncomeRow(
                          'รายรับเสริม',
                          userData['profile']?['side_income_amount']?.toString() ?? '0.00',
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

  Widget _buildIncomeRow(String label, String amount, Color color,
      {bool isBold = false}) {
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
              // TODO: นำไปหน้าตั้งค่า
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟีเจอร์ตั้งค่า (เร็วๆ นี้)')),
              );
            },
          ),
          
          const SizedBox(height: 10),
          
          _buildActionButton(
            icon: Icons.logout,
            label: 'ออกจากระบบ',
            color: Colors.red.shade600,
            onTap: () {
              _showLogoutDialog();
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.beVietnamPro(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: ทำการ logout และ clear token
              Navigator.pop(context);
              Navigator.pop(context); // กลับไปหน้าก่อนหน้า
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ออกจากระบบสำเร็จ',
                    style: GoogleFonts.beVietnamPro(),
                  ),
                ),
              );
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
