# PolicyShift: Counterfactual Simulation Shiny App
## Quick Start Guide

---

## 📦 Files Included

| File | Description |
|------|-------------|
| `policyshift_app.R` | Main Shiny app (run this) |
| `policyshift_sample_data.csv` | Sample dataset (100 rows) |
| `README.md` | This guide |

---

## 🚀 How to Run

### Option 1: Run directly in R / RStudio

```r
# Step 1: Install required packages
install.packages(c(
  "shiny", "shinydashboard", "ggplot2", "dplyr",
  "randomForest", "pROC", "DT", "plotly",
  "viridis", "shinyWidgets", "shinycssloaders"
))

# Step 2: Run the app
shiny::runApp("policyshift_app.R")
```

### Option 2: Run from RStudio
1. Open `policyshift_app.R` in RStudio
2. Click the **"Run App"** button (top right of editor)

---

## 📋 Step-by-Step Usage

### Step 1 — Load Data (Data Upload tab)
- Select **"Use built-in sample dataset"** → click **Load Data**
- OR upload your own CSV with matching variable names

### Step 2 — Explore Data (Exploratory tab)
- View variable distributions
- Check depression prevalence by subgroup
- Explore correlation heatmap

### Step 3 — Train Model (ML Model tab)
- Adjust number of trees (default: 200)
- Click **"Train Model"**
- Check AUC and ROC curve

### Step 4 — Simulate Policy (Simulation tab)
- Adjust sliders:
  - Education level (years)
  - Wealth index (1–5)
  - Healthcare access (0–10)
  - Employment rate (%)
  - Media exposure (0–10)
- Click **"Run Simulation"**
- View before/after prevalence and subgroup effects

### Step 5 — Download (Download tab)
- **HTML Report** — Full interactive report
- **Sample CSV** — Data file
- **R Script** — Standalone script for offline use

---

## 📊 Variable Dictionary

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `depression` | Binary | 0/1 | **Outcome variable** |
| `education_yr` | Numeric | 0–20 | Years of education (policy lever) |
| `wealth_idx` | Numeric | 1–5 | Wealth index score (policy lever) |
| `urban` | Binary | 0/1 | Urban (1) vs Rural (0) |
| `employed` | Binary | 0/1 | Employment status (policy lever) |
| `health_access` | Numeric | 0–10 | Healthcare access score (policy lever) |
| `media_exp` | Numeric | 0–10 | Media exposure score |
| `age` | Numeric | 18–50 | Age in years |
| `weight` | Numeric | 0.5–2.5 | Survey sampling weight |

---

## 🧠 Methodology

1. **Model**: Random Forest classifier (survey-weighted compatible)
2. **Counterfactual Engine**: Feature perturbation — user changes policy lever values, model re-predicts
3. **Subgroup Analysis**: Effects estimated by urban/rural × wealth group
4. **Evaluation**: AUC, Accuracy on held-out test set

---

## 🔬 Extending the App

To add XGBoost or causal forests:
```r
# Add to required packages
library(xgboost)
library(grf) # for causal forest

# Causal forest (requires treatment + outcome)
cf <- causal_forest(X, Y, W)
```

---

## 📬 Contact
Built for competition: PolicyShift v1.0
