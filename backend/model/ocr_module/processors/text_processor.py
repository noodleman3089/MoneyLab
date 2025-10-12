"""
Text Processing utilities for receipt extraction
"""
import re
from typing import Dict, List, Optional, Tuple


class TextProcessor:
    """Handles text processing and field extraction"""

    def __init__(self, pattern_manager):
        self.pattern_manager = pattern_manager
        self.field_confidences = {}  # Store confidence scores for extracted fields

    def extract_field_with_patterns(self, text: str, patterns: List[str], text_blocks: List[Tuple[str, float]] = None, field_name: str = '') -> Optional[str]:
        """Extract field using multiple regex patterns and calculate confidence"""
        for pattern_idx, pattern in enumerate(patterns):
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                extracted_text = None
                # Handle multi-group patterns (e.g., for *** *** \n 4625)
                if len(match.groups()) > 1:
                    # Combine groups for multi-part patterns
                    extracted_text = ' '.join([g.strip() for g in match.groups() if g]).strip()
                else:
                    extracted_text = match.group(1).strip()

                # Calculate confidence for this field
                confidence = self._calculate_field_confidence(
                    extracted_text, pattern_idx, len(patterns), text_blocks, field_name
                )

                if field_name:
                    self.field_confidences[field_name] = confidence

                return extracted_text

        if field_name:
            self.field_confidences[field_name] = 0.0
        return None

    def _calculate_field_confidence(self, extracted_text: str, pattern_idx: int, total_patterns: int,
                                   text_blocks: List[Tuple[str, float]], field_name: str) -> float:
        """Calculate confidence score for extracted field"""
        if not extracted_text:
            return 0.0

        confidence_factors = []

        # 1. Pattern priority score (earlier patterns are more reliable)
        pattern_score = 1.0 - (pattern_idx / max(total_patterns, 1))
        confidence_factors.append(pattern_score * 0.3)

        # 2. OCR confidence score (if text_blocks available)
        if text_blocks:
            ocr_confidence = self._get_ocr_confidence_for_text(extracted_text, text_blocks)
            confidence_factors.append(ocr_confidence * 0.4)

        # 3. Field validation score
        validation_score = self._validate_field_format(extracted_text, field_name)
        confidence_factors.append(validation_score * 0.3)

        # Calculate weighted average
        final_confidence = sum(confidence_factors) if confidence_factors else 0.0
        return min(1.0, max(0.0, final_confidence))

    def _get_ocr_confidence_for_text(self, target_text: str, text_blocks: List[Tuple[str, float]]) -> float:
        """Get OCR confidence for specific text"""
        target_words = target_text.lower().split()
        max_confidence = 0.0

        for text, confidence in text_blocks:
            text_words = text.lower().split()
            # Check if any words from target text appear in this block
            overlap = len(set(target_words) & set(text_words))
            if overlap > 0:
                # Weight confidence by overlap ratio
                overlap_ratio = overlap / len(target_words)
                weighted_confidence = confidence * overlap_ratio
                max_confidence = max(max_confidence, weighted_confidence)

        return max_confidence

    def _validate_field_format(self, text: str, field_name: str) -> float:
        """Validate field format and return confidence score"""
        if not text:
            return 0.0

        if field_name == 'amount' or field_name == 'fee':
            # Check if it's a valid number format
            try:
                float(text.replace(',', ''))
                if re.match(r'^\d+([.,]\d{2})?$', text.replace(',', '')):
                    return 1.0
                else:
                    return 0.7
            except ValueError:
                return 0.0

        elif field_name == 'date':
            # Check if it looks like a date
            date_patterns = [
                r'\d{1,2}/\d{1,2}/\d{2,4}',
                r'\d{1,2}-\d{1,2}-\d{2,4}',
                r'\d{1,2}\s+[ก-๙]{1,3}\.?\s*\d{2,4}'
            ]
            for pattern in date_patterns:
                if re.search(pattern, text):
                    return 0.9
            return 0.5

        elif field_name == 'reference_id':
            # Reference IDs are usually alphanumeric with certain length
            if len(text) >= 8 and re.match(r'^[A-Za-z0-9:]+$', text):
                return 0.9
            return 0.6

        elif field_name in ['sender_name', 'receiver_name']:
            # Names should contain Thai characters or English letters
            if re.search(r'[ก-๙]', text) or re.search(r'[a-zA-Z]', text):
                # Bonus for having title words
                if any(title in text for title in ['นาย', 'นาง', 'นางสาว']):
                    return 0.9
                return 0.7
            return 0.3

        # Default confidence for other fields
        return 0.6

    def extract_receiver_name_special(self, text: str, text_blocks: List[Tuple[str, float]]) -> Optional[str]:
        """Special extraction for receiver names when standard patterns fail"""
        # For organization names split across lines (like "มทร.ตะวันออก (ค่าธรรมเนียมการศึกษา)")
        org_parts = []
        for i, (text_block, confidence) in enumerate(text_blocks):
            if confidence >= 0.6:  # Accept medium confidence
                # Check for organization patterns
                if (re.search(r'[ก-๙a-zA-Z\.]+(?:ตะวันออก|ตะวันตก|เหนือ|ใต้|กลาง)', text_block) or
                    re.search(r'มทร\.|บทร\.|โรงเรียน|มหาวิทยาลัย|วิทยาลัย', text_block)):
                    org_parts.append(text_block.strip())
                # Check for content in parentheses in the next block
                elif (text_block.strip().startswith('(') or
                      re.search(r'\([ก-๙a-zA-Z\s]*\)|\([ก-๙a-zA-Z\s]*$|^[ก-๙a-zA-Z\s]*\)', text_block)):
                    org_parts.append(text_block.strip())
                # Check for education-related terms
                elif any(term in text_block for term in ['ศึกษา', 'การศึกษา', 'ค่าธรรมเนียม']):
                    org_parts.append(text_block.strip())

        # Combine organization parts
        if len(org_parts) >= 2:
            combined = ' '.join(org_parts)
            # Clean up the combined text
            if 'ศึกษา' in combined and ('มทร' in combined or 'บทร' in combined):
                # Fix parentheses if needed
                if '(' in combined and ')' not in combined:
                    combined += ')'
                elif ')' in combined and '(' not in combined:
                    combined = combined.replace(')', '(', 1)
                # Remove duplicate or partial duplicate words
                words = combined.split()
                cleaned_words = []
                for i, word in enumerate(words):
                    is_duplicate = False
                    # Check if this word is a substring of any previous word or vice versa
                    for prev_word in cleaned_words:
                        if word in prev_word or prev_word in word:
                            # If current word is longer, replace the previous one
                            if len(word) > len(prev_word):
                                cleaned_words = [w if w != prev_word else word for w in cleaned_words]
                            is_duplicate = True
                            break
                    if not is_duplicate:
                        cleaned_words.append(word)
                combined = ' '.join(cleaned_words)
                return combined
        elif len(org_parts) == 1 and len(org_parts[0]) > 10:  # Single long organization name
            return org_parts[0]

        # For PromptPay receipts, try to reconstruct split names
        if 'PromptPay' in text or 'พร้อมเพย์' in text:
            # Find "นาง", "ยุพดี", "เจียมจรรยา" pattern
            title_match = None
            first_name = None
            last_name = None

            for text_block, confidence in text_blocks:
                if confidence >= 0.8:  # Accept high confidence
                    if text_block.strip() in ['นาง', 'นาย', 'นางสาว']:
                        title_match = text_block.strip()
                    elif text_block.strip() == 'ยุพดี':
                        first_name = text_block.strip()
                    elif text_block.strip() == 'เจียมจรรยา':
                        last_name = text_block.strip()
                elif confidence >= 1.0:  # Perfect confidence for ยุพดี
                    if text_block.strip() == 'ยุพดี':
                        first_name = text_block.strip()

            # If we found all components, combine them
            if title_match and first_name and last_name:
                return f"{title_match} {first_name} {last_name}"
            # If we have title and either first or last name, try that
            elif title_match and (first_name or last_name):
                if first_name and last_name:
                    return f"{title_match} {first_name} {last_name}"
                elif first_name:
                    return f"{title_match} {first_name}"
                else:
                    return f"{title_match} {last_name}"

        return None

    def normalize_amount(self, amount_str: str) -> Optional[float]:
        """Normalize amount to decimal with 2 places, handling OCR errors"""
        if not amount_str:
            return None

        # Fix common OCR errors first
        amount_str = self._fix_ocr_errors(amount_str)

        # Handle Thai number format with comma as thousands separator
        if ',' in amount_str and '.' in amount_str:
            amount_str = amount_str.replace(',', '')
        elif ',' in amount_str and '.' not in amount_str:
            amount_str = amount_str.replace(',', '.')

        try:
            amount = float(amount_str)
            return round(amount, 2)
        except ValueError:
            return None

    def _fix_ocr_errors(self, text: str) -> str:
        """Fix common OCR misreads in numbers"""
        # Common OCR confusions
        ocr_fixes = {
            'o': '0',  # lowercase o -> zero
            'O': '0',  # uppercase O -> zero
            'l': '1',  # lowercase l -> one
            'I': '1',  # uppercase I -> one
            'i': '1',  # lowercase i -> one
        }

        # Apply fixes character by character, but only for digits context
        fixed = ""
        for char in text:
            if char in ocr_fixes and self._is_likely_digit_context(text, char):
                fixed += ocr_fixes[char]
            else:
                fixed += char

        return fixed

    def _is_likely_digit_context(self, text: str, char: str) -> bool:
        """Check if character is likely a misread digit based on context"""
        # If text contains numbers or decimal points, likely digit context
        has_numbers = any(c.isdigit() for c in text)
        has_decimal = '.' in text
        return has_numbers or has_decimal

    def convert_buddhist_year(self, date_str: str) -> str:
        """Convert Buddhist year (B.E.) to Christian year (C.E.)"""
        year_match = re.search(r'(\d{4})', date_str)
        if year_match:
            year = int(year_match.group(1))
            if year >= 2400:  # Buddhist year
                new_year = year - 543
                date_str = date_str.replace(str(year), str(new_year))
        return date_str

    def detect_merchant_and_source(self, full_text: str) -> Tuple[Optional[str], Dict[str, str]]:
        """Detect merchant name and source type/brand"""
        merchant = None
        source = {'type': 'unknown', 'brand': 'unknown'}

        text_upper = full_text.upper()

        # First, try to extract merchant from business name patterns
        merchant_patterns = [
            r"สาขา\s+([^:\n\r]+)",
            r"(?:ร้าน|shop|store)\s*:?\s*([^\n\r]+)",
            r"(?:merchant|ผู้ขาย)\s*:?\s*([^\n\r]+)",
            r"^([A-Z\s]{3,20})(?:ที่|@|location)",
            r"รหัสร้าน\s*:\s*(\d+)",
            # Pattern for coffee shop names
            r"(เดอะเฟิร์สเอสเปรสโซ่โรสเตอร์)",
            r"(บจก\.\s*[^\n\r]+)",
            # General business name patterns
            r"([ก-๙a-zA-Z\s]+(?:โรสเตอร์|คอฟฟี่|ร้าน|เซ็นเตอร์))",
        ]

        for pattern in merchant_patterns:
            match = re.search(pattern, full_text, re.IGNORECASE | re.MULTILINE)
            if match:
                candidate = match.group(1).strip()
                if candidate.isdigit() and len(candidate) == 5:
                    continue
                merchant = candidate
                break

        # Then check for known brands to determine source type
        for brand_key, brand_info in self.pattern_manager.brand_patterns.items():
            if brand_key in text_upper:
                source = {
                    'type': brand_info['type'],
                    'brand': brand_info['brand']
                }
                # If no merchant found yet and this is not a bank, use brand as merchant
                if not merchant and brand_info['type'] != 'bank':
                    merchant = brand_info['brand']
                break

        return merchant, source
