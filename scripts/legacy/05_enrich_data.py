# =============================================================================
# PROJECT  : NEA Nepal — Enriched Dataset
# SCRIPT   : 05_enrich_data.py
# PURPOSE  : Add 3 new columns to All_Data sheet in NEA_Raw_Data.xlsx
#            1. System_Loss_Pct     — all 6 years confirmed
#            2. Consumers_Million   — 5 of 6 years confirmed
#            3. Total_Capacity_MW   — 4 of 6 years confirmed
# SOURCE   : NEA Annual Reports (direct PDF extraction)
# RULES    : No fabrication — NULL if not found in PDF
#            All existing sheets untouched
# =============================================================================

import pandas as pd
from pathlib import Path
from openpyxl import load_workbook

# -----------------------------------------------------------------------------
# STEP 1: PATHS
# -----------------------------------------------------------------------------
OUTPUT_DIR = Path.home() / "Desktop/NEA_Projects/data/output"
EXCEL_PATH = OUTPUT_DIR / "NEA_Raw_Data.xlsx"

if not EXCEL_PATH.exists():
    print(f"❌ File not found: {EXCEL_PATH}")
    exit()

print(f"✅ Found → {EXCEL_PATH.name}")
print(f"   Will UPDATE Sheet 1 (All_Data) only\n")

# -----------------------------------------------------------------------------
# STEP 2: COMPLETE VERIFIED DATASET
# All values sourced directly from NEA Annual Report PDF text dumps
# NULL = genuinely not found in any PDF
# -----------------------------------------------------------------------------
data = {
    "Fiscal_Year"              : [2020,       2021,       2022,       2023,        2024,        2025      ],
    "NEA_Generation_GWh"       : [3021.06,    2810.74,    3259.00,    2930.00,     2911.00,     2953.00   ],
    "IPP_Purchase_GWh"         : [2991.00,    3241.00,    6262.00,    7606.00,     9161.00,     11006.00  ],
    "Total_Production_GWh"     : [6012.06,    6051.74,    9521.00,    10536.00,    12072.00,    13959.00  ],
    "Import_GWh"               : [1729.00,    2826.21,    1543.00,    1833.00,     1895.00,     1681.00   ],
    "Export_GWh"               : [107.00,     44.00,      493.00,     1346.00,     1946.00,     2380.00   ],
    "Domestic_Consumption_GWh" : [6422.00,    7275.00,    8870.00,    9358.00,     10243.00,    11343.00  ],
    "Peak_Demand_MW"           : [1407.94,    1482.00,    1747.53,    1870.46,     2211.62,     2409.00   ],
    "Peak_Supply_MW"           : [None,       1481.85,    1963.98,    2171.15,     2467.00,     2901.00   ],
    "Revenue_NPR_Million"      : [73760.00,   76726.00,   87120.00,   100032.00,   115798.00,   125277.00 ],
    "Cost_NPR_Million"         : [62704.00,   70718.00,   70955.00,   87639.00,    102491.00,   116210.00 ],
    "Profit_NPR_Million"       : [11056.00,   6008.00,    16165.00,   12393.00,    13307.00,    9067.00   ],

    # ── NEW COLUMNS ───────────────────────────────────────────────────
    # System Loss % — confirmed from all 6 PDFs
    # Source: Managing Director's Report — Loss section each year
    "System_Loss_Pct"          : [15.27,      17.18,      15.38,      13.46,       12.73,       12.26     ],

    # Total Consumers in Millions
    # 2020: 4.22M (Annual_book_2077)
    # 2021: 5.08M (2020-21 report)
    # 2022: NULL  — not confirmed in PDF
    # 2023: 5.134058M → rounded 5.13M (NEA_Annual_Report_2023)
    # 2024: 5.46M (2023-2024 report)
    # 2025: 5.71M (2024-2025 report)
    "Consumers_Million"        : [4.22,       5.08,       None,       5.13,        5.46,        5.71      ],

    # Total System Installed Capacity MW
    # = NEA own + IPP + Subsidiaries (total national grid)
    # 2020: 5,978.13 MW (Annual_book_2077 line 766)
    # 2021: NULL — only NEA own (626 MW) found, total not stated
    # 2022: NULL — not found in PDF
    # 2023: 7,758 MW (NEA_Annual_Report_2023 line 522)
    # 2024: 10,301 MW (2023-2024 report line 771)
    # 2025: NULL — only NEA own (3,591 MW) confirmed, total not stated
    "Total_Capacity_MW"        : [5978.13,    None,       None,       7758.00,     10301.00,    None      ],
}

