import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
  // 1. ⭐️ (แก้ไข) ลบ _walletService และ _walletBalance ออก
  final TransactionService _transactionService = TransactionService();
  final DailyBudgetService _dailyBudgetService = DailyBudgetService();
  models.DailySummary? _dailySummary;
  bool _isLoading = true;
  String? _errorMessage;

  // (State สำหรับ Animation ... เหมือนเดิม)
  bool _isFabOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 2. ⭐️ (แก้ไข) ฟังก์ชันสำหรับดึงข้อมูลจาก API
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // (A) อ่าน WalletService จาก Provider
      final walletService = context.read<WalletService>();

      // (B) เรียก API ทั้งสองพร้อมกัน
      //final results = await Future.wait([
     //   _transactionService.fetchDailySummary(DateTime.now()),
     //   walletService.fetchWallet(), // (ตัวนี้จะอัปเดต Provider แต่คืนค่า null)
      //]);
      await walletService.fetchWallet();
      // (C) ดึงผลลัพธ์เฉพาะตัวที่ 0
      final summary = await _transactionService.fetchDailySummary(DateTime.now());

      if (mounted) {
        setState(() {
          _dailySummary = summary;
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

  // ... (ฟังก์ชัน _refreshData, _toggleFab, _navigateToAddTransaction, _showAddExpenseOptions ... เหมือนเดิม) ...
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

  Future<void> _navigateToAddTransaction(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(transactionType: type),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกรายการสำเร็จ'), backgroundColor: Colors.green));
    }
  }

  Future<void> _showAddExpenseOptions() async {
    _toggleFab();

    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseOptionSheet(),
    );

    if (result == 'manual') {
      _navigateToAddTransaction('expense');
    } else if (result == 'upload') {
      final ocrResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OcrConfirmationPage(),
          fullscreenDialog: true,
        ),
      );
      if (ocrResult == true) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกรายการจากสลิปสำเร็จ'), backgroundColor: Colors.green));
      }
    }
  }


  // 3. ⭐️ (แก้ไข) ฟังก์ชันสำหรับแสดง Dialog ยืนยันการรีเซ็ต Wallet
  Future<void> _showResetWalletDialog() async {
    // (A) อ่าน Service จาก Provider
    final walletService = context.read<WalletService>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // ... (UI ของ Dialog ... เหมือนเดิม)
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
                  // (B) เรียกใช้ Service จาก Provider
                  final message = await walletService.resetWallet();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message), backgroundColor: Colors.green),
                  );
                  _refreshData(); // โหลดข้อมูลใหม่
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

  // ... (ฟังก์ชัน _showSetBudgetDialog ... เหมือนเดิม) ...
  void _showSetBudgetDialog() {
    final TextEditingController budgetController = TextEditingController();
    budgetController.text = (_dailySummary?.dailyGoal ?? 0).toInt().toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ตั้งงบประมาณรายวัน', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: budgetController,
            // ... (UI TextField ... เหมือนเดิม)
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
                    await _dailyBudgetService.setDailyBudget(amount: amount, date: DateTime.now()); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ตั้งงบประมาณสำเร็จ'), backgroundColor: Colors.green),
                    );
                    _refreshData(); // โหลดข้อมูลใหม่
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
  // 4. ⭐️ อ่าน Wallet Balance จาก Provider
  final walletBalance = context.watch<WalletService>().wallet?.balance ?? 0;

  // 5. ⭐️ ดึงข้อมูลจาก State
  final double dailyGoal = _dailySummary?.dailyGoal ?? 0;
  final double currentSpending = _dailySummary?.currentSpending ?? 0;
  final List<models.Transaction> dailyTransactions = _dailySummary?.transactions ?? [];
  final double progress = (dailyGoal > 0) ? (currentSpending / dailyGoal) : 0;

  return Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        // 🌈 พื้นหลัง
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

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  // 💰 สรุปรายวัน
                                  DailySummaryCard(
                                    dailyGoal: dailyGoal,
                                    currentSpending: currentSpending,
                                    walletBalance: walletBalance,
                                    progress: progress,
                                    onEditBudget: _showSetBudgetDialog,
                                    onResetWallet: _showResetWalletDialog,
                                  ),
                                  const SizedBox(height: 20),
                                  if (dailyGoal > 0)
                                    AllocationRecommendationCard(dailyBudget: dailyGoal),
                                  const SizedBox(height: 20),
                                  DailyTransactionList(transactions: dailyTransactions),
                                  const SizedBox(height: 120), // เผื่อพื้นที่ให้ FAB
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),

    // 🚀 Floating Action Button (FAB)
    floatingActionButton: Stack(
      alignment: Alignment.bottomRight,
      children: [
        // ปุ่มย่อย — เพิ่มรายรับ
        if (_isFabOpen)
          ScaleTransition(
            scale: _animation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 140.0),
              child: FloatingActionButton.extended(
                heroTag: 'incomeFab',
                backgroundColor: Colors.green,
                onPressed: () => _navigateToAddTransaction('income'),
                label: const Text('รายรับ'),
                icon: const Icon(Icons.add_card),
              ),
            ),
          ),

        // ปุ่มย่อย — เพิ่มรายจ่าย
        if (_isFabOpen)
          ScaleTransition(
            scale: _animation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 75.0),
              child: FloatingActionButton.extended(
                heroTag: 'expenseFab',
                backgroundColor: Colors.redAccent,
                onPressed: _showAddExpenseOptions,
                label: const Text('รายจ่าย'),
                icon: const Icon(Icons.money_off),
              ),
            ),
          ),

        // ปุ่มหลัก (เปิด/ปิด FAB)
        FloatingActionButton(
          heroTag: 'mainFab',
          backgroundColor: const Color(0xFF14B8A6),
          onPressed: _toggleFab,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animationController,
          ),
        ),
      ],
    ),
  );
}
}