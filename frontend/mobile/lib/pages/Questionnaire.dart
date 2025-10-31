import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'Navbar.dart' as navbar;
import 'FinancialDataQA.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  // เก็บคำตอบของแต่ละคำถาม (10 คำถาม)
  final Map<String, List<String>> answers = {
    'q1': [],
    'q2': [],
    'q3': [],
    'q4': [],
    'q5': [],
    'q6': [],
    'q7': [],
    'q8': [],
    'q9': [],
    'q10': [],
  };

  // คำถามทั้งหมด
  final List<Map<String, dynamic>> questions = [
    {
      'id': 'q1',
      'title': 'ไก่กับไข่อะไรเกิดก่อน',
      'options': ['ไม่รู้', 'ไม่แน่ใจ', 'ไม่ตอบ', 'ไก่']
    },
    {
      'id': 'q2',
      'title': 'คำถามที่2',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q3',
      'title': 'คำถามที่3',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q4',
      'title': 'คำถามที่4',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q5',
      'title': 'คำถามที่5',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q6',
      'title': 'คำถามที่6',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q7',
      'title': 'คำถามที่7',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q8',
      'title': 'คำถามที่8',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q9',
      'title': 'คำถามที่9',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      'id': 'q10',
      'title': 'คำถามที่10',
      'options': ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
  ];

  // จัดการการเปลี่ยนแปลง checkbox
  void handleCheckboxChange(String questionId, String option) {
    setState(() {
      final currentAnswers = answers[questionId]!;
      if (currentAnswers.contains(option)) {
        // ถ้าเลือกแล้ว ให้ลบออก
        currentAnswers.remove(option);
      } else {
        // ถ้ายังไม่เลือก ให้เพิ่มเข้าไป
        currentAnswers.add(option);
      }
    });
  }

  // ส่งแบบสอบถามไปยัง API
  Future<void> handleSubmit() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/questionnaire'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'answers': answers}),
      );

      final result = jsonDecode(response.body);

      if (!mounted) return;

      // แสดงข้อความจาก API
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('แจ้งเตือน'),
          content: Text(result['message'] ?? 'บันทึกข้อมูลเรียบร้อย'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ถ้าส่งแบบสอบถามสำเร็จ จะ redirect ไปหน้าแรก
                if (result['status'] == true) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const navbar.MainScreen(),
                    ),
                  );
                }
              },
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      // แสดงข้อความเมื่อส่งไม่สำเร็จ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: const Text('ไม่สามารถส่งแบบสอบถามได้ กรุณาลองใหม่อีกครั้ง'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }

  // ทดสอบการเปลี่ยนหน้า
  void handleNextPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FinancialDataQAPage(),
      ),
    );
  }

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
        child: Column(
          children: [
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'แบบสอบถามเรื่องการใช้งาน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF223248),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Form Container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8D4D6),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Questions
                        ...questions.map((question) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question Title
                                Text(
                                  question['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF223248),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Options
                                ...question['options'].map<Widget>((option) {
                                  return InkWell(
                                    onTap: () => handleCheckboxChange(
                                      question['id'],
                                      option,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: answers[question['id']]!
                                                .contains(option),
                                            onChanged: (bool? value) {
                                              handleCheckboxChange(
                                                question['id'],
                                                option,
                                              );
                                            },
                                            activeColor: const Color(0xFF4FB7B3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF223248),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: 155,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FB7B3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Test Button to Test Home Page
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FinancialDataQAPage(),
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

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
