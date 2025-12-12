# FUTURE_ML_01
A complete end-to-end machine learning and forecasting project built using Power BI, Python, and Prophet to analyze retail sales patterns and predict future performance. This project demonstrates the ability to integrate advanced ML models directly inside Power BI using dynamic parameters—allowing real-time, scenario-based forecasting without static CSVs.

Here is a clean, professional summary written exactly as a **Machine Learning Engineer** would document a GitHub project.




# 📊 AI-Powered Dynamic Sales Forecasting Dashboard
Power BI + Python Prophet + Superstore Dataset

This project is a complete end-to-end forecasting system combining:
* Power BI Desktop for interactive dashboards
* Python Prophet for time-series forecasting
* Power Query + Python.Execute() for dynamic model retraining
* Superstore Retail Dataset as source data

Unlike traditional dashboards that rely on static CSVs, this project performs dynamic forecasting inside Power BI.

Whenever the user updates parameters (Region, Date Range, Forecast Horizon), Power BI sends the filtered dataset to Python → Prophet retrains → forecasts return to Power BI → visuals update automatically.


## 🚀 Key Features
🔄 **Dynamic Machine Learning**

* Power BI dynamically calls Python via Python.Execute()
* Prophet trains a new forecasting model on every refresh
* Forecasts adapt to selected:
* Region
* Start Date / End Date
* Forecast Horizon (months)

🗂️ **Multiple Forecasting Modes**

1. Region-wise forecasting
2. Date-range forecasting
3. Monthly aggregation of sales
4. Confidence intervals (upper/lower forecast)

📈 **Interactive Dashboard (PBIX Included)**

The dashboard contains:
1. Actual vs Forecast comparison
2. Region-wise sales trend
3. Monthly and seasonal patterns
4. KPI Cards (Actual Sales, Forecast Sales, YoY)
5. Forecast uncertainty bounds

🧠 **Prophet Model Features**

1. Yearly seasonality
2. Automatic trend detection
3. Support for custom horizon
4. Works on aggregated monthly sales


## 🏗️ Repository Structure
AI-Sales-Forecasting-Dashboard/
│
├── data/
│   ├── Sample_Superstore.csv            # Raw dataset (original Superstore sample)
│   └── superstore_cleaned.csv           # Cleaned version used for forecasting
│
├── powerbi/
│   ├── SalesForecastDashboard.pbix      # Main Power BI dashboard file
│   │                                    
│   ├── SalesForecastDynamic.m           # Power Query M script for dynamic forecasting
│   ├── RegionWiseSales.m                # Additional M script for region-wise visuals
│   ├── HorizonMonths.m                  # Parameter M script for forecasting horizon
│   │                                    
│   └── pythonSalesForecastDynamic.py    # Python code used inside Power BI (converted from M)
│
├── python/
│   ├── SalesForecastDynamic.py          # Standalone Python script for testing Prophet models
│   ├── clean_csv.py                     # Script to clean the raw Superstore dataset
│   ├── current_dir.py                   # Utility script (debug, print working directory)
│   └── __pycache__/                     # Auto-generated Python cache files
│
├── screenshots/
│   └── Screenshot 2025-12-12 ...        # Dashboard preview image
│
├── LICENSE                              # Project license (MIT recommended)
└── README.md


## 🔧 How the System Works (Architecture)
1️⃣ Power Query Filters Superstore & Calls Python

SalesForecastDynamic.m sends data + parameters to:

Python.Execute(...)

2️⃣ Python Script Runs Prophet

Aggregates sales monthly

Trains Prophet

Generates forecast for N months

Returns:

| ds | actual_sales | forecast_sales | forecast_lower | forecast_upper | Region |

3️⃣ Power BI Visuals Update

All graphs now use the freshly computed forecast.

📌 Important Files & Their Role
🔹 powerbi/SalesForecastDashboard.pbix

The main dashboard containing:

All visuals

Parameter bindings

Dynamic forecast line charts

KPI summary cards

🔹 powerbi/SalesForecastDynamic.m

Power Query script that handles:

Date filtering

Region filtering

Calling Python

Receiving forecast table

🔹 powerbi/pythonSalesForecastDynamic.py

The Python script executed inside Power BI, extracted for readability.
(It contains the Prophet training + forecasting logic.)

🔹 python/SalesForecastDynamic.py

A standalone Python version for:

Offline testing

Model debugging

Development without Power BI

## 🐍 Python Forecasting Logic (Summary)

Steps performed inside Python:

1. Convert Order Date → datetime

2. Filter by region + date

3. Aggregate sales → monthly

4. Train Prophet model:
m = Prophet(yearly_seasonality=True)
m.fit(ts)

5. Generate future dates

6. Predict:
forecast[['yhat', 'yhat_lower', 'yhat_upper']]

7. Merge history + forecast

8. Return result DataFrame to Power BI


## 🖥️ How to Run This Project on Your Machine
1. Install Requirements

Python 3.10+

Prophet

Power BI Desktop

Install Prophet:

pip install prophet pandas numpy

2. Configure Power BI Python

Power BI →
File → Options → Python Scripting → Select your Python installation.

3. Open Dashboard

Open:

powerbi/SalesForecastDashboard.pbix

4. Change Parameters

Inside Power Query →
Manage Parameters → Region / Dates / Horizon

Click Close & Apply → Power BI runs Prophet → dashboard updates.


## 📸 Dashboard Preview
<img width="1412" height="792" alt="Screenshot 2025-12-12 115038" src="https://github.com/user-attachments/assets/8e3089bd-eca0-4d36-8a22-7cac08fa9290" />


## 🎯 Project Goals

This project demonstrates:

Integration of ML models directly inside BI tools

Dynamic forecasting without external CSVs

Clean modular architecture (Python + Power Query + Power BI)

Strong understanding of analytics engineering

Real-world retail forecasting use case

Perfect for portfolios, interviews, and internships.


## 👤 Author

Devansh Gupta
AI Developer • Data Analyst • Power BI + Python + Automation
Linkedin:- https://www.linkedin.com/in/devansh-gupta-532410339


## 📄 License

This project is licensed under the MIT License.
See the LICENSE file for full legal text.






