import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 👈 1. Import service และ models ที่สร้างขึ้นใหม่
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../services/daily_budget_service.dart'; // 👈 Import service ใหม่
import '../services/transaction_models.dart' as models;
import 'widgets/daily_summary_card.dart'; // 👈 Import Widget ใหม่
import 'widgets/daily_transaction_list.dart'; // 👈 Import Widget ใหม่
import 'widgets/allocation_recommendation_card.dart'; // 👈 Import Widget ใหม่
import 'widgets/add_expense_option_sheet.dart'; // 👈 Import Widget ใหม่
import 'add_transaction_page.dart'; // 👈 Import หน้าใหม่
import 'ocr_confirmation_page.dart'; // 👈 Import หน้า OCR

// DailyManagementPage Widget (renamed from GoalPage)
class DailyManagementPage extends StatefulWidget {
  const DailyManagementPage({super.key});

  @override
  State<DailyManagementPage> createState() => _DailyManagementPageState(); // แก้ไขชื่อ State
}

class _DailyManagementPageState extends State<DailyManagementPage>
    with SingleTickerProviderStateMixin {
  // 👈 2. สร้าง State สำหรับจัดการข้อมูลและสถานะการโหลด
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService(); // 👈 สร้าง instance ของ WalletService
  final DailyBudgetService _dailyBudgetService = DailyBudgetService(); // 👈 สร้าง instance ของ DailyBudgetService
  models.DailySummary? _dailySummary;
  double? _walletBalance; // 👈 State สำหรับเก็บยอดเงินใน Wallet
  bool _isLoading = true;
  String? _errorMessage;

  // State สำหรับ UI (Animation)
  bool _isFabOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 👈 3. เรียกฟังก์ชันเพื่อดึงข้อมูลจาก API เมื่อหน้าถูกโหลด
    _fetchData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 👈 4. ฟังก์ชันสำหรับดึงข้อมูลจาก API
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ใช้ Future.wait เพื่อดึงข้อมูลสรุป และเรียก fetchWallet แยกกัน
      final results = await Future.wait([
        _transactionService.fetchDailySummary(DateTime.now()), // ดึงข้อมูลสรุปรายวัน
      ]);

      final summary = results[0] as models.DailySummary; // ผลลัพธ์ตัวแรกคือ summary
      await _walletService.fetchWallet(); // เรียกให้ service ไปดึงข้อมูล wallet

      if (mounted) {
        setState(() {
          _dailySummary = summary;
          _walletBalance = _walletService.wallet?.balance; // 👈 ดึงค่า balance จาก service โดยตรง
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // 👈 5. ฟังก์ชันสำหรับ Refresh ข้อมูล (ใช้หลังเพิ่มรายการสำเร็จ)
  void _refreshData() {
    _fetchData();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // 👈 ฟังก์ชันสำหรับนำทางไปยังหน้าเพิ่มรายการ
  Future<void> _navigateToAddTransaction(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(transactionType: type),
        fullscreenDialog: true, // ทำให้หน้าจอลอยขึ้นมาจากข้างล่าง
      ),
    );

    // ถ้ามีการบันทึกสำเร็จ (pop กลับมาพร้อมค่า true) ให้โหลดข้อมูลใหม่
    if (result == true) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกรายการสำเร็จ'), backgroundColor: Colors.green));
    }
  }

  // 👈 ฟังก์ชันสำหรับแสดงตัวเลือกการเพิ่มรายจ่าย
  Future<void> _showAddExpenseOptions() async {
    // ปิด FAB menu ก่อน
    _toggleFab();

    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseOptionSheet(),
    );

    // จัดการผลลัพธ์ที่ได้จากการเลือกใน Bottom Sheet
    if (result == 'manual') {
      // ถ้าเลือก 'กรอกเอง' ให้ไปหน้า AddTransactionPage
      _navigateToAddTransaction('expense');
    } else if (result == 'upload') {
      // 👈 ถ้าเลือก 'อัปโหลด' ให้ไปหน้า OcrConfirmationPage
      final ocrResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OcrConfirmationPage(),
          fullscreenDialog: true,
        ),
      );
      // 👈 ถ้ามีการบันทึกสำเร็จ (pop กลับมาพร้อมค่า true) ให้โหลดข้อมูลใหม่
      if (ocrResult == true) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกรายการจากสลิปสำเร็จ'), backgroundColor: Colors.green));
      }
    }
  }

  // 👈 ฟังก์ชันสำหรับแสดง Dialog ยืนยันการรีเซ็ต Wallet
  Future<void> _showResetWalletDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ยืนยันการรีเซ็ต', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
          content: Text('คุณต้องการรีเซ็ตยอดเงินใน Wallet เป็น 0 หรือไม่? การดำเนินการนี้จะทำให้การคำนวณยอดคงเหลือเริ่มนับใหม่ทั้งหมด (ธุรกรรมเก่าจะไม่ถูกลบ)', style: GoogleFonts.beVietnamPro()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context); // ปิด Dialog ก่อน
                try {
                  final message = await _walletService.resetWallet();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message), backgroundColor: Colors.green),
                  );
                  _refreshData(); // โหลดข้อมูลใหม่เพื่ออัปเดตหน้าจอ
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('ยืนยันการรีเซ็ต', style: GoogleFonts.beVietnamPro(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 👈 ฟังก์ชันสำหรับแสดง Dialog เพื่อตั้งงบประมาณใหม่
  void _showSetBudgetDialog() {
    final TextEditingController budgetController = TextEditingController();
    // แสดงค่าปัจจุบันในช่องกรอก
    budgetController.text = (_dailySummary?.dailyGoal ?? 0).toInt().toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ตั้งงบประมาณรายวัน', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.beVietnamPro(),
            decoration: InputDecoration(
              labelText: 'งบประมาณ (บาท)',
              labelStyle: GoogleFonts.beVietnamPro(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final amount = double.tryParse(budgetController.text);
                if (amount != null && amount >= 0) {
                  Navigator.pop(context); // ปิด Dialog ก่อน
                  try {
                    await _dailyBudgetService.setDailyBudget(amount: amount, date: DateTime.now()); // 👈 เปลี่ยนไปใช้ Service ใหม่
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ตั้งงบประมาณสำเร็จ'), backgroundColor: Colors.green),
                    );
                    _refreshData(); // โหลดข้อมูลใหม่เพื่ออัปเดตหน้าจอ
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text('บันทึก', style: GoogleFonts.beVietnamPro(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 👈 6. ใช้ข้อมูลจาก State ที่ดึงมาจาก API
    final double dailyGoal = _dailySummary?.dailyGoal ?? 0;
    final double currentSpending = _dailySummary?.currentSpending ?? 0;
    final List<models.Transaction> dailyTransactions = _dailySummary?.transactions ?? [];
    final double walletBalance = _walletBalance ?? 0; // 👈 ดึงค่า wallet balance มาใช้
    final double progress = (dailyGoal > 0) ? (currentSpending / dailyGoal) : 0;

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14B8A6), Color(0xFFC7DCDE)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'จัดการรายวัน',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF223248),
                        ),
                      ),
                    ),
                  ),
                  // Body Content
                  Expanded( // 👈 7. จัดการ UI ตามสถานะการโหลดและ Error
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'เกิดข้อผิดพลาด: $_errorMessage',
                                        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _fetchData,
                                        child: const Text('ลองอีกครั้ง'),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                          const SizedBox(height: 8),
                          // 👈 ใช้ Widget ที่แยกออกมา
                          DailySummaryCard(
                            dailyGoal: dailyGoal,
                            currentSpending: currentSpending,
                            walletBalance: walletBalance,
                            progress: progress,
                            onEditBudget: _showSetBudgetDialog,
                            onResetWallet: _showResetWalletDialog, // 👈 ส่งฟังก์ชันไปที่ Card
                          ),
                          const SizedBox(height: 20),
                          // 👈 แสดงการ์ดแนะนำการจัดสรรเงิน
                          if (dailyGoal > 0) // แสดงก็ต่อเมื่อมีการตั้งงบแล้ว
                            AllocationRecommendationCard(dailyBudget: dailyGoal),
                          const SizedBox(height: 20),
                          // 👈 ใช้ Widget ที่แยกออกมา
                          DailyTransactionList(transactions: dailyTransactions),
                          const SizedBox(height: 100), // Space for FAB
                        ],
                      ), // ปิด SingleChildScrollView
                    ),
                  ),
                ],
              ),
            ),
          ),
          // FAB Backdrop
          if (_isFabOpen)
            GestureDetector(
              onTap: _toggleFab,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          // Speed Dial FAB
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // รายรับ Button
                ScaleTransition(
                  scale: _animation,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'รายรับ',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          heroTag: 'income',
                          mini: true,
                          backgroundColor: Colors.green,
                          onPressed: () {
                            _navigateToAddTransaction('income');
                          },
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // รายจ่าย Button
                ScaleTransition(
                  scale: _animation,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'รายจ่าย',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF223248),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          heroTag: 'expense',
                          mini: true,
                          backgroundColor: Colors.red,
                          onPressed: () {
                            _showAddExpenseOptions();
                          },
                          child: const Icon(Icons.remove, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main FAB
                FloatingActionButton(
                  heroTag: 'main',
                  backgroundColor: const Color(0xFF14B8A6),
                  onPressed: _toggleFab,
                  child: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _animation,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
