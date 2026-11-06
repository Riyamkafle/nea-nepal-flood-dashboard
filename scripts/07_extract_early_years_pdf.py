"""Plant baselines for FY2019/20, FY2020/21 and FY2022/23 (PRJ-009 Upper Trishuli 3A, PRJ-010 Trishuli,
PRJ-011 Devighat). Reads data/raw PDFs read-only. Needs PyMuPDF:  pip install pymupdf

FY2019/20 (Annual_book_2077.pdf p.44) and FY2020/21 (2020-21.pdf p.45) are monthly tables.
 - Words are read with coordinates (the page is rotated, so row = x, column order = y descending),
   which avoids the reversed-text problem of the dumps. Columns run Shrawan ... Ashar, then Total.
 - FY2020/21: the name column and the abbreviation column DISAGREE for three rows (name 'Upper Trishuli 3A'
   sits beside abbreviation KLI; name 'Kulekhani II' sits beside UT3A). The values follow the abbreviation:
   UT3A = 314,767.50 MWh, which the report's own text states (314.767 GWh), and Kulekhani I = 195.157 GWh.
   So FY2020/21 rows are matched by ABBREVIATION only.
FY2022/23 has no monthly table. Annual totals come from the FY2023/24 report's comparison table
(2023-2024.pdf); the script requires that the table's printed % changes reproduce from them.

Writes: data/cleaned/plant_generation_monthly.csv (adds FY2020, FY2021 rows; replaces any earlier ones)
        sql/08_seed_plant_baseline_early.sql
"""
import re
import statistics
import pandas as pd
try:
    import pymupdf
except ImportError:          # older PyMuPDF installs expose it as 'fitz'
    import fitz as pymupdf
from config import ROOT, CLEANED_DIR, SQL_DIR

RAW = ROOT / "data" / "raw"
SNAPSHOT = "2026-10-01"
NUM = re.compile(r"^\d[\d,]*(\.\d+)?$|^-$")
PROJECT = {"Upper Trishuli 3A": "PRJ-009", "Trishuli": "PRJ-010", "Devighat": "PRJ-011"}
# PDF columns are Shrawan..Ashar; the project CSV stores Ashad first (month_order 1), fiscal_month_no 1 = Shrawan
PDF_MONTHS = ["Shrawan", "Bhadra", "Aswin", "Kartik", "Mangsir", "Poush", "Magh", "Falgun",
              "Chaitra", "Baisakh", "Jestha", "Ashad"]

def val(s):
    return 0.0 if s == "-" else float(s.replace(",", ""))

def read_table(pdf, page, expect_text):
    doc = pymupdf.open(RAW / pdf)
    pg = doc[page - 1]
    assert expect_text in pg.get_text(), f"{pdf} p.{page}: expected heading {expect_text!r} not found"
    rows = {}
    for x0, y0, x1, y1, t, *_ in pg.get_text("words"):
        rows.setdefault(round(x0 / 2), []).append((y0, t))
    out = []
    for k in sorted(rows):
        ws = [t for _, t in sorted(rows[k], key=lambda a: -a[0])]
        nums = [t for t in ws if NUM.match(t)]
        if len(nums) >= 13:
            out.append(([t for t in ws if not NUM.match(t)], [val(x) for x in nums[-13:]]))
    return out

STRAY = {"Electricity", "Authority", "Nepal", "DIRECTORATE", "YEAR", "FISCAL", "GENERATION"}

def pick(rows, key):
    # key is a whole row label ('Trishuli') or an exact abbreviation token ('THPS'); never a substring,
    # so 'Trishuli' cannot match 'Upper Trishuli 3A'
    hit = []
    for t, a in rows:
        clean = [w for w in t if w not in STRAY]
        is_abbr = key == key.upper()          # 'UT3A', 'THPS', 'DHPS'
        if " ".join(clean) == key or (is_abbr and key in clean):
            hit.append((t, a))
    assert len(hit) == 1, f"{key!r}: expected exactly one row, got {len(hit)}"
    t, a = hit[0]
    assert abs(sum(a[:12]) - a[12]) <= 3, f"{key!r}: months do not add to the total"
    return a

def full_text(pdf):
    return "\n".join(p.get_text() for p in pymupdf.open(RAW / pdf))

records, notes = [], {}
SPECS = [  # fiscal_year, pdf, page, heading text, {plant: row key}
    (2020, "Annual_book_2077.pdf", 44, "FY 2019/20",
     {"Upper Trishuli 3A": "Upper Trishuli 3A", "Trishuli": "Trishuli", "Devighat": "Devighat"}),
    (2021, "2020-21.pdf", 45, "FY 2020/2021",
     {"Upper Trishuli 3A": "UT3A", "Trishuli": "THPS", "Devighat": "DHPS"}),
]
text21 = full_text("2020-21.pdf")
for fy, pdf, page, heading, keys in SPECS:
    rows = read_table(pdf, page, heading)
    for plant, key in keys.items():
        a = pick(rows, key)
        months, total = a[:12], a[12]
        by_pdf_order = list(zip(PDF_MONTHS, months))
        for k, (mname, mv) in enumerate(reversed(by_pdf_order)):   # Ashad first, as in the existing CSV
            records.append(dict(fiscal_year=fy, fiscal_year_label=f"{fy-1}/{str(fy)[2:]}", plant=plant,
                                month_order=k + 1, bs_month=mname, fiscal_month_no=12 - k,
                                generation_mwh=mv, total_mwh=total, pdf_page=page,
                                source_dump=pdf + " (PDF text layer)", sum_check="pass"))
        med = statistics.median(months)
        low = [f"{n} {v/1000:.1f}" for n, v in by_pdf_order if v < 0.5 * med]
        note = (f"PDF p.{page}, monthly generation table. Annual total equals the sum of the 12 monthly values "
                f"(check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.")
        if low:
            note += f" Unusually low months (under half the median, GWh): {', '.join(low)}."
        notes[(fy, plant)] = note

