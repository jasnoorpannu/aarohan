import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import roc_auc_score
import lightgbm as lgb
from src.config import RAW_DATA, MODEL_PATH
from src.preprocessing import load_raw, prepare_features

def train_and_save():
    print("Loading raw data...")
    raw = load_raw(RAW_DATA)

    print("Preparing features...")
    df = prepare_features(raw, cutoff=60) 

    print("Training shape:", df.shape)

    cat_cols = ["gender", "region", "highest_education", "imd_band", "age_band", "disability", "code_module", "code_presentation"]
    
    X = df.drop(["id_student", "dropout"], axis=1)
    y = df["dropout"]

    skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    
    fold_aucs = []
    
    params = {
        "objective": "binary",
        "metric": "auc",
        "boosting_type": "gbdt",
        "num_leaves": 31,
        "learning_rate": 0.05,
        "feature_fraction": 0.8,
        "bagging_fraction": 0.8,
        "bagging_freq": 5,
        "is_unbalance": True,
        "verbosity": -1
    }

    print("Starting 5-Fold CV...")
    
    for fold, (train_idx, val_idx) in enumerate(skf.split(X, y)):
        X_train, X_val = X.iloc[train_idx], X.iloc[val_idx]
        y_train, y_val = y.iloc[train_idx], y.iloc[val_idx]

        train_data = lgb.Dataset(X_train, label=y_train, categorical_feature=cat_cols)
        val_data = lgb.Dataset(X_val, label=y_val, categorical_feature=cat_cols, reference=train_data)

        model = lgb.train(
            params,
            train_data,
            valid_sets=[val_data],
            callbacks=[lgb.early_stopping(50), lgb.log_evaluation(0)]
        )
        
        preds = model.predict(X_val)
        auc = roc_auc_score(y_val, preds)
        fold_aucs.append(auc)
        print(f"Fold {fold+1} AUC: {auc:.4f}")
        
        if fold == 4:
            joblib.dump(model, MODEL_PATH)

    print(f"Average AUC: {np.mean(fold_aucs):.4f}")

if __name__ == "__main__":
    train_and_save()