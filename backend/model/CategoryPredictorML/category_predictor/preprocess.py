import sklearn
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.compose import ColumnTransformer


def create_preprocessor(numeric_features, categorical_features, text_features_map):
    """Build a ColumnTransformer for numeric, categorical and text features.

    Args:
        numeric_features (list): numeric column names
        categorical_features (list): categorical column names
        text_features_map (dict): mapping of text column -> max_features for TF-IDF

    Returns:
        ColumnTransformer
    """
    transformers = []

    # Numeric
    numeric_transformer = StandardScaler()
    transformers.append(('num', numeric_transformer, numeric_features))

    # Categorical: handle sklearn versions where parameter name changed
    skl_major, skl_minor = map(int, sklearn.__version__.split('.')[:2])
    if (skl_major, skl_minor) >= (1, 2):
        categorical_transformer = OneHotEncoder(handle_unknown='ignore', sparse_output=True)
    else:
        categorical_transformer = OneHotEncoder(handle_unknown='ignore', sparse=False)
    transformers.append(('cat', categorical_transformer, categorical_features))

    # Text features: ensure column passed as list (not string)
    for col_name, max_f in text_features_map.items():
        # สร้าง Pipeline ย่อยสำหรับแต่ละ Text Feature
        # 1. เลือกคอลัมน์ (ทำโดย ColumnTransformer) -> 2. ทำ TF-IDF
        text_pipeline = Pipeline([('tfidf', TfidfVectorizer(max_features=max_f))])
        # ระบุชื่อคอลัมน์โดยตรง (ไม่ใช่ list)
        transformers.append((f'text_{col_name}', text_pipeline, col_name))

    preprocessor = ColumnTransformer(transformers=transformers, remainder='drop')
    return preprocessor
