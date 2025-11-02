// 1. Import packages เข้ามาใช้งาน
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/Navbar.dart' as navbar;
import '../Questionnaire.dart';

// import '../authentication/verifyotp.dart';

// 2. Creating and Exporting a Widget
class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Page', style: GoogleFonts.beVietnamPro()),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'This is a test page.',
                style: GoogleFonts.beVietnamPro(fontSize: 24),
              ),

              const SizedBox(height: 24),

              // Test Button to Home Page
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const navbar.MainScreen(),
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
                    'Test Home Page',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // // Test Button to Verify OTP Page
              // SizedBox(
              //   width: 200,
              //   height: 50,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) =>
              //               VerifyOtpPage(email: rusravee.text),
              //         ),
              //       );
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: const Color(0xFFFFB74D),
              //       foregroundColor: Colors.white,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(25),
              //       ),
              //       elevation: 4,
              //     ),
              //     child: Text(
              //       'Test Verify OTP Page',
              //       style: GoogleFonts.beVietnamPro(
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 24),

              // Test Button to Questionnaire Page
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuestionnairePage(),
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
                    textAlign: TextAlign.center,
                    'Test Questionnaire Page',
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
    );
  }
}
