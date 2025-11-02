import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DebtInfoQAPage extends StatefulWidget {
  const DebtInfoQAPage({super.key});

  @override
  State<DebtInfoQAPage> createState() => _DebtInfoQAPageState();
}

class _DebtInfoQAPageState extends State<DebtInfoQAPage> {
  // Controllers for text fields
  final TextEditingController _debtAmountController = TextEditingController();
  final TextEditingController _monthlyPaymentController = TextEditingController();

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
    super.dispose();
  }

  void _handleSubmit() {
    // ตรวจสอบว่ากรอกข้อมูลครบหรือไม่
    if (_selectedDebtType == null) {
      _showDialog('กรุณาเลือกประเภทหนี้');
      return;
    }

    if (_debtAmountController.text.isEmpty) {
      _showDialog('กรุณากรอกรากหนี้');
      return;
    }

    if (_monthlyPaymentController.text.isEmpty) {
      _showDialog('กรุณากรอกผ่อนต่อเดือน');
      return;
    }

    // แสดงข้อมูลที่กรอก (สามารถส่งไป API ได้)
    _showDialog('บันทึกข้อมูลเรียบร้อย');
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Header Title
                Text(
                  'คำถามข้อมูลหนี้',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประเภทหนี้',
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
                      child: DropdownButtonFormField<String>(
                        value: _selectedDebtType,
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
                          'เลือกประเภทหนี้',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.grey,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF223248),
                        ),
                        items: _debtTypeOptions.map((String debtType) {
                          return DropdownMenuItem<String>(
                            value: debtType,
                            child: Text(
                              debtType,
                              style: GoogleFonts.beVietnamPro(),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDebtType = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // รากหนี้
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รากหนี้',
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
                        controller: _debtAmountController,
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
                          hintText: 'กรอกจำนวนเงิน',
                          hintStyle: GoogleFonts.beVietnamPro(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ผ่อนต่อเดือน
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผ่อนต่อเดือน',
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
                        controller: _monthlyPaymentController,
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
                          hintText: 'กรอกจำนวนเงิน',
                          hintStyle: GoogleFonts.beVietnamPro(
                            color: Colors.grey,
                          ),
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
