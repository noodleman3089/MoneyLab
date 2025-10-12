"""
Pattern Manager for regex patterns used in receipt extraction
"""
from typing import Dict, List


class PatternManager:
    """Manages regex patterns for different types of receipts"""

    def __init__(self):
        self.patterns = self._init_patterns()
        self.brand_patterns = self._init_brand_patterns()

    def _init_patterns(self) -> Dict[str, List[str]]:
        """Initialize regex patterns for field extraction"""
        return {
            'amount': [
                r"(?:ยอดรวม|รวม|total|amount)\s*:?\s*(\d+[.,]\d{2})",
                r"(?:จำนวนเงิน).*?(\d{1,3}(?:,\d{3})*\.?\d{2})",
                r"(\d{1,3}(?:,\d{3})*\.?\d{2})\s*บาท",
                r"(\d+[.,]\d{2})\s*(?:บาท|THB|baht)",
                r"(?:ยอด|total).*?(\d+\.\d{2})",
                # Enhanced bank transfer patterns
                r"จำนวนเงิน\s*[^\d]*(\d{1,3}(?:,\d{3})*\.?\d{2})",
                r"(\d{1,3},\d{3}\.\d{2})",  # Specific for 3,000.00 format
                # OCR error patterns - common misreads
                r"(?:b|฿)\s*([1lioO0]+[.,]\d{2})",  # ฿ read as 'b', digits as letters
                r"(?:b|฿)\s*(\d+[.,]\d{2})",        # Normal ฿ pattern
                r"([1lioO0]+[oO0][.,]\d{2})",       # OCR digit confusion
                r"(\d+[oO][.,]\d{2})"               # Zero read as 'O'
            ],
            'fee': [
                r"(?:ค่าธรรมเนียม|fee|charge).*?(\d+[.,]\d{2})",
                r"(?:service|transaction)\s*fee.*?(\d+[.,]\d{2})",
                r"ค่าธรรมเนียม[^\d]*([o0]\.\d{2})",  # Handle OCR "o.00"
                r"ค่าธรรมเนียม[^\d]*(\d+\.\d{2})"     # Standard fee pattern
            ],
            'reference_id': [
                r"(?:เลขที่รายการ|reference|ref#?|tid|r#|รหัสอ้างอิง)\s*:?\s*([A-Za-z0-9]+)",
                r"(\d{12}[A-Za-z0-9]{3,}\d+)",  # KBank format: 12 digits + 3+ alphanumeric + digits
                r"(\d{10,}[A-Za-z0-9]+)",  # Generic: 10+ digits followed by alphanumeric
                r"(?:transaction|ref)\s*id.*?([A-Za-z0-9]+)",
                r"(?:หมายเลข|รหัส).*?([A-Za-z0-9]{8,})",
                r"([A-Za-z]{3}\d{8,})",
                r"(\d{10,}:\s*[A-Z0-9]+)"
            ],
            'date': [
                r"(\d{1,2}/\d{1,2}/\d{2,4})(?:\s*[|\s]\s*(\d{1,2}:\d{2}))?",
                r"(\d{1,2}-\d{1,2}-\d{2,4})(?:\s*[|\s]\s*(\d{1,2}:\d{2}))?",
                r"(\d{2,4}/\d{1,2}/\d{1,2})(?:\s*[|\s]\s*(\d{1,2}:\d{2}))?",
                r"(\d{1,2}\s+(?:ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.)\s+\d{4})",
                # Enhanced Thai date patterns
                r"(\d{1,2}\s+ส\.ค\.\s+\d{2,4}(?:\s+\d{1,2}:\d{2})?)",  # "31 ส.ค. 68 14:50"
                r"(\d{1,2}\s+[ก-๙]{1,3}\.?[ก-๙]{1,3}\.?\s+\d{2,4}(?:\s+\d{1,2}:\d{2})?)",  # General Thai month pattern
                r"(\d{1,2}:\d{2})"  # Time pattern
            ],
            'sender_name': [
                # Pattern หาชื่อที่มีคำนำหน้า - ป้องกันการรวม "พร้อมเพย์"
                r"จาก[^\n]*?((?:นาย|นาง|นางสาว|เด็กชาย|เด็กหญิง)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|ธนาคาร|bank|\n|$))",
                r"ผู้โอน[:\s]*((?:นาย|นาง|นางสาว|เด็กชาย|เด็กหญิง)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|ธนาคาร|bank|\n|$))",
                r"ส่งเงินจาก[:\s]*((?:นาย|นาง|นางสาว|เด็กชาย|เด็กหญิง)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|ธนาคาร|bank|\n|$))",
                # Bank transfer patterns - look for names near account info
                r"((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]{3,}?)(?=\s*(?:บัญชี|ไอแบงก์|อินทร์))",
                r"(?:นาย|นาง|นางสาว)\s+([\w\s]+?)\s+(?:อินทร์)",  # For "สุดเขต อินทร์อยู่" pattern
                # Pattern หาชื่อที่ไม่มีคำนำหน้าแต่อยู่หลัง "จาก"
                r"จาก[^\n]*?([ก-๙a-zA-Z\s]{3,})(?=\s*(?:บัญชี|ธนาคาร|bank|\n|$))",
                # KBank transfer: first name after success message (usually sender)
                r"โอนเงินสำเร็จ[^ก-๙]*?([ก-๙a-zA-Z\s]{3,}?)(?=\s*xxx|$)",
                # Pattern สำหรับ TrueMoney - ชื่อผู้ส่งที่อยู่หลัง "จากวอลเล็ท"
                r"จากวอลเล็ท\s+((?:สุเขทา|[ก-๙a-zA-Z\s]+?)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*บัญชีทรูมันนี่)",
                # Pattern สำหรับชื่อที่อยู่ก่อน "อินทร์" (TrueMoney specific) - รวมถึง ****
                r"([ก-๙a-zA-Z\s\*]{3,}?)\s+อินทร์",
                # Pattern สำหรับชื่อแบบอิสระที่ไม่มี masked characters
                r"^((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:บัญชี|ธนาคาร|bank|\n))",
                # Pattern สำหรับ multi-line names
                r"((?:นาย|นาง|นางสาว)\s*\n\s*[ก-๙a-zA-Z\s]{2,})"
            ],
            'receiver_name': [
                # ========== PRIORITY 1: Organizations/Institutions (มีความจำเพาะสูง) ==========
                # มหาวิทยาลัย/สถาบัน - Pattern เฉพาะที่มีวงเล็บ
                r"(มทร\.\s*[ก-๙a-zA-Z\s]*)\s*\(\s*([ก-๙a-zA-Z\s]*)\s*\)",  # "มทร.ตะวันออก (ค่าธรรมเนียมการศึกษา)"
                r"((?:มหาวิทยาลัย|มทร\.|บทร\.|มข\.|มอ\.|ม\.)[ก-๙a-zA-Z\s\.]*)\s*\([^)]+\)",  # ชื่อมหาวิทยาลัยที่มีวงเล็บ

                # องค์กร/สถาบัน - มีคำสำคัญ
                r"([ก-๙a-zA-Z\s\.]+(?:โรงเรียน|มหาวิทยาลัย|วิทยาลัย|สถาบัน|ศูนย์|องค์การ|กรม|กระทรวง|เทศบาล|องค์การบริหาร|สำนัก)[ก-๙a-zA-Z\s\(\)\.]*?)(?=\s*\d{5,}|\s*พร้อมเพย์|\n|$)",

                # บริษัท/ร้านค้า
                r"((?:บริษัท|ห้างหุ้นส่วน|หจก\.|บจก\.)[ก-๙a-zA-Z\s\(\)\.]+?)(?=\s*\d{5,}|\s*พร้อมเพย์|\n|$)",

                # ชื่อที่มีวงเล็บ (มักเป็นองค์กร)
                r"([ก-๙a-zA-Z\s]+\s*\([ก-๙a-zA-Z\s]+\))(?=\s*\d{5,}|\s*\d{10,}|\s*พร้อมเพย์|\n|$)",

                # ========== PRIORITY 2: Context-based (มีคำนำ "ถึง", "ผู้รับ") ==========
                # "ถึง" + คำนำหน้า (นาย/นาง/นางสาว) - แม่นยำสูง
                r"ถึง\s*[:\-]?\s*((?:นาย|นาง|นางสาว|น\.ส\.|ด\.ช\.|ด\.ญ\.)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|ธนาคาร|เบอร์|xxx|\*|\d{10}|\n|$))",

                # "ถึง" multi-line - OCR แยกบรรทัด
                r"ถึง\s*[:\-]?\s*\n\s*((?:นาย|นาง|นางสาว|น\.ส\.)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|\n|$))",

                # "ผู้รับ" / "รับเงินที่" - explicit receiver
                r"ผู้รับ\s*[:\-]?\s*((?:นาย|นาง|นางสาว|น\.ส\.)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|ธนาคาร|\n|$))",
                r"รับเงิน(?:ที่|จาก)?\s*[:\-]?\s*((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|\n|$))",

                # "ถึง" ไม่มีคำนำหน้า (ลำดับถัดไป)
                r"ถึง\s*[:\-]?\s*([ก-๙a-zA-Z\s]{3,}?)(?=\s*(?:พร้อมเพย์|บัญชี|ธนาคาร|\d{10}|\n|$))",

                # ========== PRIORITY 3: PromptPay/Bank specific patterns ==========
                # "พร้อมเพย์" แล้วตามด้วยชื่อ - Bank transfers
                r"พร้อมเพย์\s*[:\-]?\s*(?:\d{10})?\s*\n?\s*((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]{3,}?)(?=\s*(?:อินทร์|xxx|\*|\n|$))",

                # "พร้อมเพย์" ข้ามบรรทัด
                r"พร้อมเพย์[^\n]*\n[^\n]*?((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]{3,}?)(?=\s*(?:อินทร์|พร้อมเพย์|xxx|\n|$))",

                # หลัง PromptPay หลายบรรทัด
                r"(?:พร้อมเพย์.*?\n.*?)((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]+?)(?=\s*(?:อินทร์|xxx|\*|\d{10}|\n|$))",

                # KBank: หลัง xxx (masked account)
                r"xxx[^ก-๙]*?([ก-๙a-zA-Z\s]{3,}?)(?=\s*(?:xxx|บัญชี|พร้อมเพย์|$))",

                # ========== PRIORITY 4: Position-based (ตำแหน่งในข้อความ) ==========
                # หลังเลขบัญชี/เบอร์โทร 10 หลัก
                r"\d{10}\s*\n?\s*((?:นาย|นาง|นางสาว)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:พร้อมเพย์|บัญชี|อินทร์|\n|$))",

                # หลังคำว่า "บัญชี" / "account"
                r"(?:บัญชี|account)\s*[:\-]?\s*([ก-๙a-zA-Z\s]{3,}?)(?=\s*(?:\d{5,}|พร้อมเพย์|\n|$))",

                # ชื่อที่มี "อินทร์" ต่อท้าย (TrueMoney pattern)
                r"([ก-๙a-zA-Z\s]{3,}?)\s+อินทร์(?:\s*[ก-๙a-zA-Z\s]*)?(?=\s*(?:บัญชี|พร้อมเพย์|\n|$))",

                # ========== PRIORITY 5: Generic patterns (ใช้ตอนสุดท้าย) ==========
                # ชื่อที่มีคำนำหน้า ตามด้วย stop words
                r"((?:นาย|นาง|นางสาว|น\.ส\.)\s+[ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:บัญชี|ธนาคาร|bank|พร้อมเพย์|xxx|\*|\d{10}|\n|$))",

                # ชื่อเต็มที่แยกคำนำหน้ากับชื่อ (OCR แยก)
                r"(?:นาย|นาง|นางสาว)\s*\n\s*([ก-๙a-zA-Z\s]{2,}?)(?=\s*(?:บัญชี|พร้อมเพย์|\n|$))",

                # Fallback: ชื่อทั่วไปที่มี 2-3 คำขึ้นไป
                r"\b([ก-๙]{2,}\s+[ก-๙]{2,}(?:\s+[ก-๙]{2,})?)(?=\s*(?:พร้อมเพย์|บัญชี|xxx|\d{10}|\n|$))",
            ]
        }

    def _init_brand_patterns(self) -> Dict[str, Dict[str, str]]:
        """Initialize brand detection patterns"""
        return {
            # Banks - all grouped under "Bank"
            'K PLUS': {'type': 'bank', 'brand': 'Bank'},
            'K+': {'type': 'bank', 'brand': 'Bank'},
            'กสิกรไทย': {'type': 'bank', 'brand': 'Bank'},
            'KBANK': {'type': 'bank', 'brand': 'Bank'},
            'KASIKORN': {'type': 'bank', 'brand': 'Bank'},
            'SCB': {'type': 'bank', 'brand': 'Bank'},
            'ไทยพาณิชย์': {'type': 'bank', 'brand': 'Bank'},
            'BBL': {'type': 'bank', 'brand': 'Bank'},
            'กรุงเทพ': {'type': 'bank', 'brand': 'Bank'},
            'KTB': {'type': 'bank', 'brand': 'Bank'},
            'กรุงไทย': {'type': 'bank', 'brand': 'Bank'},
            'TMB': {'type': 'bank', 'brand': 'Bank'},
            'ทหารไทย': {'type': 'bank', 'brand': 'Bank'},
            'UOB': {'type': 'bank', 'brand': 'Bank'},
            'CIMB': {'type': 'bank', 'brand': 'Bank'},
            # Generic bank detection patterns
            'BANK': {'type': 'bank', 'brand': 'Bank'},
            # Retail stores
            '7-ELEVEN': {'type': 'retail', 'brand': '7-Eleven'},
            '7-ELEVE': {'type': 'retail', 'brand': '7-Eleven'},
            '7-ELEVEท': {'type': 'retail', 'brand': '7-Eleven'},
            'เซเว่น': {'type': 'retail', 'brand': '7-Eleven'},
            'CP': {'type': 'retail', 'brand': 'CP'},
            'เซ็นทรัล': {'type': 'retail', 'brand': 'Central'},
            'โลตัส': {'type': 'retail', 'brand': 'Lotus'},
            'บิ๊กซี': {'type': 'retail', 'brand': 'Big C'},
            'แม็คโคร': {'type': 'retail', 'brand': 'Makro'},
            # E-wallets and payment apps
            'TRUE WALLET': {'type': 'e_wallet', 'brand': 'TrueMoney'},
            'TRUEMONEY': {'type': 'e_wallet', 'brand': 'TrueMoney'},
            'RABBIT LINE PAY': {'type': 'e_wallet', 'brand': 'Rabbit LINE Pay'},
            'SHOPEE PAY': {'type': 'e_wallet', 'brand': 'ShopeePay'},
            'PROMPTPAY': {'type': 'e_wallet', 'brand': 'PromptPay'},
            # MyMo PromptPay app
            'มายมอ': {'type': 'e_wallet', 'brand': 'MyMo'},
            'รายการสำเร็จ': {'type': 'e_wallet', 'brand': 'PromptPay'},
            'กำรายการสำเร็จ': {'type': 'e_wallet', 'brand': 'PromptPay'},
            'รายการโอนเงิน': {'type': 'e_wallet', 'brand': 'PromptPay'},
            'พร้อมเพย์': {'type': 'e_wallet', 'brand': 'PromptPay'},
            # Services
            'GRAB': {'type': 'ride_hailing', 'brand': 'Grab'},
            'แกร็บ': {'type': 'ride_hailing', 'brand': 'Grab'},
            'FOODPANDA': {'type': 'food_delivery', 'brand': 'foodpanda'},
        }
