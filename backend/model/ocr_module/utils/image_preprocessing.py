"""
Image preprocessing utilities for better OCR results
"""
import os
from typing import Optional

try:
    import cv2
    import numpy as np
except ImportError:
    cv2 = None
    np = None


def preprocess_image(image_path: str) -> Optional[str]:
    """Enhanced image preprocessing for better OCR results"""
    if cv2 is None or np is None:
        print("OpenCV not available. Skipping preprocessing.")
        return None

    try:
        # Load image
        img = cv2.imread(image_path)
        if img is None:
            return None

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Apply multiple preprocessing techniques

        # 1. Enhance contrast using CLAHE (Contrast Limited Adaptive Histogram Equalization)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        enhanced = clahe.apply(gray)

        # 2. Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)

        # 3. Apply adaptive threshold for better text separation
        adaptive_thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2)

        # 4. Apply morphological operations to clean up
        kernel = np.ones((2,2), np.uint8)
        morph = cv2.morphologyEx(adaptive_thresh, cv2.MORPH_CLOSE, kernel)

        # 5. Sharpen the image
        sharpen_kernel = np.array([[-1,-1,-1], [-1,9,-1], [-1,-1,-1]])
        sharpened = cv2.filter2D(morph, -1, sharpen_kernel)

        # Save preprocessed image
        base_name = os.path.splitext(image_path)[0]
        preprocessed_path = f"{base_name}_enhanced.jpg"
        cv2.imwrite(preprocessed_path, sharpened)

        return preprocessed_path

    except Exception as e:
        try:
            print(f"Enhanced image preprocessing failed: {e}")
        except UnicodeEncodeError:
            print(f"Enhanced image preprocessing failed: [Unicode encoding error]")
        return None
