"""
Base OCR interface and backend detection
"""
import sys

# Try to import OCR libraries and determine backend
OCR_BACKEND = None
try:
    import easyocr
    OCR_BACKEND = 'easyocr'
    print("Using EasyOCR (GPU-enabled)")
except ImportError:
    try:
        from paddleocr import PaddleOCR
        OCR_BACKEND = 'paddleocr'
        print("Using PaddleOCR (CPU-only)")
    except ImportError:
        print("No OCR backend found. Please install one of:")
        print("  GPU support: pip install easyocr")
        print("  CPU only:    pip install paddlepaddle paddleocr")
        sys.exit(1)
