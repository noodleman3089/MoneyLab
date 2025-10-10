"""
Utility modules for OCR
"""

from .validation import ReceiptValidator, validate_receipt_data, ValidationResult

__all__ = ['ReceiptValidator', 'validate_receipt_data', 'ValidationResult']
