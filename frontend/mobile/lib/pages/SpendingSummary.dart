import 'package:flutter/material.dart';
import 'dart:math' as math;

// Models
class Transaction {
  final String id;
  final String date;
  final String category;
  final String description;
  final double amount;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.type,
  });
}

enum TransactionType { income, expense }

class CategorySummary {
  final String category;
  final double amount;
  final double percentage;
  final Color color;

  CategorySummary({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class MonthlyData {
  final String month;
  final double income;
  final double expense;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class SpendingSummaryPage extends StatefulWidget {
  const SpendingSummaryPage({super.key});

  @override
  State<SpendingSummaryPage> createState() => _SpendingSummaryPageState();
}

class _SpendingSummaryPageState extends State<SpendingSummaryPage> {
  String filterType = 'all'; // all, income, expense

  // Mock data - แทนที่ด้วย API calls
  final List<Transaction> transactions = [
    Transaction(
      id: '1',
      date: '2025-10-18',
      category: 'อาหาร',
      description: 'ซื้ออาหารกลางวัน',
      amount: 250,
      type: TransactionType.expense,
    ),
    Transaction(
      id: '2',
      date: '2025-10-17',
      category: 'ค่าโทร',
      description: 'โทรศัพท์',
      amount: 500,
      type: TransactionType.expense,
    ),
    Transaction(
      id: '3',
      date: '2025-10-16',
      category: 'บันเทิง',
      description: 'ดูหนัง',
      amount: 300,
      type: TransactionType.expense,
    ),
    Transaction(
      id: '4',
      date: '2025-10-15',
      category: 'เงินเดือน',
      description: 'รายได้ประจำ',
      amount: 15000,
      type: TransactionType.income,
    ),
    Transaction(
      id: '5',
      date: '2025-10-14',
      category: 'อาหาร',
      description: 'ซื้อของใช้ในบ้าน',
      amount: 800,
      type: TransactionType.expense,
    ),
    Transaction(
      id: '6',
      date: '2025-10-13',
      category: 'การศึกษา',
      description: 'ซื้อหนังสือ',
      amount: 1200,
      type: TransactionType.expense,
    ),
    Transaction(
      id: '7',
      date: '2025-10-12',
      category: 'ค่าโทร',
      description: 'โทรศัพท์บิลรายเดือน',
      amount: 150,
      type: TransactionType.expense,
    ),
    Transaction(
      id: '8',
      date: '2025-10-11',
      category: 'รายได้เสริม',
      description: 'ขายของออนไลน์',
      amount: 3000,
      type: TransactionType.income,
    ),
  ];

  final List<MonthlyData> monthlyData = [
    MonthlyData(month: 'ก.ค. 68', income: 18000, expense: 12000),
    MonthlyData(month: 'ส.ค. 68', income: 20000, expense: 15000),
    MonthlyData(month: 'ก.ย. 68', income: 17000, expense: 13000),
    MonthlyData(month: 'ต.ค. 68', income: 18000, expense: 11700),
  ];

  final Map<String, Color> categoryColors = {
    'อาหาร': const Color(0xFFFF6B9D),
    'ค่าโทร': const Color(0xFF4FB7B3),
    'บันเทิง': const Color(0xFFFFB84D),
    'การศึกษา': const Color(0xFFA78BFA),
    'ขนส่ง': const Color(0xFF34D399),
    'อื่นๆ': const Color(0xFF94A3B8),
  };

  // Calculate totals
  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  // Calculate category summary
  List<CategorySummary> get categorySummary {
    Map<String, double> expenseByCategory = {};

    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        expenseByCategory[t.category] =
            (expenseByCategory[t.category] ?? 0) + t.amount;
      }
    }

    List<CategorySummary> summary = expenseByCategory.entries.map((entry) {
      return CategorySummary(
        category: entry.key,
        amount: entry.value,
        percentage: (entry.value / totalExpense) * 100,
        color: categoryColors[entry.key] ?? categoryColors['อื่นๆ']!,
      );
    }).toList();

    summary.sort((a, b) => b.amount.compareTo(a.amount));
    return summary;
  }

  // Filter transactions
  List<Transaction> get filteredTransactions {
    if (filterType == 'all') return transactions;
    return transactions
        .where((t) => t.type.toString().split('.').last == filterType)
        .toList();
  }

  double get maxMonthlyValue {
    double max = 0;
    for (var data in monthlyData) {
      if (data.income > max) max = data.income;
      if (data.expense > max) max = data.expense;
    }
    return max;
  }

  String formatCurrency(double amount) {
    return '฿${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
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

            // Summary Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSummaryCard(
                    title: 'รายรับทั้งหมด',
                    amount: totalIncome,
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
                    amount: totalExpense,
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
                    amount: balance,
                    gradient: balance >= 0
                        ? const LinearGradient(
                            colors: [Color(0xFF4FB7B3), Color(0xFF3a9793)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFfbbf24), Color(0xFFf59e0b)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    icon: Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pie Chart Section
            _buildPieChartSection(),

            const SizedBox(height: 24),

            // Bar Chart Section
            _buildBarChartSection(),

            const SizedBox(height: 24),

            // Transaction List
            _buildTransactionList(),

            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Gradient gradient,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              child: CustomPaint(
                painter: PieChartPainter(categorySummary: categorySummary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...categorySummary.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cat.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.category,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF223248),
                        ),
                      ),
                    ),
                    Text(
                      '${cat.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCurrency(cat.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF223248),
                      ),
                    ),
                  ],
                ),
              )),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // Legend
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
              children: monthlyData.map((data) {
                double incomeHeight = (data.income / maxMonthlyValue) * 150;
                double expenseHeight = (data.expense / maxMonthlyValue) * 150;

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
                      data.month,
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF223248),
          ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // Filter Buttons
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
          // Transaction Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
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
                      .map((entry) => _buildTransactionRow(entry.value, entry.key))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(Transaction transaction, int index) {
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
          // Date
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(transaction.date),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF223248),
              ),
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: transaction.type == TransactionType.income
                    ? Colors.green[100]
                    : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.category,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: transaction.type == TransactionType.income
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
          // Description
          Expanded(
            flex: 3,
            child: Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF223248),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '${transaction.type == TransactionType.income ? '+' : '-'}${formatCurrency(transaction.amount)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.income
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
      'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]} ${(date.year + 543).toString().substring(2)}';
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<CategorySummary> categorySummary;

  PieChartPainter({required this.categorySummary});

  @override
  void paint(Canvas canvas, Size size) {
    double total = categorySummary.fold(0, (sum, cat) => sum + cat.amount);
    double startAngle = -math.pi / 2;

    for (var category in categorySummary) {
      double sweepAngle = (category.amount / total) * 2 * math.pi;

      Paint paint = Paint()
        ..color = category.color
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

      // White border
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
