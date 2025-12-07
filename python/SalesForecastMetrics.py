import pandas as pd
from prophet import Prophet
import numpy as np
from typing import Optional
import os

from current_dir import get_current_dir

def build_forecast_metrics(
    df: pd.DataFrame, 
    region: str = "All", 
    start_date: Optional[str] = None, 
    end_date: Optional[str] = None, 
    horizon: int = 6,
    ) -> pd.DataFrame:

    df = df.copy()
    df["Order Date"] = pd.to_datetime(df["Order Date"])

    if start_date is None:
        start_date = df["Order Date"].min()
    if end_date is None:
        end_date = df["Order Date"].max()

    if isinstance(region, str) and region not in ["", "All"]:
        df = df[df["Region"] == region]

    df = df[
        (df["Order Date"] >= pd.to_datetime(start_date)) &
        (df["Order Date"] <= pd.to_datetime(end_date))
    ]

    metrics = pd.DataFrame(
        columns=[
            "Region", "TestMonths", "MAE", "RMSE", "MAPE",
            "TrainStart", "TrainEnd", "TestStart", "TestEnd"
        ]
    )

    try:
        if df.empty:
            region_value = region if isinstance(region, str) else "All"
            return pd.DataFrame([{
                "Region": region_value,
                "TestMonths": 0,
                "MAE": None,
                "RMSE": None,
                "MAPE": None,
                "TrainStart": None,
                "TrainEnd": None,
                "TestStart": None,
                "TestEnd": None
            }])

        df["ds"] = df["Order Date"].dt.to_period("M").dt.to_timestamp()
        monthly = (
            df.groupby("ds", as_index=False)["Sales"]
              .sum()
              .sort_values("ds")
        )
        ts = monthly.rename(columns={"Sales": "y"})

        total_points = len(ts)
        if total_points < 3:
            region_value = region if isinstance(region, str) else "All"
            return pd.DataFrame([{
                "Region": region_value,
                "TestMonths": 0,
                "MAE": None,
                "RMSE": None,
                "MAPE": None,
                "TrainStart": ts["ds"].min() if total_points > 0 else None,
                "TrainEnd": ts["ds"].max() if total_points > 0 else None,
                "TestStart": None,
                "TestEnd": None
            }])

        test_months = min(6, max(1, total_points // 4))
        train = ts.iloc[:-test_months]
        test = ts.iloc[-test_months:]

        m = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=False,
            daily_seasonality=False
        )
        m.fit(train)

        future_hist = ts[["ds"]].copy()
        forecast = m.predict(future_hist)

        merged = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].merge(
            ts[["ds", "y"]], on="ds", how="left"
        )

        merged.rename(
            columns={
                "y": "actual_sales",
                "yhat": "forecast_sales",
                "yhat_lower": "forecast_lower",
                "yhat_upper": "forecast_upper"
            },
            inplace=True
        )

        region_value = region if isinstance(region, str) and region not in ["", "All"] else "All"

        test_merge = merged[merged["ds"].isin(test["ds"])].copy()
        test_merge = test_merge.dropna(subset=["actual_sales"])

        if test_merge.empty:
            return pd.DataFrame([{
                "Region": region_value,
                "TestMonths": 0,
                "MAE": None,
                "RMSE": None,
                "MAPE": None,
                "TrainStart": train["ds"].min(),
                "TrainEnd": train["ds"].max(),
                "TestStart": None,
                "TestEnd": None
            }])

        y_true = test_merge["actual_sales"].values
        y_pred = test_merge["forecast_sales"].values

        mae = np.mean(np.abs(y_true - y_pred))
        rmse = np.sqrt(np.mean((y_true - y_pred) ** 2))

        denom = np.where(y_true == 0, np.nan, y_true)
        mape = np.nanmean(np.abs((y_true - y_pred) / denom)) * 100

        metrics = pd.DataFrame([{
            "Region": region_value,
            "TestMonths": int(len(test_merge)),
            "MAE": float(mae),
            "RMSE": float(rmse),
            "MAPE": float(mape),
            "TrainStart": train["ds"].min(),
            "TrainEnd": train["ds"].max(),
            "TestStart": test["ds"].min(),
            "TestEnd": test["ds"].max()
        }])

        return metrics

    except Exception:
        region_value = region if isinstance(region, str) else "All"
        return pd.DataFrame([{
            "Region": region_value,
            "TestMonths": 0,
            "MAE": None,
            "RMSE": None,
            "MAPE": None,
            "TrainStart": None,
            "TrainEnd": None,
            "TestStart": None,
            "TestEnd": None
        }])

if __name__ == "__main__":
    BASE_DIR = get_current_dir()

    data_path = os.path.join(BASE_DIR, "..", "data", "superstore_cleaned.csv")
    data_path = os.path.normpath(data_path)

    df_superstore = pd.read_csv(data_path)

    forecast_df = build_forecast_metrics(
        df_superstore,
        region="All",
        start_date="2015-01-01",
        end_date="2018-12-31",
        horizon=6,
    )

    print("Forecast Metrics:")
    print(forecast_df)