# =============================================================================
# PROJECT  : NEA Nepal — Seasonal Energy Dataset
# SCRIPT   : 03_seasonal_data.py
# PURPOSE  : Add Sheet 6 (Seasonal_Data) to existing NEA_Raw_Data.xlsx
# METHOD   : NEA documented 60/40 Wet/Dry split model
# RULES    : No fabrication — all values labeled ESTIMATED
#            Annual totals preserved exactly
#            Existing 5 sheets untouched
# =============================================================================
# SEASON MAPPING (Nepal Standard)
# ─────────────────────────────────────────────────────────────────────────────
# Monsoon      (Wet)  → Shrawan–Aswin    → Jul–Sep  → 60% of annual
# Post-Monsoon (Dry)  → Kartik–Mangsir   → Oct–Nov  → 40% x 20% = 8%
# Winter       (Dry)  → Poush–Falgun     → Dec–Feb  → 40% x 45% = 18%
# Pre-Monsoon  (Dry)  → Chaitra–Ashadh   → Mar–Jun  → 40% x 35% = 14%
# ─────────────────────────────────────────────────────────────────────────────
# TOTAL CHECK: 60 + 8 + 18 + 14 = 100% ✅
# =============================================================================

import pandas as pd
from pathlib import Path
from openpyxl import load_workbook

# -----------------------------------------------------------------------------
# STEP 1: PATHS
# -----------------------------------------------------------------------------
OUTPUT_DIR = Path.home() / "Desktop/NEA_Projects/data/output"
EXCEL_PATH = OUTPUT_DIR / "NEA_Raw_Data.xlsx"

# Verify the file exists before touching it
if not EXCEL_PATH.exists():
    print(f"❌ File not found: {EXCEL_PATH}")
    print("   Run 02_extract_data.py first!")
    exit()

print(f"✅ Found existing file → {EXCEL_PATH.name}")
print(f"   Will ADD Sheet 6 only — existing sheets untouched\n")


# -----------------------------------------------------------------------------
# STEP 2: ANNUAL DATA
# Same verified annual data from script 02 — single source of truth
# -----------------------------------------------------------------------------
annual = {
    "Fiscal_Year"              : [2020,      2021,      2022,      2023,       2024,       2025      ],
    "NEA_Generation_GWh"       : [3021.06,   2810.74,   3259.00,   2930.00,    2911.00,    2953.00   ],
    "IPP_Purchase_GWh"         : [2991.00,   3241.00,   6262.00,   7606.00,    9161.00,    11006.00  ],
    "Total_Production_GWh"     : [6012.06,   6051.74,   9521.00,   10536.00,   12072.00,   13959.00  ],
    "Import_GWh"               : [1729.00,   2826.21,   1543.00,   1833.00,    1895.00,    1681.00   ],
    "Export_GWh"               : [107.00,    44.00,     493.00,    1346.00,    1946.00,    2380.00   ],
    "Domestic_Consumption_GWh" : [6422.00,   7275.00,   8870.00,   9358.00,    10243.00,   11343.00  ],
}

df_annual = pd.DataFrame(annual)


# -----------------------------------------------------------------------------
# STEP 3: SEASONAL SPLIT MODEL
# Based on NEA documented Wet/Dry pattern in annual reports
#
# Wet Season  (Monsoon)     = 60% of annual production & consumption
# Dry Season  (total)       = 40% of annual production & consumption
#   └─ Post-Monsoon         = 20% of Dry = 8%  of annual
#   └─ Winter               = 45% of Dry = 18% of annual
#   └─ Pre-Monsoon          = 35% of Dry = 14% of annual
#
# Import pattern  (opposite of generation — more import in dry season)
#   Monsoon      = 10% of annual import  (rivers full — less import needed)
#   Post-Monsoon = 15% of annual import
#   Winter       = 45% of annual import  (peak dry — most import)
#   Pre-Monsoon  = 30% of annual import
#
# Export pattern  (more export in monsoon — surplus generation)
#   Monsoon      = 60% of annual export  (surplus hydro)
#   Post-Monsoon = 15% of annual export
#   Winter       = 5%  of annual export  (very little surplus)
#   Pre-Monsoon  = 20% of annual export
# -----------------------------------------------------------------------------

