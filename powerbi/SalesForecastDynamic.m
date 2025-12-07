let
    Source = Superstore,

    #"Filtered Rows by Date" =
        Table.SelectRows(
            Source,
            each [Order Date] >= StartDateParam and [Order Date] <= EndDateParam
        ),

    Script =
"import pandas as pd
from prophet import Prophet

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
",
    #"Invoked Python" =
        Python.Execute(
            Script,
            [dataset = #"Filtered Rows by Date"]
        ),

    #"Get Result Table" = #"Invoked Python"{[Name="result"]}[Value],

    #"Changed Type" =
        Table.TransformColumnTypes(
            #"Get Result Table",
            {
                {"ds", type datetime},
                {"actual_sales", type number},
                {"forecast_sales", type number},
                {"forecast_lower", type number},
                {"forecast_upper", type number},
                {"Region", type text}
            }
        )

in
    #"Changed Type"