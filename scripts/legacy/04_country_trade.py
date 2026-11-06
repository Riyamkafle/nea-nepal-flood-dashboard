# =============================================================================
# PROJECT  : NEA Nepal — Cross Border Electricity Trade Dataset
# SCRIPT   : 04_country_trade.py
# PURPOSE  : Add Sheet 7 (Country_Trade) to existing NEA_Raw_Data.xlsx
# SOURCE   : NEA Annual Reports FY 2019/20 → FY 2024/25
# RULES    : No fabrication — NULL if not found in PDF
#            All units in GWh for energy, Million NPR for value
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
    print("   Run 02_extract_data.py first!")
    exit()

print(f"✅ Found → {EXCEL_PATH.name}")
print(f"   Will ADD Sheet 7 only — existing sheets untouched\n")


# -----------------------------------------------------------------------------
# STEP 2: COUNTRY TRADE DATA
# Every value sourced directly from NEA Annual Report PDF text dumps
# NULL = genuinely not found in any PDF — no assumptions made
#
# INDIA: Nepal's only active electricity trade partner (all years)
# BANGLADESH: Trade started June 2025 (40 MW monsoon season only)
# CHINA: Study stage only — no actual trade data exists
# -----------------------------------------------------------------------------
data = [

    # ── INDIA FY 2019/20 ──────────────────────────────────────────────
    {
        "Fiscal_Year"              : 2020,
        "Country"                  : "India",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "NVVN / PGCIL",
        "Trade_Mechanism"          : "Power Exchange / Bilateral",
        "Export_GWh"               : 107.00,
        "Import_GWh"               : 1729.00,
        "Net_Flow_GWh"             : 107.00 - 1729.00,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Year Round",
        "Notes"                    : "Import via Dhalkebar-Muzaffarpur 400kV line. Nepal net importer.",
        "Data_Source"              : "NEA Annual Report 2019/20",
    },

    # ── INDIA FY 2020/21 ──────────────────────────────────────────────
    {
        "Fiscal_Year"              : 2021,
        "Country"                  : "India",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "NVVN / PGCIL",
        "Trade_Mechanism"          : "Power Exchange / Bilateral",
        "Export_GWh"               : 44.00,
        "Import_GWh"               : 2826.21,
        "Net_Flow_GWh"             : 44.00 - 2826.21,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Year Round",
        "Notes"                    : "High import due to delay in Upper Tamakoshi commissioning. COVID impact on export.",
        "Data_Source"              : "NEA Annual Report 2020/21",
    },

    # ── INDIA FY 2021/22 ──────────────────────────────────────────────
    {
        "Fiscal_Year"              : 2022,
        "Country"                  : "India",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "NVVN / PGCIL / IEX",
        "Trade_Mechanism"          : "Power Exchange / Day-Ahead Market",
        "Export_GWh"               : 493.00,
        "Import_GWh"               : 1543.00,
        "Net_Flow_GWh"             : 493.00 - 1543.00,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : 452.00,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Year Round",
        "Notes"                    : "First country in South Asia to join Indian Energy Exchange (IEX). Export 452 MW from 10 hydro projects.",
        "Data_Source"              : "NEA Annual Report 2021/22",
    },

    # ── INDIA FY 2022/23 ──────────────────────────────────────────────
    {
        "Fiscal_Year"              : 2023,
        "Country"                  : "India",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "NVVN / PGCIL / IEX / PTC India",
        "Trade_Mechanism"          : "PEC / Day-Ahead / Medium Term Bilateral",
        "Export_GWh"               : 1346.00,
        "Import_GWh"               : 1833.00,
        "Net_Flow_GWh"             : 1346.00 - 1833.00,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Year Round",
        "Notes"                    : "Medium term agreement: 200 MW to Haryana (May 2023). PTC India agreement 300 MW (June 2023). PEC tariff escalation 5.5%.",
        "Data_Source"              : "NEA Annual Report 2022/23",
    },

    # ── INDIA FY 2023/24 ──────────────────────────────────────────────
    {
        "Fiscal_Year"              : 2024,
        "Country"                  : "India",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "NVVN / PGCIL / IEX / PTC India",
        "Trade_Mechanism"          : "PEC / Day-Ahead / Medium Term Bilateral",
        "Export_GWh"               : 1946.00,
        "Import_GWh"               : 1895.00,
        "Net_Flow_GWh"             : 1946.00 - 1895.00,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Year Round",
        "Notes"                    : "Nepal became NET EXPORTER for first time. Export exceeded import by 51 GWh. Butwal-Gorakhpur 400kV line under implementation.",
        "Data_Source"              : "NEA Annual Report 2023/24",
    },

    # ── INDIA FY 2024/25 ──────────────────────────────────────────────
    {
        "Fiscal_Year"              : 2025,
        "Country"                  : "India",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "NVVN / PGCIL / IEX / NTPC Vidhyut",
        "Trade_Mechanism"          : "PEC / Day-Ahead / Medium Term Bilateral",
        "Export_GWh"               : 2380.00,
        "Import_GWh"               : 1681.00,
        "Net_Flow_GWh"             : 2380.00 - 1681.00,
        "Export_Revenue_NPR_Million": 17471.00,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Year Round",
        "Notes"                    : "Export revenue NRs 17,471 million (17.47 billion). Export up 22% from previous year. Nepal confirmed net exporter.",
        "Data_Source"              : "NEA Annual Report 2024/25",
    },

    # ── BANGLADESH FY 2019/20 to 2023/24 ─────────────────────────────
    {
        "Fiscal_Year"              : 2020,
        "Country"                  : "Bangladesh",
        "Trade_Status"             : "No Trade",
        "Trade_Partner"            : None,
        "Trade_Mechanism"          : None,
        "Export_GWh"               : None,
        "Import_GWh"               : None,
        "Net_Flow_GWh"             : None,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : None,
        "Notes"                    : "No electricity trade. Discussions at study stage only.",
        "Data_Source"              : "NEA Annual Report 2019/20",
    },
    {
        "Fiscal_Year"              : 2021,
        "Country"                  : "Bangladesh",
        "Trade_Status"             : "No Trade",
        "Trade_Partner"            : None,
        "Trade_Mechanism"          : None,
        "Export_GWh"               : None,
        "Import_GWh"               : None,
        "Net_Flow_GWh"             : None,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : None,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : None,
        "Notes"                    : "No electricity trade. COVID impacted cross-border discussions.",
        "Data_Source"              : "NEA Annual Report 2020/21",
    },
    {
        "Fiscal_Year"              : 2022,
        "Country"                  : "Bangladesh",
        "Trade_Status"             : "No Trade",
        "Trade_Partner"            : "BPDB (planned)",
        "Trade_Mechanism"          : "Tripartite (planned)",
        "Export_GWh"               : None,
        "Import_GWh"               : None,
        "Net_Flow_GWh"             : None,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : 40.00,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : None,
        "Notes"                    : "40 MW export planned via Indian grid. Baharampur-Bheramara 400kV HVDC link discussed.",
        "Data_Source"              : "NEA Annual Report 2021/22",
    },
    {
        "Fiscal_Year"              : 2023,
        "Country"                  : "Bangladesh",
        "Trade_Status"             : "Planned",
        "Trade_Partner"            : "BPDB / NVVN",
        "Trade_Mechanism"          : "Tripartite Agreement (finalizing)",
        "Export_GWh"               : None,
        "Import_GWh"               : None,
        "Net_Flow_GWh"             : None,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : 40.00,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Monsoon (planned)",
        "Notes"                    : "Tripartite agreement NEA+NVVN+BPDB in final stage. 40 MW via Baharampur-Bheramara HVDC. Wet season export planned.",
        "Data_Source"              : "NEA Annual Report 2022/23",
    },
    {
        "Fiscal_Year"              : 2024,
        "Country"                  : "Bangladesh",
        "Trade_Status"             : "Planned",
        "Trade_Partner"            : "BPDB / NVVN",
        "Trade_Mechanism"          : "Tripartite Agreement (signing soon)",
        "Export_GWh"               : None,
        "Import_GWh"               : None,
        "Net_Flow_GWh"             : None,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : 40.00,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Monsoon (planned)",
        "Notes"                    : "Agreement to be signed soon. 4th JSC meeting Nepal-Bangladesh agreed to form JV for Sunkoshi III (683 MW).",
        "Data_Source"              : "NEA Annual Report 2023/24",
    },
    {
        "Fiscal_Year"              : 2025,
        "Country"                  : "Bangladesh",
        "Trade_Status"             : "Active",
        "Trade_Partner"            : "BPDB / NVVN / India",
        "Trade_Mechanism"          : "Tripartite Agreement",
        "Export_GWh"               : None,
        "Import_GWh"               : None,
        "Net_Flow_GWh"             : None,
        "Export_Revenue_NPR_Million": None,
        "Import_Cost_NPR_Million"  : None,
        "Export_Capacity_MW"       : 40.00,
        "Import_Capacity_MW"       : None,
        "Season_Active"            : "Monsoon only (June 15 - Oct 2025)",
        "Notes"                    : "FIRST EVER export to Bangladesh. 40 MW started June 15 2025 via India transmission line. 5 month monsoon season. Tripartite signed October 2024.",
        "Data_Source"              : "NEA Annual Report 2024/25",
    },
]

