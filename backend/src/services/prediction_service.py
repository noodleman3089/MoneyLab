import pandas as pd
from datetime import datetime
import os
import json
import sys
import mysql.connector
from dotenv import load_dotenv

# --- [THE FIX] ---
# 1. หา Path ไปยังรากของโปรเจกต์ ML (CategoryPredictorML)
# โหลด .env จากโฟลเดอร์รากของ backend
dotenv_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
load_dotenv(dotenv_path)

# ตั้งค่าการเชื่อมต่อ DB จาก .env
db_config = {
    'host': os.getenv('DB_HOST'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'database': os.getenv('DB_NAME')
}

ML_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'model', 'CategoryPredictorML'))
# 2. เพิ่ม Path นั้นเข้าไปใน sys.path เพื่อให้ Python หาโมดูลเจอ
if ML_PROJECT_ROOT not in sys.path:
    sys.path.insert(0, ML_PROJECT_ROOT)

# 2. Import คลาสและฟังก์ชันจากโปรเจกต์ ML
from category_predictor.model import CategoryPredictorML 
from app.rule_based_predictor import RuleBasedPredictor
from app.feature_engineering import engineer_features

class PredictionService:
    def __init__(self):
        # --- [REFACTORED] ---
        # 1. ไม่โหลดโมเดลตอนเริ่มต้น แต่สร้าง Cache ว่างๆ ไว้รอ
        self.models_cache = {}
        print("Initializing Rule-Based predictor (L1)...")
        # --- [THE FIX] ---
        # โหลดข้อมูล Category ทั้งหมดมาเก็บไว้ใน cache เพื่อลดการ query db ซ้ำๆ
        self.category_map = self._load_categories()
        self.rule_based_model = RuleBasedPredictor()
        print("--- PredictionService initialized (ready to load models on demand) ---")

    def _load_categories(self):
        """โหลดข้อมูล category ทั้งหมดจาก DB มาทำเป็น map {name: id}"""
        try:
            conn = mysql.connector.connect(**db_config)
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT category_id, category_name FROM category")
            categories = cursor.fetchall()
            cursor.close()
            conn.close()
            # สร้าง map โดยแปลงชื่อเป็นตัวเล็กเพื่อการค้นหาที่ง่ายขึ้น
            return {cat['category_name'].lower(): cat['category_id'] for cat in categories}
        except Exception as e:
            print(f"[ERROR] Could not load categories from DB: {e}")
            return {}

    def _get_ml_model(self, user_id):
        """
        ฟังก์ชันภายในสำหรับจัดการการโหลดโมเดล ML แบบไดนามิกพร้อม Cache
        """
        # 1. เช็คใน Cache ก่อน
        if user_id in self.models_cache:
            print(f"Model for user_id={user_id} found in cache.")
            return self.models_cache[user_id]

        # 2. ถ้าไม่มีใน Cache, ลองโหลดไฟล์โมเดลส่วนตัว
        # เรายังต้องหา Path ของโปรเจกต์ ML เพื่อโหลดไฟล์ .joblib
        # แต่เราไม่จำเป็นต้องแก้ sys.path อีกแล้ว
        # โค้ดส่วนนี้ยังทำงานได้ถูกต้อง
        ml_project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'model', 'CategoryPredictorML'))
        models_dir = os.path.join(ml_project_root, 'models')
        model_path = os.path.join(models_dir, f"model_user_{user_id}.joblib")
        print(f"Attempting to load personal model: {model_path}")
        
        loaded_model = CategoryPredictorML.load_model(model_path)
        if loaded_model:
            print(f"Personal model for user_id={user_id} loaded and cached.")
            self.models_cache[user_id] = loaded_model
            return loaded_model

        # 3. ถ้าไม่มีโมเดลส่วนตัว, ลองโหลด "โมเดลกลาง" (Global Model)
        # (ในอนาคต คุณอาจสร้างไฟล์นี้โดยเทรนจากข้อมูลผู้ใช้หลายๆ คน)
        global_model_path = os.path.join(models_dir, "model_global.joblib")
        print(f"Personal model not found. Attempting to load global model: {global_model_path}")

        # เช็คใน cache ก่อนว่าเคยโหลด global model ไปหรือยัง
        if 'global' in self.models_cache:
            print("Global model found in cache.")
            return self.models_cache['global']

        loaded_global_model = CategoryPredictorML.load_model(global_model_path)
        if loaded_global_model:
            print("Global model loaded and cached.")
            self.models_cache['global'] = loaded_global_model
            return loaded_global_model

        # 4. ถ้าไม่มีโมเดลใดๆ เลย
        print("[Warning] No personal or global ML model found.")
        return None

    def predict_category(self, user_id, transaction_data):
        """
        รับ user_id และข้อมูลธุรกรรม (dict) และทำนายผลแบบ Hybrid
        """
        # Layer 1: ลอง Rule-Based ก่อน
        print("L1 (Rule-Based) attempt...")
        rule_result = self.rule_based_model.predict(transaction_data)

        if not rule_result['need_ml']:
            print(f"L1 (Rule-Based) SUCCESS: Keyword matched. Category: {rule_result['predicted_category_name']}")
            # --- [THE FIX] ---
            # ค้นหา ID จากชื่อที่ทำนายได้
            predicted_name = rule_result.get('predicted_category_name')
            if predicted_name:
                category_id = self.category_map.get(predicted_name.lower())
                if category_id:
                    rule_result['predicted_category_id'] = category_id
                    print(f"Found category_id: {category_id} for name: '{predicted_name}'")
                else:
                    print(f"[Warning] Rule-based predicted a category ('{predicted_name}') not found in DB.")
            return rule_result
        
        # Layer 2: ถ้า L1 ล้มเหลว, ส่งต่อให้ ML
        print("L1 FAILED. Attempting to use L2 (ML)...")
        # --- [THE FIX] ---
        # แปลงผลลัพธ์จาก ML ให้อยู่ในรูปแบบที่ Frontend ต้องการ

        # --- [REFACTORED] ---
        # เรียกใช้ฟังก์ชันเพื่อหาโมเดลที่เหมาะสมสำหรับ user คนนี้
        ml_model = self._get_ml_model(user_id)

        # ถ้าไม่มีโมเดลใดๆ เลย (ทั้งส่วนตัวและส่วนกลาง)
        if ml_model is None:
            print("L2 FAILED: No ML model available for this user.")
            # คืนค่าพิเศษเพื่อให้ Frontend รู้ว่าต้องให้ผู้ใช้เลือกเอง (ไม่มีการเปลี่ยนแปลง)
            return {'predicted_category': None, 'confidence': 0.0, 'method': 'no_model_available', 'need_manual_input': True}

        print("L2 (ML) model found. Proceeding with prediction...")
        try:
            # เพิ่ม transaction_date ถ้ายังไม่มี
            if 'transaction_date' not in transaction_data:
                transaction_data['transaction_date'] = datetime.now()

            sample_df = pd.DataFrame([transaction_data])
            sample_df = engineer_features(sample_df) # สร้าง hour, day_of_week
            
            ml_predictions = ml_model.predict_proba(sample_df)
            raw_prediction = ml_predictions[0] # ผลลัพธ์ดิบจากโมเดล

            predicted_name = raw_prediction.get('predicted_category')
            category_id = None
            if predicted_name:
                category_id = self.category_map.get(predicted_name.lower())

            # สร้าง dict ผลลัพธ์ใหม่ตาม format ที่ต้องการ
            final_result = {
                'predicted_category_id': category_id,
                'predicted_category_name': predicted_name,
                'confidence': raw_prediction.get('confidence', 0.0),
                'method': 'ml_lgbm' # ระบุว่าเป็น ML
            }
            return final_result
        except Exception as e:
            print(f"[ERROR] L2 (ML) prediction failed: {e}")
            return {'error': f"ML prediction failed: {e}"}

# สร้าง instance ของ Service ไว้เลยเพื่อให้โหลดโมเดลรอ
prediction_service = PredictionService()