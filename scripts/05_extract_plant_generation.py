"""Extract monthly generation for three NEA-owned plants from the annual-report dumps.

READ-ONLY on data/extracted. Writes data/cleaned/plant_generation_monthly.csv and prints a
summary so YOU can confirm the numbers against the PDF pages before anything goes into PostgreSQL.

Why this works: each report's appendix table "Generation Related Statistics" is rotated, so the
dump holds every line REVERSED (e.g. 'tahgiveD'). We reverse lines back, find the plant row, take the
13 numbers (12 months + total, in MWh) and require that the months add up to the total.

Month order in every layout = Ashad, Jestha, ... Shrawan (last month of the year first).
Years covered: FY2021/22, FY2023/24, FY2024/25. FY2019/20 and 2020/21 use a different table;
the FY2022/23 dump has no per-plant table (gaps, not errors).
"""
import re
import statistics
import pandas as pd
from config import EXTRACTED_DIR, CLEANED_DIR, SOURCE_REPORTS, fy_label

YEARS = [2022, 2024, 2025]
NUMRX = re.compile(r"^(\d[\d,]*(\.\d+)?|-)$")
ABBR = re.compile(r"^[A-Z0-9]{2,6}$")
ALIASES = {
    "Upper Trishuli 3A": {"UT3A", "Trishuli 3A", "Upper Trishuli 3A"},
    "Trishuli":          {"THPS", "Trishuli"},
    "Devighat":          {"DHPS", "Devighat"},
}
MONTHS = ["Ashad", "Jestha", "Baisakh", "Chaitra", "Falgun", "Magh",
          "Poush", "Mangsir", "Kartik", "Aswin", "Bhadra", "Shrawan"]

def pages(text):
    parts = re.split(r"=+ PAGE (\d+) =+", text)
    return [(int(parts[i]), parts[i + 1]) for i in range(1, len(parts) - 1, 2)]

def val(s):
    return 0.0 if s == "-" else float(s.replace(",", ""))

rows, summary = [], []
for fy in YEARS:
    dump = EXTRACTED_DIR / f"{SOURCE_REPORTS[fy]}_text_dump.txt"
    pg = pages(dump.read_text(errors="ignore").replace("\r", ""))
    rotated = [(n, t) for n, t in pg
               if re.search("noitareneg", t, re.I) and re.search("etarotcerid|ytirohtua", t, re.I)]
    for plant, names in ALIASES.items():
        found = False
        for n, t in rotated:
            rev = [l.strip()[::-1] for l in t.split("\n") if l.strip()]
            for i, l in enumerate(rev):
                if l not in names:
                    continue
                j = i - 1
                if j >= 0 and not NUMRX.match(rev[j]) and ABBR.match(rev[j]):
                    j -= 1
                nums = []
                while j >= 0 and len(nums) < 13 and NUMRX.match(rev[j]):
                    nums.append(rev[j]); j -= 1
                nums = nums[::-1]
                if len(nums) != 13:
                    continue
                v = [val(x) for x in nums]
                if abs(sum(v[:12]) - v[12]) <= 3:
                    months, total, layout = v[:12], v[12], "total last"
                elif abs(sum(v[1:]) - v[0]) <= 3:
                    months, total, layout = v[1:], v[0], "total first"
                else:
                    continue
                med = statistics.median(months)
                low = [f"{MONTHS[k]} {months[k]/1000:.1f}" for k in range(12) if months[k] < 0.5 * med]
                for k in range(12):
                    rows.append(dict(fiscal_year=fy, fiscal_year_label=fy_label(fy), plant=plant,
                                     month_order=k + 1, bs_month=MONTHS[k],
                                     fiscal_month_no=12 - k,  # 1=Shrawan ... 12=Ashad
                                     generation_mwh=months[k], total_mwh=total, pdf_page=n,
                                     source_dump=dump.name, sum_check="pass"))
                summary.append((fy_label(fy), plant, round(total / 1000, 2), n, layout, "pass",
                                ", ".join(low) if low else "-"))
                found = True
                break
            if found:
                break
        if not found:
            summary.append((fy_label(fy), plant, None, None, "-", "NOT FOUND", "-"))

out = pd.DataFrame(rows)
out.to_csv(CLEANED_DIR / "plant_generation_monthly.csv", index=False)
print(f"{'FY':8} {'Plant':18} {'Total GWh':>10} {'PDF pg':>7}  {'Layout':11} {'Sum':9} Low months (< half the median, GWh)")
for s in summary:
    print(f"{s[0]:8} {s[1]:18} {str(s[2]):>10} {str(s[3]):>7}  {s[4]:11} {s[5]:9} {s[6]}")
print(f"\n{len(out)} monthly rows saved to data/cleaned/plant_generation_monthly.csv")
