import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // 👈 Import
import 'package:mockito/mockito.dart'; // 👈 Import
import 'package:http/http.dart' as http; // 👈 Import
import 'package:mobile/services/goal_service.dart';
import 'package:mobile/config/api_config.dart';

// 1. สั่งให้ Mockito สร้าง MockClient
@GenerateMocks([http.Client])
import 'goal_service_test.mocks.dart'; // 👈 นี่คือไฟล์ที่จะถูกสร้าง

void main() {
  late GoalService goalService;
  late MockClient mockClient;

  // (setup)
  setUp(() {
    mockClient = MockClient(); // สร้าง Mock
    // 2. ฉีด MockClient เข้าไปใน Service
    goalService = GoalService(client: mockClient); 
  });

  group('GoalService Helper Functions', () {
    test('unitLabel should return correct Thai labels', () {
      expect(goalService.unitLabel('day'), 'วัน');
      expect(goalService.unitLabel('week'), 'สัปดาห์');
      expect(goalService.unitLabel('month'), 'เดือน');
      expect(goalService.unitLabel('year'), 'ปี');
      expect(goalService.unitLabel('invalid'), 'เดือน');
    });

    test('calculateProgress should return correct percentage', () {
      expect(goalService.calculateProgress(50, 100), 50.0);
      expect(goalService.calculateProgress(25, 50), 50.0);
      expect(goalService.calculateProgress(0, 100), 0.0);
    });

    // 3. (ตัวอย่าง) เทสฟังก์ชันที่เรียก API
    test('fetchGoals returns goals if http call completes successfully', () async {
      // (Arrange) "สตั๊ฟ" ข้อมูลจำลอง
      // บอกว่าถ้า mockClient.get ถูกเรียกด้วย URL นี้...
      when(mockClient.get(Uri.parse(ApiConfig.savingGoalsUrl)))
          .thenAnswer((_) async => // ...ให้ตอบกลับด้วย JSON นี้
              http.Response(
                '[{"id":"1", "name":"Test Goal", "emoji":"💰", "saved":100, "target":1000, "duration":10, "unit":"day", "plan":"ประจำวัน", "investMode":"none", "symbols":"", "progress":10, "perPeriod":100, "perDay":100}]', 
                200)
      );

      // (Act) เรียกฟังก์ชัน
      await goalService.fetchGoals();

      // (Assert) ตรวจสอบว่า goals มีข้อมูล
      expect(goalService.goals.isNotEmpty, isTrue);
      expect(goalService.goals[0].name, 'Test Goal');
    });
  });
}