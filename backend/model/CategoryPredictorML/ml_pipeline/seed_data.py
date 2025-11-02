# seed_data.py
import pandas as pd
import random
from faker import Faker
from datetime import datetime, timedelta
import app.data_loader as data_loader # Import module ที่เราสร้างไว้

# --- การตั้งค่า ---
USER_ID_TO_SEED = 1      # เราจะสร้างข้อมูลให้ User ID นี้
TOTAL_TRANSACTIONS = 1000 # จำนวนธุรกรรมทั้งหมดที่จะสร้าง
# --------------------

# 1. เริ่มต้น Faker (ใช้ภาษาไทย)
fake = Faker("th_TH")

def fetch_lookup_data(connection):
    """
    ดึงข้อมูลจำเป็น (User และ Category) จาก DB จริง
    """
    print("Fetching lookup data (categories and users)...")
    
    # 1. ดึง Categories
    # เราดึงมาทั้งหมดเพื่อใช้ในการจับคู่ ID, Name, Type
    try:
        categories_df = pd.read_sql("SELECT * FROM category", connection)
        if categories_df.empty:
            print("[ERROR] 'category' table is empty. Cannot seed data.")
            return None, None
            
        # 2. ตรวจสอบ User (ใช้ User ID ที่กำหนด)
        user_df = pd.read_sql("SELECT user_id FROM users WHERE user_id = %s", connection, params=(USER_ID_TO_SEED,))
        if user_df.empty:
            print(f"[ERROR] User with user_id={USER_ID_TO_SEED} not found.")
            return None, None
        
        print("Lookup data fetched successfully.")
        return categories_df, USER_ID_TO_SEED
        
    except Exception as e:
        print(f"[ERROR] Failed to fetch lookup data: {e}")
        return None, None

def get_category_info(categories_df, name_prefix, c_type):
    """
    Helper: ค้นหา category จาก DataFrame
    """
    try:
        # ค้นหาชื่อที่ขึ้นต้นด้วย...
        row = categories_df[
            (categories_df['category_name'].str.startswith(name_prefix)) &
            (categories_df['category_type'] == c_type)
        ].iloc[0]
        return row['category_id'], row['category_name']
    except IndexError:
        print(f"[Warning] Category matching '{name_prefix}' ({c_type}) not found. Skipping.")
        return None, None

def generate_mock_transactions(categories_df, user_id, num_transactions):
    """
    สร้าง List ของข้อมูลธุรกรรมตาม Scenarios
    """
    transactions = []
    print(f"Generating {num_transactions} mock transactions...")

    # --- สร้าง "บุคคล" ที่จะใช้ซ้ำๆ ---
    receiver_food_person = fake.name()
    receiver_rent_person = fake.name()
    receiver_family_person = f"คุณแม่ {fake.first_name()}"
    sender_company = fake.company()

    # ==================================================================
    # ▼▼▼ [REFACTORED] สร้างฟังก์ชัน Generator สำหรับแต่ละ Scenario ▼▼▼
    # ==================================================================

    def gen_food_lunch():
        cat_id, _ = get_category_info(categories_df, 'อาหาร/เครื่องดื่ม', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(50, 150), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None).replace(hour=random.randint(11, 13)),
            'receiver_name': random.choice([receiver_food_person, "ร้านป้าพรตามสั่ง", "ร้านก๋วยเตี๋ยวลุงชัย"]),
            'sender_name': None,
            'payment_source': random.choice(['PromptPay', 'Bank', 'TrueMoney']),
        }

    def gen_food_dinner_delivery():
        cat_id, _ = get_category_info(categories_df, 'อาหาร/เครื่องดื่ม', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(120, 400), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None).replace(hour=random.randint(17, 20)),
            'receiver_name': fake.company(), # ชื่อร้านอาหาร
            'sender_name': random.choice(["GrabFood", "LINE MAN", "Robinhood"]),
            'payment_source': random.choice(['GrabPay', 'Credit Card', 'Rabbit LINE Pay']),
        }

    def gen_coffee_shop():
        cat_id, _ = get_category_info(categories_df, 'อาหาร/เครื่องดื่ม', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(60, 120), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None),
            'receiver_name': random.choice(["Starbucks", "Amazon Cafe", "Inthanin", "ร้านกาแฟแถวบ้าน"]),
            'sender_name': None,
            'payment_source': random.choice(['TrueMoney', 'Credit Card', 'ShopeePay']),
        }

    def gen_convenience_store():
        cat_id, _ = get_category_info(categories_df, 'ไลฟ์สไตล์/บันเทิง', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(45, 300), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None),
            'receiver_name': "7-Eleven", # Keyword ชัดเจน
            'sender_name': None,
            'payment_source': 'TrueMoney',
        }

    def gen_salary():
        cat_id, _ = get_category_info(categories_df, 'รายรับประจำ', 'income')
        if not cat_id: return None
        random_date = fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None)
        first_day_of_next_month = (random_date.replace(day=1) + timedelta(days=32)).replace(day=1)
        end_of_month_date = first_day_of_next_month - timedelta(days=random.randint(1, 4))
        return {
            'category_id': cat_id, 'type': 'income',
            'amount': round(random.uniform(25000, 45000), 2),
            'transaction_date': end_of_month_date,
            'receiver_name': None,
            'sender_name': sender_company,
            'payment_source': random.choice(['Bank', 'Payroll']),
        }

    def gen_rent():
        cat_id, _ = get_category_info(categories_df, 'ที่อยู่อาศัย', 'expense')
        if not cat_id: return None
        random_date = fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None)
        first_day_of_next_month = (random_date.replace(day=1) + timedelta(days=32)).replace(day=1)
        end_of_month_date = first_day_of_next_month - timedelta(days=random.randint(1, 3))
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(4000, 8000), 2),
            'transaction_date': end_of_month_date,
            'receiver_name': receiver_rent_person,
            'sender_name': None,
            'payment_source': random.choice(['Bank', 'PromptPay']),
        }

    def gen_family_support():
        cat_id, _ = get_category_info(categories_df, 'ให้เงินครอบครัว', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(1000, 5000), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None),
            'receiver_name': receiver_family_person,
            'sender_name': None,
            'payment_source': random.choice(['Bank', 'PromptPay']),
        }

    def gen_transport():
        cat_id, _ = get_category_info(categories_df, 'การเดินทาง', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(45, 500), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None),
            'receiver_name': random.choice(["BTS", "MRT", "Bolt", "วินมอเตอร์ไซค์", "ทางด่วน"]),
            'sender_name': None,
            'payment_source': random.choice(['Rabbit LINE Pay', 'TrueMoney', 'PromptPay', 'Easy Pass']),
        }

    def gen_subscriptions():
        cat_id, _ = get_category_info(categories_df, 'ไลฟ์สไตล์/บันเทิง', 'expense')
        if not cat_id: return None
        sub = random.choice([
            ("Netflix", 169.0), ("Spotify", 129.0), ("YouTube Premium", 159.0)
        ])
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': sub[1],
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None),
            'receiver_name': sub[0],
            'sender_name': None,
            'payment_source': 'Credit Card',
        }

    def gen_ecommerce():
        cat_id, _ = get_category_info(categories_df, 'ไลฟ์สไตล์/บันเทิง', 'expense')
        if not cat_id: return None
        return {
            'category_id': cat_id, 'type': 'expense',
            'amount': round(random.uniform(100, 2500), 2),
            'transaction_date': fake.date_time_between(start_date='-1y', end_date='now', tzinfo=None),
            'receiver_name': random.choice(["Shopee", "Lazada", "Tiktok Shop"]),
            'sender_name': None,
            'payment_source': random.choice(['Credit Card', 'ShopeePay', 'Bank']),
        }

    # --- List ของ Generators ทั้งหมด ---
    scenario_generators = [
        gen_food_lunch, gen_food_dinner_delivery, gen_coffee_shop,
        gen_convenience_store, gen_salary, gen_rent, gen_family_support,
        gen_transport, gen_subscriptions, gen_ecommerce
    ]

    for _ in range(num_transactions):
        # สุ่มเลือก 1 generator จาก list แล้วเรียกใช้งาน
        generator = random.choice(scenario_generators)
        tx_data = generator()
        
        if tx_data:
            # เพิ่ม fields ที่ต้องมีเสมอ
            tx_data['user_id'] = user_id
            tx_data['data_source'] = 'manual' # สมมติว่าป้อนเอง
            tx_data['fee'] = tx_data.get('fee', 0.0)
            transactions.append(tx_data)
            
    return transactions

