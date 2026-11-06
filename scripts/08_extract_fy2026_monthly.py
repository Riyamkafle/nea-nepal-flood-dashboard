"""FY2025/26 monthly generation for PRJ-009 Upper Trishuli 3A, PRJ-010 Trishuli, PRJ-011 Devighat.
Reads data/raw/A Year In Review Annual Report 2025_2026_compressed.pdf (read-only). Needs PyMuPDF.

Source table: 'Generation Related Statistics' > 'MONTHLY ENERGY GENERATION FY 2082/83 (MWh)'
(printed p.176, PDF p.186). Text is upright here; columns are Total Actual, then Shrawan ... Ashar.
The page is found by its heading, not by number. Stops (assert) if any check fails:
  - each plant's 12 months add to its total
  - the 21 plant rows add to the report's 'Total (Hydro)'
  - each plant total appears in the report's own narrative (GWh to 2 decimals)
Writes: data/cleaned/plant_generation_monthly.csv (adds/replaces FY2026 rows)
        sql/11_fy2026_monthly_notes.sql (appends evidence to project_baseline notes; flags the national
        row's source as provisional)
"""
import re
import statistics
import pandas as pd
try:
    import pymupdf
except ImportError:          # older PyMuPDF installs expose it as 'fitz'
    import fitz as pymupdf
from config import ROOT, CLEANED_DIR, SQL_DIR

PDF = ROOT / "data" / "raw" / "A Year In Review Annual Report 2025_2026_compressed.pdf"
HEAD = "MONTHLY ENERGY GENERATION FY 2082/83"
NUM = re.compile(r"^\d[\d,]*(\.\d+)?$|^-$")
PLANTS = {"Upper Trishuli 3A": "PRJ-009", "Trishuli": "PRJ-010", "Devighat": "PRJ-011"}
NARRATIVE_GWH = {"Upper Trishuli 3A": "391.90", "Trishuli": "80.35", "Devighat": "59.53"}
PDF_MONTHS = ["Shrawan", "Bhadra", "Aswin", "Kartik", "Mangsir", "Poush", "Magh", "Falgun",
              "Chaitra", "Baisakh", "Jestha", "Ashad"]          # Aswin = Ashoj, Ashad = Ashar in this report
TOTAL_ROWS = {"Total PROR/ROR", "Total (STORAGE)", "Total (Hydro)", "Total (Thermal)", "Grand Total", "Large", "Medium"}
FY = 2026

doc = pymupdf.open(PDF)
flat = [re.sub(r"\s+", " ", p.get_text()) for p in doc]
cand = [i for i, t in enumerate(flat) if HEAD in t and "Kaligandaki" in t]
assert len(cand) == 1, f"expected one monthly table page, found {len(cand)}"
page_idx = cand[0]
page_no = page_idx + 1

def rows_on(page):
    words = sorted(page.get_text("words"), key=lambda w: (w[1] + w[3]) / 2)
    lines, cur, last = [], [], None
    for w in words:
        yc = (w[1] + w[3]) / 2
        if last is None or yc - last <= 2.5:
            cur.append(w)
        else:
            lines.append(cur); cur = [w]
        last = yc
    if cur:
        lines.append(cur)
    out = {}
    for ln in lines:
        ws = [w[4] for w in sorted(ln, key=lambda w: w[0])]
        nums = [t for t in ws if NUM.match(t)]
        if len(nums) == 13:
            out[" ".join(t for t in ws if not NUM.match(t))] = [0.0 if x == "-" else float(x.replace(",", "")) for x in nums]
    return out

table = rows_on(doc[page_idx])
plant_rows = {k: v for k, v in table.items() if k not in TOTAL_ROWS}
for k, a in table.items():
    assert abs(a[0] - sum(a[1:])) <= 3, f"{k}: months do not add to total"
hydro = table["Total (Hydro)"][0]
assert abs(sum(a[0] for a in plant_rows.values()) - hydro) <= 5, "plant rows do not add to Total (Hydro)"
fulltext = " ".join(flat)
for plant, g in NARRATIVE_GWH.items():
    assert re.search(re.escape(g) + r"\s*GWh", fulltext), f"{plant}: {g} GWh not found in report narrative"
    assert abs(table[plant][0] / 1000 - float(g)) < 0.01, f"{plant}: table total differs from narrative"

records, notes = [], {}
for plant in PLANTS:
    a = table[plant]
    total, months = a[0], a[1:]
    by_pdf = list(zip(PDF_MONTHS, months))
    for k, (mname, mv) in enumerate(reversed(by_pdf)):          # Ashad first, as in the existing CSV
        records.append(dict(fiscal_year=FY, fiscal_year_label="2025/26", plant=plant, month_order=k + 1,
                            bs_month=mname, fiscal_month_no=12 - k, generation_mwh=mv, total_mwh=total,
                            pdf_page=page_no, source_dump="A Year In Review ... 2025_2026 (PDF text layer)",
                            sum_check="pass"))
    med = statistics.median(months)
    low = [f"{n} {v/1000:.1f}" for n, v in by_pdf if v < 0.5 * med]
    note = (f"Monthly table: PDF p.{page_no} (printed p.{page_no-10}); 12 months add to the total and the 21 plant "
            f"rows add to the report's hydro total. Report marks FY2025/26 figures provisional (subject to audit).")
    if low:
        note += f" Months under half the median (GWh): {', '.join(low)}. Cause not established by the report."
    if plant == "Upper Trishuli 3A":
        note += (" The report describes the 8 July 2025 GLOF flash flood for Rasuwagadhi (PDF p.130-131); for this plant it "
                 "says only that radial-gate hydraulics were restored 'after the flash flood' (PDF p.26, undated).")
    notes[plant] = note

new = pd.DataFrame(records)
cur = pd.read_csv(CLEANED_DIR / "plant_generation_monthly.csv")
pd.concat([cur[cur.fiscal_year != FY], new]).sort_values("fiscal_year", kind="stable").to_csv(
    CLEANED_DIR / "plant_generation_monthly.csv", index=False)

def q(s):
    return "'" + str(s).replace("'", "''") + "'"
sql = ["BEGIN;", ""]
for plant, pid in PLANTS.items():
    sql.append(f"UPDATE project_baseline SET notes = notes || {q(' ' + notes[plant])} "
               f"WHERE project_id = {q(pid)} AND fiscal_year = {FY} AND notes NOT LIKE '%Monthly table:%';")
sql.append("UPDATE nea_annual_data SET source_report = source_report || ' (provisional, subject to audit)' "
           f"WHERE fiscal_year = {FY} AND source_report NOT LIKE '%provisional%';")
sql += ["", "COMMIT;", ""]
(SQL_DIR / "11_fy2026_monthly_notes.sql").write_text("\n".join(sql), encoding="utf-8")

print(f"table found on PDF p.{page_no}; {len(table)} rows checked, all sums pass; hydro total {hydro/1000:,.2f} GWh")
print("\nGWh by month (Shrawan ... Ashar, FY2025/26):")
for plant in PLANTS:
    print(f"  {plant:18} total {table[plant][0]/1000:7.2f} |", " ".join(f"{m/1000:5.1f}" for m in table[plant][1:]))
print(f"\n{len(new)} monthly rows written; wrote sql/11_fy2026_monthly_notes.sql")
