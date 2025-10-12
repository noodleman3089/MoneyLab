"""
Name cleaning utilities for extracted names
"""
import re


def clean_name(name: str) -> str:
    """Clean up extracted names from OCR artifacts"""
    if not name:
        return name

    # Remove extra whitespace
    name = ' '.join(name.split())

    # Remove common OCR artifacts from start/end only
    name = name.strip('.,:-')

    # If it's a masked pattern (has *, x, or multiple digits), return None to indicate it should be null
    # But exclude organization names with parentheses which may contain digits
    if not re.search(r'\([^)]+\)', name):  # No parentheses
        if (('*' in name and any(c.isdigit() for c in name)) or
            ('x' in name.lower() and any(c.isdigit() for c in name)) or
            re.search(r'\d{4,}', name)):  # 4+ consecutive digits
            return None

    # Remove unwanted words that commonly appear with names
    # But be careful not to remove them from organization names
    unwanted_words = [
        'บัญชี', 'ทรูมันนี่', 'พร้อมเพย์', 'ธนาคาร', 'bank', 'วอลเล็ท',
        'ออมสิน', 'ไอแบงก์', 'account', 'wallet', 'ออมทรัพย์', 'pomnipar',
        'บัญชีทรูมันนี่', 'จากวอลเล็ท'
    ]

    # Only remove unwanted words if this doesn't look like an organization name
    if not (re.search(r'\([^)]+\)', name) or
            any(org_word in name for org_word in ['บทร.', 'โรงเรียน', 'มหาวิทยาลัย', 'วิทยาลัย', 'สถาบัน', 'ศูนย์', 'องค์การ', 'กรม', 'กระทรวง', 'เทศบาล', 'บริษัท', 'หจก', 'บจก', 'ศึกษา'])):
        for word in unwanted_words:
            name = re.sub(rf'\b{word}\b', '', name, flags=re.IGNORECASE)

    # Clean up multiple spaces
    name = ' '.join(name.split())

    # Remove trailing punctuation and artifacts, but preserve parentheses for organizations
    if not re.search(r'\([^)]+\)', name):  # No parentheses - apply strict cleaning
        name = re.sub(r'[^\u0e00-\u0e7fa-zA-Z\s]+$', '', name).strip()
        # Check if what's left is a valid name (has at least 2 characters and no numbers)
        if len(name) < 2 or any(c.isdigit() for c in name):
            return None
    else:  # Has parentheses - likely organization name, be more lenient
        name = re.sub(r'[.,:;]+$', '', name).strip()  # Remove only trailing punctuation
        if len(name) < 3:  # Organizations should be at least 3 characters
            return None

    return name if name else None