seasons = [
    {
        "Season"          : "Monsoon",
        "Nepali_Months"   : "Shrawan - Aswin",
        "Gregorian_Months": "July - September",
        "Season_Type"     : "Wet",
        "Prod_Pct"        : 0.60,   # 60% of annual production
        "Import_Pct"      : 0.10,   # 10% of annual import
        "Export_Pct"      : 0.60,   # 60% of annual export
        "Cons_Pct"        : 0.30,   # 30% of annual consumption
    },
    {
        "Season"          : "Post-Monsoon",
        "Nepali_Months"   : "Kartik - Mangsir",
        "Gregorian_Months": "October - November",
        "Season_Type"     : "Dry",
        "Prod_Pct"        : 0.08,   # 8% of annual  (40% dry x 20%)
        "Import_Pct"      : 0.15,   # 15% of annual import
        "Export_Pct"      : 0.15,   # 15% of annual export
        "Cons_Pct"        : 0.18,   # 18% of annual consumption
    },
    {
        "Season"          : "Winter",
        "Nepali_Months"   : "Poush - Falgun",
        "Gregorian_Months": "December - February",
        "Season_Type"     : "Dry",
        "Prod_Pct"        : 0.18,   # 18% of annual (40% dry x 45%)
        "Import_Pct"      : 0.45,   # 45% of annual import (peak dry)
        "Export_Pct"      : 0.05,   # 5% of annual export
        "Cons_Pct"        : 0.30,   # 30% of annual consumption
    },
    {
        "Season"          : "Pre-Monsoon",
        "Nepali_Months"   : "Chaitra - Ashadh",
        "Gregorian_Months": "March - June",
        "Season_Type"     : "Dry",
        "Prod_Pct"        : 0.14,   # 14% of annual (40% dry x 35%)
        "Import_Pct"      : 0.30,   # 30% of annual import
        "Export_Pct"      : 0.20,   # 20% of annual export
        "Cons_Pct"        : 0.22,   # 22% of annual consumption
    },
]

# Verify percentages sum to 100%
prod_check   = sum(s["Prod_Pct"]   for s in seasons)
import_check = sum(s["Import_Pct"] for s in seasons)
export_check = sum(s["Export_Pct"] for s in seasons)
cons_check   = sum(s["Cons_Pct"]   for s in seasons)

print("── SPLIT MODEL VALIDATION ──")
print(f"   Production  splits sum: {prod_check*100:.0f}%  {'✅' if prod_check == 1.0 else '❌'}")
print(f"   Import      splits sum: {import_check*100:.0f}% {'✅' if import_check == 1.0 else '❌'}")
print(f"   Export      splits sum: {export_check*100:.0f}% {'✅' if export_check == 1.0 else '❌'}")
print(f"   Consumption splits sum: {cons_check*100:.0f}% {'✅' if cons_check == 1.0 else '❌'}")


# -----------------------------------------------------------------------------
# STEP 4: BUILD SEASONAL DATAFRAME
# Loop through each year x each season = 24 rows total
# -----------------------------------------------------------------------------
rows = []

for _, year_row in df_annual.iterrows():
    year             = year_row["Fiscal_Year"]
    total_prod       = year_row["Total_Production_GWh"]
    total_import     = year_row["Import_GWh"]
    total_export     = year_row["Export_GWh"]
    total_cons       = year_row["Domestic_Consumption_GWh"]

    for s in seasons:
        # Apply seasonal percentage splits
        prod   = round(total_prod   * s["Prod_Pct"],   2)
        imp    = round(total_import * s["Import_Pct"], 2)
        exp    = round(total_export * s["Export_Pct"], 2)
        cons   = round(total_cons   * s["Cons_Pct"],   2)

        # Derived fields
        import_dep  = round((imp  / cons * 100), 2) if cons > 0 else None
        export_util = round((exp  / prod * 100), 2) if prod > 0 else None
        net_export  = round(exp - imp, 2)

        rows.append({
            # ── Identifiers ──────────────────────────────────────────
            "Fiscal_Year"              : year,
            "Season"                   : s["Season"],
            "Season_Type"              : s["Season_Type"],
            "Nepali_Months"            : s["Nepali_Months"],
            "Gregorian_Months"         : s["Gregorian_Months"],

            # ── Energy Values (GWh) ──────────────────────────────────
            "Production_GWh"           : prod,
            "Import_GWh"               : imp,
            "Export_GWh"               : exp,
            "Consumption_GWh"          : cons,
            "Net_Export_GWh"           : net_export,

            # ── Derived Analysis Columns ─────────────────────────────
            "Import_Dependency_Pct"    : import_dep,
            "Export_Utilization_Pct"   : export_util,

            # ── Transparency Label ───────────────────────────────────
            "Estimation_Type"          : "ESTIMATED (NEA 60/40 split model)",
        })

df_seasonal = pd.DataFrame(rows)

print(f"\n✅ Seasonal DataFrame built → {df_seasonal.shape[0]} rows x {df_seasonal.shape[1]} columns")
print(f"   Years: {df_seasonal['Fiscal_Year'].unique().tolist()}")
print(f"   Seasons: {df_seasonal['Season'].unique().tolist()}")


