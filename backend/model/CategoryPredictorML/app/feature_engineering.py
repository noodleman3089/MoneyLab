# feature_engineering.py
import pandas as pd

def engineer_features(df):
    """
    สร้าง Features ใหม่ (เช่น hour, day_of_week) 
    จากคอลัมน์ transaction_date
    """
    
    # 1. ตรวจสอบว่าคอลัมน์ transaction_date มีอยู่จริง
    if 'transaction_date' not in df.columns:
        print("[Warning] 'transaction_date' column not found in DataFrame. Skipping time features.")
        return df

    # 2. แปลงเป็น Datetime (สำคัญมาก!)
    # errors='coerce' จะเปลี่ยนค่าที่ผิดพลาด (เช่น สตริงว่าง) เป็น NaT (Not a Time)
    df['transaction_date'] = pd.to_datetime(df['transaction_date'], errors='coerce')

    # 3. สกัด Features ใหม่
    df['transaction_hour'] = df['transaction_date'].dt.hour
    df['transaction_day_of_week'] = df['transaction_date'].dt.dayofweek # (Mon=0, Sun=6)
    df['transaction_day_of_month'] = df['transaction_date'].dt.day
    df['transaction_is_weekend'] = df['transaction_day_of_week'].isin([5, 6]).astype(int)
    
    # 4. เติมค่าว่าง (NaN) ที่เกิดจากการสกัด (เช่น ถ้า transaction_date เป็น NaT)
    # เราเติม 0 (ค่ากลาง) ให้มัน
    num_cols_to_fill = ['transaction_hour', 'transaction_day_of_week', 'transaction_day_of_month', 'transaction_is_weekend']
    for col in num_cols_to_fill:
        if col in df.columns:
            # เติม 0 ถ้าเป็น NaN (เช่น สกัดจาก NaT ไม่ได้) แล้วแปลงเป็น int
            df[col] = df[col].fillna(0).astype(int) 

    return df