df_trade = pd.DataFrame(data)

# Add dependency columns where possible
df_trade["Export_Share_of_Total_Pct"] = None
df_trade["Import_Dependency_Pct"]     = None

print(f"✅ Trade DataFrame built → {df_trade.shape[0]} rows x {df_trade.shape[1]} columns")
print(f"   Countries: {df_trade['Country'].unique().tolist()}")
print(f"   Years    : {df_trade['Fiscal_Year'].unique().tolist()}")


# -----------------------------------------------------------------------------
# STEP 3: ADD SHEET 7 TO EXISTING EXCEL FILE
# -----------------------------------------------------------------------------
print(f"\n── ADDING SHEET 7 TO {EXCEL_PATH.name} ──")

wb = load_workbook(EXCEL_PATH)
if "Country_Trade" in wb.sheetnames:
    del wb["Country_Trade"]
    print("   Removed old Country_Trade sheet")
wb.save(EXCEL_PATH)
wb.close()

with pd.ExcelWriter(
    EXCEL_PATH,
    engine="openpyxl",
    mode="a",
    if_sheet_exists="replace"
) as writer:

    df_trade.to_excel(
        writer,
        sheet_name="Country_Trade",
        index=False
    )

    ws = writer.sheets["Country_Trade"]
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col) + 3
        ws.column_dimensions[col[0].column_letter].width = min(max_len, 35)

