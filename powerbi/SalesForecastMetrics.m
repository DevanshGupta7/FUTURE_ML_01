let
    Source = Superstore,

    #"Filtered Rows by Date" =
        Table.SelectRows(
            Source,
            each [Order Date] >= StartDateParam and [Order Date] <= EndDateParam
        ),

    PythonOutput = Python.Execute(
"import pandas as pd
from prophet import Prophet
import numpy as np

df = dataset.copy()

region = '" & RegionParam & "'
start_date = '" & DateTime.ToText(StartDateParam, "yyyy-MM-dd HH:mm:ss") & "'
end_date = '" & DateTime.ToText(EndDateParam, "yyyy-MM-dd HH:mm:ss") & "'
horizon = " & Text.From(HorizonMonthsParam) & "

df['Order Date'] = pd.to_datetime(df['Order Date'])

if isinstance(region, str) and region not in ['', 'All']:
    df = df[df['Region'] == region]

df = df[
    (df['Order Date'] >= pd.to_datetime(start_date)) &
    (df['Order Date'] <= pd.to_datetime(end_date))
]

result = pd.DataFrame(columns=[
    'ds', 'actual_sales', 'forecast_sales',
    'forecast_lower', 'forecast_upper', 'Region'
])
metrics = pd.DataFrame(columns=[
    'Region', 'TestMonths', 'MAE', 'RMSE', 'MAPE',
    'TrainStart', 'TrainEnd', 'TestStart', 'TestEnd'
])

try:
    if df.empty:
        pass
    else:
        df['ds'] = df['Order Date'].dt.to_period('M').dt.to_timestamp()
        monthly = (
            df.groupby('ds', as_index=False)['Sales']
              .sum()
              .sort_values('ds')
        )

        ts = monthly.rename(columns={'Sales': 'y'})

        total_points = len(ts)
        test_months = min(6, max(1, total_points // 4))

        train = ts.iloc[:-test_months]
        test = ts.iloc[-test_months:]

        m = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=False,
            daily_seasonality=False
        )
        m.fit(train)

        future_hist = ts[['ds']].copy()
        forecast = m.predict(future_hist)

        merged = forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].merge(
            ts[['ds', 'y']], on='ds', how='left'
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

        region_value = region if isinstance(region, str) and region not in ['', 'All'] else 'All'
        merged['Region'] = region_value

        result = merged

        test_merge = merged[merged['ds'].isin(test['ds'])].copy()
        test_merge = test_merge.dropna(subset=['actual_sales'])

        if not test_merge.empty:
            y_true = test_merge['actual_sales'].values
            y_pred = test_merge['forecast_sales'].values

            mae = np.mean(np.abs(y_true - y_pred))
            rmse = np.sqrt(np.mean((y_true - y_pred) ** 2))

            denom = np.where(y_true == 0, np.nan, y_true)
            mape = np.nanmean(np.abs((y_true - y_pred) / denom)) * 100

            metrics = pd.DataFrame([{
                'Region': region_value,
                'TestMonths': int(len(test_merge)),
                'MAE': float(mae),
                'RMSE': float(rmse),
                'MAPE': float(mape),
                'TrainStart': train['ds'].min(),
                'TrainEnd': train['ds'].max(),
                'TestStart': test['ds'].min(),
                'TestEnd': test['ds'].max()
            }])

except Exception as e:
    metrics = pd.DataFrame([{
        'Region': str(region),
        'TestMonths': 0,
        'MAE': None,
        'RMSE': None,
        'MAPE': None,
        'TrainStart': None,
        'TrainEnd': None,
        'TestStart': None,
        'TestEnd': None
    }])
",
        [dataset = #"Filtered Rows by Date"]
    ),

    MetricsTable = PythonOutput{[Name="metrics"]}[Value],
    #"Changed Type" = Table.TransformColumnTypes(
        MetricsTable,
        {
            {"Region", type text},
            {"TestMonths", Int64.Type},
            {"MAE", type number},
            {"RMSE", type number},
            {"MAPE", type number},
            {"TrainStart", type datetime},
            {"TrainEnd", type datetime},
            {"TestStart", type datetime},
            {"TestEnd", type datetime}
        }
    )
in
    #"Changed Type"