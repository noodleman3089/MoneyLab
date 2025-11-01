import joblib


def save_model(pipeline, target_encoder, feature_config, path="category_predictor.joblib"):
    data_to_save = {
        'pipeline': pipeline,
        'target_encoder': target_encoder,
        'feature_config': feature_config
    }
    joblib.dump(data_to_save, path)


def load_model(path="category_predictor.joblib"):
    return joblib.load(path)
