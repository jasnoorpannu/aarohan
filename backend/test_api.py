"""
Test script for the Dropout Prediction API
"""
import requests
import json

# API base URL
BASE_URL = "http://localhost:5000"


def test_health():
    """Test the health check endpoint"""
    print("=" * 50)
    print("Testing Health Check Endpoint")
    print("=" * 50)
    
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print()


def test_predict_csv(csv_file_path, cutoff=None):
    """Test the CSV upload prediction endpoint"""
    print("=" * 50)
    print("Testing CSV Upload Prediction")
    print("=" * 50)
    
    url = f"{BASE_URL}/predict"
    
    with open(csv_file_path, 'rb') as f:
        files = {'file': f}
        params = {}
        if cutoff:
            params['cutoff'] = cutoff
        
        response = requests.post(url, files=files, params=params)
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Total Students: {data.get('total_students')}")
        print(f"Cutoff Days: {data.get('cutoff_days')}")
        print("\nTop 5 Students by Dropout Probability:")
        print("-" * 50)
        
        for pred in data.get('predictions', [])[:5]:
            prob = pred['dropout_probability']
            # Determine risk emoji based on probability (for display only)
            if prob > 0.75:
                emoji = "🔴"
            elif prob > 0.45:
                emoji = "🟡"
            else:
                emoji = "🟢"
            print(f"{emoji} Student {pred['student_id']}: {prob:.2%}")
    else:
        print(f"Error: {response.json()}")
    print()


def test_predict_json():
    """Test the JSON prediction endpoint"""
    print("=" * 50)
    print("Testing JSON Batch Prediction")
    print("=" * 50)
    
    # Sample data (you can modify this)
    sample_data = {
        "cutoff": 60,
        "data": [
            {
                "id_student": 999,
                "gender": "M",
                "region": "East Region",
                "highest_education": "A Level or Equivalent",
                "imd_band": "50-60%",
                "age_band": "18-25",
                "num_of_prev_attempts": 0,
                "studied_credits": 60,
                "disability": "N",
                "code_module": "AAA",
                "code_presentation": "2013J",
                "date": 10,
                "sum_click": 15
            }
        ]
    }
    
    response = requests.post(
        f"{BASE_URL}/predict-batch",
        json=sample_data,
        headers={'Content-Type': 'application/json'}
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"Success: {data.get('success')}")
        print(f"Total Students: {data.get('total_students')}")
        print("\nPredictions:")
        print("-" * 50)
        
        for pred in data.get('predictions', []):
            prob = pred['dropout_probability']
            # Determine risk emoji based on probability (for display only)
            if prob > 0.75:
                emoji = "🔴"
            elif prob > 0.45:
                emoji = "🟡"
            else:
                emoji = "🟢"
            print(f"{emoji} Student {pred['student_id']}: {prob:.2%}")
    else:
        print(f"Error: {response.json()}")
    print()


if __name__ == "__main__":
    print("\n🚀 Starting API Tests\n")
    
    try:
        # Test 1: Health check
        test_health()
        
        # Test 2: CSV upload (modify path as needed)
        csv_path = "../data/test.csv"
        print(f"Note: Using CSV file at: {csv_path}")
        print("If this file doesn't exist, the test will fail.\n")
        
        try:
            test_predict_csv(csv_path, cutoff=60)
        except FileNotFoundError:
            print(f"⚠️  CSV file not found at {csv_path}")
            print("Skipping CSV test. You can provide your own path.\n")
        
        # Test 3: JSON batch prediction
        # test_predict_json()  # Uncomment to test
        
        print("✅ Tests completed!")
        
    except requests.exceptions.ConnectionError:
        print("❌ Error: Could not connect to the API.")
        print("Make sure the Flask server is running on http://localhost:5000")
        print("\nTo start the server, run:")
        print("    cd backend")
        print("    python app.py")
