#!/usr/bin/env python3
"""Append DoED / RDNA evidence rows to data/cleaned/known_conflicts.csv.
Default = preview only. Add --write to append. Skips rows already present."""
import csv, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data" / "cleaned" / "known_conflicts.csv"
COLS = ["conflict_id", "metric", "period", "value_a", "source_a", "source_a_type",
        "value_b", "source_b", "source_b_type", "definition_note",
        "resolution_status", "value_used", "reason"]
P = "2026 flood (RDNA cut-off 2026-09-03)"
Q = "Project membership of the RDNA inventory is unconfirmed; needs a project-level RDNA or PDNA list, or the NEA/DoED/MoEWRI submission"

def row(metric, period, va, sa, ta, vb, sb, tb, note, status, used, reason):
    return dict(zip(COLS[1:], [metric, period, va, sa, ta, vb, sb, tb, note, status, used, reason]))

NEW = [
 row("rdna_operating_hydro_capacity_mw", P, "250.4", "RDNA Table 34, printed p.91 (SRC-015)", "Primary",
     "250.4", "Sum of 7 DoED operating-list capacities (SRC-012): Rasuwagadhi 111 + Upper Trishuli 3A 60 + Trishuli 24 + Chilime 22.0 + Upper Mailun Khola 14.3 + Devighat 14.1 + Mailung Khola 5", "Derived",
     "Arithmetic match only; the RDNA names no projects. A second 7-project set with Tadi Khola (Thaprek) 5.0 MW instead of Mailung Khola also sums to 250.4. Stored capacities (Chilime 22.10, Devighat 15.00) give 251.40.",
     "open_membership_unconfirmed", "", Q),
 row("rdna_construction_hydro_capacity_mw", P, "508.625", "RDNA Table 34, printed p.91 (SRC-015)", "Primary",
     "508.625", "Sum of 6 DoED construction-licence capacities (SRC-014): Upper Trishuli-1 216 + Rasuwa Bhotekoshi 120 + Super Trishuli 100 + Upper Trishuli 3B 37 + Langtang Khola 20 + Middle Trishuli Ganga 15.625", "Derived",
     "Arithmetic match only. Only set of 6 among 16 Rasuwa/Nuwakot candidates read (DoED page output cut at row 201). Database stores Middle Trishuli Ganga as 15.63 (numeric(10,2)), so the stored sum is 508.63.",
     "open_membership_unconfirmed", "", Q),
 row("rdna_solar_capacity_mw", P, "24.36", "RDNA Table 34, printed p.91 (SRC-015)", "Primary",
     "24.36", "Sum of 5 NEA Nuwakot solar farms on DoED solar list (SRC-013): 5.1 + 8.3 + 1.37 + 3.09 + 6.5", "Derived",
     "Arithmetic match only. PRJ-012 is stored as one 25 MW solar record (press: 25 MW Nuwakot Solar Power Project, SRC-004). Record kept; not split.",
     "open_membership_unconfirmed", "", Q),
 row("pre_flood_phase_PRJ-006_Langtang_Khola", "pre-flood (Aug 2026)", "operating", "Energy ministry list via myRepublica 27 Aug 2026 (SRC-001)", "Secondary",
     "under_construction", "DoED construction licence 142 (SRC-014) and NEA appendix list PDF p.198 (SRC-006); not on DoED operating list (SRC-012)", "Primary",
     "Press (SRC-004) says testing phase; kept as an unverified note, not evidence of operation.",
     "resolved_provisionally", "under_construction", "Two official lists agree. RDNA Table 34 sums are consistent but do not name the project."),
 row("capacity_mw_PRJ-007_Chilime", "n/a", "22.1", "NEA appendix list PDF p.188 (SRC-006); stored 22.10", "Primary",
     "22.0", "DoED operating list, licence 6 (SRC-012)", "Primary",
     "Different publishers; no stated reason for the difference.",
     "open", "22.10 (unchanged)", "Proposed correction to 22.0 prepared but not applied"),
 row("commissioning_date_PRJ-007_Chilime", "n/a", "BS 2060.05.08 (2003-08-25 stored)", "NEA appendix list PDF p.188 (SRC-006)", "Primary",
     "BS 2065-05-07", "DoED operating list, licence 6 (SRC-012)", "Primary",
     "Five-year gap in BS year; cause not established (possible later upgrade, not confirmed).",
     "open", "2003-08-25 (unchanged)", "Needs a source stating which event each date records"),
 row("capacity_mw_PRJ-011_Devighat", "n/a", "15.1", "NEA FY2025/26 report p.177 (SRC-006); stored 15.00", "Primary",
     "14.1", "DoED operating list (SRC-012); press 14.1 (SRC-004)", "Primary",
     "project_status_log also holds 14.00 (press, 27 Aug). Related to the existing Devighat register item.",
     "open", "15.00 (unchanged)", "Proposed correction to 14.10 prepared but not applied"),
 row("district_PRJ-009_Upper_Trishuli_3A", "n/a", "Nuwakot", "Press, stored value (SRC-001)", "Secondary",
     "Rasuwa", "DoED operating list, licence 43 (SRC-012): Dandagoun, Laharepouwa, Thulogoun, Ramche (Rasuwa)", "Primary",
     "Closes or extends the existing Upper Trishuli 3A district item.",
     "open", "Nuwakot (unchanged)", "Needs the NEA own statement of location"),
 row("rdna_assessed_status_Upper_Tadi_and_Sanjen_group", P, "operating", "DoED operating list (SRC-012): Upper Tadi 11.0, Sanjen 42.5, Upper Sanjen 14.8, Sanjen Khola 78.0", "Primary",
     "not in either arithmetic set", "Upper Tadi not in the press lists I read; Sanjen group in the 27 Aug list (SRC-001) but not in the later IPPAN-based lists", "Secondary",
     "Absence from a press list or an arithmetic set does not prove exclusion from the RDNA.",
     "open", "", "Do not classify as damaged or as excluded"),
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
        r = {"conflict_id": f"C-{nxt:03d}", **r}
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
