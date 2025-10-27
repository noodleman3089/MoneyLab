// 1. Importing Dependencies
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

// 2. Creating and Exporting a Widget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 2.1 Defining Variables, States, and Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ใช้ http package เพื่อส่ง POST request ไปยัง API
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      final result = jsonDecode(response.body);

      if (!mounted) return;

      // แสดงข้อความจาก API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login response')),
      );

      // ถ้าเข้าสู่ระบบสำเร็จ จะ redirect ไปหน้าแรก
      if (result['status'] == true) {
        // อาจเก็บ token หรือ user_id ไว้ใน SharedPreferences
        // await SharedPreferences.getInstance().then((prefs) {
        //   prefs.setString('user_id', result['user_id']);
        //   prefs.setString('token', result['token']);
        // });
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (error) {
      if (!mounted) return;

      print('Login error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า Forget Password
  void _handleForgotPassword() {
    Navigator.pushNamed(context, '/forgetpassword');
  }

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า Register
  void _handleSignUp() {
    Navigator.pushNamed(context, '/register');
  }

  // ฟังก์ชันสำหรับย้อนกลับ
  void _handleBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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

  // Helper method สำหรับสร้าง input field
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
            color: const Color(0xFF9CAAD6).withValues(alpha: 0.3),
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