#!/usr/bin/env python3
"""Append Budhi Gandaki (EVT-004) conflicts to data/cleaned/known_conflicts.csv.
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
 row("capacity_mw_Yaru_Khola_HEP", "n/a",
     "30.590", "DoED construction licence 435 (SRC-014)", "Primary",
     "30.542 (NEA appendix PDF p.198, SRC-006); 30.91 (Peoples Review, SRC-016)", "NEA appendix and press", "Primary and Secondary",
     "Three different capacities for one project. Clickmandu (SRC-017) gives 30.59.",
     "open", "30.59 (DoED, stored)", "Licence capacity used for consistency with the other DoED-based projects; confirm with the promoter or NEA."),
 row("budhi_gandaki_event_total_mw", "2026-10-11",
     "412.41", "Peoples Review headline (SRC-016), read as search excerpt", "Secondary",
     "412.09 (sum of DoED capacities 341 + 24.5 + 30.59 + 16)", "Derived from SRC-014", "Derived",
     "Clickmandu headline says 413 (rounded). The 412.41 total matches only if Yaru Khola is 30.91 MW. This is licensed capacity of under-construction projects, not lost generation.",
     "open", "412.09 (sum of stored capacities)", "Use the stored sum; keep the press total as a conflict."),
 row("developer_name_Dobhan_Khola_HEP", "n/a",
     "Upper Syange Hydropower Limited (project Dovan khola)", "NEA appendix PDF p.198 (SRC-006)", "Primary",
     "Dobhan Khola Hydropower Ltd", "DoED construction licence 429 (SRC-014)", "Primary",
     "Same capacity (24.5 MW) and district (Gorkha); likely the same project (inference). A different Dobhan/Dovan project exists: Junbeshi 5.2 MW in Solukhumbu.",
     "open", "DoED name", "Needs a source stating the licence holder history."),
 row("nea_ppa_list_membership_Budhi_Gandaki_HEP_341MW", "2026-10-11",
     "341 MW, licence 420, Times Energy Ltd", "DoED construction licence list (SRC-014)", "Primary",
     "Not found by name search for budhi; only Naulo Nepal Ka 103.4 MW and Kha 226 MW (PPA-signed table) and Super Machha Khola Sana 4.6 MW", "NEA appendix PDF pp.198 and 202 (SRC-006)", "Primary",
     "A name search can miss a renamed entry. DoED licenses Ka at 130 MW and Kha at 260 MW; NEA PPA table shows 103.4 and 226 MW. Press calls the 341 MW project under construction.",
     "open", "", "Check the NEA list by developer name (Times Energy)."),
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
