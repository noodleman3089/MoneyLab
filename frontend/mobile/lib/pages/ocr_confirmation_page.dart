import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 👈 1. Import kIsWeb
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/transaction_service.dart';
import 'select_category_page.dart';

class OcrConfirmationPage extends StatefulWidget {
  const OcrConfirmationPage({super.key});

  @override
  State<OcrConfirmationPage> createState() => _OcrConfirmationPageState();
}

class _OcrConfirmationPageState extends State<OcrConfirmationPage> {
  final TransactionService _transactionService = TransactionService();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageXFile; // 👈 2. เปลี่ยนจาก File เป็น XFile เพื่อเก็บข้อมูลดิบ
  bool _isLoading = false;
  String _statusMessage = 'เลือกรูปภาพเพื่อเริ่มต้น';

  Map<String, dynamic>? _ocrData;
  Map<String, dynamic>? _predictionData;
  Map<String, dynamic>? _selectedCategory;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // เลือกรูปภาพทันทีเมื่อเข้ามาหน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        // ถ้าผู้ใช้ไม่เลือกรูป ให้กลับไปหน้าก่อนหน้า
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        _imageXFile = pickedFile; // 👈 3. เก็บ XFile ที่ได้มาโดยตรง
        _isLoading = true;
        _statusMessage = 'กำลังอัปโหลดและประมวลผล...';
        _ocrData = null;
        _predictionData = null;
      });

      // อัปโหลดและประมวลผล
      final apiResult = await _transactionService.uploadReceipt(pickedFile.path);

      // --- [REFACTOR] ---
      // --- [THE FIX] ---
      // 1. ดึงข้อมูลอย่างปลอดภัย ป้องกันกรณีที่ key 'data' หรือ key ภายในเป็น null
      final data = apiResult['data'] as Map<String, dynamic>?;
      final ocrData = data?['ocr_data'] as Map<String, dynamic>?;
      final predictionData = data?['prediction_data'] as Map<String, dynamic>?;

      // ถ้าไม่มีข้อมูล OCR เลย ถือว่าล้มเหลว
      // 2. เตรียมข้อมูลสำหรับอัปเดต State
      final amountText = (ocrData?['amount'] ?? 0.0).toString();
      final descriptionText = ocrData?['receiver_name'] ?? '';
      Map<String, dynamic>? newSelectedCategory;

      if (predictionData != null && predictionData['predicted_category_id'] != null) {
        newSelectedCategory = {
          'category_id': predictionData['predicted_category_id'],
          'category_name': predictionData['predicted_category_name']
        };
      }

      setState(() {
        // 3. อัปเดต State ทั้งหมดในครั้งเดียว
        _ocrData = ocrData;
        _predictionData = predictionData;
        _amountController.text = amountText;
        _descriptionController.text = descriptionText;
        _selectedCategory = newSelectedCategory;
        _isLoading = false;
        _statusMessage = 'ตรวจสอบและยืนยันข้อมูล';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'เกิดข้อผิดพลาด: ${e.toString().replaceAll("Exception: ", "")}';
        });
      }
    }
  }

  Future<void> _selectCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectCategoryPage(transactionType: 'expense'),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _confirmTransaction() async {
    if (_isLoading) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาใส่จำนวนเงินที่ถูกต้อง')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')));
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังบันทึกข้อมูล...';
    });

    try {
      // --- [THE FIX] ---
      // เปลี่ยนมาใช้ addTransaction ซึ่งเป็นฟังก์ชันกลางสำหรับบันทึกข้อมูล
      // และส่งข้อมูลตามที่ฟังก์ชันต้องการ
      await _transactionService.addTransaction(
        amount: amount,
        categoryId: _selectedCategory!['category_id'],
        description: _descriptionController.text,
      );

      if (mounted) {
        // ส่ง true กลับไปเพื่อบอกให้หน้า DailyManagement refresh ข้อมูล
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
          _statusMessage = 'ตรวจสอบและยืนยันข้อมูล';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ยืนยันข้อมูลจากสลิป', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14B8A6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imageXFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // 👈 4. ตรวจสอบแพลตฟอร์มเพื่อเลือก Widget ที่เหมาะสม
                      child: kIsWeb
                          ? Image.network(_imageXFile!.path, fit: BoxFit.contain)
                          : Image.file(File(_imageXFile!.path), fit: BoxFit.contain),
                    )
                  : Center(child: Text(_statusMessage, style: GoogleFonts.beVietnamPro())),
            ),
            const SizedBox(height: 16),

            // Loading or Form
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage, style: GoogleFonts.beVietnamPro()),
                ],
              )
            else if (_ocrData != null || _imageXFile != null && !_isLoading)
              _buildConfirmationForm()
            else
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('เลือกรูปภาพอื่น'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_statusMessage, style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'จำนวนเงิน', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'รายละเอียด/ผู้รับ', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: Text(_selectedCategory?['category_name'] ?? 'เลือกหมวดหมู่'),
          subtitle: _predictionData != null ? Text('ระบบแนะนำหมวดหมู่นี้ให้คุณ', style: GoogleFonts.beVietnamPro(color: Colors.green.shade700)) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectCategory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14B8A6),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('ยืนยันการบันทึก', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickImage,
          child: const Text('เลือกรูปภาพอื่น'),
        ),
      ],
    );
  }
}