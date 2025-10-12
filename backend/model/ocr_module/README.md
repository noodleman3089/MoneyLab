# OCR Module - Receipt Extraction

โมดูล OCR สำหรับดึงข้อมูลจากใบเสร็จภาษาไทย รองรับใบเสร็จจากธนาคาร, TrueMoney, PromptPay

## 🚀 การติดตั้ง

### สำหรับเครื่องที่มี GPU (NVIDIA)

```bash
pip install -r requirements.txt
```

### สำหรับเครื่องที่ไม่มี GPU

```bash
pip install paddlepaddle paddleocr opencv-python numpy Pillow
```

## 💻 วิธีใช้งาน

### แบบพื้นฐาน

```python
from receipt_extractor import ReceiptExtractor

# สร้าง extractor
extractor = ReceiptExtractor(use_gpu=True)  # ใช้ False ถ้าไม่มี GPU

# ดึงข้อมูลจากรูป
result = extractor.extract_receipt_data('receipt.jpg')

# ดูผลลัพธ์
print(f"วันที่: {result.date}")
print(f"จำนวนเงิน: {result.amount} บาท")
print(f"ผู้ส่ง: {result.sender_name}")
print(f"ผู้รับ: {result.receiver_name}")
print(f"แหล่งที่มา: {result.merchant}")
```

### แบบมี Validation

```python
from receipt_extractor import ReceiptExtractor
from utils.validation import validate_receipt_data

# ดึงข้อมูล
extractor = ReceiptExtractor(use_gpu=True)
result = extractor.extract_receipt_data('receipt.jpg')

# ตรวจสอบความถูกต้อง
validation = validate_receipt_data(result.to_dict())

if validation.is_valid:
    print("✓ ข้อมูลถูกต้อง")
    data = validation.corrected_data  # ข้อมูลที่แก้ไขแล้ว
else:
    print("✗ พบปัญหา:")
    for issue in validation.issues:
        print(f"  - {issue.field}: {issue.message}")
```

### ใช้ผ่าน Command Line

```bash
# ใช้งานพื้นฐาน
python extract_receipt.py receipt.jpg --pretty

# บันทึกผลลัพธ์
python extract_receipt.py receipt.jpg --output result.json
```

## 📊 ข้อมูลที่ดึงได้

| ฟิลด์ | คำอธิบาย | ตัวอย่าง |
|------|----------|----------|
| `date` | วันที่และเวลา | `"31/08/2025 14:50"` |
| `amount` | จำนวนเงิน | `3000.0` |
| `fee` | ค่าธรรมเนียม | `0.0` |
| `merchant` | แหล่งที่มา | `"Bank"`, `"TrueMoney"` |
| `sender_name` | ชื่อผู้ส่ง | `"นาย สมชาย ใจดี"` |
| `receiver_name` | ชื่อผู้รับ | `"นาง สมหญิง"` |
| `reference_id` | เลขที่อ้างอิง | `"202508311450ABC"` |

## 📁 โครงสร้างโฟลเดอร์

```text
ocr_module/
├── receipt_extractor.py      # คลาสหลักสำหรับดึงข้อมูล
├── extract_receipt.py        # CLI สำหรับ command line
├── requirements.txt          # Dependencies
├── models/                   # Data models
│   └── extraction_result.py
├── patterns/                 # Regex patterns
│   └── pattern_manager.py
├── processors/               # ประมวลผลข้อความ
│   └── text_processor.py
├── ocr_backends/            # OCR engines
│   ├── base_ocr.py
│   └── gpu_manager.py
└── utils/                   # Utilities
    ├── validation.py
    ├── image_preprocessing.py
    └── name_cleaner.py
```

## ✨ คุณสมบัติ

- รองรับทั้ง **EasyOCR (GPU)** และ **PaddleOCR (CPU)**
- ปรับปรุงคุณภาพรูปภาพอัตโนมัติก่อน OCR
- ตรวจสอบความถูกต้องของข้อมูลด้วย Validation System
- รองรับใบเสร็จจากธนาคาร, TrueMoney, PromptPay, MyMo
- แปลง พ.ศ. เป็น ค.ศ. อัตโนมัติ
- คำนวณคะแนนความมั่นใจ (confidence score)

## 🐛 แก้ปัญหา

### OCR อ่านไม่ออก

- ลองใช้ GPU แทน CPU: `ReceiptExtractor(use_gpu=True)`
- ตรวจสอบว่ารูปชัด ไม่เบลอ
- ตรวจสอบขนาดไฟล์ไม่ใหญ่เกินไป

### ติดตั้ง Dependencies ไม่ได้

```bash
# ถ้าไม่มี GPU ใช้ PaddleOCR แทน
pip install paddlepaddle paddleocr opencv-python numpy Pillow
```

### Validation ไม่ผ่าน

```python
# ดูปัญหาที่เกิดขึ้น
for issue in validation.issues:
    print(f"{issue.severity}: {issue.field} - {issue.message}")

# ใช้โหมดที่ผ่อนปรนกว่า
validation = validate_receipt_data(data, strict_mode=False)
```

## 📝 หมายเหตุ

- Module จะ auto-detect OCR backend ที่ติดตั้งอยู่
- ถ้ามี GPU ควรใช้ EasyOCR เพราะแม่นกว่า
- สามารถนำไปใช้ใน project อื่นได้โดยการ copy โฟลเดอร์ ocr_module ไปใช้

---

MoneyLab Development Team
