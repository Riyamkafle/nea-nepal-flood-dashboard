"""Validate hand-entered values and compute derived columns.

Input : data/cleaned/annual_national.csv   (hand-entered from NEA annual reports)
Output: data/processed/annual_national_full.csv  (entered + derived columns)
        data/processed/validation_checks.csv     (every check, pass/flag)

Derived columns are ALWAYS recomputed here, never typed by hand:
  total_production_gwh = nea_generation_gwh + ipp_purchase_gwh
  net_export_gwh       = export_gwh - import_gwh
  total_available_gwh  = total_production_gwh + import_gwh
  cost_npr_million     = revenue_npr_million - profit_npr_million
  profit_margin_pct    = profit / revenue * 100 (2 dp)
"""
import pandas as pd
from config import CLEANED_DIR, PROCESSED_DIR, ARCHIVE_DIR

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
d = pd.read_csv(CLEANED_DIR / "annual_national.csv")

d["total_production_gwh"] = (d.nea_generation_gwh + d.ipp_purchase_gwh).round(2)
d["net_export_gwh"] = (d.export_gwh - d.import_gwh).round(2)
d["total_available_gwh"] = (d.total_production_gwh + d.import_gwh).round(2)
d["cost_npr_million"] = (d.revenue_npr_million - d.profit_npr_million).round(2)
d["profit_margin_pct"] = (d.profit_npr_million / d.revenue_npr_million * 100).round(2)

checks = []
def add(fy, check, expected, actual, tol, note=""):
    if pd.isna(expected) or pd.isna(actual):
        status = "not_testable"
    else:
        status = "pass" if abs(expected - actual) <= tol else "FLAG"
    checks.append(dict(fiscal_year=fy, check=check, expected=expected, actual=actual, status=status, note=note))

# 1. Regression test against the legacy workbook's derived columns
legacy = pd.read_excel(ARCHIVE_DIR / "legacy_outputs" / "NEA_Raw_Data.xlsx", sheet_name="All_Data")
for _, r in d.iterrows():
    L = legacy[legacy.Fiscal_Year == r.fiscal_year].iloc[0]
    for new, old, tol in [("total_production_gwh", "Total_Production_GWh", 0.005),
                          ("net_export_gwh", "Net_Export_GWh", 0.005),
                          ("total_available_gwh", "Total_Available_GWh", 0.005),
                          ("cost_npr_million", "Cost_NPR_Million", 0.005),
                          ("profit_margin_pct", "Profit_Margin_Pct", 0.006)]:
        add(int(r.fiscal_year), f"{new} == legacy workbook", L[old], r[new], tol)

# 2. Does the reported system loss reconcile with the energy balance?
#    implied loss = (available - domestic consumption - exports) / available
d["implied_loss_pct"] = ((d.total_available_gwh - d.domestic_consumption_gwh - d.export_gwh)
                         / d.total_available_gwh * 100).round(2)
for _, r in d.iterrows():
    add(int(r.fiscal_year), "reported system_loss_pct vs energy-balance implied loss (pp)",
        r.system_loss_pct, r.implied_loss_pct, 0.05,
        "Basis: energy available; loss = available - domestic - exports. FLAG = reported loss uses a different basis or figure in that report; check definition")

# 3. Ordering / sanity
for _, r in d.iterrows():
    if pd.notna(r.peak_supply_mw):
        add(int(r.fiscal_year), "peak_supply_mw >= peak_demand_mw", 1, int(r.peak_supply_mw >= r.peak_demand_mw), 0,
            "FLAG is informational: supply can sit slightly below demand (e.g. load shedding, different measurement); not necessarily an error")

pd.DataFrame(checks).to_csv(PROCESSED_DIR / "validation_checks.csv", index=False)
d.to_csv(PROCESSED_DIR / "annual_national_full.csv", index=False)

c = pd.DataFrame(checks)
print(c.groupby("status").size().to_string())
print()
print(c[c.status == "FLAG"].to_string(index=False))
