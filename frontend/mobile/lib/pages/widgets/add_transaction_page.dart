import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'select_category_page.dart';
import '../services/transaction_service.dart';

class AddTransactionPage extends StatefulWidget {
  final String transactionType; // 'income' or 'expense'

  const AddTransactionPage({super.key, required this.transactionType});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _amountController = TextEditingController(text: '0');
  final TextEditingController _noteController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  Map<String, dynamic>? _selectedCategory;
  bool _isSaving = false;

  void _onDigitPress(String digit) {
    setState(() {
      if (_amountController.text == '0') {
        _amountController.text = digit;
      } else {
        _amountController.text += digit;
      }
    });
  }

  void _onBackspacePress() {
    setState(() {
      String currentText = _amountController.text;
      if (currentText.length > 1) {
        _amountController.text = currentText.substring(0, currentText.length - 1);
      } else {
        _amountController.text = '0';
      }
    });
  }

  Future<void> _selectCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCategoryPage(transactionType: widget.transactionType),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาใส่จำนวนเงิน')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _transactionService.addTransaction(
        amount: amount,
        categoryId: _selectedCategory!['category_id'],
        description: _noteController.text.isNotEmpty ? _noteController.text : _selectedCategory!['category_name'],
      );
      Navigator.pop(context, true); // ส่ง true กลับไปเพื่อบอกว่าบันทึกสำเร็จ
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transactionType == 'expense';
    final color = isExpense ? Colors.red.shade400 : Colors.green.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isExpense ? 'เพิ่มรายจ่าย' : 'เพิ่มรายรับ',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
      ),
      body: Column(
        children: [
          // Display Section
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: color.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('จำนวนเงิน', style: GoogleFonts.beVietnamPro(color: color, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormat("#,##0").format(double.tryParse(_amountController.text) ?? 0)} ฿',
                  style: GoogleFonts.beVietnamPro(fontSize: 48, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          // Form Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(_selectedCategory?['category_name'] ?? 'เลือกหมวดหมู่'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectCategory,
                ),
                const Divider(),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.notes_outlined),
                    labelText: 'โน้ต (ไม่บังคับ)',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Numpad and Save Button
          _buildNumpad(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('บันทึก', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    // This is a simplified numpad. You can customize it further.
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      children: [
        ...List.generate(9, (i) => TextButton(onPressed: () => _onDigitPress('${i + 1}'), child: Text('${i + 1}', style: const TextStyle(fontSize: 24)))),
        Container(), // Empty space
        TextButton(onPressed: () => _onDigitPress('0'), child: const Text('0', style: TextStyle(fontSize: 24))),
        IconButton(onPressed: _onBackspacePress, icon: const Icon(Icons.backspace_outlined)),
      ],
    );
  }
}