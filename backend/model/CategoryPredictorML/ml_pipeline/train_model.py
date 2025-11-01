# train_model.py

import pandas as pd
from sklearn.model_selection import TimeSeriesSplit
import os

# Import คลาสและฟังก์ชันที่เราสร้าง
from category_predictor.model import CategoryPredictorML # <-- แก้ไข Path ที่ถูกต้อง
from app.data_loader import fetch_training_data
from app.feature_engineering import engineer_features # <-- 1. Import ฟังก์ชัน

# --- 1. กำหนดค่าคงที่และ Features ---
USER_ID_TO_TRAIN = 1

# --- [THE FIX] กำหนดรายชื่อ Features ให้ครบถ้วน ---
NUMERIC_FEATURES = [
    'amount', 'fee', 'net_amount', 
    'transaction_hour', 'transaction_day_of_week', 'transaction_day_of_month', 'transaction_is_weekend'
]
CATEGORICAL_FEATURES = ['payment_source', 'type']
TEXT_FEATURES_MAP = {
    'receiver_name': 50, # ลด max_features ลงเพื่อความเร็ว
    'sender_name': 30
}

# --- 2. ดึงข้อมูลและทำ Feature Engineering ---
all_data = fetch_training_data(USER_ID_TO_TRAIN)

if not all_data.empty:
    print(f"Data fetched successfully: {len(all_data)} rows")

    # --- [ใหม่] 3. ทำความสะอาดข้อมูลจริง (Data Cleaning) ---
    # ลบรายการที่มี amount เป็น 0 หรือติดลบ (ถ้ามี)
    all_data = all_data[all_data['amount'] > 0]

    # ลบรายการที่ไม่มี receiver_name (ซึ่งสำคัญต่อการทำนาย)
    all_data = all_data.dropna(subset=['receiver_name'])
    all_data = all_data[all_data['receiver_name'].str.strip() != '']
    print(f"Data after cleaning: {len(all_data)} rows")

    all_data = engineer_features(all_data) # <-- 2. เรียกใช้ฟังก์ชันเดียวจบ
    # จัดการค่า Null ในคอลัมน์ Text (สำคัญมากสำหรับ TfidfVectorizer)
    for col in TEXT_FEATURES_MAP.keys():
        all_data[col] = all_data[col].fillna('')


    # --- 4. เตรียมข้อมูลสำหรับ Train ---
    X = all_data.drop('category_name', axis=1) 
    y = all_data['category_name']

    # --- 5. สร้าง Model ---
    ml_model = CategoryPredictorML(
        numeric_features=NUMERIC_FEATURES,
        categorical_features=CATEGORICAL_FEATURES,
        text_features_map=TEXT_FEATURES_MAP
    )

    # --- 6. ประเมินผลด้วย Time Series Cross-Validation ---
    print("\n--- Starting Time Series Cross-Validation ---")
    # แบ่งข้อมูลเป็น 5 ส่วน (folds) ตามลำดับเวลา
    # fold แรก: train 1/5, test 1/5
    # fold สอง: train 2/5, test 1/5
    # ...
    tscv = TimeSeriesSplit(n_splits=5)
    f1_scores = []

    for i, (train_index, test_index) in enumerate(tscv.split(X)):
        print(f"\n[Fold {i+1}/5]")
        X_train, X_test = X.iloc[train_index], X.iloc[test_index]
        y_train, y_test = y.iloc[train_index], y.iloc[test_index]
        
        print(f"Train size: {len(X_train)}, Test size: {len(X_test)}")
        
        # Train และ Evaluate ในแต่ละ fold
        ml_model.train(X_train, y_train)
        f1 = ml_model.evaluate(X_test, y_test)
        f1_scores.append(f1)

    print("\n--- Cross-Validation Summary ---")
    print(f"F1 Scores for each fold: {[round(f, 4) for f in f1_scores]}")
    print(f"Average F1-Score (Macro): {sum(f1_scores) / len(f1_scores):.4f}")

    # --- 7. Train final model ด้วยข้อมูลทั้งหมด และ Save ---
    print("\nTraining final model on all data...")
    
    # --- [FIX] ระบุโฟลเดอร์ที่จะบันทึก ---
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    MODELS_DIR = os.path.join(project_root, 'models')
    os.makedirs(MODELS_DIR, exist_ok=True) # สร้างโฟลเดอร์ถ้ายังไม่มี
    
    ml_model.train(X, y)
    model_filename = f"model_user_{USER_ID_TO_TRAIN}.joblib"
    ml_model.save_model(os.path.join(MODELS_DIR, model_filename))
else:
    print("No data found to train the model.")