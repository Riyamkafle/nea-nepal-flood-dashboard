#!/usr/bin/env python3
"""Build dashboard/data.js from the JSON exported by sql/20_export_dashboard_json.sql and from the processed CSV files.

Reads only. Checks row counts, key sums and cross-references first; writes dashboard/data.js ONLY if every check passes.
Nothing here changes the database or any source file.
Usage (repo root):  python scripts/15_build_dashboard_data.py
"""
import json
import sys
from datetime import date
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
JSON_DIR = ROOT / "dashboard" / "json"
OUT = ROOT / "dashboard" / "data.js"
CSVS = {
    "monthly": ROOT / "data" / "cleaned" / "plant_generation_monthly.csv",
    "monthly_baseline": ROOT / "data" / "processed" / "plant_monthly_baseline.csv",
    "gap": ROOT / "data" / "processed" / "generation_gap_scenarios.csv",
    "conflicts": ROOT / "data" / "cleaned" / "known_conflicts.csv",
    "rdna_claims": ROOT / "data" / "cleaned" / "rdna_claims.csv",
}
JSONS = {"annual": "annual.json", "trade": "trade.json", "projects": "projects.json", "status_log": "status_log.json",
         "events": "events.json", "sources": "sources.json", "assets": "assets.json",
         "evacuation": "evacuation.json", "baseline": "baseline.json"}
EXPECTED_COUNTS = {"annual": 7, "trade": 14, "projects": 22, "status_log": 24, "events": 4, "sources": 23,
                   "assets": 12, "evacuation": 14, "baseline": 21,
                   "monthly": 216, "monthly_baseline": 72, "gap": 99, "conflicts": 22, "rdna_claims": 21}


def native(o):
    return o.item() if hasattr(o, "item") else str(o)


def load_csv(path):
    df = pd.read_csv(path, encoding="utf-8-sig")
    return df.astype(object).where(df.notna(), None).to_dict("records")


def num(v):
    return 0.0 if v is None else float(v)


def main():
    data, problems = {}, []
    for key, name in JSONS.items():
        p = JSON_DIR / name
        if not p.exists():
            problems.append("missing file %s (run sql/20 first)" % p)
            continue
        data[key] = json.loads(p.read_text(encoding="utf-8-sig"))
    for key, p in CSVS.items():
        if not p.exists():
            problems.append("missing file %s" % p)
            continue
        data[key] = load_csv(p)
    if problems:
        print("PROBLEMS:", *problems, sep="\n  ")
        sys.exit(1)

    print("=== 1. ROW COUNTS (found / expected) ===")
    for k, exp in EXPECTED_COUNTS.items():
        got = len(data[k])
        print("  %-17s %4d / %4d  %s" % (k, got, exp, "ok" if got == exp else "MISMATCH"))
        if got != exp:
            problems.append("%s has %d rows, expected %d" % (k, got, exp))

    print("\n=== 2. KEY SUMS ===")
    proj = data["projects"]
    for phase, n_exp, mw_exp in [("operating", 12, 422.70), ("under_construction", 10, 920.72)]:
        rows = [p for p in proj if p["pre_flood_phase"] == phase]
        mw = round(sum(num(p["capacity_mw"]) for p in rows), 2)
        ok = len(rows) == n_exp and abs(mw - mw_exp) < 0.005
        print("  projects %-19s n=%2d MW=%8.2f  (expected %d, %.2f) %s" % (phase, len(rows), mw, n_exp, mw_exp, "ok" if ok else "MISMATCH"))
        if not ok:
            problems.append("projects %s differ" % phase)
    for ev, exp in [("EVT-002", 431.10), ("EVT-004", 412.09)]:
        s = round(sum(num(r["affected_mw"]) for r in data["status_log"] if r["event_id"] == ev), 2)
        ok = abs(s - exp) < 0.005
        print("  status_log %s affected_mw sum = %.2f (expected %.2f) %s" % (ev, s, exp, "ok" if ok else "MISMATCH"))
        if not ok:
            problems.append("%s affected_mw sum differs" % ev)
    cap = round(sum(num(t["export_capacity_mw"]) for t in data["trade"] if t["fiscal_year"] == 2026), 2)
    print("  trade FY2026 export_capacity_mw sum = %.2f (expected 1200.01) %s" % (cap, "ok" if abs(cap - 1200.01) < 0.005 else "MISMATCH"))
    if abs(cap - 1200.01) >= 0.005:
        problems.append("trade FY2026 capacity differs")

    print("\n=== 3. CROSS-REFERENCES ===")
    pid = {p["project_id"] for p in proj}
    sid = {s["source_id"] for s in data["sources"]}
    aid = {a["asset_id"] for a in data["assets"]}
    eid = {e["event_id"] for e in data["events"]}
    bad = []
    bad += ["status_log project %s" % r["project_id"] for r in data["status_log"] if r["project_id"] not in pid]
    bad += ["status_log event %s" % r["event_id"] for r in data["status_log"] if r["event_id"] not in eid]
    bad += ["status_log source %s" % r["source_id"] for r in data["status_log"] if r.get("source_id") and r["source_id"] not in sid]
    bad += ["evacuation project %s" % r["project_id"] for r in data["evacuation"] if r["project_id"] not in pid]
    bad += ["evacuation asset %s" % r["asset_id"] for r in data["evacuation"] if r["asset_id"] not in aid]
    bad += ["baseline project %s" % r["project_id"] for r in data["baseline"] if r["project_id"] not in pid]
    print("  broken references:", len(bad))
    for b in bad:
        print("    ", b)
    problems += bad

    if problems:
        print("\nSTOPPING: %d problem(s). dashboard/data.js was NOT written." % len(problems))
        for p in problems:
            print("  -", p)
        sys.exit(1)

    data["meta"] = {
        "built": date.today().isoformat(),
        "fiscal_year_convention": "Gregorian END year (2026 = FY2025/26); Nepali fiscal year runs Shrawan (mid-July) to Ashad",
        "events": {"EVT-002": "Bhotekoshi/Trishuli flood, 26 Aug 2026", "EVT-004": "Budhi Gandaki flood, 11 Oct 2026"},
        "counts": {k: len(data[k]) for k in EXPECTED_COUNTS},
    }
    text = "window.NEA_DATA = " + json.dumps(data, ensure_ascii=False, allow_nan=False, default=native) + ";\n"
    OUT.write_text(text, encoding="utf-8")
    print("\nAll checks passed. Wrote %s (%.0f KB)." % (OUT, len(text.encode("utf-8")) / 1024))


main()
