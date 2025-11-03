#!/usr/bin/env python3
"""
Flask API for OCR Receipt Extraction Service
Provides REST API endpoints for receipt OCR processing
"""

from flask import Flask, request, jsonify
import os
import tempfile
from werkzeug.utils import secure_filename
from receipt_extractor import ReceiptExtractor

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'tiff'}

# Initialize OCR extractor (singleton)
extractor = None

def get_extractor():
    """Lazy initialization of OCR extractor"""
    global extractor
    if extractor is None:
        use_gpu = os.getenv('USE_GPU', 'false').lower() == 'true'
        lang = os.getenv('OCR_LANG', 'th')
        extractor = ReceiptExtractor(use_gpu=use_gpu, lang=lang)
        print(f"OCR Extractor initialized (GPU: {use_gpu}, Language: {lang})")
    return extractor

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'ocr-api',
        'version': '1.0.0'
    }), 200

@app.route('/extract', methods=['POST'])
def extract_receipt():
    """
    Extract receipt data from uploaded image

    Request:
        - file: Image file (multipart/form-data)

    Response:
        - JSON with extracted receipt data
    """
    # Check if file is present
    if 'file' not in request.files:
        return jsonify({
            'error': 'No file provided',
            'message': 'Please upload an image file'
        }), 400

    file = request.files['file']

    # Check if file is selected
    if file.filename == '':
        return jsonify({
            'error': 'No file selected',
            'message': 'Please select a file to upload'
        }), 400

    # Check file extension
    if not allowed_file(file.filename):
        return jsonify({
            'error': 'Invalid file type',
            'message': f'Allowed file types: {", ".join(ALLOWED_EXTENSIONS)}'
        }), 400

    try:
        # Save file temporarily
        filename = secure_filename(file.filename)
        temp_dir = tempfile.gettempdir()
        temp_path = os.path.join(temp_dir, filename)
        file.save(temp_path)

        # Extract receipt data
        ocr = get_extractor()
        result = ocr.extract_to_dict(temp_path)

        # Clean up temporary file
        os.remove(temp_path)

        # Return result
        return jsonify({
            'success': True,
            'data': result
        }), 200

    except Exception as e:
        # Clean up on error
        if os.path.exists(temp_path):
            os.remove(temp_path)

        return jsonify({
            'error': 'Extraction failed',
            'message': str(e)
        }), 500

@app.route('/', methods=['GET'])
def index():
    """API information endpoint"""
    return jsonify({
        'service': 'OCR Receipt Extraction API',
        'version': '1.0.0',
        'endpoints': {
            '/health': 'Health check',
            '/extract': 'Extract receipt data (POST with image file)',
        }
    }), 200

@app.errorhandler(413)
def request_entity_too_large(error):
    """Handle file too large error"""
    return jsonify({
        'error': 'File too large',
        'message': 'Maximum file size is 16MB'
    }), 413

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not found',
        'message': 'The requested endpoint does not exist'
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        'error': 'Internal server error',
        'message': 'An unexpected error occurred'
    }), 500

if __name__ == '__main__':
    # For development only
    app.run(host='0.0.0.0', port=8000, debug=True)
