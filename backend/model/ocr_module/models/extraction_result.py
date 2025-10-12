"""
Data models for OCR extraction results
"""
from dataclasses import dataclass
from typing import Dict, Optional


@dataclass
class ExtractionResult:
    """Data class for extraction results"""
    date: Optional[str] = None
    merchant: Optional[str] = None
    reference_id: Optional[str] = None
    amount: Optional[float] = None
    fee: Optional[float] = None
    sender_name: Optional[str] = None
    receiver_name: Optional[str] = None
    source: Dict[str, str] = None
    confidence: Dict[str, float] = None
    overall_confidence: float = 0.0

    def __post_init__(self):
        if self.source is None:
            self.source = {'type': 'unknown', 'brand': 'unknown'}
        if self.confidence is None:
            self.confidence = {}

    def to_dict(self) -> Dict:
        return {
            'date': self.date,
            'merchant': self.merchant,
            'reference_id': self.reference_id,
            'amount': self.amount,
            'fee': self.fee,
            'sender_name': self.sender_name,
            'receiver_name': self.receiver_name,
            'source': self.source,
            'confidence': self.confidence,
            'overall_confidence': round(self.overall_confidence, 3)
        }
