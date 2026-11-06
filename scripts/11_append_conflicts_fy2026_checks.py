#!/usr/bin/env python3
"""Append two FY2025/26 report checks to data/cleaned/known_conflicts.csv.
Default = preview only. Add --write to append. Skips rows already present."""
import csv, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data" / "cleaned" / "known_conflicts.csv"
COLS = ["conflict_id", "metric", "period", "value_a", "source_a", "source_a_type",
        "value_b", "source_b", "source_b_type", "definition_note",
        "resolution_status", "value_used", "reason"]

def row(metric, period, va, sa, ta, vb, sb, tb, note, status, used, reason):
    return dict(zip(COLS[1:], [metric, period, va, sa, ta, vb, sb, tb, note, status, used, reason]))

NEW = [
 row("transmission_line_length_circuit_km_by_voltage", "FY2025/26",
     "66 kV 514; 132 kV 4,464; 220 kV 1,324; 400 kV 807; total 7,110 (the four values printed add to 7,109)",
     "NEA FY2025/26 report, ten-year comparison table, PDF p.205 (SRC-006)", "Primary",
     "66 kV 514.46; 132 kV 4,355; 220 kV 1,310.00; 400 kV 560.00; these add to 6,739.46",
     "Same report, appendix line tables, PDF pp.208-209 (SRC-006)", "Primary",
     "Both tables are inside one report. 66 kV agrees; 132, 220 and 400 kV do not. Cause not established.",
     "open", "",
     "Not used in any calculation yet. Individual line lengths come from the appendix rows."),
 row("nea_export_gwh", "FY2025/26",
     "3,965",
     "Managing Director message, as recorded in the project handoff and loaded in nea_annual_data.export_gwh (page not re-read in this chat)", "Primary",
     "3,938",
     "System operation table, PDF p.54 (SRC-006); equals system energy demand 19,077.95 minus national energy demand 15,139.94 = 3,938.01 (my subtraction)", "Primary",
     "Also: about 3,962 GWh sold to India (PDF p.55); 3,877 in the NEA release via press 23-24 Jul 2026 (per handoff, not re-checked). All FY2025/26 figures are provisional, subject to audit.",
     "open", "3,965 (loaded, unchanged)",
     "Choose after the audited report or an NEA statement."),
]

def main():
    write = "--write" in sys.argv
    raw = CSV_PATH.read_bytes()
    eol = "\r\n" if b"\r\n" in raw[:5000] else "\n"
    existing = list(csv.DictReader(raw.decode("utf-8-sig").splitlines()))
    header = list(existing[0].keys()) if existing else COLS
    assert header == COLS, "Header differs from expected: " + str(header)
    have = {(r["metric"], r["period"]) for r in existing}
    nums = [int(m.group(1)) for r in existing if (m := re.match(r"C-(\d+)$", r["conflict_id"].strip()))]
    nxt = max(nums) + 1 if nums else 1
    todo = []
    for r in NEW:
        if (r["metric"], r["period"]) in have:
            print("SKIP (already present):", r["metric"])
            continue
        r = {"conflict_id": "C-%03d" % nxt, **r}
        nxt += 1
        todo.append(r)
    for r in todo:
        print(r["conflict_id"], "|", r["metric"], "|", r["resolution_status"], "| used:", r["value_used"] or "-")
    print(len(todo), "row(s) to append;", "WRITING" if write else "preview only (use --write)")
    if write and todo:
        with open(CSV_PATH, "ab") as f:
            if not raw.endswith(b"\n"):
                f.write(eol.encode())
        with open(CSV_PATH, "a", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=COLS, lineterminator=eol)
            w.writerows(todo)
        print("Appended to", CSV_PATH)

main()
