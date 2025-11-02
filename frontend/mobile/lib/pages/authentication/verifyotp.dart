import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/authe_service.dart';
import '../Questionnaire.dart'; // 👈 1. Import หน้า QuestionnairePage

class VerifyOtpPage extends StatefulWidget {
  final String email;

  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  // --- 1. ส่วน State และ Logic (เหมือนเดิม) ---
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  final AutheService _authService = AutheService();

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณากรอก OTP ให้ครบ 6 หลัก',
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'ยืนยัน OTP สำเร็จ',
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: result['status'] == true
              ? const Color(0xFF4FB7B3)
              : Colors.red,
        ),
      );

      if (result['status'] == true) {
        // 👈 2. [THE FIX] เปลี่ยนจากไปหน้า Login เป็นไปหน้า Questionnaire
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QuestionnairePage()),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst("Exception: ", ""),
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  // --- 2. ส่วน UI (แก้ไข) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2.1: AppBar (คง Theme เดิมไว้)
      appBar: AppBar(
        backgroundColor: const Color(0xFF6ECCC4),
        elevation: 0,
        // (เอา automaticallyImplyLeading: false ออก
        //  เพื่อให้ Flutter สร้างปุ่ม Back ◀️ ให้อัตโนมัติ)
        // automaticallyImplyLeading: false,
        title: Text(
          'Verify OTP',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF223248),
          ),
        ),
      ),
      body: Container(
        // 2.2: Background (คง Theme เดิมไว้)
        // ตั้งค่าให้พื้นหลังไล่สีเต็มหน้าจอ
        width: double.infinity, // ทำให้ Container กว้างเต็มจอ
        height: double.infinity, // ทำให้ Container สูงเต็มจอ
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6ECCC4), Color(0xFFB8D4D6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            // 2.3: เนื้อหา (แก้ไขการจัดวาง)
            child: Column(
              // (แก้ไข) เปลี่ยนจาก .start เป็น .stretch
              // เพื่อยืด Column ให้เต็มความกว้าง
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                Text(
                  'Confirm\nYour OTP',
                  // (แก้ไข) เพิ่ม textAlign: TextAlign.center
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF223248),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Enter the 6-digit OTP',
                  // (แก้ไข) เพิ่ม textAlign: TextAlign.center
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: const Color(0xFF223248),
                  ),
                ),
                Text(
                  'We just sent to your email address.',
                  // (แก้ไข) เพิ่ม textAlign: TextAlign.center
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: const Color(0xFF223248),
                  ),
                ),

                const SizedBox(height: 32),

                // 2.4: ช่อง OTP (เหมือนเดิม)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              // (แก้ไข) ⭐️ .withValues ➜ .withOpacity
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.length == 1 && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                Text(
                  'OTP has been sent to your email.',
                  // (แก้ไข) เพิ่ม textAlign: TextAlign.center
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: const Color(0xFF223248),
                  ),
                ),
                Text(
                  widget.email,
                  // (แก้ไข) เพิ่ม textAlign: TextAlign.center
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF223248),
                  ),
                ),

                const SizedBox(height: 48),

                // 2.5: ปุ่ม Confirm (เหมือนเดิม)
                // (โค้ดเดิมของคุณใช้ Center หุ้มอยู่แล้ว ซึ่งถูกต้องครับ)
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FB7B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Confirm',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 2.6: ปุ่ม Back (เหมือนเดิม)
                // (แก้ไข) หุ้มด้วย Center เพื่อให้มันอยู่กึ่งกลาง
                Center(
                  child: TextButton.icon(
                    onPressed: _handleBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF223248),
                    ),
                    label: Text(
                      'Back',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        color: const Color(0xFF223248),
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
