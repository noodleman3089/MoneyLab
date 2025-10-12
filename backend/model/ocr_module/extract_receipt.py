#!/usr/bin/env python3
"""
Receipt/E-slip OCR Extraction Script
Extracts structured data from Thai receipts using PaddleOCR and regex patterns.

Usage: python extract_receipt.py input.jpg
"""

import json
import sys
import os
import argparse
import io
import locale

try:
    import cv2
    import numpy as np
except ImportError:
    print("Required packages not installed. Please run:")
    print("pip install opencv-python numpy")
    sys.exit(1)

# Import from modular structure
from receipt_extractor import ReceiptExtractor


def main():
    """Command line interface for receipt extraction"""
    # Set console encoding for Windows
    try:
        os.environ['PYTHONIOENCODING'] = 'utf-8'
        # Fix Windows console encoding
        if sys.platform == 'win32':
            sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
            sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except:
        pass

    parser = argparse.ArgumentParser(
        description='Extract receipt data to JSON using OCR',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python extract_receipt.py receipt.jpg
  python extract_receipt.py receipt.jpg --gpu
  python extract_receipt.py receipt.jpg --output result.json --pretty
        """
    )
    parser.add_argument('image_path', help='Path to receipt image')
    parser.add_argument('--output', '-o', help='Output JSON file (optional)')
    parser.add_argument('--pretty', action='store_true', help='Pretty print JSON')
    parser.add_argument('--gpu', action='store_true', help='Use GPU acceleration (requires CUDA)')
    parser.add_argument('--lang', default='th', help='OCR language (default: th for Thai)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--save-db', action='store_true', help='Save to database')
    parser.add_argument('--db-path', default='receipts.db', help='Database path (default: receipts.db)')
    parser.add_argument('--user-id', type=int, help='User ID for database record')
    parser.add_argument('--category-id', type=int, help='Category ID for database record')

    args = parser.parse_args()

    if not os.path.exists(args.image_path):
        print(f"Error: Image file '{args.image_path}' not found")
        sys.exit(1)

    try:
        # Initialize extractor
        if args.verbose:
            print(f"Initializing OCR extractor (GPU: {args.gpu}, Language: {args.lang})")

        extractor = ReceiptExtractor(use_gpu=args.gpu, lang=args.lang)

        # Extract data
        if args.verbose:
            print(f"Processing image: {args.image_path}")

        result = extractor.extract_to_dict(args.image_path)

        # Save to database if requested
        if args.save_db:
            try:
                from database import ReceiptDatabase
                db = ReceiptDatabase(args.db_path)
                txn_id = db.insert_transaction(
                    result,
                    user_id=args.user_id,
                    cate_id=args.category_id
                )
                if txn_id:
                    print(f"Transaction saved to database with ID: {txn_id}")
                    result['txn_id'] = txn_id
                else:
                    print("Warning: Transaction may already exist in database")
            except ImportError:
                print("Error: database.py not found. Cannot save to database.")
            except Exception as e:
                print(f"Error saving to database: {e}")

        # Format output
        if args.pretty:
            json_output = json.dumps(result, indent=2, ensure_ascii=False)
        else:
            json_output = json.dumps(result, ensure_ascii=False)

        # Output result
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(json_output)
            print(f"Results saved to {args.output}")
        else:
            print(json_output)

        if args.verbose:
            device = getattr(extractor, 'device', 'unknown')
            print(f"\nExtraction completed successfully using {device.upper()}")

    except Exception as e:
        print(f"Error processing image: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
