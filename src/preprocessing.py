import pandas as pd
import numpy as np

def load_raw(path):
    df = pd.read_csv(path)
    df["date"] = pd.to_numeric(df["date"], errors="coerce").fillna(0)
    return df

def label_dropout(df):
    target = df.groupby("id_student")["final_result"].first()
    dropout = (target == "Withdrawn").astype(int).reset_index()
    dropout.columns = ["id_student", "dropout"]
    return dropout

def get_static_features(df):
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
    if cutoff is not None:
        print(f"    -> Filtering data: Keeping only days <= {cutoff}")
        df = df[df["date"] <= cutoff]

    daily = df.groupby(["id_student", "date"])["sum_click"].sum().reset_index()

    def slope(values):
        if len(values) < 3: return 0
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
        if len(dates) < 2: return 0
        sorted_dates = np.sort(dates)
        return np.mean(np.diff(sorted_dates))

    gap_stats = daily.groupby("id_student")["date"].apply(avg_gap).to_frame("avg_study_gap")

    dynamic = pd.concat([click_stats, click_trend, gap_stats], axis=1).reset_index()
    return dynamic

def prepare_features(df, cutoff=None):
    print("Extracting Static Features...")
    static_feats = get_static_features(df)
    
    print(f"Extracting Dynamic Features (Cutoff: {cutoff})...")
    dynamic_feats = advanced_agg(df, cutoff=cutoff)
    
    print("Merging...")
    features = static_feats.merge(dynamic_feats, on="id_student", how="left")
    numeric_cols = features.select_dtypes(include=['number']).columns
    features[numeric_cols] = features[numeric_cols].fillna(0)
    
    labels = label_dropout(df)
    
    out = features.merge(labels, on="id_student", how="inner")
    
    return out