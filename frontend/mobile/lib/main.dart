import 'package:flutter/material.dart';
import 'package:mobile/pages/Questionnaire.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/goal_service.dart';
import 'package:mobile/pages/goal_page.dart';
import 'package:provider/provider.dart';

import 'pages/authentication/login.dart';
import 'pages/authentication/register.dart';
import 'pages/forgetpassword.dart';
import 'pages/restpassword.dart';
import 'pages/Test/TestPage.dart';
import 'package:mobile/services/wallet_service.dart';
import 'services/authe_service.dart';
import 'auth_wrapper.dart';

// import 'pages/Additional.dart';
// import 'pages/UserProfilePage.dart' as userprofile;

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GoalService()),
        ChangeNotifierProvider(create: (context) => WalletService()),
        Provider(create: (context) => AutheService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14B8A6)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgetpassword': (context) => const ForgotPasswordScreen(),
        '/questionnaire': (context) => const QuestionnairePage(),
      },
      // ใช้ onGenerateRoute เพื่อจัดการ route ที่ต้องการ arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/restpassword') {
          // ดึง arguments ที่ส่งมา
          final args = settings.arguments as Map<String, dynamic>?;
          
          // ตรวจสอบว่ามี token หรือไม่
          if (args != null && args['token'] != null) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(token: args['token']),
            );
          }
          
          // ถ้าไม่มี token ให้กลับไปหน้า login
          return MaterialPageRoute(
            builder: (context) => const LoginPage(),
          );
        }
        return null;
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14B8A6), Color(0xFFC7DCDE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Text(
                    'MoneyLab',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF223248),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to MoneyLab',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      color: const Color(0xFF223248),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Button
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FB7B3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF008170),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(
                            color: Color(0xFF008170),
                            width: 2,
                          ),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF008170),
                        ),
                      ),
                    ),
                  ),

                 const SizedBox(height: 24),

                  // Test Button to Test Page
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TestPage(),
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
                        'Test Page',
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
      ),
    );
  }
}