def insert_data_to_db(connection, transactions):
    """
    บันทึกข้อมูลลง DB ทีละเยอะๆ (executemany)
    """
    if not transactions:
        print("No transactions to insert.")
        return

    print(f"Preparing to insert {len(transactions)} rows...")
    cursor = connection.cursor()
    
    # --- [สำคัญ] ---
    # 1. เรียงคอลัมน์ให้ตรงกับ query
    # 2. ห้ามมี `transaction_id` (auto-increment)
    # 3. ห้ามมี `net_amount` (stored column)
    # 4. ห้ามมีคอลัมน์ที่ auto-default เช่น created_at
    
    query = """
    INSERT INTO transactions
    (user_id, wallet_id, category_id, type, amount, fee, 
     transaction_date, sender_name, receiver_name, 
     payment_source, data_source)
    VALUES
    (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    # แปลง List of Dicts เป็น List of Tuples
    data_tuples = []
    for tx in transactions:
        data_tuples.append((
            int(tx['user_id']), # <-- [FIX] แปลงเป็น Python int
            None, # wallet_id (สมมติเป็น null)
            int(tx['category_id']), # <-- [FIX] แปลงเป็น Python int
            tx['type'],
            float(tx['amount']), # <-- [FIX] แปลงเป็น Python float
            float(tx['fee']), # <-- [FIX] แปลงเป็น Python float
            tx['transaction_date'],
            tx.get('sender_name', None),
            tx.get('receiver_name', None),
            tx.get('payment_source', None),
            tx.get('data_source', 'manual')
        ))

    try:
        # 3. รัน Query
        cursor.executemany(query, data_tuples)
        connection.commit()
        print(f"Successfully inserted {cursor.rowcount} rows.")
        
    except Exception as e:
        print(f"[ERROR] Failed to insert data: {e}")
        connection.rollback()
    finally:
        cursor.close()

# --- Main script ---
def main():
    print("--- Starting Data Seeder ---")
    connection = data_loader.get_db_connection()
    if connection is None:
        return

    categories_df, user_id = fetch_lookup_data(connection)
    
    if categories_df is not None and user_id is not None:
        mock_data = generate_mock_transactions(categories_df, user_id, TOTAL_TRANSACTIONS)
        insert_data_to_db(connection, mock_data)

    if connection and connection.is_connected():
        connection.close()
        print("MySQL connection closed.")
    print("--- Seeding complete ---")

if __name__ == "__main__":
    main()