from setuptools import setup, find_packages

setup(
    name="CategoryPredictorML", # 👈 ใช้ชื่อให้ตรงกับโฟลเดอร์เพื่อความชัดเจน
    version="0.1.0",
    description="A hybrid category predictor for financial transactions.",
    author="Your Name", # ใส่ชื่อของคุณได้เลย
    # find_packages() จะหาโฟลเดอร์ที่มี __init__.py ให้เองโดยอัตโนมัติ
    # ซึ่งจะรวม 'app', 'category_predictor', 'ml_pipeline' เข้ามา
    packages=find_packages(), 
)