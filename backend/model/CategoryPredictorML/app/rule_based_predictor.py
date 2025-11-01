import pandas as pd

# 1. สร้าง "พจนานุกรมคีย์เวิร์ด" ของเรา
# (นี่คือ "สมอง" ของชั้นที่ 1)
# --- [UPDATED] เพิ่มคีย์เวิร์ดให้ละเอียดและครอบคลุมมากขึ้น ---
KEYWORD_MAP = {
    # หมวด: อาหาร/เครื่องดื่ม (เพิ่มใหม่)
    'อาหาร/เครื่องดื่ม': ['GrabFood', 'LINE MAN', 'Foodpanda', 'Robinhood', 
                           'Starbucks', 'Amazon Cafe', 'KFC', 'McDonald', 'Pizza',
                           'ร้านอาหาร', 'food'],

    # หมวด: การเดินทาง
    'การเดินทาง': ['ปตท', 'PTT', 'Shell', 'บางจาก', 'Caltex', 
                     'ทางด่วน', 'Easy Pass', 'BTS', 'MRT', 'Bolt', 'Grab',
                     'Agoda', 'Traveloka', 'Booking.com', 'AirAsia'],
    
    # หมวด: ที่อยู่อาศัย/สาธารณูปโภค
    'ที่อยู่อาศัย/สาธารณูปโภค': ['การไฟฟ้า', 'การประปา', 'MEA', 'MWA', 'ค่าไฟ', 'ค่าน้ำ', 
                                 'AIS Fibre', 'True Online', '3BB', 'ค่าเน็ต', 'ค่าโทรศัพท์'],
    
    # หมวด: สุขภาพ/การดูแลตนเอง
    'สุขภาพ/การดูแลตัวเอง': ['โรงพยาบาล', 'รพ.', 'คลินิก', 'เภสัช', 'Watsons', 'Boots', 'Fascino', 'ร้านยา',
                               'บาร์เบอร์', 'barber', 'ร้านตัดผม', 'ทำผม', 'เสริมสวย'],
    
    # หมวด: ไลฟ์สไตล์/บันเทิง
    'ไลฟ์สไตล์/บันเทิง': ['7-Eleven', '7-11', 'Lotus', 'Big C', 'Tops', 'Gourmet Market',
                           'Shopee', 'Lazada', 'Tiktok', 'Central', 'The Mall', 'Robinson',
                           'Major', 'SF Cinema', 'Netflix', 'Spotify', 'YouTube', 'Disney+', 'Viu'],

    # หมวด: การศึกษา/พัฒนาตนเอง (เพิ่มใหม่)
    'การศึกษา/พัฒนาตนเอง': ['B2S', 'ซีเอ็ด', 'นายอินทร์', 'Kinokuniya', 'Udemy', 'Coursera', 'SkillLane',
                             'ค่าเทอม', 'ค่าเล่าเรียน', 'มหาวิทยาลัย'],

    # หมวด: การเงิน (เพิ่มใหม่)
    'การเงิน': ['AIA', 'เมืองไทยประกัน', 'FWD', 'ประกันสังคม', 'ค่าธรรมเนียม', 'สินเชื่อ', 'ดอกเบี้ย']
}


class RuleBasedPredictor:
    
    def __init__(self):
        # เราแปลงพจนานุกรมให้ค้นหาง่ายขึ้น
        self.rules = []
        for category, keywords in KEYWORD_MAP.items():
            for keyword in keywords:
                self.rules.append((keyword.lower(), category)) # เก็บเป็น (คีย์เวิร์ดตัวเล็ก, หมวด)

    def predict(self, transaction_data):
        """
        รับข้อมูล 1 ธุรกรรม (เป็น dict) และพยายามทำนาย
        """
        
        # 1. ดึงข้อมูล Text ที่เราจะตรวจสอบ
        # (เราจะเช็คทั้ง 2 ฝั่ง)
        receiver = str(transaction_data.get('receiver_name', '')).lower()
        sender = str(transaction_data.get('sender_name', '')).lower()
        
        text_to_check = f"{receiver} {sender}"
        
        # 2. วนลูปเช็คคีย์เวิร์ด
        for keyword, category in self.rules:
            if keyword in text_to_check:
                # เจอปุ๊บ! คืนค่าทันที
                return {
                    'predicted_category': category,
                    'confidence': 0.95, # เรามั่นใจใน Rule เสมอ
                    'method': 'rule_based_keyword',
                    'need_ml': False # ไม่ต้องส่งต่อ
                }
                
        # 3. ถ้าไม่เจอคีย์เวิร์ดเลย
        return {
            'predicted_category': None,
            'confidence': 0.0,
            'method': 'rule_based_failed',
            'need_ml': True # "ส่งต่อให้ ML จัดการ!"
        }