import pandas as pd
from prophet import Prophet
from typing import Optional
import os

from current_dir import get_current_dir

def build_forecast(
    df: pd.DataFrame, 
    region: str = "All", 
    start_date: Optional[str] = None, 
    end_date: Optional[str] = None, 
    horizon: int = 6,
    ) -> pd.DataFrame:

    df = df.copy()

    df['Order Date'] = pd.to_datetime(df['Order Date'])

    if isinstance(region, str) and region not in ['', 'All']:
        df = df[df['Region'] == region]

    df = df[
        (df['Order Date'] >= pd.to_datetime(start_date)) &
        (df['Order Date'] <= pd.to_datetime(end_date))
    ]

    if df.empty:
        result = pd.DataFrame(columns=[
            'ds', 'actual_sales', 'forecast_sales',
            'forecast_lower', 'forecast_upper', 'Region'
        ])

    else:
        df['ds'] = df['Order Date'].dt.to_period('M').dt.to_timestamp()
        monthly = (
            df.groupby('ds', as_index=False)['Sales']
            .sum()
            .sort_values('ds')
        )

        ts = monthly.rename(columns={'Sales': 'y'})

        m = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=False,
            daily_seasonality=False
        )

        m.fit(ts)

        future = m.make_future_dataframe(
            periods=horizon,
            freq='MS'
        )

        forecast = m.predict(future)

        merged = forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].merge(
            ts[['ds', 'y']],
            on='ds',
            how='left'
        )

        merged.rename(
            columns={
                'y': 'actual_sales',
                'yhat': 'forecast_sales',
                'yhat_lower': 'forecast_lower',
                'yhat_upper': 'forecast_upper'
            },
            inplace=True
        )

        if isinstance(region, str) and region not in ['', 'All']:
            region_value = region

        else:
            region_value = 'All'

        merged['Region'] = region_value

        result = merged
        return result

if __name__ == "__main__":
    BASE_DIR = get_current_dir()

    data_path = os.path.join(BASE_DIR, "..", "data", "superstore_cleaned.csv")
    data_path = os.path.normpath(data_path)

    df_superstore = pd.read_csv(data_path)

    forecast_df = build_forecast(
        df_superstore,
        region="All",
        start_date="2015-01-01",
        end_date="2018-12-31",
        horizon=6,
    )

    print("Forecast head:")
    print(forecast_df.head())