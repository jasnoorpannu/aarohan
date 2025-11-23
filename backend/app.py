from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import joblib
import numpy as np
import os
from pathlib import Path
import tempfile

app = Flask(__name__)
CORS(app)

# Paths
BASE_DIR = Path(__file__).resolve().parents[1]
MODEL_PATH = BASE_DIR / "models" / "dropout_model.pkl"

# Load model at startup
try:
    model = joblib.load(MODEL_PATH)
    print(f"✓ Model loaded successfully from {MODEL_PATH}")
except FileNotFoundError:
    print(f"⚠ Warning: Model not found at {MODEL_PATH}")
    model = None


def load_raw(path):
    """Load and preprocess raw CSV data"""
    df = pd.read_csv(path)
    df["date"] = pd.to_numeric(df["date"], errors="coerce").fillna(0)
    return df


def get_static_features(df):
    """Extract static student features"""
    static_cols = [
        "id_student", "gender", "region", "highest_education", 
        "imd_band", "age_band", "num_of_prev_attempts", 
        "studied_credits", "disability", "code_module", "code_presentation"
    ]
    
    static = df[static_cols].drop_duplicates(subset=["id_student"])
    
    cat_cols = ["gender", "region", "highest_education", "imd_band", 
                "age_band", "disability", "code_module", "code_presentation"]
    
    for col in cat_cols:
        static[col] = static[col].astype("category")
        
    return static


def advanced_agg(df, cutoff=None):
    """Extract dynamic features from student activity"""
    if cutoff is not None:
        print(f"    -> Filtering data: Keeping only days <= {cutoff}")
        df = df[df["date"] <= cutoff]

    daily = df.groupby(["id_student", "date"])["sum_click"].sum().reset_index()

    def slope(values):
        if len(values) < 3:
            return 0
        return np.polyfit(np.arange(len(values)), values, 1)[0]

    click_stats = daily.groupby("id_student").agg(
        total_clicks=("sum_click", "sum"),
        avg_daily_clicks=("sum_click", "mean"),
        std_clicks=("sum_click", "std"),
        active_days_count=("date", "nunique"),
        last_active_day=("date", "max")
    )

    click_trend = daily.groupby("id_student")["sum_click"].apply(list).apply(slope).to_frame("click_trend")
    
    def avg_gap(dates):
        if len(dates) < 2:
            return 0
        sorted_dates = np.sort(dates)
        return np.mean(np.diff(sorted_dates))

    gap_stats = daily.groupby("id_student")["date"].apply(avg_gap).to_frame("avg_study_gap")

    dynamic = pd.concat([click_stats, click_trend, gap_stats], axis=1).reset_index()
    return dynamic


def prepare_inference_data(df, cutoff=None):
    """Prepare data for model inference"""
    print(f"--- Preparing Data (Cutoff: {cutoff} days) ---")
    
    static = get_static_features(df)
    dynamic = advanced_agg(df, cutoff=cutoff)
    
    features = static.merge(dynamic, on="id_student", how="left")
    
    numeric_cols = features.select_dtypes(include=['number']).columns
    features[numeric_cols] = features[numeric_cols].fillna(0)
    
    return features


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None
    }), 200


@app.route('/predict', methods=['POST'])
def predict_dropout():
    """
    Predict dropout probability for students
    
    Expected input: CSV file with student data
    Query params (optional):
        - cutoff: number of days to consider (default: None)
    
    Returns: JSON with predictions for each student
    """
    if model is None:
        return jsonify({
            'error': 'Model not loaded. Please train the model first.'
        }), 500
    
    # Check if CSV file is provided
    if 'file' not in request.files:
        return jsonify({
            'error': 'No CSV file provided. Please upload a file with key "file".'
        }), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({
            'error': 'No file selected.'
        }), 400
    
    if not file.filename.endswith('.csv'):
        return jsonify({
            'error': 'File must be a CSV file.'
        }), 400
    
    # Get optional cutoff parameter
    cutoff = request.args.get('cutoff', type=int, default=None)
    
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(mode='wb', suffix='.csv', delete=False) as tmp_file:
            file.save(tmp_file.name)
            temp_path = tmp_file.name
        
        # Load and process data
        print(f"Processing uploaded CSV file...")
        raw_df = load_raw(temp_path)
        
        # Prepare features
        X_df = prepare_inference_data(raw_df, cutoff=cutoff)
        
        if X_df.empty:
            return jsonify({
                'error': 'Feature extraction resulted in empty data. Check CSV format.'
            }), 400
        
        student_ids = X_df["id_student"].tolist()
        X = X_df.drop(["id_student"], axis=1)
        
        # Handle categorical columns
        for col in X.select_dtypes(['category']).columns:
            X[col] = X[col].astype('category')
        
        # Make predictions
        print("Running predictions...")
        probs = model.predict(X)
        
        # Prepare results
        results = []
        for sid, prob in zip(student_ids, probs):
            results.append({
                'student_id': int(sid),
                'dropout_probability': float(prob)
            })
        
        # Sort by probability (highest first)
        results = sorted(results, key=lambda x: x['dropout_probability'], reverse=True)
        
        # Clean up temp file
        os.unlink(temp_path)
        
        return jsonify({
            'success': True,
            'cutoff_days': cutoff,
            'total_students': len(results),
            'predictions': results
        }), 200
        
    except Exception as e:
        # Clean up temp file if it exists
        if 'temp_path' in locals():
            try:
                os.unlink(temp_path)
            except:
                pass
        
        return jsonify({
            'error': f'Error processing request: {str(e)}'
        }), 500


@app.route('/predict-batch', methods=['POST'])
def predict_batch():
    """
    Alternative endpoint that accepts JSON data directly
    
    Expected input: JSON with student data records
    Body format:
    {
        "cutoff": 60 (optional),
        "data": [
            {
                "id_student": 123,
                "gender": "M",
                "region": "East Region",
                ... (all required fields)
            },
            ...
        ]
    }
    """
    if model is None:
        return jsonify({
            'error': 'Model not loaded. Please train the model first.'
        }), 500
    
    try:
        data = request.get_json()
        
        if not data or 'data' not in data:
            return jsonify({
                'error': 'Missing "data" field in JSON body.'
            }), 400
        
        cutoff = data.get('cutoff', None)
        
        # Convert JSON to DataFrame
        raw_df = pd.DataFrame(data['data'])
        raw_df["date"] = pd.to_numeric(raw_df["date"], errors="coerce").fillna(0)
        
        # Prepare features
        X_df = prepare_inference_data(raw_df, cutoff=cutoff)
        
        if X_df.empty:
            return jsonify({
                'error': 'Feature extraction resulted in empty data. Check JSON format.'
            }), 400
        
        student_ids = X_df["id_student"].tolist()
        X = X_df.drop(["id_student"], axis=1)
        
        # Handle categorical columns
        for col in X.select_dtypes(['category']).columns:
            X[col] = X[col].astype('category')
        
        # Make predictions
        probs = model.predict(X)
        
        # Prepare results
        results = []
        for sid, prob in zip(student_ids, probs):
            results.append({
                'student_id': int(sid),
                'dropout_probability': float(prob)
            })
        
        results = sorted(results, key=lambda x: x['dropout_probability'], reverse=True)
        
        return jsonify({
            'success': True,
            'cutoff_days': cutoff,
            'total_students': len(results),
            'predictions': results
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': f'Error processing request: {str(e)}'
        }), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
