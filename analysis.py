import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.preprocessing import LabelEncoder
import warnings
warnings.filterwarnings("ignore")

# ── Config ──────────────────────────────────────────────────────────────────
FILE_PATH = "data/SCMS_Delivery_History.xlsx"
REPORT_DIR = "reports"
RANDOM_STATE = 42

plt.rcParams.update({"figure.dpi": 130, "axes.spines.top": False,
                     "axes.spines.right": False})

# ── 1. Load & Clean ──────────────────────────────────────────────────────────
df = pd.read_excel(FILE_PATH)

# Standardise column names
df.columns = [c.strip().lower().replace(" ", "_").replace("/", "_").replace("(", "").replace(")", "") for c in df.columns]

# Parse dates that came in as object
for col in ["pq_first_sent_to_client_date", "po_sent_to_vendor_date"]:
    df[col] = pd.to_datetime(df[col], errors="coerce")

# Freight cost – strip non-numeric rows
df["freight_cost_usd"] = pd.to_numeric(df["freight_cost_usd"], errors="coerce")
df["weight_kilograms"] = pd.to_numeric(df["weight_kilograms"], errors="coerce")

# Delivery delay in days (positive = late, negative = early)
df["delay_days"] = (df["delivered_to_client_date"] - df["scheduled_delivery_date"]).dt.days
df["is_delayed"] = (df["delay_days"] > 0).astype(int)

print(f"Dataset shape : {df.shape}")
print(f"Delayed shipments: {df['is_delayed'].sum()} / {df['is_delayed'].count()} "
      f"({df['is_delayed'].mean()*100:.1f}%)\n")

# ── 2. EDA Plots ─────────────────────────────────────────────────────────────

# 2a. Shipments by Mode
fig, axes = plt.subplots(1, 2, figsize=(13, 5))

mode_counts = df["shipment_mode"].value_counts()
axes[0].barh(mode_counts.index, mode_counts.values, color="#4C72B0")
axes[0].set_xlabel("Number of Shipments")
axes[0].set_title("Shipments by Mode")

# 2b. Delay distribution per mode
delay_mode = df.groupby("shipment_mode")["delay_days"].mean().sort_values()
axes[1].barh(delay_mode.index, delay_mode.values,
             color=["#dd4949" if v > 0 else "#55a868" for v in delay_mode.values])
axes[1].axvline(0, color="black", linewidth=0.8, linestyle="--")
axes[1].set_xlabel("Avg Delay (days)")
axes[1].set_title("Average Delay by Shipment Mode")

plt.tight_layout()
plt.savefig(f"{REPORT_DIR}/shipment_mode_analysis.png")
plt.close()
print("Saved: shipment_mode_analysis.png")

# 2c. Top 10 countries by shipment volume
fig, ax = plt.subplots(figsize=(10, 5))
top_countries = df["country"].value_counts().head(10)
ax.bar(top_countries.index, top_countries.values, color="#4C72B0")
ax.set_ylabel("Shipments")
ax.set_title("Top 10 Countries by Shipment Volume")
plt.xticks(rotation=35, ha="right")
plt.tight_layout()
plt.savefig(f"{REPORT_DIR}/top_countries.png")
plt.close()
print("Saved: top_countries.png")

# 2d. Monthly shipment trend
df["year_month"] = df["scheduled_delivery_date"].dt.to_period("M")
monthly = df.groupby("year_month").size()
fig, ax = plt.subplots(figsize=(13, 4))
monthly.plot(ax=ax, color="#4C72B0", linewidth=1.8)
ax.set_title("Monthly Scheduled Deliveries")
ax.set_xlabel("")
ax.set_ylabel("Shipment Count")
plt.tight_layout()
plt.savefig(f"{REPORT_DIR}/monthly_trend.png")
plt.close()
print("Saved: monthly_trend.png")

# 2e. Freight cost by shipment mode (box)
fig, ax = plt.subplots(figsize=(9, 5))
df_fc = df[df["freight_cost_usd"].notna() & (df["freight_cost_usd"] < df["freight_cost_usd"].quantile(0.99))]
df_fc.boxplot(column="freight_cost_usd", by="shipment_mode", ax=ax, grid=False)
ax.set_title("Freight Cost Distribution by Shipment Mode")
plt.suptitle("")
ax.set_xlabel("")
ax.set_ylabel("Freight Cost (USD)")
plt.tight_layout()
plt.savefig(f"{REPORT_DIR}/freight_cost_boxplot.png")
plt.close()
print("Saved: freight_cost_boxplot.png")

# ── 3. ML – Delay Prediction ──────────────────────────────────────────────────
print("\n── Delay Prediction Model ──")

features = ["shipment_mode", "fulfill_via", "vendor_inco_term", "country",
            "product_group", "weight_kilograms", "line_item_quantity", "line_item_value"]

ml_df = df[features + ["is_delayed"]].dropna()

le = LabelEncoder()
for col in ["shipment_mode", "fulfill_via", "vendor_inco_term", "country", "product_group"]:
    ml_df[col] = le.fit_transform(ml_df[col].astype(str))

X = ml_df[features]
y = ml_df["is_delayed"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2,
                                                     random_state=RANDOM_STATE, stratify=y)

clf = RandomForestClassifier(n_estimators=200, max_depth=8, class_weight="balanced",
                              random_state=RANDOM_STATE, n_jobs=-1)
clf.fit(X_train, y_train)
y_pred = clf.predict(X_test)

print(classification_report(y_test, y_pred, target_names=["On Time", "Delayed"]))

# Feature importance
importance = pd.Series(clf.feature_importances_, index=features).sort_values()
fig, ax = plt.subplots(figsize=(8, 5))
importance.plot(kind="barh", ax=ax, color="#4C72B0")
ax.set_title("Feature Importances – Delay Prediction")
ax.set_xlabel("Importance Score")
plt.tight_layout()
plt.savefig(f"{REPORT_DIR}/feature_importance.png")
plt.close()
print("Saved: feature_importance.png")

# Confusion matrix
fig, ax = plt.subplots(figsize=(5, 4))
cm = confusion_matrix(y_test, y_pred)
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", ax=ax,
            xticklabels=["On Time", "Delayed"], yticklabels=["On Time", "Delayed"])
ax.set_ylabel("Actual")
ax.set_xlabel("Predicted")
ax.set_title("Confusion Matrix")
plt.tight_layout()
plt.savefig(f"{REPORT_DIR}/confusion_matrix.png")
plt.close()
print("Saved: confusion_matrix.png")

print("\nAll done. Check the /reports folder.")
