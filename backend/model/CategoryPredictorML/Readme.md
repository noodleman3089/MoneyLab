# Category Predictor API

โปรเจกต์นี้คือระบบ API สำหรับทำนายหมวดหมู่ของธุรกรรมทางการเงินโดยอัตโนมัติ โดยใช้สถาปัตยกรรมแบบผสม (Hybrid) ที่รวมระหว่างการใช้กฎ (Rule-Based) และ Machine Learning (LightGBM) เพื่อให้ได้ทั้งความเร็ว, ความแม่นยำ, และความเป็นส่วนตัว (Personalization)

## ✨ คุณสมบัติหลัก (Features)

- **Hybrid Prediction Model**: ใช้ `RuleBasedPredictor` สำหรับเคสที่ตรงไปตรงมา (เช่น ชื่อร้านค้าชัดเจน) เพื่อความรวดเร็ว และส่งต่อให้ `CategoryPredictorML` จัดการกับเคสที่ซับซ้อน
- **Dynamic Model Loading**: ระบบสามารถโหลดโมเดลที่เหมาะสมกับผู้ใช้ได้โดยอัตโนมัติ:
  - **Personal Model**: ใช้โมเดลที่ฝึกจากข้อมูลของผู้ใช้คนนั้นๆ เพื่อความแม่นยำสูงสุด
  - **Global Model**: หากเป็นผู้ใช้ใหม่ที่ยังไม่มีโมเดลส่วนตัว ระบบจะใช้ "โมเดลกลาง" เป็นค่าเริ่มต้น
- **RESTful API**: ให้บริการผ่าน Flask API ทำให้ง่ายต่อการเชื่อมต่อกับ Frontend หรือ Service อื่นๆ
- **Clean Architecture**: โครงสร้างฝั่ง Backend แยกส่วน `Controller` (จัดการ Request/Response) และ `Service` (จัดการ Business Logic) ออกจากกันอย่างชัดเจน
- **Complete ML Pipeline**: มีสคริปต์สำหรับการสร้างข้อมูลจำลอง (`seed_data.py`), ฝึกโมเดลส่วนตัว (`train_model.py`), และฝึกโมเดลกลาง (`train_global_model.py`)

---

## 📂 โครงสร้างโปรเจกต์ (Project Structure)

```
CategoryPredictorML/
├── app/
│   ├── data_loader.py         # โค้ดสำหรับเชื่อมต่อและดึงข้อมูลจาก DB
│   ├── feature_engineering.py # ฟังก์ชันกลางสำหรับสร้าง Features
│   ├── main_predictor.py      # Logic หลักของ Hybrid Predictor
│   └── rule_based_predictor.py  # Predictor ชั้นที่ 1 (ใช้กฎ)
│
├── category_predictor/
│   ├── __init__.py
│   ├── model.py               # คลาส CategoryPredictorML (แกนหลักของ ML)
│   ├── persistence.py         # ฟังก์ชันสำหรับ Save/Load โมเดล
│   └── preprocess.py          # โค้ดสำหรับสร้าง Preprocessor
│
├── db_schema/
│   └── moneylab_newV.sql      # Schema ของฐานข้อมูล
│
├── ml_pipeline/
│   ├── seed_data.py           # สคริปต์สำหรับสร้างข้อมูลจำลอง
│   └── train_model.py         # สคริปต์สำหรับฝึกและบันทึกโมเดล
│
├── test_prediction.py         # สคริปต์สำหรับทดสอบโมเดลที่บันทึกไว้
├── .env                       # ไฟล์เก็บค่า Environment (สร้างเอง)
└── requirements.txt           # รายชื่อ Dependencies (สร้างเอง)
```

---

## 🚀 การติดตั้งและตั้งค่า (Setup and Installation)

### สิ่งที่ต้องมี (Prerequisites)
- Python 3.9+
- MySQL Server

### ขั้นตอนการติดตั้ง

1.  **Clone Repository**
    ```bash
    git clone <your-repository-url>
    cd CategoryPredictorML
    ```

2.  **ตั้งค่าฐานข้อมูล (Database Setup)**
    - สร้างฐานข้อมูล (Schema) ใน MySQL ของคุณชื่อ `moneylab`
    - รันสคริปต์ `db_schema/moneylab_newV.sql` เพื่อสร้างตารางทั้งหมด
    - **(สำคัญ)** เพิ่มข้อมูลผู้ใช้อย่างน้อย 1 คนในตาราง `users` เพื่อให้ `user_id = 1` มีอยู่จริง
      ```sql
      INSERT INTO users (username, email) VALUES ('testuser', 'test@example.com');
      ```

