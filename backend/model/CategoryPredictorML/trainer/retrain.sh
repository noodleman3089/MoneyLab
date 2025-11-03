#!/bin/sh
# ไม่จำเป็นต้องตั้ง PYTHONPATH เพราะเราอยู่ใน working directory ที่ถูกต้องแล้ว

echo "--- Starting Model Retraining Process --- $(date)"

# redirect stdout & stderr
# --- [FIX] ใช้ path ที่สัมพันธ์กับ WORKDIR (/usr/src/app) ---
python ml_pipeline/train_model.py >> /var/log/cron.log 2>&1
python ml_pipeline/train_global_model.py >> /var/log/cron.log 2>&1

echo "--- Retraining process has been completed! --- $(date)" >> /var/log/cron.log 2>&1
