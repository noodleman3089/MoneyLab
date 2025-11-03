// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart'; // 👈 import main.dart ของคุณ
import 'package:provider/provider.dart'; // 👈 import provider
import 'package:mobile/services/goal_service.dart'; // 👈 import service

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // 1. สร้าง Service (จำเป็นเพราะ main.dart เรียกใช้)
    final goalService = GoalService(); 

    // 2. Build แอปของคุณโดยหุ้มด้วย Provider ที่จำเป็น
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => goalService,
        child: const MyApp(),
      ),
    );

    // 3. ตรวจสอบว่ามีข้อความ "MoneyLab"
    // (ใช้ findsWidgets เพราะมันอาจมีหลายที่)
    expect(find.text('MoneyLab'), findsWidgets);

    // 4. ตรวจสอบว่ามีปุ่ม "Login" และ "Sign Up"
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // 5. ตรวจสอบว่า *ไม่มี* ข้อความของแอปนับเลข
    expect(find.text('0'), findsNothing);
  });
}