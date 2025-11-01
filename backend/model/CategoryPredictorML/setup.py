from setuptools import setup, find_packages

setup(
    name="category_predictor_ml",
    version="0.1.0",
    description="A hybrid category predictor for financial transactions.",
    author="Your Name", # ใส่ชื่อของคุณได้เลย
    packages=find_packages(),
    # find_packages() จะหาโฟลเดอร์ที่มี __init__.py ให้เอง
    # ในที่นี้คือ 'app', 'category_predictor', 'ml_pipeline' ฯลฯ
)