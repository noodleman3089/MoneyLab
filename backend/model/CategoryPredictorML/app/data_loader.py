# data_loader.py

import os
import mysql.connector
import pandas as pd
from mysql.connector import Error
from dotenv import load_dotenv

def get_db_connection():
    """
    อ่านค่าจาก .env และสร้างการเชื่อมต่อ MySQL (เหมือนเดิม)
    """
    load_dotenv()
    
    host = os.getenv('DB_HOST')
    port = os.getenv('DB_PORT')
    user = os.getenv('DB_USER')
    password = os.getenv('DB_PASSWORD')
    database = os.getenv('DB_NAME')
    
    try:
        connection = mysql.connector.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )
        if connection.is_connected():
            print(f"Successfully connected to database: {database}")
            return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def fetch_training_data(user_id):
    """
    ดึงข้อมูลสำหรับ Train Model (ปรับปรุง Query ให้ JOIN กับตาราง category)
    """
    connection = get_db_connection()
    if connection is None:
        return pd.DataFrame()
        
    # <-- [UPDATED] Query ที่มีประสิทธิภาพและถูกต้องตาม schema ใหม่
    # 1. JOIN ตาราง transactions กับ category
    # 2. เลือก c.category_name มาเป็น target
    # 3. กรองหมวดที่ไม่ต้องการ train ออกโดยใช้ชื่อ (เช่น 'รายรับเบ็ดเตล็ด')
    # 4. เปลี่ยนชื่อตารางเป็น transactions (มี s)
    # 5. [ใหม่] ดึงเฉพาะข้อมูลที่ผู้ใช้ยืนยันแล้ว (manual, ocr)
    query = """
    SELECT 
        t.*, 
        c.category_name
    FROM 
        transactions t
    JOIN 
        category c ON t.category_id = c.category_id
    WHERE 
        t.user_id = %s
        AND t.category_id IS NOT NULL
        AND t.data_source IN ('manual', 'ocr') -- ดึงเฉพาะข้อมูลที่เชื่อถือได้
        AND c.category_name NOT IN ('รายรับเบ็ดเตล็ด', 'ยังไม่ได้ระบุ', 'โอนเงิน') -- กรองหมวดหมู่ที่ไม่ต้องการสอน
    ORDER BY 
        t.transaction_date ASC;
    """
    
    try:
        print(f"Fetching data for user_id={user_id}...")
        df = pd.read_sql(query, connection, params=(user_id,))
        # <-- [UPDATED] ลบคอลัมน์ที่ไม่จำเป็นสำหรับการ train ออก (หลังจากตรวจสอบว่าไม่ว่าง)
        if not df.empty:
            df = df.drop(columns=['category_id'])
        return df
        
    except Error as e:
        print(f"Error fetching data: {e}")
        return pd.DataFrame()
        
    finally:
        if connection and connection.is_connected():
            connection.close()
            print("MySQL connection is closed.")

def fetch_global_training_data(min_transactions_per_user=50):
    """
    ดึงข้อมูลจากผู้ใช้ "ทุกคน" เพื่อใช้เทรนโมเดลกลาง (Global Model)
    """
    connection = get_db_connection()
    if connection is None:
        return pd.DataFrame()

    # Query นี้จะดึงข้อมูลจากผู้ใช้ทุกคนที่มีธุรกรรมมากกว่า `min_transactions_per_user`
    # เพื่อกรองผู้ใช้ที่ยังไม่มีข้อมูลคุณภาพดีพอออกไป
    query = """
    SELECT 
        t.*, 
        c.category_name
    FROM 
        transactions t
    JOIN 
        category c ON t.category_id = c.category_id
    WHERE 
        t.user_id IN (SELECT user_id FROM transactions GROUP BY user_id HAVING COUNT(*) >= %s)
        AND t.category_id IS NOT NULL
        AND c.category_name NOT IN ('รายรับเบ็ดเตล็ด');
    """
    try:
        print(f"Fetching global data (users with >={min_transactions_per_user} tx)...")
        df = pd.read_sql(query, connection, params=(min_transactions_per_user,))
        return df
    except Error as e:
        print(f"Error fetching global data: {e}")
        return pd.DataFrame()
    finally:
        if connection and connection.is_connected():
            connection.close()
            print("MySQL connection for global data is closed.")