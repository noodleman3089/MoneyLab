from flask import Blueprint, request, jsonify
from ..services.prediction_service import prediction_service

prediction_bp = Blueprint('prediction_bp', __name__)

@prediction_bp.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid input"}), 400

    user_id = data.get('user_id')
    transaction_data = data.get('transaction')

    if user_id is None or transaction_data is None:
        return jsonify({"error": "Missing user_id or transaction data"}), 400

    result = prediction_service.predict_category(user_id, transaction_data)
    return jsonify(result)