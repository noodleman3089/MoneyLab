import 'package:flutter/foundation.dart';

class AppConfig {
  /// ฐาน URL สำหรับเรียก API
  ///
  /// ใช้ [kIsWeb] เพื่อตรวจสอบว่ากำลังรันบน Web หรือไม่
  /// - ถ้าเป็น Web: ใช้ 'http://localhost:5000'
  /// - ถ้าเป็น Mobile (Android/iOS): ใช้ 'http://10.0.2.2:5000' สำหรับ Android Emulator
  ///   (สำหรับ iOS Simulator จะใช้ localhost ได้เลย)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000'; // สำหรับ Web
    } else {
      // สำหรับ Mobile (โดยเฉพาะ Android Emulator)
      return 'http://10.0.2.2:5000';
    }
  }
}