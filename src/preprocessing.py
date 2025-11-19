import pandas as pd
import numpy as np

def load_raw(path):
    return pd.read_csv(path)

def label_dropout(df):
    df = df.copy()
    df["dropout"] = (df["final_result"] == "Withdrawn").astype(int)
    return df

def basic_agg(df):
    daily = df.groupby(["id_student", "date"])["sum_click"].sum().reset_index()

    def slope(values):
        if len(values) < 2:
            return 0
        x = np.arange(len(values))
        return np.polyfit(x, values, 1)[0]

    gb = daily.groupby("id_student").agg(
        total_clicks=("sum_click", "sum"),
        avg_clicks=("sum_click", "mean"),
        max_daily_clicks=("sum_click", "max"),
        min_daily_clicks=("sum_click", "min"),
        std_clicks=("sum_click", "std"),
        active_days=("date", "nunique"),
        engagement_trend=("sum_click", slope),
        last_active=("date", "max"),
    ).reset_index()

    max_date = daily["date"].max()
    gb["days_since_last_active"] = max_date - gb["last_active"]

    gb = gb.drop(columns=["last_active"])
    gb = gb.fillna(0)

    return gb

def prepare_features(df):
    df = label_dropout(df)
    feats = basic_agg(df)
    labels = df.groupby("id_student")["dropout"].max().reset_index()
    out = feats.merge(labels, on="id_student", how="left")
    return out.fillna(0)

def prepare_features_inference(df):
    feats = basic_agg(df)
    return feats.fillna(0)