3.  **สร้าง Virtual Environment** (แนะนำ)
    ```bash
    python -m venv venv
    ```
    - **Windows**: `venv\Scripts\activate`
    - **macOS/Linux**: `source venv/bin/activate`

4.  **ติดตั้ง Dependencies**
    - สร้างไฟล์ `requirements.txt` และใส่เนื้อหาข้างล่างนี้:
      ```
      pandas
      scikit-learn
      lightgbm
      faker
      mysql-connector-python
      python-dotenv
      ```
    - รันคำสั่งติดตั้ง:
      ```bash
      pip install -r requirements.txt
      ```

5.  **ตั้งค่า Environment Variables**
    - สร้างไฟล์ชื่อ `.env` ในโฟลเดอร์รากของโปรเจกต์
    - ใส่ข้อมูลการเชื่อมต่อฐานข้อมูลของคุณตามรูปแบบนี้:
      ```env
      DB_HOST=localhost
      DB_PORT=3306
      DB_USER=your_db_user
      DB_PASSWORD=your_db_password
      DB_NAME=moneylab
      ```

---

## 🛠️ วิธีการใช้งาน (How to Use)

ทำตามขั้นตอนเรียงลำดับดังนี้:

### 1. สร้างข้อมูลจำลอง (Seed Data)

สคริปต์นี้จะสร้างข้อมูลธุรกรรมจำลองจำนวน 1,000 รายการสำหรับ `user_id = 1` และบันทึกลงในฐานข้อมูล

> **Note:** หากต้องการรันซ้ำ ควรลบข้อมูลเก่าในตาราง `transactions` ของ user นั้นๆ ก่อน เพื่อป้องกันข้อมูลซ้ำซ้อน
> `DELETE FROM transactions WHERE user_id = 1;`

รันคำสั่ง:
```bash
python ml_pipeline/seed_data.py
```

### 2. ฝึกโมเดล (Train Model)

สคริปต์นี้จะดึงข้อมูลที่สร้างไว้จากฐานข้อมูล, ทำ Feature Engineering, ประเมินผลด้วย `TimeSeriesSplit`, และสุดท้ายคือฝึกโมเดลด้วยข้อมูลทั้งหมดแล้วบันทึกเป็นไฟล์ `.joblib`

รันคำสั่ง:
```bash
python ml_pipeline/train_model.py
```

หลังจากรันเสร็จ คุณจะได้ไฟล์ `model_user_1.joblib` ซึ่งเป็นโมเดลที่พร้อมใช้งาน

### 3. ทดสอบการทำนายผล (Test Prediction)

คุณสามารถทดสอบการทำงานของโมเดลที่บันทึกไว้ได้โดยตรงด้วยสคริปต์ `test_prediction.py`

- เปิดไฟล์ `test_prediction.py` และแก้ไขข้อมูลใน `sample_data_list` เพื่อทดสอบกับเคสต่างๆ ที่คุณสนใจ
- รันคำสั่ง:
  ```bash
  python test_prediction.py
  ```
  ผลลัพธ์การทำนายจะแสดงออกมาในรูปแบบ JSON

### 4. ทดสอบ Hybrid Predictor

สคริปต์ `app/main_predictor.py` เป็นตัวอย่างการจำลองการทำงานของระบบ Hybrid ทั้ง 2 ชั้น (Rule-Based + ML)

- เปิดไฟล์ `app/main_predictor.py` และแก้ไข `sample_raw_data`
- รันคำสั่ง:
  ```bash
  python app/main_predictor.py
  ```
  คุณจะเห็น Log การทำงานว่าเคสนั้นๆ ถูกจัดการโดย Layer ใด (L1 หรือ L2)

```

**วิธีนำไปใช้:**

1.  สร้างไฟล์ใหม่ในโฟลเดอร์รากของโปรเจกต์ชื่อ `README.md`
2.  คัดลอกเนื้อหาทั้งหมดจากโค้ดบล็อกด้านบนไปวางในไฟล์ `README.md` ที่เพิ่งสร้าง
3.  บันทึกไฟล์

เพียงเท่านี้ เพื่อนของคุณก็จะได้รับคู่มือการใช้งานโปรเจกต์ที่ครบถ้วนและเข้าใจง่ายครับ!

<!--
[PROMPT_SUGGESTION]ช่วยสร้าง API Endpoint ด้วย Flask เพื่อเรียกใช้งาน Hybrid Predictor นี้หน่อย[/PROMPT_SUGGESTION]
[PROMPT_SUGGESTION]อธิบายเพิ่มเติมเกี่ยวกับข้อดีของการทำ Refactoring โค้ดที่ซ้ำซ้อน[/PROMPT_SUGGESTION]
