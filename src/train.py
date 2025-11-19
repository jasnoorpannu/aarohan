import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, average_precision_score
import lightgbm as lgb
from src.config import RAW_DATA, MODEL_PATH
from src.preprocessing import load_raw, prepare_features

def train_and_save():
    print("Loading raw data...")
    raw = load_raw(RAW_DATA)

    print("Preparing features...")
    df = prepare_features(raw)

    X = df.drop(["id_student", "dropout"], axis=1)
    y = df["dropout"]

    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=42
    )

    train_data = lgb.Dataset(X_train, label=y_train)
    val_data = lgb.Dataset(X_val, label=y_val)

    params = {
        "objective": "binary",
        "metric": "auc",
        "verbosity": -1,
        "boosting_type": "gbdt",
        "num_leaves": 31,
        "learning_rate": 0.03,
        "feature_fraction": 0.9,
        "bagging_fraction": 0.9,
        "bagging_freq": 5,
    }

    print("Training model...")
    model = lgb.train(
        params,
        train_data,
        valid_sets=[val_data],
        callbacks=[
            lgb.early_stopping(50),
            lgb.log_evaluation(50),
        ],
        num_boost_round=1500
    )

    preds = model.predict(X_val)
    auc = roc_auc_score(y_val, preds)
    ap = average_precision_score(y_val, preds)

    print(f"Validation AUC: {auc:.4f}, AP: {ap:.4f}")

    joblib.dump(model, MODEL_PATH)
    print("Saved model to", MODEL_PATH)

if __name__ == "__main__":
    train_and_save()
