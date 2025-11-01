import pandas as pd
from datetime import datetime
import os

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
        self.rule_based_model = RuleBasedPredictor()
        print("--- PredictionService initialized (ready to load models on demand) ---")

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
            print("L1 (Rule-Based) SUCCESS: Keyword matched.")
            return rule_result
        
        # Layer 2: ถ้า L1 ล้มเหลว, ส่งต่อให้ ML
        print("L1 FAILED. Attempting to use L2 (ML)...")

        # --- [REFACTORED] ---
        # เรียกใช้ฟังก์ชันเพื่อหาโมเดลที่เหมาะสมสำหรับ user คนนี้
        ml_model = self._get_ml_model(user_id)

        # ถ้าไม่มีโมเดลใดๆ เลย (ทั้งส่วนตัวและส่วนกลาง)
        if ml_model is None:
            print("L2 FAILED: No ML model available for this user.")
            # คืนค่าพิเศษเพื่อให้ Frontend รู้ว่าต้องให้ผู้ใช้เลือกเอง
            return {'predicted_category': None, 'confidence': 0.0, 'method': 'no_model_available', 'need_manual_input': True}

        print("L2 (ML) model found. Proceeding with prediction...")
        try:
            # เพิ่ม transaction_date ถ้ายังไม่มี
            if 'transaction_date' not in transaction_data:
                transaction_data['transaction_date'] = datetime.now()

            sample_df = pd.DataFrame([transaction_data])
            sample_df = engineer_features(sample_df) # สร้าง hour, day_of_week
            
            ml_predictions = ml_model.predict_proba(sample_df)
            return ml_predictions[0] # คืนค่าผลลัพธ์ของแถวแรก
        except Exception as e:
            print(f"[ERROR] L2 (ML) prediction failed: {e}")
            return {'error': f"ML prediction failed: {e}"}, 500

# สร้าง instance ของ Service ไว้เลยเพื่อให้โหลดโมเดลรอ
prediction_service = PredictionService()