df = pd.DataFrame(data)

# ── DERIVED COLUMNS ──────────────────────────────────────────────────────────
df["Net_Export_GWh"]       = df["Export_GWh"]           - df["Import_GWh"]
df["Total_Available_GWh"]  = df["Total_Production_GWh"] + df["Import_GWh"]
df["Profit_Margin_Pct"]    = (df["Profit_NPR_Million"]  / df["Revenue_NPR_Million"] * 100).round(2)

# Capacity utilization — only where both values exist
df["Capacity_Utilization_Pct"] = None
for i, row in df.iterrows():
    if row["Total_Capacity_MW"] and row["Peak_Demand_MW"]:
        df.at[i, "Capacity_Utilization_Pct"] = round(
            row["Peak_Demand_MW"] / row["Total_Capacity_MW"] * 100, 2
        )

# Print full dataset
pd.set_option("display.max_columns", None)
pd.set_option("display.width", 250)
pd.set_option("display.float_format", "{:,.2f}".format)

print("=" * 80)
print("  NEA NEPAL — ENRICHED COMPLETE DATASET   2020 → 2025")
print("=" * 80)
print(df.to_string(index=False))
print(f"\nShape: {df.shape[0]} rows x {df.shape[1]} columns")

# Missing value report
print("\n── MISSING VALUES ──")
missing = df.isnull().sum()
missing = missing[missing > 0]
if len(missing) > 0:
    for col, count in missing.items():
        print(f"   {col:35s} → {count} missing out of {len(df)}")
else:
    print("   ✅ No missing values!")

# -----------------------------------------------------------------------------
# STEP 3: REPLACE ALL_DATA SHEET IN EXCEL
# Keep all other sheets untouched
# -----------------------------------------------------------------------------
print(f"\n── UPDATING All_Data SHEET IN {EXCEL_PATH.name} ──")

wb = load_workbook(EXCEL_PATH)
if "All_Data" in wb.sheetnames:
    del wb["All_Data"]
    print("   Removed old All_Data sheet")
wb.save(EXCEL_PATH)
wb.close()

with pd.ExcelWriter(
    EXCEL_PATH,
    engine="openpyxl",
    mode="a",
    if_sheet_exists="replace"
) as writer:
    df.to_excel(writer, sheet_name="All_Data", index=False)
    ws = writer.sheets["All_Data"]
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col) + 3
        ws.column_dimensions[col[0].column_letter].width = min(max_len, 28)

print(f"✅ All_Data sheet updated with 3 new columns")

# -----------------------------------------------------------------------------
# STEP 4: VERIFY FINAL EXCEL STRUCTURE
# -----------------------------------------------------------------------------
wb_check = load_workbook(EXCEL_PATH)
print(f"\n── FINAL EXCEL STRUCTURE ──")
for i, sheet in enumerate(wb_check.sheetnames, 1):
    ws     = wb_check[sheet]
    rows   = ws.max_row - 1
    cols   = ws.max_column
    status = "✅ UPDATED" if sheet == "All_Data" else "✅ untouched"
    print(f"   Sheet {i}: {sheet:<25} {rows:>3} rows x {cols:>2} cols  {status}")
wb_check.close()

# -----------------------------------------------------------------------------
# STEP 5: ANALYSIS SUMMARY
# -----------------------------------------------------------------------------
print("""
── KEY INSIGHTS FROM ENRICHED DATA ──

System Loss Trend:
  2020: 15.27% → 2021: 17.18% (COVID impact)
  → 2022: 15.38% → 2023: 13.46%
  → 2024: 12.73% → 2025: 12.26% (all time low!)
  Story: NEA cutting losses every year after COVID ✅

Consumer Growth:
  2020: 4.22M → 2025: 5.71M = +35% in 5 years
  Story: Rapid electrification of Nepal ✅

Capacity Growth:
  2020: 5,978 MW → 2024: 10,301 MW = +72% in 4 years
  Story: IPP boom driving Nepal energy surplus ✅

Nepal Energy Journey:
  2020 → Heavy importer (1,729 GWh import)
  2024 → First NET EXPORTER (export > import)
  2025 → Confirmed net exporter (2,380 GWh export)
""")

print("🎉 DONE! Your dataset is now complete for Power BI analysis!")
print(f"   Open NEA_Raw_Data.xlsx → All_Data sheet")
print(f"   Now has {df.shape[1]} columns across 6 years 🚀")