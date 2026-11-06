#!/usr/bin/env python3
"""Generation-gap scenarios for the three NEA plants (UT3A, Trishuli, Devighat) after EVT-002.

CONDITIONAL ANALYSIS. It answers only: IF a plant had produced nothing (or less) from 26 Aug 2026,
how much energy would it not have generated in the rest of FY2026/27 (to the end of Ashad 2084)?
It does NOT say the plants were out of service: that is unverified (project_status_log, SRC-004, verified = No).
It does NOT say how much of the lost energy would have been delivered or exported.

Inputs  data/processed/plant_monthly_baseline.csv  (script 13, window 'recent3', base_mwh)
        data/cleaned/plant_generation_monthly.csv   (FY2025/26 actual months)
Output  printed tables; data/processed/generation_gap_scenarios.csv ONLY with --write. PostgreSQL is not touched.

Two reference levels per plant and month:
  A 'last_year'      = FY2025/26 actual month (stated in the report; includes the recent decline)
  B 'recent3_clean'  = median of the clean months of the latest three years (my calculation)
Three outage profiles (my assumptions; the RDNA gives no project-specific outage or restart dates):
  optimistic   : everything returns at 4.96 months (time of the first Rasuwagadhi unit after the 8 Jul 2025 flood)
  precedent    : stepwise return copied from Rasuwagadhi after 8 Jul 2025: 1/3 at 4.96, 2/3 at 5.58, all at 10.18 months
                 (equal unit sizes assumed; Rasuwagadhi is a different plant and event: precedent, not forecast)
  pessimistic  : nothing returns before the end of FY2026/27
Time zero = 26 Aug 2026 = Bhadra 10, 2083 (SRC-004). Bhadra is assumed to have 31 days (my assumption);
each later BS month counts as one month. Usage: python scripts/14_generation_gap_scenarios.py [--write]
"""
import sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
BASE_CSV = ROOT / "data" / "processed" / "plant_monthly_baseline.csv"
MONTHLY_CSV = ROOT / "data" / "cleaned" / "plant_generation_monthly.csv"
OUT_PATH = ROOT / "data" / "processed" / "generation_gap_scenarios.csv"

PLANTS = ["Upper Trishuli 3A", "Trishuli", "Devighat"]
BHADRA_DAY, BHADRA_DAYS_ASSUMED = 10, 31
FIRST_FRAC = (BHADRA_DAYS_ASSUMED - BHADRA_DAY + 1) / BHADRA_DAYS_ASSUMED      # 22/31 of Bhadra remains
T1, T2, T3 = 151 / 30.44, 170 / 30.44, 310 / 30.44                             # Rasuwagadhi: 6 Dec 2025, 25 Dec 2025, 14 May 2026
PROFILES = {   # list of (start time in months, share of capacity available from then on)
    "optimistic":  [(0.0, 0.0), (T1, 1.0)],
    "precedent":   [(0.0, 0.0), (T1, 1 / 3), (T2, 2 / 3), (T3, 1.0)],
    "pessimistic": [(0.0, 0.0)],
}
MONTH_NO = list(range(2, 13))   # fiscal month 2 = Bhadra ... 12 = Ashad (month 1 = Shrawan is before the event)


def lost_months(profile, t0, t1):
    """Integral of (1 - availability) over [t0, t1], in month-units."""
    total = 0.0
    for i, (ts, share) in enumerate(profile):
        te = profile[i + 1][0] if i + 1 < len(profile) else float("inf")
        lo, hi = max(t0, ts), min(t1, te)
        if hi > lo:
            total += (1.0 - share) * (hi - lo)
    return total


