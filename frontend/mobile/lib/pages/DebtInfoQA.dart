import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 👈 1. Import service และหน้าหลัก
import '../services/profile_service.dart';
import 'components/Navbar.dart' as navbar;


class DebtInfoQAPage extends StatefulWidget {
  const DebtInfoQAPage({super.key});

  @override
  State<DebtInfoQAPage> createState() => _DebtInfoQAPageState();
}

class _DebtInfoQAPageState extends State<DebtInfoQAPage> {
  // 👈 2. [NEW] สร้าง State และ Service instance
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;

  // Controllers for text fields
  final TextEditingController _debtAmountController = TextEditingController();
  final TextEditingController _monthlyPaymentController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController(); // เพิ่มสำหรับดอกเบี้ย

  String? _selectedDebtType;
  
  // รายการประเภทหนี้สำหรับ dropdown
  final List<String> _debtTypeOptions = [
    'สินเชื่อบุคคล',
    'บัตรเครดิต',
    'สินเชื่อบ้าน',
    'สินเชื่อรถยนต์',
    'สินเชื่อการศึกษา',
    'อื่นๆ',
  ];

  @override
  void dispose() {
    _debtAmountController.dispose();
    _monthlyPaymentController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  // 👈 3. [REFACTORED] ปรับปรุงฟังก์ชัน handleSubmit ให้เรียก API
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debtData = {
        'debt_type': _selectedDebtType,
        'debt_amount': double.tryParse(_debtAmountController.text),
        'debt_monthly_payment': double.tryParse(_monthlyPaymentController.text),
        'debt_interest_rate': double.tryParse(_interestRateController.text.isEmpty ? '0' : _interestRateController.text),
      };

      // 👈 [THE FIX] เรียกใช้ฟังก์ชัน addDebtInfo จาก service จริง
      final result = await _profileService.addDebtInfo(debtData);

      if (!mounted) return;

      if (result['status'] == true) {
        _showSuccessDialogAndNavigate();
      } else {
        _showDialog(result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      if (!mounted) return;
      _showDialog(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'แจ้งเตือน',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ตกลง',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👈 4. [NEW] สร้าง Dialog สำหรับเมื่อสำเร็จ และนำทางไปหน้าหลัก
  void _showSuccessDialogAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('สำเร็จ!', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.green)),
        content: Text('ตั้งค่าบัญชีของคุณเรียบร้อยแล้ว', style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ปิด Dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const navbar.MainScreen()),
                (Route<dynamic> route) => false, // ลบทุกหน้าก่อนหน้า
              );
            },
            child: Text('เริ่มต้นใช้งาน', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
          'คำถามข้อมูลหนี้',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6ECCC4), Color(0xFFB8D4D6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form( // 👈 5. [NEW] ครอบด้วย Form widget
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Header Title
                  Text(
                    'ข้อมูลหนี้สิน',
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
                          color: Colors.black.withOpacity(0.1), // 👈 6. [FIXED]
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/debt_illustration.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if image not found
                          return const Center(
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 100,
                              color: Color(0xFF6ECCC4),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ประเภทหนี้ Dropdown
                  _buildDropdownField(
                    label: 'ประเภทหนี้',
                    hint: 'เลือกประเภทหนี้',
                    value: _selectedDebtType,
                    items: _debtTypeOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedDebtType = value;
                      });
                    },
                    validator: (value) => value == null ? 'กรุณาเลือกประเภทหนี้' : null,
                  ),

                  const SizedBox(height: 24),

                  // ยอดหนี้คงเหลือ
                  _buildTextField(
                    controller: _debtAmountController,
                    label: 'ยอดหนี้คงเหลือ',
                    hint: 'กรอกจำนวนเงิน',
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกยอดหนี้' : null,
                  ),

                  const SizedBox(height: 24),

                  // ยอดผ่อนชำระต่อเดือน
                  _buildTextField(
                    controller: _monthlyPaymentController,
                    label: 'ยอดผ่อนชำระต่อเดือน',
                    hint: 'กรอกจำนวนเงิน',
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกยอดผ่อน' : null,
                  ),

                  const SizedBox(height: 24),

                  // อัตราดอกเบี้ย
                  _buildTextField(
                    controller: _interestRateController,
                    label: 'อัตราดอกเบี้ยต่อปี (%) (ถ้ามี)',
                    hint: 'เช่น 18.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // ไม่บังคับกรอก
                  ),

                  const SizedBox(height: 40),

                  // ปุ่มตกลง
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF223248),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'บันทึก',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // ปุ่มข้าม
                  TextButton(
                    onPressed: _isLoading ? null : _showSuccessDialogAndNavigate,
                    child: Text(
                      'ข้ามขั้นตอนนี้',
                      style: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF223248),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 👈 7. [NEW] สร้าง Helper Widgets เพื่อลดโค้ดซ้ำซ้อน
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF223248),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.beVietnamPro(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: hint,
            hintStyle: GoogleFonts.beVietnamPro(color: Colors.grey),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF223248),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: Text(hint, style: GoogleFonts.beVietnamPro(color: Colors.grey)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.beVietnamPro()),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
