# src/use.py

import pandas as pd
import joblib
import numpy as np
from src.config import MODEL_PATH, TEST_DATA 
from src.preprocessing import load_raw, get_static_features, advanced_agg

def prepare_inference_data(df, cutoff=None):
    print(f"--- Preparing Data (Cutoff: {cutoff} days) ---")
    
    static = get_static_features(df)
    
    dynamic = advanced_agg(df, cutoff=cutoff)
    
    features = static.merge(dynamic, on="id_student", how="left")
    
    numeric_cols = features.select_dtypes(include=['number']).columns
    features[numeric_cols] = features[numeric_cols].fillna(0)
    
    return features

def predict_dropout(csv_path, cutoff=None):
    print(f"Loading model from {MODEL_PATH}...")
    try:
        model = joblib.load(MODEL_PATH)
    except FileNotFoundError:
        print("Error: Model not found. Run 'python -m src.train' first.")
        return

    print(f"Loading test data from {csv_path}...")
    raw_df = load_raw(csv_path)

    X_df = prepare_inference_data(raw_df, cutoff=cutoff)
    
    if X_df.empty:
        print("Error: Feature extraction resulted in an empty DataFrame. Check your test data format.")
        return
    
    student_ids = X_df["id_student"]
    X = X_df.drop(["id_student"], axis=1)
    
    print("Running predictions...")
    
    for col in X.select_dtypes(['category']).columns:
        X[col] = X[col].astype('category') 

    probs = model.predict(X)

    results = pd.DataFrame({
        "Student ID": student_ids,
        "Dropout Probability": probs
    })
    
    results = results.sort_values("Dropout Probability", ascending=False)

    print("\n" + "="*40)
    print("       DROPOUT RISK REPORT")
    print("="*40)
    print(results.to_string(index=False, formatters={"Dropout Probability": "{:.2%}".format}))
    print("\n")
    
    for _, row in results.iterrows():
        risk = row['Dropout Probability']
        sid = row['Student ID']
        if risk > 0.75:
            status = "🔴 CRITICAL RISK - INTERVENE NOW"
        elif risk > 0.45:
            status = "🟡 WATCH LIST"
        else:
            status = "🟢 SAFE"
        print(f"Student {sid}: {status}")

if __name__ == "__main__":
    predict_dropout(TEST_DATA, cutoff=60)