def main():
    write = "--write" in sys.argv
    b = pd.read_csv(BASE_CSV)
    m = pd.read_csv(MONTHLY_CSV)
    b = b[b["window"] == "recent3"]
    problems = []
    for p in PLANTS:
        if len(b[b["plant"] == p]) != 12:
            problems.append("baseline for %s does not have 12 months" % p)
        if len(m[(m["plant"] == p) & (m["fiscal_year"] == 2026)]) != 12:
            problems.append("FY2025/26 actual for %s does not have 12 months" % p)
    if problems:
        print("PROBLEMS:", problems)
        sys.exit(1)

    # month intervals in months since 26 Aug 2026
    iv = {2: (0.0, FIRST_FRAC)}
    for k in range(3, 13):
        iv[k] = (FIRST_FRAC + (k - 3), FIRST_FRAC + (k - 2))
    horizon = iv[12][1]
    print("=== 1. SETTINGS ===")
    print("Time zero: 26 Aug 2026 (Bhadra 10, 2083). Bhadra share remaining: %.3f (assumes 31 days)." % FIRST_FRAC)
    print("Horizon: end of Ashad 2084 = %.2f months after the event. Months after that are NOT counted." % horizon)
    print("Profile times (months): first unit %.2f, second %.2f, third %.2f (Rasuwagadhi precedent, days 151, 170, 310 after 8 Jul 2025)." % (T1, T2, T3))
    print("Share of month-units lost per fiscal month, by profile:")
    print("%-3s %-8s" % ("no", "month") + "".join("%13s" % k for k in PROFILES))
    names = {2: "Bhadra", 3: "Aswin", 4: "Kartik", 5: "Mangsir", 6: "Poush", 7: "Magh", 8: "Falgun", 9: "Chaitra", 10: "Baisakh", 11: "Jestha", 12: "Ashad"}
    lm = {k: {pn: lost_months(pr, *iv[k]) for pn, pr in PROFILES.items()} for k in MONTH_NO}
    for k in MONTH_NO:
        print("%-3d %-8s" % (k, names[k]) + "".join("%13.3f" % lm[k][pn] for pn in PROFILES))
    print("%-12s" % "total" + "".join("%13.3f" % sum(lm[k][pn] for k in MONTH_NO) for pn in PROFILES) + "   (month-equivalents of full outage)")

    rows = []
    print()
    print("=== 2. ENERGY NOT GENERATED (GWh), if out of service from 26 Aug 2026 ===")
    for p in PLANTS:
        bp = b[b["plant"] == p].set_index("fiscal_month_no")
        ap = m[(m["plant"] == p) & (m["fiscal_year"] == 2026)].set_index("fiscal_month_no")
        print("\n-- %s --" % p)
        print("%-3s %-8s %8s %9s %2s" % ("no", "month", "A_last", "B_recent3", "n") + "".join("%12s" % ("A_" + k[:4]) for k in PROFILES) + "".join("%12s" % ("B_" + k[:4]) for k in PROFILES))
        tot = {("A", pn): 0.0 for pn in PROFILES}
        tot.update({("B", pn): 0.0 for pn in PROFILES})
        for k in MONTH_NO:
            a_mwh = float(ap.loc[k, "generation_mwh"]); b_mwh = float(bp.loc[k, "base_mwh"]); n = int(bp.loc[k, "n_clean_years"])
            line = "%-3d %-8s %8.1f %9.1f %2d%s" % (k, names[k], a_mwh / 1000, b_mwh / 1000, n, "*" if n < 3 else " ")
            la, lb = [], []
            for pn in PROFILES:
                va, vb = a_mwh * lm[k][pn], b_mwh * lm[k][pn]
                tot[("A", pn)] += va; tot[("B", pn)] += vb
                la.append(va); lb.append(vb)
                rows.append({"plant": p, "fiscal_month_no": k, "bs_month": names[k], "profile": pn,
                             "A_last_year_mwh": round(a_mwh, 1), "B_recent3_mwh": round(b_mwh, 1), "n_clean_years_B": n,
                             "lost_month_units": round(lm[k][pn], 4), "not_generated_A_mwh": round(va, 1), "not_generated_B_mwh": round(vb, 1)})
            line += "".join("%12.1f" % (x / 1000) for x in la) + "".join("%12.1f" % (x / 1000) for x in lb)
            print(line)
        print("%-24s" % "TOTAL GWh" + " " * 3 + "".join("%12.1f" % (tot[("A", pn)] / 1000) for pn in PROFILES) + "".join("%12.1f" % (tot[("B", pn)] / 1000) for pn in PROFILES))
        fy = float(m[(m["plant"] == p) & (m["fiscal_year"] == 2026)]["generation_mwh"].sum()) / 1000
        print("FY2025/26 actual annual: %.2f GWh" % fy)

    print()
    print("=== 3. SUMMARY: THREE PLANTS TOGETHER (GWh not generated to the end of FY2026/27) ===")
    df = pd.DataFrame(rows)
    fy_all = float(m[(m["plant"].isin(PLANTS)) & (m["fiscal_year"] == 2026)]["generation_mwh"].sum()) / 1000
    print("%-14s %14s %14s" % ("profile", "A last year", "B recent3"))
    for pn in PROFILES:
        s = df[df["profile"] == pn]
        print("%-14s %14.1f %14.1f" % (pn, s["not_generated_A_mwh"].sum() / 1000, s["not_generated_B_mwh"].sum() / 1000))
    print("FY2025/26 actual output of the three plants together: %.2f GWh" % fy_all)

    print()
    print("=== 4. CAUTIONS ===")
    print("* Conditional on the plants being out of service. project_status_log says 'destroyed' from one secondary source (SRC-004), verified = No.")
    print("* Outage profiles are my assumptions based on one precedent (Rasuwagadhi); the RDNA states no project-specific outage or restart dates.")
    print("* 'Not generated' is not 'not delivered' and not 'not exported': no dataset in the project links these plants to monthly deliveries or exports.")
    print("* * marks months where reference B rests on fewer than 3 clean years (thin). The first months after the event are the thinnest.")
    print("* Newly commissioned plants (Rasuwagadhi, Sanjen, Upper Sanjen, Middle Bhotekoshi) and under-construction projects are NOT in this table.")
    print("* FY2025/26 report figures are provisional (subject to audit). FY2025/26 export total is disputed (3,965 / 3,938 / 3,962 GWh): not used here.")
    if write:
        df.to_csv(OUT_PATH, index=False)
        print("\nWrote", OUT_PATH, "(%d rows)" % len(df))
    else:
        print("\nPreview only. Add --write to save data/processed/generation_gap_scenarios.csv")


main()
