import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'components/Navbar.dart' as navbar;
import 'FinancialDataQA.dart';
import '../services/survey_service.dart'; // 👈 1. Import service ใหม่

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  // 👈 2. [REFACTORED] State สำหรับเก็บข้อมูลที่ดึงมาจาก API
  final SurveyService _surveyService = SurveyService();
  List<dynamic> _questions = [];
  Map<int, List<String>> _answers = {}; // ใช้ question_id (int) เป็น key
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _surveyService.fetchSurveyQuestions();
      if (result['status'] == true && mounted) {
        setState(() {
          _questions = result['data'];
          // สร้างโครง answers จากคำถามที่ได้มา
          _answers = {for (var q in _questions) q['question_id']: []};
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to load questions');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // จัดการการเปลี่ยนแปลง checkbox
  void handleCheckboxChange(int questionId, String optionValue, bool isSingleChoice) {
    setState(() {
      final currentAnswers = _answers[questionId]!;
      if (isSingleChoice) {
        currentAnswers.clear();
        currentAnswers.add(optionValue);
      } else {
        if (currentAnswers.contains(optionValue)) {
        // ถ้าเลือกแล้ว ให้ลบออก
        currentAnswers.remove(optionValue);
      } else {
        // ถ้ายังไม่เลือก ให้เพิ่มเข้าไป
        currentAnswers.add(optionValue);
      }
      }
    });
  }

  // ส่งแบบสอบถามไปยัง API
  Future<void> handleSubmit() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/questionnaire'),
        headers: {'Content-Type': 'application/json'}, // TODO: เพิ่ม Token
        body: jsonEncode({'answers': _answers}),
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
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('เกิดข้อผิดพลาด: $_errorMessage', style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(onPressed: _fetchQuestions, child: const Text('ลองอีกครั้ง'))
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
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
                        ..._questions.map((question) {
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
                                  question['question_text'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF223248),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Options
                                ...question['options'].map<Widget>((option) {
                                  final questionId = question['question_id'];
                                  final isSingleChoice = question['question_type'] == 'single_choice';
                                  return InkWell(
                                    onTap: () => handleCheckboxChange(
                                      questionId,
                                      option['value'],
                                      isSingleChoice,
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
                                          isSingleChoice
                                              ? Radio<String>(
                                                  value: option['value'],
                                                  groupValue: _answers[questionId]!.isNotEmpty ? _answers[questionId]!.first : null,
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      handleCheckboxChange(questionId, value, true);
                                                    }
                                                  },
                                                  activeColor: const Color(0xFF4FB7B3),
                                                )
                                              : Checkbox(
                                                  value: _answers[questionId]!.contains(option['value']),
                                                  onChanged: (bool? value) {
                                                    handleCheckboxChange(questionId, option['value'], false);
                                                  },
                                                  activeColor: const Color(0xFF4FB7B3),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option['label'],
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

                        // Test Button to Test FinancialDataQA Page
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
                              'Test FinancialDataQA Page',
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
      ),
    );
  }
}
