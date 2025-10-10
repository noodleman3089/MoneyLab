"""
OCR Module for Receipt Extraction
Standalone OCR module that can be integrated into any project
"""

from .extract_receipt import ReceiptExtractor, ExtractionResult

__all__ = ['ReceiptExtractor', 'ExtractionResult']
__version__ = '1.0.0'
