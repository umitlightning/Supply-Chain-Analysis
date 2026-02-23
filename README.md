# Supply Chain Delivery Analysis

An end-to-end analysis of the USAID Supply Chain Management System (SCMS) delivery history dataset — covering exploratory data analysis, SQL-based reporting, and a machine learning model to predict shipment delays.

## Dataset

**Source:** [SCMS Delivery History Dataset – Kaggle / USAID](https://catalog.data.gov/dataset/supply-chain-shipment-pricing-data)  
**Size:** ~10,300 shipment records across 43 countries (2006–2015)  
**Key fields:** Shipment mode, country, vendor, scheduled vs. actual delivery dates, freight cost, product group, weight

## Project Structure

```
supply-chain-analysis/
│
├── data/
│   └── SCMS_Delivery_History.xlsx    # Raw dataset
│
├── sql/
│   └── supply_chain_queries.sql      # MySQL queries (EDA + reporting)
│
├── reports/
│   └── *.png                         # Generated charts
│
├── analysis.py                       # Main Python script (EDA + ML)
├── requirements.txt
└── README.md
```

## What's Inside

### Python (`analysis.py`)
- Data cleaning: date parsing, numeric coercion for freight cost & weight columns
- Derived feature: `delay_days` and binary `is_delayed` flag
- EDA charts saved to `/reports`:
  - Shipment volume & average delay by mode
  - Top 10 destination countries
  - Monthly delivery trend
  - Freight cost distribution (boxplot by mode)
- **Delay prediction model** — Random Forest Classifier
  - Features: shipment mode, fulfillment channel, incoterm, country, product group, weight, quantity, line item value
  - Output: classification report + feature importance + confusion matrix

### SQL (`supply_chain_queries.sql`)
10 ready-to-run MySQL queries covering:

| # | Query |
|---|-------|
| 1 | Overall on-time vs. delayed rate |
| 2 | Delay & freight cost by shipment mode |
| 3 | Top 10 countries by volume & delay rate |
| 4 | Vendor performance ranking |
| 5 | Monthly shipment trend |
| 6 | Product group breakdown by value |
| 7 | Freight cost vs. weight bucket |
| 8 | Most expensive delayed shipments |
| 9 | Incoterm impact on delay |
| 10 | Fulfillment channel comparison |

## Setup & Run

```bash
# 1. Clone the repo
git clone https://github.com/<your-username>/supply-chain-analysis.git
cd supply-chain-analysis

# 2. Install dependencies
pip install -r requirements.txt

# 3. Run analysis (generates charts in /reports)
python analysis.py
```

For the SQL queries, import the dataset into MySQL first (e.g. via a CSV export + `LOAD DATA INFILE`) and then run `sql/supply_chain_queries.sql` in your preferred client (MySQL Workbench, DBeaver, etc.).

## Key Findings

- **Air freight** dominates volume but carries a notable delay rate; **Ocean** shipments show higher average delays despite lower frequency.
- Freight cost varies significantly by shipment mode — Air Charter is the most expensive on a per-shipment basis.
- The Random Forest model achieves reasonable precision in flagging likely-delayed shipments, with **shipment mode, country, and weight** being the strongest predictors.

## Tools & Libraries

| Layer | Tools |
|-------|-------|
| Data wrangling | pandas, numpy |
| Visualisation | matplotlib, seaborn |
| Machine Learning | scikit-learn (Random Forest) |
| Database | MySQL |
| Dashboard *(in progress)* | Power BI |
