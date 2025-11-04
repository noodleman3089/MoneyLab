import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/authe_service.dart';
import 'pages/DailyManagement.dart';
import 'main.dart';
import 'services/wallet_service.dart';
import 'pages/components/Navbar.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // เราจะเก็บผลลัพธ์การตรวจสอบไว้ใน state
  late Future<bool> _loginCheck;

  @override
  void initState() {
    super.initState();
    _loginCheck = _checkLoginAndLoadData(); // 👈 2. เปลี่ยนชื่อฟังก์ชัน
  }

  Future<bool> _checkLoginAndLoadData() async {
    final authService = context.read<AutheService>();
    final walletService = context.read<WalletService>();

    // 4. ตรวจสอบ Token
    final bool hasToken = await authService.isLoggedIn();

    // 5. ถ้าล็อกอินผ่าน ให้โหลด Wallet ทันที
    if (!hasToken) {
      return false; // ไม่มี Token เลย = ไปหน้า Login
    }

    // 2. ถ้ามี Token, ลองโหลดข้อมูล Wallet (ซึ่งเป็นการ validate token ไปในตัว)
    // ⭐️ เพิ่มการ Retry เข้าไป
    int retryCount = 0;
    while (retryCount < 3) { // พยายาม 3 ครั้ง
      try {
        await walletService.fetchWallet();
        return true; // โหลดสำเร็จ! ไปหน้า MainScreen
      } catch (e) {
        debugPrint('Failed to load wallet (Attempt ${retryCount + 1}): $e');
        
        retryCount++;
        if (retryCount < 3) {
          await Future.delayed(const Duration(seconds: 2)); // รอ 2 วินาที
        }
      }
    }

    // 3. ถ้าพยายาม 3 ครั้งแล้วยังล่ม
    debugPrint('Failed to load wallet after 3 attempts.');
    return false; // กลับไปหน้า Login
  }

  @override
  Widget build(BuildContext context) {
    // 3. ใช้ FutureBuilder เพื่อรอผลลัพธ์
    return FutureBuilder<bool>(
      future: _loginCheck,
      builder: (context, snapshot) {
        
        // --- A. กรณีกำลังโหลด (รอผล) ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          // แสดงหน้า Loading
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --- B. กรณีล็อกอินไม่ผ่าน (หรือ Error) ---
        if (snapshot.hasError || snapshot.data == false) {
          // ส่งไปหน้า Welcome/Login (หน้า MyHomePage ใน main.dart)
          return const MyHomePage(title: 'MoneyLab');
        }

        // --- C. กรณีล็อกอินผ่าน (snapshot.data == true) ---
        // (คุณสามารถเปลี่ยน GoalPage เป็น Dashboard หรือหน้าหลักอื่นๆ ได้)
        return const MainScreen();
      },
    );
  }
}