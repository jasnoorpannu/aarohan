from pathlib import Path

BASE = Path(__file__).resolve().parents[1]

DATA_DIR = BASE / "data"
MODEL_DIR = BASE / "models"
RAW_DATA = DATA_DIR / "oulad_joined.csv"
MODEL_PATH = MODEL_DIR / "dropout_model.pkl"
TEST_DATA = DATA_DIR / "test.csv"
