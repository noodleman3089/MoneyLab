import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'DebtInfoQA.dart';
import '../services/lookup_service.dart';
import '../services/profile_service.dart';
import 'components/Navbar.dart' as navbar;

class FinancialDataQAPage extends StatefulWidget {
  const FinancialDataQAPage({super.key});

  @override
  State<FinancialDataQAPage> createState() => _FinancialDataQAPageState();
}

class _FinancialDataQAPageState extends State<FinancialDataQAPage> {
  // Services
  final LookupService _lookupService = LookupService();
  final ProfileService _profileService = ProfileService();

  // Controllers for text fields
  final TextEditingController _mainIncomeController = TextEditingController();
  final TextEditingController _extraIncomeController = TextEditingController();

  // Dropdown selections
  int? _selectedOccupationId;
  int? _selectedMainIncomePeriodId;
  int? _selectedSideIncomePeriodId;

  // Data from API
  List<Map<String, dynamic>> _occupations = [];
  List<Map<String, dynamic>> _incomePeriods = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// โหลดข้อมูลจาก API
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // ดึงข้อมูล lookups
      final lookupData = await _lookupService.fetchAllLookups();

      setState(() {
        _occupations = (lookupData['occupations'] as List).cast<Map<String, dynamic>>();
        _incomePeriods = (lookupData['income_periods'] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showDialog('ไม่สามารถโหลดข้อมูลได้: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _mainIncomeController.dispose();
    _extraIncomeController.dispose();
    super.dispose();
  }

  /// บันทึกข้อมูลไปยัง Backend
  Future<void> _handleSubmit() async {
    // ตรวจสอบว่ากรอกข้อมูลครบหรือไม่
    if (_selectedOccupationId == null) {
      _showDialog('กรุณาเลือกอาชีพ');
      return;
    }

    if (_mainIncomeController.text.isEmpty || _selectedMainIncomePeriodId == null) {
      _showDialog('กรุณากรอกรายได้หลักและเลือกระยะเวลา');
      return;
    }

    // เตรียมข้อมูลสำหรับส่งไป API
    final profileData = {
      'occupation_id': _selectedOccupationId,
      'main_income_amount': double.tryParse(_mainIncomeController.text) ?? 0.0,
      'main_income_period_id': _selectedMainIncomePeriodId,
      'side_income_amount': _extraIncomeController.text.isEmpty
          ? 0.0
          : double.tryParse(_extraIncomeController.text) ?? 0.0,
      'side_income_period_id': _selectedSideIncomePeriodId,
    };

    try {
      // แสดง Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // เรียก API
      final result = await _profileService.updateUserProfile(profileData);

      // ปิด Loading Dialog
      if (mounted) Navigator.of(context).pop();

      if (result['status'] == true) {
        // ถามว่ามีหนี้ไหม
        _showDebtQuestionDialog();
      } else {
        _showDialog(result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      // ปิด Loading Dialog
      if (mounted) Navigator.of(context).pop();
      _showDialog('ไม่สามารถบันทึกข้อมูลได้: ${e.toString()}');
    }
  }

  void _showDialog(String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แจ้งเตือน'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  /// แสดง Dialog ถามว่ามีหนี้ไหม
  void _showDebtQuestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'คุณมีหนี้สินหรือไม่?',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'ถ้าคุณมีหนี้สิน กรุณาบันทึกข้อมูลเพื่อให้เราช่วยวางแผนการเงินให้คุณได้ดีขึ้น',
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ไม่มีหนี้ - ไปหน้าหลัก
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const navbar.MainScreen()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text(
              'ไม่มี',
              style: GoogleFonts.beVietnamPro(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // มีหนี้ - ไปหน้ากรอกข้อมูลหนี้
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DebtInfoQAPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF223248),
            ),
            child: Text(
              'มี',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ทดสอบการเปลี่ยนหน้า
  void handleNextPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DebtInfoQAPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF223248),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'คำถามข้อมูลการเงิน',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6ECCC4), Color(0xFFB8D4D6)],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                const SizedBox(height: 20),

                // Header Title
                Text(
                  'คำถามข้อมูลการเงิน',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF223248),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Illustration
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 100,
                      color: Color(0xFF6ECCC4),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // อาชีพ Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อาชีพ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF223248),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedOccupationId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        hint: Text(
                          'เลือกอาชีพ',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.grey,
                          ),
                        ),
                        items: _occupations.map((occupation) {
                          return DropdownMenuItem<int>(
                            value: occupation['occupation_id'],
                            child: Text(
                              occupation['occupation_name'],
                              style: GoogleFonts.beVietnamPro(),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedOccupationId = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // รายได้หลัก และ ระยะเวลา
                Row(
                  children: [
                    // รายได้หลัก
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายได้หลัก',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _mainIncomeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.beVietnamPro(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                hintText: 'บาท',
                                hintStyle: GoogleFonts.beVietnamPro(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ระยะเวลา
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ระยะเวลา',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<int>(
                              value: _selectedMainIncomePeriodId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              hint: Text(
                                'เลือก',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.grey,
                                ),
                              ),
                              items: _incomePeriods.map((period) {
                                return DropdownMenuItem<int>(
                                  value: period['period_id'],
                                  child: Text(
                                    period['name_th'],
                                    style: GoogleFonts.beVietnamPro(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedMainIncomePeriodId = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // รายได้เสริม และ ระยะเวลา
                Row(
                  children: [
                    // รายได้เสริม
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายได้เสริม (ถ้ามี)',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _extraIncomeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.beVietnamPro(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                hintText: 'บาท',
                                hintStyle: GoogleFonts.beVietnamPro(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ระยะเวลา
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ระยะเวลา',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<int>(
                              value: _selectedSideIncomePeriodId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              hint: Text(
                                'เลือก',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.grey,
                                ),
                              ),
                              items: _incomePeriods.map((period) {
                                return DropdownMenuItem<int>(
                                  value: period['period_id'],
                                  child: Text(
                                    period['name_th'],
                                    style: GoogleFonts.beVietnamPro(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedSideIncomePeriodId = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ปุ่มตกลง
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF223248),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'ตกลง',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Test Button to Test DebtInfoQA Page
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebtInfoQAPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB74D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Test DebtInfoQA Page',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
