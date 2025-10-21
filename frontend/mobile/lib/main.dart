import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/forgetpassword.dart';
import 'pages/restpassword.dart';
import 'pages/Home Page.dart' as homepage;
import 'pages/Additional.dart';
import 'pages/UserProfilePage.dart' as userprofile;

void main() {
  runApp(const MyApp());
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
        '/': (context) => const MyHomePage(title: 'MoneyLab'),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),

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
                  // Logo or App Title
                  const Text(
                    'MoneyLab',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223248),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to MoneyLab',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF223248),
                    ),
                  ),
                  const SizedBox(height: 80),

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
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                        foregroundColor: const Color(0xFF4FB7B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(
                            color: Color(0xFF4FB7B3),
                            width: 2,
                          ),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            builder: (context) => const homepage.MainScreen(),
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
                      child: const Text(
                        'Test Home Page',
                        style: TextStyle(
                          fontSize: 18,
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
    );
  }
}