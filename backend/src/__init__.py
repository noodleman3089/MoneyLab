from flask import Flask
from flask_cors import CORS
import json

# Import ฟังก์ชันที่เราสร้างขึ้นมาใหม่
from .utils.json_encoder import custom_default

def create_app():
    """Application Factory Pattern"""
    app = Flask(__name__)
    
    # --- [THE FIX] ---
    # บอกให้ Flask ใช้ฟังก์ชัน custom_default ของเราในการแปลง JSON
    app.json.default = custom_default
    # -----------------

    # เปิดใช้งาน CORS เพื่อให้ Frontend (จาก Domain อื่น) เรียกใช้ API ได้
    CORS(app)

    # Import และลงทะเบียน Controller (Blueprint)
    from .controllers.prediction_controller import prediction_bp
    app.register_blueprint(prediction_bp, url_prefix='/api')

    return app