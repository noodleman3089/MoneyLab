# train_global_model.py

import pandas as pd
import os

# Import คลาสและฟังก์ชันที่เราสร้าง
from category_predictor.model import CategoryPredictorML
from app.data_loader import fetch_global_training_data # <-- ใช้ฟังก์ชันใหม่
from app.feature_engineering import engineer_features

# --- 1. กำหนดค่าคงที่และ Features (เหมือนกับ train_model.py) ---
NUMERIC_FEATURES = [
    'amount', 'fee', 'net_amount', 
    'transaction_hour', 'transaction_day_of_week', 'transaction_day_of_month', 'transaction_is_weekend'
]
CATEGORICAL_FEATURES = ['payment_source', 'type']
TEXT_FEATURES_MAP = {
    'receiver_name': 50,
    'sender_name': 30
}

# --- 2. ดึงข้อมูลและทำ Feature Engineering ---
# ดึงข้อมูลจากผู้ใช้ทุกคนที่มีธุรกรรมอย่างน้อย 50 รายการ
all_data = fetch_global_training_data(min_transactions_per_user=50)

if not all_data.empty:
    print(f"Global data fetched successfully: {len(all_data)} rows")

    all_data = engineer_features(all_data)
    for col in TEXT_FEATURES_MAP.keys():
        all_data[col] = all_data[col].fillna('')

    # --- 3. เตรียมข้อมูลสำหรับ Train ---
    # ไม่จำเป็นต้องทำ Cross-Validation ที่ซับซ้อนสำหรับโมเดลกลาง
    X = all_data.drop(['category_name', 'category_id'], axis=1, errors='ignore')
    y = all_data['category_name']

    # --- 4. สร้างและฝึกโมเดล ---
    global_model = CategoryPredictorML(
        numeric_features=NUMERIC_FEATURES,
        categorical_features=CATEGORICAL_FEATURES,
        text_features_map=TEXT_FEATURES_MAP
    )

    print("\nTraining global model on all fetched data...")
    global_model.train(X, y)
    
    # --- 5. บันทึกโมเดลด้วยชื่อเฉพาะ ---
    # --- [FIX] ระบุโฟลเดอร์ที่จะบันทึก ---
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    MODELS_DIR = os.path.join(project_root, 'models')
    os.makedirs(MODELS_DIR, exist_ok=True) # สร้างโฟลเดอร์ถ้ายังไม่มี

    model_filename = "model_global.joblib"
    global_model.save_model(os.path.join(MODELS_DIR, model_filename))
else:
    print("No sufficient global data found to train the model.")