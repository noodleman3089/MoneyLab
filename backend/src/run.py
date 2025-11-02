import os
import sys
from src import create_app

# --- [THE FIX] ---
# เพิ่ม Path ของโปรเจกต์ ML เข้าไปใน sys.path ณ จุดเริ่มต้นของแอปพลิเคชัน
# เพื่อให้ทุกโมดูลที่ถูก import หลังจากนี้สามารถมองเห็น 'app' และ 'category_predictor' ได้
ml_project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'model', 'CategoryPredictorML'))
sys.path.insert(0, ml_project_root)

# โหลดค่าจาก .env ไฟล์ที่อยู่ในโฟลเดอร์รากของโปรเจกต์
# (สำคัญ: ต้องมั่นใจว่า .env อยู่ถูกที่)
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

app = create_app()

if __name__ == '__main__':
    # ใช้ port 5001 เพื่อไม่ให้ชนกับ Frontend ที่อาจจะรันบน port อื่น
    app.run(debug=True, port=5001)