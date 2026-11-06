#!/usr/bin/env python3
"""Month-by-month generation baseline for the three NEA plants (UT3A, Trishuli, Devighat).

Reads  data/cleaned/plant_generation_monthly.csv   (hand-checked monthly tables, SRC-006..011)
Prints checks and baseline tables. Writes data/processed/plant_monthly_baseline.csv ONLY with --write.
Nothing here touches PostgreSQL.

Method (my calculation, not stated in any report):
  * A month is FLAGGED LOW if it is below 50% of the median of the same plant and same
    fiscal month in the OTHER years (leave-one-out). Flagged months stay visible and are
    excluded from low/base/high. The cause of a low month is NOT established by this rule.
  * low = minimum, base = median, high = maximum of the clean months in the window.
  * Windows: 'all' = every year in the file; 'recent3' = the latest three years in the file.
  * base_all_mwh = median including flagged months, shown only to expose the effect of flagging.
  * FY2022/23 has annual totals only (no monthly table), so it is not in this file.
Usage:  python scripts/13_build_monthly_baseline.py [--csv PATH] [--write]
"""
import sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
CSV_DEFAULT = ROOT / "data" / "cleaned" / "plant_generation_monthly.csv"
OUT_PATH = ROOT / "data" / "processed" / "plant_monthly_baseline.csv"

# Annual GWh already stored in project_baseline (handoff section 5); FY = Gregorian END year.
EXPECTED_GWH = {
    "UT3A":     {2020: 407.55, 2021: 314.77, 2022: 432.83, 2024: 427.06, 2025: 355.97, 2026: 391.90},
    "TRISHULI": {2020: 128.97, 2021: 121.21, 2022: 137.11, 2024: 117.04, 2025: 97.70,  2026: 80.35},
    "DEVIGHAT": {2020: 92.05,  2021: 85.43,  2022: 98.39,  2024: 86.83,  2025: 76.36,  2026: 59.53},
}
# Upper bound for the physical-limit check only (Devighat uses 15.1 MW, the highest value seen in sources).
CAP_MW_UPPER = {"UT3A": 60.0, "TRISHULI": 24.0, "DEVIGHAT": 15.1}
SOURCE_BY_FY = {2020: "SRC-010", 2021: "SRC-011", 2022: "SRC-007",
                2024: "SRC-008", 2025: "SRC-009", 2026: "SRC-006"}
MAX_HOURS_IN_MONTH = 32 * 24      # BS months have 29-32 days
LOW_RULE = 0.5                    # flagged if below 50% of the leave-one-out median
TOL_SUM_MWH = 1.0                 # monthly sum vs printed total (months printed with decimals)
TOL_ROUNDING_MWH = 6.0            # 12 whole-number months x 0.5 MWh rounding each (months printed as whole MWh)
TOL_ANNUAL_GWH = 0.006            # vs value stored in the database


def plant_key(name):
    n = str(name).lower()
    if "upper" in n:
        return "UT3A"
    if "devighat" in n:
        return "DEVIGHAT"
    if "trishuli" in n or "trisuli" in n:
        return "TRISHULI"
    return None


