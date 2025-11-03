import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/transaction_models.dart' as models;

class DailyTransactionList extends StatelessWidget {
  final List<models.Transaction> transactions;

  const DailyTransactionList({
    super.key,
    required this.transactions,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'อาหาร':
      case 'อาหาร/เครื่องดื่ม':
        return Icons.restaurant;
      case 'ช้อปปิ้ง':
        return Icons.shopping_bag;
      case 'เดินทาง':
        return Icons.directions_car;
      case 'บันเทิง':
        return Icons.movie;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Text(
              'การใช้จ่ายประจำวันนี้',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Transaction List
          transactions.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF4FB7B3)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getCategoryIcon(transaction.category),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        transaction.description,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF223248),
                        ),
                      ),
                      subtitle: Text(
                        transaction.category,
                        style: GoogleFonts.beVietnamPro(
                          color: const Color(0xFF999999),
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        '${transaction.type == 'expense' ? '-' : '+'}${transaction.amount.toInt()} ฿',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: transaction.type == 'expense' ? Colors.red.shade400 : Colors.green.shade600,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFF14B8A6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการใช้จ่ายวันนี้',
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เพิ่มรายการเพื่อติดตามการใช้จ่าย',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}