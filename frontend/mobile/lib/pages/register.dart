// 1. Importing Dependencies
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

// 2. Creating and Exporting a Widget
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 2.1 Defining Variables, States, and Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ตรวจสอบว่ากดติ๊กถูกที่ Terms and Conditions หรือยัง
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว'),
        ),
      );
      return;
    }

    // ตรวจสอบว่า password ตรงกับ confirmPassword หรือไม่
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text,
          'email': _emailController.text,
          'phone_number': _phoneNumberController.text,
        }),
      );

      final result = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration response')),
      );

      if (result['status'] == true) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (error) {
      if (!mounted) return;

      print('Registration error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันสำหรับจัดการการเข้าสู่ระบบด้วย Google (ยังไม่ได้ implement)
  void _handleGoogleSignIn() {
    print('Google sign-in clicked');
    // TODO: Implement Google sign-in
  }

  // ฟังก์ชันสำหรับย้อนกลับ
  void _handleBack() {
    Navigator.pop(context);
  }

  // แสดง Terms of Use Modal
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เงื่อนไขการใช้งาน',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF223248),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยินดีต้อนรับสู่ MoneyLab กรุณาอ่านเงื่อนไขการใช้งานเหล่านี้อย่างละเอียดก่อนใช้บริการของเรา',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '1. การยอมรับเงื่อนไข',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'การใช้บริการของเราถือว่าคุณยอมรับและตกลงที่จะปฏิบัติตามเงื่อนไขการใช้งานทั้งหมด',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '2. การใช้บริการ',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'คุณตกลงที่จะใช้บริการเพื่อวัตถุประสงค์ที่ถูกต้องตามกฎหมายเท่านั้น',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '3. ความรับผิดชอบของผู้ใช้',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'ผู้ใช้มีหน้าที่รับผิดชอบในการรักษาความปลอดภัยของบัญชีและรหัสผ่านของตนเอง',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '4. การเปลี่ยนแปลงเงื่อนไข',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'เราขอสงวนสิทธิ์ในการเปลี่ยนแปลงเงื่อนไขการใช้งานได้ตลอดเวลา',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FB7B3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'ปิด',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  // แสดง Privacy Policy Modal
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'นโยบายความเป็นส่วนตัว',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF223248),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เราให้ความสำคัญกับความเป็นส่วนตัวของคุณ นโยบายนี้อธิบายว่าเราจัดการข้อมูลส่วนบุคคลของคุณอย่างไร',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '1. การเก็บรวบรวมข้อมูล',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'เราเก็บรวบรวมข้อมูลที่คุณให้ไว้เมื่อลงทะเบียนและใช้บริการของเรา รวมถึงชื่อผู้ใช้ อีเมล และเบอร์โทรศัพท์',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '2. การใช้ข้อมูล',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'ข้อมูลของคุณจะถูกใช้เพื่อให้บริการและปรับปรุงประสบการณ์การใช้งานของคุณ',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '3. การปกป้องข้อมูล',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248)),
                        ),
                        Text(
                          'เราใช้มาตรการรักษาความปลอดภัยเพื่อปกป้องข้อมูลส่วนบุคคลของคุณ',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '4. การแบ่งปันข้อมูล',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF223248),
                          ),
                        ),
                        Text(
                          'เราจะไม่แบ่งปันข้อมูลส่วนบุคคลของคุณกับบุคคลที่สามโดยไม่ได้รับความยินยอมจากคุณ',
                          style: GoogleFonts.beVietnamPro(color: const Color(0xFF223248)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FB7B3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'ปิด',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        );
      },
    );
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
                            'Sign up',
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
                          
                          const SizedBox(height: 16),

                          // Email Input
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Phone Number Input
                          _buildInputField(
                            controller: _phoneNumberController,
                            hintText: 'Phone Numbers',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

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

                          const SizedBox(height: 16),

                          // Confirm Password Input
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm passwords',
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Terms and Conditions Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF008170),
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text(
                                      'I accept ',
                                      style: GoogleFonts.beVietnamPro(
                                        color: const Color(0xFF223248),
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showTermsDialog,
                                      child: Text(
                                        'Terms of Use',
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' and ',
                                      style: GoogleFonts.beVietnamPro(
                                        color: const Color(0xFF223248),
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showPrivacyDialog,
                                      child: Text(
                                        'Privacy Policy',
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Register Button
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
                                      'Register',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Or Divider
                          Text(
                            'or',
                            style: GoogleFonts.beVietnamPro(
                              color: const Color(0xFF223248),
                              fontSize: 16,
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // Google Sign In Button
                          SizedBox(
                            width: 155,
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              icon: Image.asset(
                                'assets/google_icon.png',
                                height: 20,
                                width: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: Colors.blue,
                                  );
                                },
                              ),
                              label: Text(
                                'Google',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
            borderSide: BorderSide(
              color: Color(0xFF4FB7B3),
              width: 2,
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }
}