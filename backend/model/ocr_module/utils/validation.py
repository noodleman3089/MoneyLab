"""
Validation Rules System for Receipt Data
Validates extracted receipt data for correctness and consistency
"""
import re
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass


@dataclass
class ValidationIssue:
    """Represents a validation issue"""
    field: str
    severity: str  # 'error', 'warning', 'info'
    message: str
    current_value: Any
    suggested_value: Any = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            'field': self.field,
            'severity': self.severity,
            'message': self.message,
            'current_value': self.current_value,
            'suggested_value': self.suggested_value
        }


@dataclass
class ValidationResult:
    """Result of validation"""
    is_valid: bool
    issues: List[ValidationIssue]
    corrected_data: Dict[str, Any]
    validation_score: float  # 0.0-1.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            'is_valid': self.is_valid,
            'validation_score': self.validation_score,
            'issues': [issue.to_dict() for issue in self.issues],
            'corrected_data': self.corrected_data
        }


class ReceiptValidator:
    """Validates receipt data with smart rules"""

    def __init__(self, strict_mode: bool = False):
        """
        Initialize validator

        Args:
            strict_mode: If True, apply stricter validation rules
        """
        self.strict_mode = strict_mode
        self.issues: List[ValidationIssue] = []

    def validate(self, receipt_data: Dict[str, Any]) -> ValidationResult:
        """
        Validate receipt data

        Args:
            receipt_data: Extracted receipt data

        Returns:
            ValidationResult with issues and corrected data
        """
        self.issues = []
        corrected_data = receipt_data.copy()

        # Run all validation rules
        corrected_data = self._validate_date(corrected_data)
        corrected_data = self._validate_amount(corrected_data)
        corrected_data = self._validate_fee(corrected_data)
        corrected_data = self._validate_names(corrected_data)
        corrected_data = self._validate_reference_id(corrected_data)
        corrected_data = self._validate_merchant(corrected_data)
        corrected_data = self._validate_relationships(corrected_data)
        corrected_data = self._validate_confidence(corrected_data)

        # Calculate validation score
        validation_score = self._calculate_validation_score()

        # Determine if valid
        error_count = sum(1 for issue in self.issues if issue.severity == 'error')
        is_valid = error_count == 0

        return ValidationResult(
            is_valid=is_valid,
            issues=self.issues,
            corrected_data=corrected_data,
            validation_score=validation_score
        )

    def _validate_date(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate date field"""
        date_str = data.get('date')

        if not date_str or date_str == 'N/A':
            self.issues.append(ValidationIssue(
                field='date',
                severity='error',
                message='Date is missing',
                current_value=date_str
            ))
            return data

        # Check date format and reasonableness
        date_patterns = [
            r'\d{1,2}/\d{1,2}/\d{4}',  # DD/MM/YYYY
            r'\d{4}-\d{2}-\d{2}',       # YYYY-MM-DD
            r'\d{1,2}\s+\w+\.?\s+\d{2,4}',  # DD MMM YY
        ]

        is_valid_format = any(re.search(pattern, str(date_str)) for pattern in date_patterns)

        if not is_valid_format:
            self.issues.append(ValidationIssue(
                field='date',
                severity='warning',
                message='Date format may be invalid',
                current_value=date_str
            ))

        # Check if date is in reasonable range (not future, not too old)
        try:
            # Try to parse date
            parsed_date = self._parse_date(date_str)
            if parsed_date:
                now = datetime.now()

                # Check if date is in future
                if parsed_date > now + timedelta(days=1):
                    self.issues.append(ValidationIssue(
                        field='date',
                        severity='error',
                        message='Date is in the future',
                        current_value=date_str
                    ))

                # Check if date is too old (>5 years)
                elif parsed_date < now - timedelta(days=365*5):
                    self.issues.append(ValidationIssue(
                        field='date',
                        severity='warning',
                        message='Date is more than 5 years old',
                        current_value=date_str
                    ))
        except:
            pass

        return data

    def _validate_amount(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate amount field"""
        amount = data.get('amount')

        if amount is None:
            self.issues.append(ValidationIssue(
                field='amount',
                severity='error',
                message='Amount is missing',
                current_value=amount
            ))
            return data

        # Convert to float if string
        try:
            amount_float = float(amount)
            data['amount'] = amount_float
        except (ValueError, TypeError):
            self.issues.append(ValidationIssue(
                field='amount',
                severity='error',
                message='Amount is not a valid number',
                current_value=amount
            ))
            return data

        # Check if amount is positive
        if amount_float <= 0:
            self.issues.append(ValidationIssue(
                field='amount',
                severity='error',
                message='Amount must be positive',
                current_value=amount_float
            ))

        # Check if amount is reasonable (not too large)
        if amount_float > 10_000_000:  # 10 million
            self.issues.append(ValidationIssue(
                field='amount',
                severity='warning',
                message='Amount is unusually large (>10M THB)',
                current_value=amount_float
            ))

        # Check if amount is too small
        if amount_float < 0.01:
            self.issues.append(ValidationIssue(
                field='amount',
                severity='warning',
                message='Amount is unusually small',
                current_value=amount_float
            ))

        # Check decimal places (should be max 2 for THB)
        if len(str(amount_float).split('.')[-1]) > 2 and '.' in str(amount_float):
            rounded = round(amount_float, 2)
            self.issues.append(ValidationIssue(
                field='amount',
                severity='warning',
                message='Amount has more than 2 decimal places',
                current_value=amount_float,
                suggested_value=rounded
            ))
            data['amount'] = rounded

        return data

    def _validate_fee(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate fee field"""
        fee = data.get('fee')
        amount = data.get('amount', 0)

        if fee is None:
            # Fee can be missing (means 0)
            data['fee'] = 0.0
            return data

        # Convert to float
        try:
            fee_float = float(fee)
            data['fee'] = fee_float
        except (ValueError, TypeError):
            self.issues.append(ValidationIssue(
                field='fee',
                severity='warning',
                message='Fee is not a valid number',
                current_value=fee
            ))
            data['fee'] = 0.0
            return data

        # Check if fee is negative
        if fee_float < 0:
            self.issues.append(ValidationIssue(
                field='fee',
                severity='error',
                message='Fee cannot be negative',
                current_value=fee_float,
                suggested_value=0.0
            ))
            data['fee'] = 0.0

        # Check if fee is larger than amount
        if fee_float > amount:
            self.issues.append(ValidationIssue(
                field='fee',
                severity='error',
                message='Fee is larger than amount',
                current_value=fee_float
            ))

        return data

    def _validate_names(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate sender and receiver names"""
        sender = data.get('sender_name', '')
        receiver = data.get('receiver_name', '')

        # Check if names exist
        if not sender or sender == 'N/A':
            self.issues.append(ValidationIssue(
                field='sender_name',
                severity='warning',
                message='Sender name is missing',
                current_value=sender
            ))

        if not receiver or receiver == 'N/A':
            self.issues.append(ValidationIssue(
                field='receiver_name',
                severity='warning',
                message='Receiver name is missing',
                current_value=receiver
            ))

        # Check name format (should have Thai title or proper format)
        thai_titles = ['นาย', 'นาง', 'นางสาว', 'น.ส.', 'ด.ช.', 'ด.ญ.']

        if sender and sender != 'N/A':
            # Check minimum length
            if len(sender) < 3:
                self.issues.append(ValidationIssue(
                    field='sender_name',
                    severity='warning',
                    message='Sender name is too short',
                    current_value=sender
                ))

            # Check for title
            has_title = any(title in sender for title in thai_titles)
            if not has_title and self.strict_mode:
                self.issues.append(ValidationIssue(
                    field='sender_name',
                    severity='info',
                    message='Sender name does not have Thai title',
                    current_value=sender
                ))

        if receiver and receiver != 'N/A':
            if len(receiver) < 3:
                self.issues.append(ValidationIssue(
                    field='receiver_name',
                    severity='warning',
                    message='Receiver name is too short',
                    current_value=receiver
                ))

            has_title = any(title in receiver for title in thai_titles)
            if not has_title and self.strict_mode:
                self.issues.append(ValidationIssue(
                    field='receiver_name',
                    severity='info',
                    message='Receiver name does not have Thai title',
                    current_value=receiver
                ))

        # Check if sender and receiver are the same
        if sender and receiver and sender == receiver:
            self.issues.append(ValidationIssue(
                field='sender_name',
                severity='warning',
                message='Sender and receiver names are identical',
                current_value=sender
            ))

        return data

    def _validate_reference_id(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate reference ID"""
        ref_id = data.get('reference_id', '')

        if not ref_id or ref_id == 'N/A':
            self.issues.append(ValidationIssue(
                field='reference_id',
                severity='info',
                message='Reference ID is missing',
                current_value=ref_id
            ))
            return data

        # Check format (should be alphanumeric)
        if not re.match(r'^[a-zA-Z0-9]+$', str(ref_id)):
            self.issues.append(ValidationIssue(
                field='reference_id',
                severity='warning',
                message='Reference ID contains invalid characters',
                current_value=ref_id
            ))

        # Check length (usually 10-30 characters)
        if len(str(ref_id)) < 8:
            self.issues.append(ValidationIssue(
                field='reference_id',
                severity='warning',
                message='Reference ID is too short',
                current_value=ref_id
            ))
        elif len(str(ref_id)) > 50:
            self.issues.append(ValidationIssue(
                field='reference_id',
                severity='warning',
                message='Reference ID is too long',
                current_value=ref_id
            ))

        return data

    def _validate_merchant(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate merchant field"""
        merchant = data.get('merchant', '')

        if not merchant or merchant == 'N/A':
            self.issues.append(ValidationIssue(
                field='merchant',
                severity='warning',
                message='Merchant is missing',
                current_value=merchant
            ))
            return data

        # Check against known merchants
        known_merchants = ['Bank', 'TrueMoney', 'PromptPay', 'MyMo', '7-Eleven', 'Retail']

        if merchant not in known_merchants:
            self.issues.append(ValidationIssue(
                field='merchant',
                severity='info',
                message=f'Merchant "{merchant}" is not in known list',
                current_value=merchant
            ))

        return data

    def _validate_relationships(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate relationships between fields"""

        # Check if source type matches merchant
        source = data.get('source', {})
        merchant = data.get('merchant', '')

        if isinstance(source, dict):
            source_type = source.get('type', '')
            source_brand = source.get('brand', '')

            # Bank receipts should have bank-related merchant
            if source_type == 'bank' and merchant and merchant not in ['Bank', 'N/A']:
                self.issues.append(ValidationIssue(
                    field='merchant',
                    severity='warning',
                    message=f'Source type is "bank" but merchant is "{merchant}"',
                    current_value=merchant,
                    suggested_value='Bank'
                ))

            # E-wallet should have matching brand
            if source_type == 'ewallet' and source_brand:
                if merchant != source_brand:
                    self.issues.append(ValidationIssue(
                        field='merchant',
                        severity='info',
                        message=f'Merchant "{merchant}" does not match source brand "{source_brand}"',
                        current_value=merchant,
                        suggested_value=source_brand
                    ))

        return data

    def _validate_confidence(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate confidence scores"""
        overall_conf = data.get('overall_confidence', 0)
        confidence = data.get('confidence', {})

        # Check if overall confidence is too low
        if overall_conf < 0.5:
            self.issues.append(ValidationIssue(
                field='overall_confidence',
                severity='error',
                message='Overall confidence is very low (<50%)',
                current_value=overall_conf
            ))
        elif overall_conf < 0.7:
            self.issues.append(ValidationIssue(
                field='overall_confidence',
                severity='warning',
                message='Overall confidence is low (<70%)',
                current_value=overall_conf
            ))

        # Check individual field confidence
        if isinstance(confidence, dict):
            for field, conf_value in confidence.items():
                if conf_value and conf_value < 0.5:
                    self.issues.append(ValidationIssue(
                        field=f'confidence.{field}',
                        severity='warning',
                        message=f'{field} confidence is low (<50%)',
                        current_value=conf_value
                    ))

        return data

    def _calculate_validation_score(self) -> float:
        """Calculate overall validation score"""
        if not self.issues:
            return 1.0

        # Weight by severity
        weights = {'error': 0.3, 'warning': 0.1, 'info': 0.05}
        total_penalty = sum(weights.get(issue.severity, 0.1) for issue in self.issues)

        # Score from 0.0 to 1.0
        score = max(0.0, 1.0 - total_penalty)
        return score

    def _parse_date(self, date_str: str) -> Optional[datetime]:
        """Try to parse date string"""
        formats = [
            '%d/%m/%Y',
            '%Y-%m-%d',
            '%d/%m/%Y %H:%M',
            '%Y-%m-%d %H:%M:%S',
        ]

        for fmt in formats:
            try:
                return datetime.strptime(date_str, fmt)
            except:
                continue

        return None


def validate_receipt_data(receipt_data: Dict[str, Any], strict_mode: bool = False) -> ValidationResult:
    """
    Convenience function to validate receipt data

    Args:
        receipt_data: Receipt data dictionary
        strict_mode: Apply stricter validation rules

    Returns:
        ValidationResult
    """
    validator = ReceiptValidator(strict_mode=strict_mode)
    return validator.validate(receipt_data)


if __name__ == "__main__":
    # Test validation
    test_data = {
        'date': '31/08/2025 14:50',
        'merchant': 'Bank',
        'reference_id': '202508311450123456',
        'amount': 3000.0,
        'fee': 0.0,
        'sender_name': 'นาย สมชาย',
        'receiver_name': 'นาง สมหญิง',
        'source': {'type': 'bank', 'brand': 'Bank'},
        'confidence': {
            'date': 0.85,
            'amount': 0.92,
            'sender_name': 0.78,
            'receiver_name': 0.81,
            'merchant': 0.90
        },
        'overall_confidence': 0.852
    }

    result = validate_receipt_data(test_data)

    print("Validation Result:")
    print(f"Is Valid: {result.is_valid}")
    print(f"Validation Score: {result.validation_score:.2f}")
    print(f"\nIssues ({len(result.issues)}):")
    for issue in result.issues:
        print(f"  [{issue.severity.upper()}] {issue.field}: {issue.message}")
        if issue.suggested_value:
            print(f"    Suggested: {issue.suggested_value}")
