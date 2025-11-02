import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';

class SelectCategoryPage extends StatefulWidget {
  final String transactionType;

  const SelectCategoryPage({super.key, required this.transactionType});

  @override
  State<SelectCategoryPage> createState() => _SelectCategoryPageState();
}

class _SelectCategoryPageState extends State<SelectCategoryPage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _transactionService.fetchCategories(widget.transactionType);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'อาหาร':
      case 'อาหาร/เครื่องดื่ม':
        return Icons.restaurant;
      case 'ช้อปปิ้ง':
        return Icons.shopping_bag;
      case 'เดินทาง':
      case 'การเดินทาง':
        return Icons.directions_car;
      case 'บันเทิง':
      case 'ไลฟ์สไตล์/บันเทิง':
        return Icons.movie;
      case 'เงินเดือน':
      case 'รายรับประจำ':
        return Icons.work;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เลือกหมวดหมู่',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF14B8A6),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบหมวดหมู่'));
          }

          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF14B8A6).withOpacity(0.1),
                  child: Icon(
                    _getCategoryIcon(category['category_name']),
                    color: const Color(0xFF14B8A6),
                  ),
                ),
                title: Text(
                  category['category_name'],
                  style: GoogleFonts.beVietnamPro(fontSize: 16),
                ),
                onTap: () {
                  // ส่งข้อมูล category ที่เลือกกลับไปหน้าก่อนหน้า
                  Navigator.pop(context, category);
                },
              );
            },
          );
        },
      ),
    );
  }
}