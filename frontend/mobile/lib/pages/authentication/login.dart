// 1. Importing Dependencies
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

// 👈 1. [REMOVED] ลบ SharedPreferences import
// import 'package:shared_preferences/shared_preferences.dart';

// ไปยังหน้า MainScreen หลังล็อกอินสำเร็จ
import '../components/Navbar.dart' as navbar;

// ⭐️ Import service (เหมือนเดิม)
import '../../services/authe_service.dart';

// 2. Creating and Exporting a Widget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ... (ส่วนตัวแปร Controllers, key, isLoading เหมือนเดิม) ...
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final AutheService _authService = AutheService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ⭐️ 3. [FIXED] แก้ไขฟังก์ชัน handleSubmit ให้สะอาดขึ้น
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. เรียกใช้ service (service จะบันทึก token/user ให้เอง)
      final result = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login response')),
      );

      // 2. ตรวจสอบผลลัพธ์เพื่อ "นำทาง" (Navigate) เท่านั้น
      if (result['status'] == true) {
        // ❌ [REMOVED] ลบโค้ด SharedPreferences จากตรงนี้ทั้งหมด ❌
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('token', result['token']);
        // await prefs.setString('user', jsonEncode(user));

        // 3. ใช้ข้อมูล 'user' จาก result เพื่อตัดสินใจ
        final user = result['user'];
        if (user != null) {
          final bool surveyCompleted = user['survey_completed'] ?? false;

          if (surveyCompleted) {
            // ถ้าเคยทำแล้ว ไปหน้าหลัก
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const navbar.MainScreen(),
              ),
            );
          } else {
            // ถ้ายังไม่เคยทำ บังคับไปหน้าแบบสอบถาม
            Navigator.pushNamed(context, '/questionnaire');
          }
        } else {
          // กรณีไม่มีข้อมูล user กลับมา (Fallback) ให้ไปหน้าหลัก
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const navbar.MainScreen()),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      print('Login error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst("Exception: ", "")),
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

  // ... (ฟังก์ชัน _handleForgotPassword, _handleSignUp, _handleBack เหมือนเดิม) ...
  void _handleForgotPassword() {
    Navigator.pushNamed(context, '/forgetpassword');
  }

  void _handleSignUp() {
    Navigator.pushNamed(context, '/register');
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // ... (โค้ดส่วน UI ทั้งหมดเหมือนเดิม) ...
    // ... ( ... ) ...
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14B8A6), Color(0xFFC7DCDE)],
            ),
          ),
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF223248),
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Form Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            'Login',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Username Input
                          _buildInputField(
                            controller: _usernameController,
                            hintText: 'Username',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter username';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Password Input
                          _buildInputField(
                            controller: _passwordController,
                            hintText: 'Passwords',
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Confirm Button
                          SizedBox(
                            width: 155,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4FB7B3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Forgot Password & Sign Up Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _handleForgotPassword,
                                child: Text(
                                  'Forget Password ?',
                                  style: GoogleFonts.beVietnamPro(
                                    color: const Color(0xFF223248),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _handleSignUp,
                                child: Text(
                                  'Don\'t have account',
                                  style: GoogleFonts.beVietnamPro(
                                    color: const Color(0xFF223248),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method (เหมือนเดิม)
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CAAD6).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.beVietnamPro(),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.beVietnamPro(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4FB7B3), width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
