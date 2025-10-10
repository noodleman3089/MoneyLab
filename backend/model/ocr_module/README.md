# OCR Module - Receipt Extraction

โมดูล OCR สำหรับดึงข้อมูลจากใบเสร็จภาษาไทย พร้อมความสามารถในการตรวจสอบความถูกต้อง

## 📁 โครงสร้างโฟลเดอร์

```
ocr_module/
├── extract_receipt.py      # ไฟล์หลัก OCR
├── requirements.txt         # Dependencies
├── __init__.py             # Module initialization
├── README.md               # คู่มือการใช้งาน
└── utils/
    ├── __init__.py
    └── validation.py       # ตรวจสอบความถูกต้องข้อมูล
```

## 🚀 การติดตั้ง

```bash
# 1. ติดตั้ง dependencies
pip install -r requirements.txt

# 2. สำหรับ GPU (NVIDIA CUDA)
pip install torch torchvision easyocr

# 3. สำหรับ CPU อย่างเดียว
pip install paddlepaddle paddleocr
```

## 💻 วิธีใช้งานใน Python

### แบบง่าย (ดึงข้อมูลอย่างเดียว)

```python
from ocr_module import ReceiptExtractor

# สร้าง extractor
extractor = ReceiptExtractor(use_gpu=True)  # use_gpu=False สำหรับ CPU

# ดึงข้อมูลจากรูป
result = extractor.extract_receipt_data('receipt.jpg')

# แสดงผล
print(f"Amount: {result.amount}")
print(f"Date: {result.date}")
print(f"Merchant: {result.merchant}")
print(f"Sender: {result.sender_name}")
print(f"Receiver: {result.receiver_name}")
```

### แบบมี Validation (แนะนำ)

```python
from ocr_module import ReceiptExtractor
from ocr_module.utils import validate_receipt_data

# ดึงข้อมูล
extractor = ReceiptExtractor(use_gpu=True)
result = extractor.extract_receipt_data('receipt.jpg')

# แปลงเป็น dict
data = result.to_dict()

# ตรวจสอบความถูกต้อง
validation = validate_receipt_data(data, strict_mode=False)

if validation.is_valid:
    print("✓ ข้อมูลถูกต้อง")
    print(f"Validation Score: {validation.validation_score:.2%}")

    # ใช้ข้อมูลที่แก้ไขแล้ว
    corrected_data = validation.corrected_data
    # บันทึกลง database ของคุณ...
else:
    print("✗ พบปัญหา:")
    for issue in validation.issues:
        print(f"  - [{issue.severity}] {issue.field}: {issue.message}")
```

## 🔌 การนำไปใช้ในโปรเจกต์

### วิธีที่ 1: คัดลอกโฟลเดอร์ทั้งหมด

```bash
# คัดลอก ocr_module ไปยังโปรเจกต์ของคุณ
cp -r ocr_module/ /path/to/your/project/
```

### วิธีที่ 2: Import จากตำแหน่งอื่น

```python
import sys
sys.path.append('/path/to/ocr_module')

from ocr_module import ReceiptExtractor
```

### วิธีที่ 3: สร้าง Python Package

```bash
# สร้าง setup.py แล้วติดตั้ง
cd ocr_module
pip install -e .
```

## 📊 ข้อมูลที่ดึงได้

| Field | Type | Description |
|-------|------|-------------|
| `date` | str | วันที่ทำรายการ |
| `merchant` | str | ชื่อร้านค้า/ธนาคาร |
| `reference_id` | str | เลขที่รายการอ้างอิง |
| `amount` | float | จำนวนเงิน (THB) |
| `fee` | float | ค่าธรรมเนียม (THB) |
| `sender_name` | str | ชื่อผู้ส่ง |
| `receiver_name` | str | ชื่อผู้รับ |
| `source` | dict | ประเภทและแบรนด์ (type, brand) |
| `confidence` | dict | คะแนนความมั่นใจแต่ละฟิลด์ |
| `overall_confidence` | float | คะแนนความมั่นใจรวม (0-1) |

## ⚙️ ตัวเลือก

```python
# GPU support
extractor = ReceiptExtractor(use_gpu=True)

# เปลี่ยนภาษา (default: th)
extractor = ReceiptExtractor(lang='th')  # 'en', 'th'

# Strict validation mode
validation = validate_receipt_data(data, strict_mode=True)
```

## 🔍 ตัวอย่างผลลัพธ์

```json
{
  "date": "31/08/2025 14:50",
  "merchant": "Bank",
  "reference_id": "202508311450ABC123",
  "amount": 3000.0,
  "fee": 0.0,
  "sender_name": "นาย สมชาย ใจดี",
  "receiver_name": "มทร.ตะวันออก (ค่าธรรมเนียมการศึกษา)",
  "source": {
    "type": "bank",
    "brand": "Bank"
  },
  "confidence": {
    "date": 0.85,
    "amount": 0.92,
    "merchant": 0.90
  },
  "overall_confidence": 0.852
}
```

## 📝 Notes

- รองรับ **PaddleOCR** (CPU) และ **EasyOCR** (GPU)
- ทำงานได้ดีกับใบเสร็จภาษาไทย
- มี validation rules สำหรับตรวจสอบข้อมูล
- **ไม่มี database code** - เชื่อมต่อกับ database ของคุณเองได้

## 🐛 Troubleshooting

**หาก OCR อ่านไม่ออก:**
- ลองใช้ GPU แทน CPU
- ตรวจสอบความคมชัดของรูป
- ลองปรับแสงในรูปก่อน OCR

**หาก validation ไม่ผ่าน:**
- ตรวจสอบ `validation.issues` เพื่อดูปัญหา
- ใช้ `validation.corrected_data` สำหรับข้อมูลที่แก้ไขแล้ว
- ปิด `strict_mode` ถ้าต้องการ validation ที่หลวมกว่า
