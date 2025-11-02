import numpy as np
import json

def custom_default(obj):
    """
    ฟังก์ชันสำหรับแปลง object ที่ json.dumps ปกติจัดการไม่ได้ (เช่น numpy types)
    """
    if isinstance(obj, (np.integer, np.floating, np.bool_)):
        return obj.item()
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")