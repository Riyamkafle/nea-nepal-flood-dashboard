# =============================================================================
# PROJECT  : NEA Nepal — Policy Targets vs Reality Analysis
# SCRIPT   : 06_policy_targets.py
# PURPOSE  : Add Sheet 8 (Policy_Targets) to NEA_Raw_Data.xlsx
# =============================================================================

import pandas as pd
from pathlib import Path
from openpyxl import load_workbook

OUTPUT_DIR = Path.home() / "Desktop/NEA_Projects/NEA_Projects/data/output"
EXCEL_PATH = OUTPUT_DIR / "NEA_Raw_Data.xlsx"

# ── POLICY TARGETS DATA ──────────────────────────────────────────────────────
policy_data = {
    "Year": [2020, 2021, 2022, 2023, 2024, 2025,
             2026, 2027, 2028, 2029, 2030],

    # Actual data from your PDFs (2020-2025)
    # Projected using avg growth rate for 2026-2030
    "Actual_Capacity_MW": [
        5978.13, None, None, 7758.00, 10301.00, None,
        None, None, None, None, None
    ],

    # Government official target (NEA/MOEWRI White Paper)
    "Govt_Official_Target_MW": [
        None, None, None, None, None, None,
        None, None, None, None, 11000.00
    ],

    # Ruling party political promise
    "Political_Target_MW": [
        None, None, None, None, None, None,
        None, None, None, 15000.00, None
    ],

    # Projection at current growth rate (+1,080 MW/year)
    "Projected_At_Current_Rate_MW": [
        5978.13, 7058.13, 8138.13, 9218.13, 10298.13, 11378.13,
        12458.13, 13538.13, 14618.13, 15698.13, 16778.13
    ],

    # Under construction pipeline
    "Under_Construction_MW": [
        None, None, None, None, 4303.00, None,
        None, None, None, None, None
    ],

    # Gap to government target
    "Gap_To_Govt_Target_MW": [
        5021.87, None, None, 3242.00, 699.00, None,
        None, None, None, None, 0
    ],

    # Gap to political target
    "Gap_To_Political_Target_MW": [
        9021.87, None, None, 7242.00, 4699.00, None,
        None, None, None, 0, None
    ],

    # Data type label
    "Data_Type": [
        "Actual", "Actual", "Actual", "Actual", "Actual", "Actual",
        "Projected", "Projected", "Projected", "Projected", "Projected"
    ],

    # Reality check
    "Feasibility_Note": [
        "Base year",
        "COVID impact on construction",
        "IPP boom begins",
        "Strong growth continues",
        "On track for 11,000 MW target",
        "11,000 MW likely achieved",
        "Growth depends on transmission",
        "Market absorption critical",
        "Export agreements needed",
        "15,000 MW — possible if IPP pace maintained",
        "11,000 MW — likely exceeded",
    ]
}

df = pd.DataFrame(policy_data)

# ── ADD TO EXCEL ─────────────────────────────────────────────────────────────
wb = load_workbook(EXCEL_PATH)
if "Policy_Targets" in wb.sheetnames:
    del wb["Policy_Targets"]
wb.save(EXCEL_PATH)
wb.close()

with pd.ExcelWriter(EXCEL_PATH, engine="openpyxl",
                    mode="a", if_sheet_exists="replace") as writer:
    df.to_excel(writer, sheet_name="Policy_Targets", index=False)
    ws = writer.sheets["Policy_Targets"]
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col) + 3
        ws.column_dimensions[col[0].column_letter].width = min(max_len, 35)

print("✅ Sheet 8 Policy_Targets added!")

# ── PRINT ANALYSIS ───────────────────────────────────────────────────────────
print("\n── POLITICAL REALITY CHECK ──")
print(f"""
Current Installed (2024)    : 10,301 MW
Under Construction          :  4,303 MW
Total Pipeline              : 14,604 MW

Government Target (2030)    : 11,000 MW → WILL BE EXCEEDED ✅
Political Target (2029)     : 15,000 MW → POSSIBLE if pace maintained ⚠️

Key Risk Factors:
→ Transmission capacity bottleneck
→ Market absorption (who buys the power?)
→ Seasonal storage gap
→ Financing requirements $15-20 billion
→ Natural disasters (Bhotekoshi flood 2024)
""")