print(f"✅ Sheet 7 'Country_Trade' added successfully")


# -----------------------------------------------------------------------------
# STEP 4: VERIFY FINAL EXCEL STRUCTURE
# -----------------------------------------------------------------------------
wb_check = load_workbook(EXCEL_PATH)
print(f"\n── FINAL EXCEL STRUCTURE ──")
for i, sheet in enumerate(wb_check.sheetnames, 1):
    ws     = wb_check[sheet]
    rows   = ws.max_row - 1
    cols   = ws.max_column
    status = "✅ NEW" if sheet == "Country_Trade" else "✅ untouched"
    print(f"   Sheet {i}: {sheet:<25} {rows:>3} rows x {cols:>2} cols  {status}")
wb_check.close()


# -----------------------------------------------------------------------------
# STEP 5: PRINT SUMMARY
# -----------------------------------------------------------------------------
print("\n── TRADE DATA SUMMARY ──")
pd.set_option("display.max_columns", None)
pd.set_option("display.width", 200)

summary = df_trade[[
    "Fiscal_Year", "Country", "Trade_Status",
    "Export_GWh", "Import_GWh", "Net_Flow_GWh",
    "Export_Revenue_NPR_Million", "Export_Capacity_MW"
]]
print(summary.to_string(index=False))

print(f"\n── KEY INSIGHTS FROM DATA ──")
india = df_trade[df_trade["Country"] == "India"]
print(f"   India Export trend  : {india['Export_GWh'].tolist()} GWh")
print(f"   India Import trend  : {india['Import_GWh'].tolist()} GWh")
print(f"   Net Flow trend      : {[round(x,2) for x in india['Net_Flow_GWh'].tolist()]} GWh")
print(f"   Nepal became NET EXPORTER in: FY 2023/24 (first time ever)")
print(f"   Bangladesh trade started  in: FY 2024/25 (June 15, 2025)")

print(f"\n🎉 DONE! Open NEA_Raw_Data.xlsx → Sheet 7: Country_Trade")
print(f"   Ready for Power BI cross-border trade map analysis! 🚀")