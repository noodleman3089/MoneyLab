"""
ตัวอย่างการใช้งาน OCR Module
"""

from extract_receipt import ReceiptExtractor
from utils.validation import validate_receipt_data


def example_basic():
    """ตัวอย่างการใช้งานแบบพื้นฐาน"""
    print("=== ตัวอย่างที่ 1: การใช้งานพื้นฐาน ===\n")

    # สร้าง extractor
    extractor = ReceiptExtractor(use_gpu=False)  # เปลี่ยนเป็น True ถ้ามี GPU

    # ดึงข้อมูลจากรูป
    result = extractor.extract_receipt_data('test_image.jpg')

    # แสดงผลลัพธ์
    print(f"วันที่: {result.date}")
    print(f"จำนวนเงิน: {result.amount} บาท")
    print(f"ค่าธรรมเนียม: {result.fee} บาท")
    print(f"ร้านค้า: {result.merchant}")
    print(f"ผู้ส่ง: {result.sender_name}")
    print(f"ผู้รับ: {result.receiver_name}")
    print(f"เลขอ้างอิง: {result.reference_id}")
    print(f"แหล่งที่มา: {result.source}")
    print(f"ความมั่นใจ: {result.overall_confidence:.1%}\n")


def example_with_validation():
    """ตัวอย่างการใช้งานพร้อม validation"""
    print("=== ตัวอย่างที่ 2: การใช้งานพร้อม Validation ===\n")

    # สร้าง extractor
    extractor = ReceiptExtractor(use_gpu=False)

    # ดึงข้อมูล
    result = extractor.extract_receipt_data('test_image.jpg')
    data = result.to_dict()

    # Validate ข้อมูล
    validation = validate_receipt_data(data, strict_mode=False)

    print(f"สถานะ: {'✓ ผ่าน' if validation.is_valid else '✗ ไม่ผ่าน'}")
    print(f"คะแนน Validation: {validation.validation_score:.1%}\n")

    if validation.issues:
        print("ปัญหาที่พบ:")
        for issue in validation.issues:
            severity_icon = {
                'error': '🔴',
                'warning': '🟡',
                'info': '🔵'
            }.get(issue.severity, '⚪')

            print(f"  {severity_icon} [{issue.severity.upper()}] {issue.field}")
            print(f"     {issue.message}")
            if issue.suggested_value:
                print(f"     แนะนำ: {issue.suggested_value}")
        print()

    # ใช้ข้อมูลที่แก้ไขแล้ว
    corrected_data = validation.corrected_data
    print("ข้อมูลหลังแก้ไข:")
    print(f"  จำนวนเงิน: {corrected_data.get('amount')} บาท")
    print(f"  ค่าธรรมเนียม: {corrected_data.get('fee')} บาท")
    print()


def example_save_to_database():
    """ตัวอย่างการบันทึกลง database (ต้องปรับให้เข้ากับ database ของคุณ)"""
    print("=== ตัวอย่างที่ 3: บันทึกลง Database ===\n")

    extractor = ReceiptExtractor(use_gpu=False)
    result = extractor.extract_receipt_data('test_image.jpg')
    data = result.to_dict()

    # Validate ก่อนบันทึก
    validation = validate_receipt_data(data)

    if validation.is_valid:
        corrected_data = validation.corrected_data

        # ตัวอย่างการบันทึก (ปรับให้เข้ากับ database ของคุณ)
        """
        # สำหรับ MySQL
        import mysql.connector

        conn = mysql.connector.connect(
            host='localhost',
            user='your_user',
            password='your_password',
            database='your_database'
        )
        cursor = conn.cursor()

        query = '''
        INSERT INTO transactions
        (date, amount, fee, merchant, sender, receiver, reference_id, source_type, confidence)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        '''

        values = (
            corrected_data.get('date'),
            corrected_data.get('amount'),
            corrected_data.get('fee'),
            corrected_data.get('merchant'),
            corrected_data.get('sender_name'),
            corrected_data.get('receiver_name'),
            corrected_data.get('reference_id'),
            corrected_data.get('source', {}).get('type'),
            corrected_data.get('overall_confidence')
        )

        cursor.execute(query, values)
        conn.commit()

        print(f"✓ บันทึกสำเร็จ! Transaction ID: {cursor.lastrowid}")

        cursor.close()
        conn.close()
        """

        print("ข้อมูลพร้อมบันทึก:")
        print(f"  Date: {corrected_data.get('date')}")
        print(f"  Amount: {corrected_data.get('amount')}")
        print(f"  Merchant: {corrected_data.get('merchant')}")
        print("\n(ปรับโค้ดให้เข้ากับ database ของคุณ)")
    else:
        print("✗ ข้อมูลไม่ผ่าน validation - ไม่บันทึกลง database")
        print(f"ปัญหา: {len(validation.issues)} รายการ")


def example_batch_processing():
    """ตัวอย่างการประมวลผลหลายไฟล์"""
    print("=== ตัวอย่างที่ 4: ประมวลผลหลายไฟล์ ===\n")

    import os

    # ไฟล์ที่จะประมวลผล
    image_files = [
        'receipt1.jpg',
        'receipt2.jpg',
        'receipt3.jpg'
    ]

    extractor = ReceiptExtractor(use_gpu=False)
    results = []

    for image_file in image_files:
        if not os.path.exists(image_file):
            print(f"⚠ ไม่พบไฟล์: {image_file}")
            continue

        print(f"กำลังประมวลผล: {image_file}...")

        result = extractor.extract_receipt_data(image_file)
        data = result.to_dict()

        # Validate
        validation = validate_receipt_data(data)

        if validation.is_valid:
            results.append({
                'file': image_file,
                'data': validation.corrected_data,
                'confidence': validation.validation_score
            })
            print(f"  ✓ สำเร็จ (Confidence: {validation.validation_score:.1%})")
        else:
            print(f"  ✗ ล้มเหลว ({len(validation.issues)} ปัญหา)")

    print(f"\nประมวลผลเสร็จสิ้น: {len(results)}/{len(image_files)} ไฟล์")

    # บันทึกทั้งหมดลง database
    # for item in results:
    #     save_to_database(item['data'])


if __name__ == "__main__":
    # เลือกตัวอย่างที่ต้องการรัน

    # ตัวอย่างพื้นฐาน
    # example_basic()

    # ตัวอย่างพร้อม validation (แนะนำ)
    # example_with_validation()

    # ตัวอย่างการบันทึก database
    # example_save_to_database()

    # ตัวอย่างประมวลผลหลายไฟล์
    # example_batch_processing()

    print("💡 แก้ไข example_usage.py เพื่อเลือกตัวอย่างที่ต้องการรัน")
