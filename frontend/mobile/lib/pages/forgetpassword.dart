import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/authe_service.dart'; // 👈 1. Import service

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;  final AutheService _authService = AutheService(); // 👈 2. สร้าง instance ของ service

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับส่ง request ไปยัง API forgot-password
  Future<void> _resetPassword() async {
    // ตรวจสอบว่ามีข้อมูลหรือไม่ (เหมือนเดิม)
    if (_identifierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email or username'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 👈 3. [REFACTORED] เรียกใช้ service แทนการยิง API ตรงๆ
      final result = await _authService.forgotPassword(_identifierController.text.trim());

      if (!mounted) return;
      // การจัดการผลลัพธ์ยังคงเหมือนเดิม
      if (result['status'] == true) {
        // สำเร็จ - แสดงข้อความและกลับไปหน้า login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Password reset link sent to your email'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // รอ 2 วินาที แล้วกลับไปหน้า login
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // ล้มเหลว - แสดง error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send reset link'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      // 👈 4. [REFACTORED] แสดงข้อความ error ที่โยนมาจาก service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5DCCCC),
              Color(0xFF8FE0D8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // Title
                Text(
                  'Forgot',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                    height: 1.1,
                  ),
                ),
                Text(
                  'Password ?',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 24),

                // Description text
                Text(
                  'คุณลืมรหัสผ่านใช่มั้ย? กรุณากรอกอีเมลแล้วเราจะส่ง link สำหรับการเปลี่ยนรหัสผ่านให้คุณ',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Email Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.beVietnamPro(),
                    decoration: InputDecoration(
                      hintText: 'Email or Username',
                      hintStyle: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF95A5A6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Reset Password Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DCCCC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
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
                            'Reset Password',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const Spacer(),
                
                // Back Button
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Back',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 16,
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