import 'package:flutter/material.dart';
import 'dart:math' as math;
// ⭐️ 1. Import Service และ Model
import '../services/transaction_service.dart';
import '../services/transaction_models.dart' as models; // 👈 ใช้ Model จากไฟล์กลาง

// ⭐️ 2. ลบ Models ที่ซ้ำซ้อนทิ้ง (Transaction, TransactionType, CategorySummary, MonthlyData)

// ⭐️ 3. แปลงเป็น StatefulWidget (มีอยู่แล้ว)
class SpendingSummaryPage extends StatefulWidget {
  const SpendingSummaryPage({super.key});

  @override
  State<SpendingSummaryPage> createState() => _SpendingSummaryPageState();
}

class _SpendingSummaryPageState extends State<SpendingSummaryPage> {
  // ⭐️ 4. เพิ่ม State สำหรับ Service, Data, Loading
  final TransactionService _transactionService = TransactionService();
  String filterType = 'all';

  bool _isLoading = true;
  String? _errorMessage;

  // State สำหรับเก็บข้อมูลจาก API
  Map<String, dynamic> _summaryData = {
    'totals': {},
    'categorySummary': [],
    'monthlyData': [],
    'recentTransactions': [],
  };

  // ⭐️ 5. เพิ่ม initState และฟังก์ชันดึงข้อมูล
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ⭐️ เรียกฟังก์ชันใหม่จาก Service
      final result = await _transactionService.fetchSpendingSummary();
      if (result['status'] == true && mounted) {
        setState(() {
          _summaryData = result['data']; // 👈 บันทึกข้อมูลที่ได้จาก API
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to load data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ⭐️ 6. แก้ไข Getters ให้อ่านจาก State `_summaryData`
  double get totalIncome =>
      _summaryData['totals']?['totalIncome']?.toDouble() ?? 0.0;
  double get totalExpense =>
      _summaryData['totals']?['totalExpense']?.toDouble() ?? 0.0;
  double get balance => _summaryData['totals']?['balance']?.toDouble() ?? 0.0;

  List<Map<String, dynamic>> get categorySummary {
    List<dynamic> raw = _summaryData['categorySummary'] ?? [];
    double total = totalExpense; // ใช้ totalExpense ที่คำนวณไว้
    if (total == 0) return [];

    List<Map<String, dynamic>> summary = raw.map((item) {
      double amount = item['amount']?.toDouble() ?? 0.0;
      return {
        'category': item['category_name'],
        'amount': amount,
        'percentage': (amount / total) * 100,
        'color': _getColorFromHex(item['color_hex']), // 👈 ใช้สีจาก Backend
      };
    }).toList();

    summary.sort((a, b) => b['amount'].compareTo(a['amount']));
    return summary;
  }

  List<Map<String, dynamic>> get monthlyData {
    List<dynamic> raw = _summaryData['monthlyData'] ?? [];
    return raw.map((item) {
      return {
        'month': _formatMonthYear(item['month']), // '2025-10' -> 'ต.ค. 68'
        'income': item['income']?.toDouble() ?? 0.0,
        'expense': item['expense']?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get recentTransactions =>
      List<Map<String, dynamic>>.from(_summaryData['recentTransactions'] ?? []);

  // ⭐️ 7. (Helper) ฟังก์ชันแปลงค่าต่างๆ (เพิ่มเข้ามา)
  String _formatMonthYear(String yearMonth) {
    try {
      final parts = yearMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      const months = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      return '${months[month - 1]} ${(year + 543 - 2500)}'; // 2500 -> 68
    } catch (e) {
      return yearMonth;
    }
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null) return const Color(0xFF94A3B8); // สี Default (อื่นๆ)
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return const Color(0xFF94A3B8);
    }
  }

  double get maxMonthlyValue {
    double maxVal = 0;
    for (var data in monthlyData) {
      if (data['income'] > maxVal) maxVal = data['income'];
      if (data['expense'] > maxVal) maxVal = data['expense'];
    }
    return maxVal == 0 ? 1 : maxVal; // ป้องกันการหารด้วย 0
  }

  String formatCurrency(double amount) {
    return '฿${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  List<Map<String, dynamic>> get filteredTransactions {
    if (filterType == 'all') return recentTransactions;
    return recentTransactions.where((t) => t['type'] == filterType).toList();
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${months[date.month - 1]} ${(date.year + 543).toString().substring(2)}';
  }

  // ⭐️ 8. (Build) แก้ไข `build` method ให้จัดการ Loading/Error
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (AppBar เหมือนเดิม) ...
        title: const Text(
          'MONEY LAB',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF223248),
          ),
        ),
        backgroundColor: const Color(0xFF4FB7B3),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // ⭐️ (Build) เพิ่ม Logic การแสดงผล
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FB7B3)),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'เกิดข้อผิดพลาด: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchData,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              // ⭐️ (Build) ถ้าโหลดสำเร็จ แสดงเนื้อหา
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (Page Title) ...
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending Summary',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF223248),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ภาพรวมรายรับรายจ่ายของคุณ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards (ใช้ Getters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildSummaryCard(
                          title: 'รายรับทั้งหมด',
                          amount: totalIncome, // 👈 Getter
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4ade80), Color(0xFF22c55e)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.arrow_upward,
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryCard(
                          title: 'รายจ่ายทั้งหมด',
                          amount: totalExpense, // 👈 Getter
                          gradient: const LinearGradient(
                            colors: [Color(0xFFf87171), Color(0xFFdc2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.arrow_downward,
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryCard(
                          title: 'ยอดคงเหลือ',
                          amount: balance, // 👈 Getter
                          gradient: balance >= 0
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF4FB7B3),
                                    Color(0xFF3a9793),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFfbbf24),
                                    Color(0xFFf59e0b),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          icon: Icons.account_balance_wallet,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pie Chart Section (ใช้ Getters)
                  _buildPieChartSection(),

                  const SizedBox(height: 24),

                  // Bar Chart Section (ใช้ Getters)
                  _buildBarChartSection(),

                  const SizedBox(height: 24),

                  // Transaction List (ใช้ Getters)
                  _buildTransactionList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ⭐️ 9. (Build) แก้ไข Helper Widgets ให้อ่านข้อมูลจาก State
  // (ฟังก์ชัน _buildSummaryCard, _buildLegendItem ไม่ต้องแก้)

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Gradient gradient,
    required IconData icon,
  }) {
    // (โค้ด UI เหมือนเดิม)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7DCDE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Header เหมือนเดิม) ...
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สัดส่วนรายจ่าย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF223248),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4FB7B3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'ดูเพิ่ม',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pie Chart
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              // ⭐️ (Build) ส่งข้อมูลจริง (ที่เป็น Map) เข้าไป
              child: CustomPaint(
                painter: PieChartPainter(categorySummary: categorySummary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend (ใช้ .map จาก getter)
          ...categorySummary.map(
            (cat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: cat['color'],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat['category'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF223248),
                      ),
                    ),
                  ),
                  Text(
                    '${(cat['percentage'] as double).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCurrency(cat['amount']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223248),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7DCDE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Header, Legend เหมือนเดิม) ...
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สรุปรายเดือน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF223248),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4FB7B3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'ดูเพิ่ม',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('รายรับ', const Color(0xFFFF6B9D)),
              const SizedBox(width: 24),
              _buildLegendItem('รายจ่าย', const Color(0xFF4FB7B3)),
            ],
          ),
          const SizedBox(height: 16),
          // Bar Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              // ⭐️ (Build) ใช้ .map จาก getter
              children: monthlyData.map((data) {
                double incomeHeight = (data['income'] / maxMonthlyValue) * 150;
                double expenseHeight =
                    (data['expense'] / maxMonthlyValue) * 150;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: incomeHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 20,
                          height: expenseHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FB7B3),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['month'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF223248),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    // (โค้ด UI เหมือนเดิม)
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF223248)),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7DCDE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Header, Filter Buttons เหมือนเดิม) ...
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายการทั้งหมด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF223248),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4FB7B3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'ดูเพิ่ม',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFilterButton('ทั้งหมด', 'all'),
              const SizedBox(width: 8),
              _buildFilterButton('รายรับ', 'income'),
              const SizedBox(width: 8),
              _buildFilterButton('รายจ่าย', 'expense'),
            ],
          ),
          const SizedBox(height: 16),
          // Transaction Table (ใช้ Getter)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              // ⭐️ (Build) ใช้ .map จาก getter
              children: filteredTransactions.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'ไม่มีรายการ',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ]
                  : filteredTransactions
                        .asMap()
                        .entries
                        .map(
                          (entry) =>
                              _buildTransactionRow(entry.value, entry.key),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    // (โค้ด UI เหมือนเดิม)
    bool isSelected = filterType == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            filterType = value;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF4FB7B3) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF223248),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> transaction, int index) {
    // ⭐️ (Build) แก้ไขให้ดึงข้อมูลจาก Map (ซึ่งตอนนี้เป็น Type ที่ถูกต้องจาก Backend)
    final type = transaction['type'] == 'income'
        ? models
              .TransactionType
              .income // 👈 ใช้นิยามจาก transaction_models.dart
        : models.TransactionType.expense;
    final amount = transaction['amount']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(
          top: index == 0
              ? BorderSide.none
              : BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(transaction['transaction_date']),
              style: const TextStyle(fontSize: 11, color: Color(0xFF223248)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: type == models.TransactionType.income
                    ? Colors.green[100]
                    : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction['category_name'] ?? 'ไม่มีหมวดหมู่',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: type == models.TransactionType.income
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              transaction['receiver_name'] ??
                  transaction['sender_name'] ??
                  'N/A', // ⭐️ ใช้ receiver_name
              style: const TextStyle(fontSize: 11, color: Color(0xFF223248)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${type == models.TransactionType.income ? '+' : '-'}${formatCurrency(amount)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: type == models.TransactionType.income
                    ? Colors.green[600]
                    : Colors.red[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ⭐️ (Build) แก้ไข Painter ให้รับข้อมูลใหม่
class PieChartPainter extends CustomPainter {
  // ⭐️ แก้ไข Type
  final List<Map<String, dynamic>> categorySummary;

  PieChartPainter({required this.categorySummary});

  @override
  void paint(Canvas canvas, Size size) {
    double total = categorySummary.fold(0, (sum, cat) => sum + cat['amount']);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    for (var category in categorySummary) {
      double sweepAngle = (category['amount'] / total) * 2 * math.pi;

      Paint paint = Paint()
        ..color =
            category['color'] // ⭐️ ใช้สีจาก Map
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - 10,
        ),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - 10,
        ),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// ⭐️ 10. (Build) เราไม่ต้องการ Enum นี้แล้ว เพราะ `transaction_models.dart` มีให้
// enum TransactionType { income, expense }
