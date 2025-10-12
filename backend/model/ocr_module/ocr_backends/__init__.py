"""OCR backends module"""
from .base_ocr import OCR_BACKEND
from .gpu_manager import GPUManager

__all__ = ['OCR_BACKEND', 'GPUManager']