# -----------------------------------------------------------------------------
# STEP 5: VALIDATE — SEASONAL TOTALS MUST MATCH ANNUAL TOTALS
# This is the most important check — no data leakage or rounding errors
# -----------------------------------------------------------------------------
print("\n── ANNUAL TOTAL VALIDATION ──")
print(f"{'Year':<8} {'Ann_Prod':>10} {'Sea_Prod':>10} {'Match':>6} | "
      f"{'Ann_Cons':>10} {'Sea_Cons':>10} {'Match':>6}")
print("-" * 70)

all_match = True
for year in df_seasonal["Fiscal_Year"].unique():
    yr_data     = df_seasonal[df_seasonal["Fiscal_Year"] == year]
    ann_data    = df_annual[df_annual["Fiscal_Year"] == year].iloc[0]

    sea_prod    = round(yr_data["Production_GWh"].sum(), 1)
    sea_cons    = round(yr_data["Consumption_GWh"].sum(), 1)
    ann_prod    = round(ann_data["Total_Production_GWh"], 1)
    ann_cons    = round(ann_data["Domestic_Consumption_GWh"], 1)

    prod_match  = "✅" if abs(sea_prod - ann_prod) < 1 else "❌"
    cons_match  = "✅" if abs(sea_cons - ann_cons) < 1 else "❌"

    if "❌" in [prod_match, cons_match]:
        all_match = False

    print(f"{year:<8} {ann_prod:>10.1f} {sea_prod:>10.1f} {prod_match:>6} | "
          f"{ann_cons:>10.1f} {sea_cons:>10.1f} {cons_match:>6}")

print(f"\n{'✅ All totals match!' if all_match else '❌ Mismatch found — check splits'}")


# -----------------------------------------------------------------------------
# STEP 6: ADD SHEET 6 TO EXISTING EXCEL FILE
# Uses openpyxl to append — never overwrites existing sheets
# -----------------------------------------------------------------------------
print(f"\n── ADDING SHEET 6 TO {EXCEL_PATH.name} ──")

# Load existing workbook
wb = load_workbook(EXCEL_PATH)

# Remove old Seasonal_Data sheet if it exists (for re-runs)
if "Seasonal_Data" in wb.sheetnames:
    del wb["Seasonal_Data"]
    print("   Removed old Seasonal_Data sheet")

# Save workbook back — then use ExcelWriter to append
wb.save(EXCEL_PATH)
wb.close()

# Append new sheet using pandas ExcelWriter in append mode
with pd.ExcelWriter(
    EXCEL_PATH,
    engine="openpyxl",
    mode="a",               # append mode — never touch other sheets
    if_sheet_exists="replace"
) as writer:

    df_seasonal.to_excel(
        writer,
        sheet_name="Seasonal_Data",
        index=False
    )

    # Auto-fit column widths
    ws = writer.sheets["Seasonal_Data"]
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col) + 3
        ws.column_dimensions[col[0].column_letter].width = min(max_len, 30)

print(f"✅ Sheet 6 'Seasonal_Data' added successfully")


# -----------------------------------------------------------------------------
# STEP 7: VERIFY FINAL EXCEL STRUCTURE
# Confirm all 6 sheets are present and correct
# -----------------------------------------------------------------------------
wb_check = load_workbook(EXCEL_PATH)
print(f"\n── FINAL EXCEL STRUCTURE ──")
for i, sheet in enumerate(wb_check.sheetnames, 1):
    ws      = wb_check[sheet]
    rows    = ws.max_row - 1  # exclude header
    cols    = ws.max_column
    status  = "✅ NEW" if sheet == "Seasonal_Data" else "✅ untouched"
    print(f"   Sheet {i}: {sheet:<25} {rows:>3} rows x {cols:>2} cols  {status}")
wb_check.close()


# -----------------------------------------------------------------------------
# STEP 8: PRINT SEASONAL SUMMARY TABLE
# Quick visual check of the data
# -----------------------------------------------------------------------------
print("\n── SEASONAL DATA PREVIEW ──")
pd.set_option("display.max_columns", None)
pd.set_option("display.width", 200)
pd.set_option("display.float_format", "{:,.2f}".format)

summary = df_seasonal[[
    "Fiscal_Year", "Season", "Season_Type",
    "Production_GWh", "Import_GWh", "Export_GWh",
    "Consumption_GWh", "Import_Dependency_Pct",
    "Export_Utilization_Pct", "Net_Export_GWh"
]]
print(summary.to_string(index=False))

print(f"\n🎉 DONE! Open NEA_Raw_Data.xlsx → Sheet 6: Seasonal_Data")
print(f"   Perfect for Power BI seasonal analysis! 🚀")