# FY2020/21 cross-checks against the report's own narrative text (must be present, else stop)
for s in ("314.767", "121.21", "85.43"):
    assert s in text21, f"narrative cross-check failed: {s} not in 2020-21.pdf text"
notes[(2021, "Upper Trishuli 3A")] += (
    " In this table the name and abbreviation columns disagree for three rows; this row is taken by abbreviation "
    "UT3A (printed beside the name 'Kulekhani II'). Confirmed by the report text (314.767 GWh) and by the FY2021/22 "
    "report (432.832 GWh was 37.51% more than the previous year). Name-matching would give 195.16 GWh, which is Kulekhani I.")
notes[(2020, "Upper Trishuli 3A")] += (
    " The FY2020/21 report says the plant was commissioned in July 2019, which fits a start-up first month.")

# FY2022/23 annual totals (MWh) from the FY2023/24 report comparison table; printed % change FY2023/24 vs FY2022/23
T23 = {"Upper Trishuli 3A": (437117.00, -2.30), "Trishuli": (123152.48, -4.96), "Devighat": (88913.59, -2.34)}
text24 = full_text("2023-2024.pdf")
pages24 = [i + 1 for i, p in enumerate(pymupdf.open(RAW / "2023-2024.pdf")) if "437,117.00" in p.get_text()]
assert pages24, "comparison table page not found in 2023-2024.pdf"
cur = pd.read_csv(CLEANED_DIR / "plant_generation_monthly.csv")
annual23 = {}
for plant, (t23, pct) in T23.items():
    assert f"{t23:,.2f}" in text24, f"{plant}: {t23:,.2f} not found in 2023-2024.pdf"
    t24 = cur[(cur.fiscal_year == 2024) & (cur.plant == plant)].total_mwh.iloc[0]
    got = round((t24 / t23 - 1) * 100, 2)
    assert abs(got - pct) <= 0.02, f"{plant}: FY2023/24 vs FY2022/23 gives {got}%, report prints {pct}%"
    annual23[plant] = t23
    notes[(2023, plant)] = (f"Annual total only (no monthly table for FY2022/23). Taken from the FY2023/24 report "
                            f"comparison table, PDF p.{pages24[0]} (SRC-008), as the previous-year column. Cross-checks: "
                            f"the table's printed change of {pct}% reproduces from FY2023/24; the FY2022/23 report text "
                            f"gives the same figure to lower precision.")

new = pd.DataFrame(records)
base = cur[~cur.fiscal_year.isin([2020, 2021])]
pd.concat([new, base]).sort_values("fiscal_year", kind="stable").to_csv(CLEANED_DIR / "plant_generation_monthly.csv", index=False)

def q(s):
    return "'" + str(s).replace("'", "''") + "'"
SRC = {2020: ("SRC-010", "NEA Annual Report FY2019/20 (A Year in Review)", "data/raw/Annual_book_2077.pdf"),
       2021: ("SRC-011", "NEA Annual Report FY2020/21", "data/raw/2020-21.pdf")}
sql = ["BEGIN;", ""]
for fy, (sid, title, path) in SRC.items():
    sql.append("INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date) "
               f"VALUES ({q(sid)}, {q(title)}, 'Nepal Electricity Authority', {q(path)}, 'Primary', NULL, {q(SNAPSHOT)});")
sql.append("")
srcmap = {2020: "SRC-010", 2021: "SRC-011", 2023: "SRC-008"}
for (fy, plant), note in sorted(notes.items()):
    total = (new[(new.fiscal_year == fy) & (new.plant == plant)].total_mwh.iloc[0] if fy != 2023 else annual23[plant])
    sql.append("INSERT INTO project_baseline (project_id, fiscal_year, generation_gwh, source_id, notes) "
               f"VALUES ({q(PROJECT[plant])}, {fy}, {total/1000:.2f}, {q(srcmap[fy])}, {q(note)});")
sql += ["", "COMMIT;", ""]
(SQL_DIR / "08_seed_plant_baseline_early.sql").write_text("\n".join(sql), encoding="utf-8")

print(f"{'FY':8} {'Plant':18} {'GWh':>8}  source")
for (fy, plant), _ in sorted(notes.items()):
    t = (new[(new.fiscal_year == fy) & (new.plant == plant)].total_mwh.iloc[0] if fy != 2023 else annual23[plant])
    print(f"{fy-1}/{str(fy)[2:]:5} {plant:18} {t/1000:8.2f}  {srcmap[fy]}")
print(f"\n{len(new)} monthly rows added; wrote sql/08_seed_plant_baseline_early.sql")
