import pandas as pd
import numpy as np
import lightgbm as lgb
from sklearn.preprocessing import LabelEncoder
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, f1_score

from .preprocess import create_preprocessor
from . import persistence


class CategoryPredictorML:
    """Machine-learning based category predictor (LightGBM + mixed features)

    This class holds pipeline (preprocessor + model) and a LabelEncoder for
    the target. Persistence helpers are delegated to `persistence` module.
    """

    def __init__(self, numeric_features, categorical_features, text_features_map):
        self.numeric_features = numeric_features
        self.categorical_features = categorical_features
        self.text_features_map = text_features_map

        # build preprocessor and model
        self.preprocessor = create_preprocessor(
            numeric_features, categorical_features, text_features_map
        )

        self.model = lgb.LGBMClassifier(
            class_weight='balanced',
            n_estimators=200,
            max_depth=10,
            learning_rate=0.05,
            num_leaves=31
        )

        self.pipeline = Pipeline(steps=[('preprocessor', self.preprocessor), ('model', self.model)])
        self.target_encoder = LabelEncoder()

    def train(self, X_train, y_train):
        print("Starting model training...")
        y_train_encoded = self.target_encoder.fit_transform(y_train)
        self.pipeline.fit(X_train, y_train_encoded)
        print(f"Training complete. Model trained on {len(self.target_encoder.classes_)} categories.")

    def predict_proba(self, X_new):
        if not isinstance(X_new, pd.DataFrame):
            raise ValueError("Input must be a pandas DataFrame")

        probabilities = self.pipeline.predict_proba(X_new)
        classes = self.target_encoder.classes_

        results = []
        for probs in probabilities:
            top_3_indices = np.argsort(probs)[-3:][::-1]
            top_3_predictions = [(classes[i], float(probs[i])) for i in top_3_indices]

            output = {
                'predicted_category': top_3_predictions[0][0],
                'confidence': top_3_predictions[0][1],
                'method': 'machine_learning',
                'model': 'lightgbm',
                'top_3_predictions': top_3_predictions,
                'need_confirmation': top_3_predictions[0][1] < 0.80
            }
            results.append(output)
        return results

    def evaluate(self, X_test, y_test):
        print("Evaluating model performance...")
        y_test_encoded = self.target_encoder.transform(y_test)
        y_pred_encoded = self.pipeline.predict(X_test)
        f1 = f1_score(y_test_encoded, y_pred_encoded, average='macro')
        print(f"F1-Score (Macro Average): {f1:.4f}")
        print("\nClassification Report:")
        print(classification_report(y_test_encoded, y_pred_encoded, target_names=self.target_encoder.classes_))
        return f1

    def save_model(self, path="category_predictor.joblib"):
        feature_config = {
            'numeric_features': self.numeric_features,
            'categorical_features': self.categorical_features,
            'text_features_map': self.text_features_map
        }
        persistence.save_model(self.pipeline, self.target_encoder, feature_config, path=path)
        print(f"Model saved successfully to {path}")

    @staticmethod
    def load_model(path="category_predictor.joblib"):
        try:
            data = persistence.load_model(path)
            model_instance = CategoryPredictorML(
                numeric_features=data['feature_config']['numeric_features'],
                categorical_features=data['feature_config']['categorical_features'],
                text_features_map=data['feature_config']['text_features_map']
            )
            model_instance.pipeline = data['pipeline']
            model_instance.target_encoder = data['target_encoder']
            print(f"Model loaded successfully from {path}")
            return model_instance
        except FileNotFoundError:
            print(f"Error: Model file not found at {path}")
            return None