def main():
    write = "--write" in sys.argv
    csv_path = CSV_DEFAULT
    if "--csv" in sys.argv:
        csv_path = Path(sys.argv[sys.argv.index("--csv") + 1])
    d = pd.read_csv(csv_path)
    d["key"] = d["plant"].map(plant_key)
    problems = []
    notes = []

    print("=== 1. FILE CHECKS ===")
    print("rows:", len(d), "| plants:", sorted(d["plant"].unique()), "| fiscal years:", [int(y) for y in sorted(d["fiscal_year"].unique())])
    if d["key"].isna().any():
        problems.append("unrecognised plant names: %s" % sorted(d.loc[d["key"].isna(), "plant"].unique()))
    for (k, y), g in d.groupby(["key", "fiscal_year"]):
        if sorted(g["fiscal_month_no"]) != list(range(1, 13)):
            problems.append("%s FY%s does not have exactly 12 fiscal months" % (k, y))
        if (g["sum_check"] != "pass").any():
            problems.append("%s FY%s has sum_check not 'pass'" % (k, y))
        diff = abs(g["generation_mwh"].sum() - g["total_mwh"].iloc[0])
        whole = bool((g["generation_mwh"] % 1 == 0).all())
        tol = TOL_ROUNDING_MWH if whole else TOL_SUM_MWH
        if diff > tol:
            problems.append("%s FY%s monthly sum differs from printed total by %.2f MWh (limit %.1f)" % (k, y, diff, tol))
        elif whole and diff > 0.5:
            notes.append("%s FY%s: monthly sum differs from printed total by %.1f MWh; all 12 months are whole numbers, "
                         "so rounding can explain up to %.0f MWh (inference, pages not re-read)" % (k, y, diff, TOL_ROUNDING_MWH))
        exp = EXPECTED_GWH.get(k, {}).get(y)
        if exp is None:
            problems.append("%s FY%s has no expected database value to compare" % (k, y))
        elif abs(g["generation_mwh"].sum() / 1000.0 - exp) > TOL_ANNUAL_GWH:
            problems.append("%s FY%s annual %.3f GWh differs from database %.2f GWh"
                            % (k, y, g["generation_mwh"].sum() / 1000.0, exp))
    over = d[d.apply(lambda r: r["generation_mwh"] > CAP_MW_UPPER.get(r["key"], 1e9) * MAX_HOURS_IN_MONTH, axis=1)]
    for _, r in over.iterrows():
        problems.append("%s FY%s %s exceeds the physical limit at full capacity" % (r["key"], r["fiscal_year"], r["bs_month"]))
    if (d["generation_mwh"] < 0).any():
        problems.append("negative generation found")
    print("Problems found:", len(problems))
    for p in problems:
        print("  PROBLEM:", p)
    for nt in notes:
        print("  NOTE:", nt)
    if problems:
        print("STOPPING: fix the problems above before using any baseline.")
        sys.exit(1)
    print("All checks passed: 12 months per plant-year, sum_check pass, monthly sums match printed totals")
    print("within the limits (1 MWh for decimal months, 6 MWh for whole-number months; see NOTE lines),")
    print("annual totals = database values, no month above the physical limit.")

    years_all = [int(y) for y in sorted(d["fiscal_year"].unique())]
    windows = {"all": years_all, "recent3": years_all[-3:]}

    d = d.copy()
    d["ref_median_other_years"] = float("nan")
    for (k, m), g in d.groupby(["key", "fiscal_month_no"]):
        for idx, r in g.iterrows():
            others = g.loc[g["fiscal_year"] != r["fiscal_year"], "generation_mwh"]
            if len(others) >= 3:
                d.loc[idx, "ref_median_other_years"] = others.median()
    d["flag_low"] = d["generation_mwh"] < LOW_RULE * d["ref_median_other_years"]

    print()
    print("=== 2. MONTHLY GENERATION (GWh), * = flagged low (below %d%% of the median of the other years) ===" % int(LOW_RULE * 100))
    names = {"UT3A": "Upper Trishuli 3A", "TRISHULI": "Trishuli", "DEVIGHAT": "Devighat"}
    for k in ["UT3A", "TRISHULI", "DEVIGHAT"]:
        g = d[d["key"] == k]
        print("\n-- %s (fiscal month 1 = Shrawan ... 12 = Ashad) --" % names[k])
        header = "%-3s %-8s" % ("no", "month") + "".join("%10s" % ("FY%d" % y) for y in years_all)
        print(header)
        for m in range(1, 13):
            gm = g[g["fiscal_month_no"] == m]
            row = "%-3d %-8s" % (m, gm["bs_month"].iloc[0])
            for y in years_all:
                r = gm[gm["fiscal_year"] == y].iloc[0]
                row += "%10s" % ("%.1f%s" % (r["generation_mwh"] / 1000.0, "*" if r["flag_low"] else ""))
            print(row)
        tot = "%-12s" % "annual GWh" + "".join("%10.2f" % (g[g["fiscal_year"] == y]["generation_mwh"].sum() / 1000.0) for y in years_all)
        print(tot)
    nflag = int(d["flag_low"].sum())
    print("\nFlagged months in total:", nflag)
    for _, r in d[d["flag_low"]].sort_values(["key", "fiscal_year", "fiscal_month_no"]).iterrows():
        print("  %-8s FY%d %-8s %.1f GWh (median of other years %.1f GWh)"
              % (r["key"], r["fiscal_year"], r["bs_month"], r["generation_mwh"] / 1000.0, r["ref_median_other_years"] / 1000.0))

    print()
    print("=== 3. BASELINE BY FISCAL MONTH (GWh), flagged months excluded ===")
    out_rows = []
    for k in ["UT3A", "TRISHULI", "DEVIGHAT"]:
        for wname, wyears in windows.items():
            g = d[(d["key"] == k) & (d["fiscal_year"].isin(wyears))]
            print("\n-- %s | window '%s' = FY%s --" % (names[k], wname, ", FY".join(str(y) for y in wyears)))
            print("%-3s %-8s %4s %5s %8s %8s %8s %9s" % ("no", "month", "n", "flag", "low", "base", "high", "base_all"))
            sum_base = 0.0
            thin = 0
            for m in range(1, 13):
                gm = g[g["fiscal_month_no"] == m]
                clean = gm[~gm["flag_low"]]["generation_mwh"]
                n = len(clean)
                nfl = int(gm["flag_low"].sum())
                base_all = gm["generation_mwh"].median()
                if n == 0:
                    low = base = high = float("nan")
                else:
                    low, base, high = clean.min(), clean.median(), clean.max()
                    sum_base += base
                if n < 2:
                    thin += 1
                print("%-3d %-8s %4d %5d %8s %8s %8s %9.1f" % (
                    m, gm["bs_month"].iloc[0], n, nfl,
                    "n/a" if n == 0 else "%.1f" % (low / 1000.0),
                    "n/a" if n == 0 else "%.1f" % (base / 1000.0),
                    "n/a" if n == 0 else "%.1f" % (high / 1000.0), base_all / 1000.0))
                out_rows.append({
                    "plant": names[k], "window": wname, "fiscal_month_no": m, "bs_month": gm["bs_month"].iloc[0],
                    "n_clean_years": n, "n_flagged_excluded": nfl,
                    "low_mwh": None if n == 0 else round(low, 1), "base_mwh": None if n == 0 else round(base, 1),
                    "high_mwh": None if n == 0 else round(high, 1), "base_all_mwh": round(base_all, 1),
                    "years_in_window": ",".join(str(y) for y in wyears),
                    "sources": ",".join(SOURCE_BY_FY[y] for y in wyears if y in SOURCE_BY_FY),
                    "evidence": "my calculation from report monthly tables; not a forecast; flagged months excluded",
                })
            print("Sum of the 12 monthly base values: %.1f GWh (not the same as a median annual total)" % (sum_base / 1000.0))
            if thin:
                print("WARNING: %d month(s) have fewer than 2 clean years in this window: treat as thin." % thin)

    print()
    print("=== 4. CAUTIONS ===")
    print("* Trishuli and Devighat decline in most years: compare the 'all' and 'recent3' tables before choosing one.")
    print("* A flagged month is not explained by this script. FY2025/26 Shrawan-Bhadra comes just after the 8 Jul 2025 flood (EVT-001),")
    print("  which the report documents only for Rasuwagadhi; the cause for UT3A is NOT established in the report.")
    print("* Plants commissioned recently (Rasuwagadhi, Sanjen, Middle Bhotekoshi) are not here: they need design energy.")
    print("* FY2025/26 report figures are provisional (subject to audit).")

    if write:
        OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
        pd.DataFrame(out_rows).to_csv(OUT_PATH, index=False)
        print("\nWrote", OUT_PATH, "(%d rows)" % len(out_rows))
    else:
        print("\nPreview only. Add --write to save data/processed/plant_monthly_baseline.csv")


main()
