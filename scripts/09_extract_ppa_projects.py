"""NEA-connected generation projects from the FY2025/26 annual report appendix (printed pp.178-194,
PDF pp.188-204): developer, project, district, installed capacity (kW), PPA date, commercial operation date
(Bikram Sambat as printed). Reads data/raw/A Year In Review Annual Report 2025_2026_compressed.pdf (read-only).

Layout notes: table columns shift between pages, so column edges are calibrated from each page's own rows;
developer/project names wrap onto lines above and below a row, so every line is attached to the nearest serial
number. Each block of the report ends with a printed SUB-TOTAL/TOTAL line. The script STOPS unless the capacity of
every block adds up to its printed subtotal to the kW (it did for all 9 blocks when written).
Writes data/cleaned/nea_ppa_projects_fy2026.csv. Optional: pip install nepali-datetime for AD dates (approximate
for invalid BS days; blank if conversion fails).
"""
import re
import csv
import collections
import statistics
try:
    import pymupdf
except ImportError:          # older PyMuPDF installs expose it as 'fitz'
    import fitz as pymupdf
from config import ROOT, CLEANED_DIR
try:
    import nepali_datetime
except ImportError:
    nepali_datetime = None

PDF = ROOT / "data" / "raw" / "A Year In Review Annual Report 2025_2026_compressed.pdf"
FIRST, LAST = 188, 204
NUMRX = re.compile(r"^\d[\d,]*(\.\d+)?$")
DATERX = re.compile(r"^\d{4}\.\d{1,2}\.\d{1,2}$")
SKIP = re.compile(r"A YEAR IN REVIEW|FISCAL YEAR|NEPAL ELECTRICITY AUTHORITY|^APPENDIX|S\.N\.|Installed Capacity|"
                  r"Developers? +Projects|^Installed|^Commercial|^Operation|^PPA|^Date$|^\(kW\)$|^\d{3}$|^Capacity")
SECRX = re.compile(r"Projects?\b|Solar|Subsidiar|Under Construction|Hybrid|Wind|Thermal", re.I)
CORP = ("Ltd", "Pvt", "Limited", "Company", "Co.")
HEADER_WORDS = {"(kW)", "Date", "Installed", "Capacity", "PPA", "Commercial", "Operation", "S.N.", "Developer",
                "Developers", "Projects", "Location", "APPENDIX", "Operation Date", "Date)"}
TITLE = re.compile(r"Status of IPPs|POWER TRADE DEPARTMENT|Power Projects \(|as of FY|2082/83 projects|PPA Signed|Projects\)", re.I)

doc = pymupdf.open(PDF)

def line_groups(words):
    ws = sorted(words, key=lambda w: (w[1] + w[3]) / 2)
    out, cur, last = [], [], None
    for w in ws:
        yc = (w[1] + w[3]) / 2
        if last is None or yc - last <= 2.5:
            cur.append(w)
        else:
            out.append(cur); cur = [w]
        last = yc
    if cur:
        out.append(cur)
    return [sorted(l, key=lambda w: w[0]) for l in out]

rows, subtotals = [], []
section = None
for pn in range(FIRST, LAST + 1):
    page = doc[pn - 1]
    keep, sec_lines = [], []
    for ln in line_groups(page.get_text("words")):
        toks = [w[4] for w in ln]
        txt = " ".join(toks)
        y = sum((w[1] + w[3]) / 2 for w in ln) / len(ln)
        if re.match(r"^(SUB-?TOTAL|TOTAL|GRAND)", txt, re.I):
            nums = [t for t in toks if NUMRX.match(t)]
            subtotals.append((pn, y, txt.split()[0].upper(), float(nums[-1].replace(",", ""))))
            continue
        has_sn = bool(re.match(r"^\d+$", toks[0])) and ln[0][0] < 130 and len(toks) > 1
        if SKIP.search(txt) and not has_sn:
            continue
        if not has_sn and (set(toks) <= HEADER_WORDS or TITLE.search(txt)):
            continue
        if (not has_sn and not any(DATERX.match(t) or NUMRX.match(t) for t in toks) and SECRX.search(txt)
                and len(toks) <= 14 and ln[0][0] < 130 and not any(c in txt for c in CORP)):
            sec_lines.append((y, txt)); continue
        keep.append((y, ln))
    # calibrate columns from SN lines that carry a date
    full = [ln for y, ln in keep if re.match(r"^\d+$", ln[0][4]) and any(DATERX.match(w[4]) for w in ln)]
    if not full:
        continue
    sn_x = statistics.median(ln[0][0] for ln in full)
    # capacity column: the number sitting directly before each row's first date
    cap_xs, last_xs = [], []
    for ln in full:
        di = next(i for i, w in enumerate(ln) if DATERX.match(w[4]))
        if di > 1 and NUMRX.match(ln[di - 1][4]):
            cap_xs.append(ln[di - 1][0])
            before = [w for w in ln[1:di - 1] if not NUMRX.match(w[4])]
            if before:
                last_xs.append(round(before[-1][0]))
    cap_x = statistics.median(cap_xs)
    loc_x = collections.Counter(last_xs).most_common(1)[0][0]          # district words start here (left aligned)
    mid = collections.Counter(round(w[0]) for ln in full for w in ln[1:]
                              if sn_x + 80 < w[0] < loc_x - 15 and not DATERX.match(w[4]))
    proj_x = mid.most_common(1)[0][0]                                   # project words start here (left aligned)
    anchors = [(y, ln[0][4]) for y, ln in keep if re.match(r"^\d+$", ln[0][4]) and abs(ln[0][0] - sn_x) < 8]
    recs = [dict(section=None, sn=sn, y=y, developer=[], project=[], district=[], nums=[], dates=[], pdf_page=pn)
            for y, sn in anchors]
    # section label in effect for each anchor = last heading above it (or carried over from the previous page)
    secs = sorted(sec_lines)
    for r in recs:
        above = [t for yy, t in secs if yy < r["y"]]
        r["section"] = above[-1] if above else section
    if secs:
        section = secs[-1][1]
    for y, ln in keep:
        owner = min(recs, key=lambda r: abs(r["y"] - y))
        for w in ln:
            t = w[4]
            if t == "APPENDIX":          # vertical margin tab printed beside some rows
                continue
            if w is ln[0] and re.match(r"^\d+$", t) and abs(w[0] - sn_x) < 8:
                continue
            if DATERX.match(t):
                owner["dates"].append((w[0], t))
            elif NUMRX.match(t) and abs(w[0] - cap_x) <= 25:
                owner["nums"].append((w[0], t))
            elif w[0] >= loc_x - 3:
                owner["district"].append(t)
            elif w[0] >= proj_x - 3:
                owner["project"].append(t)
            else:
                owner["developer"].append(t)
    for r in recs:
        r["dates"].sort()
        r["capacity_kw"] = float(r["nums"][0][1].replace(",", "")) if r["nums"] else None
        r["ppa_bs"] = r["dates"][0][1] if r["dates"] else ""
        r["cod_bs"] = r["dates"][1][1] if len(r["dates"]) > 1 else ""
        for k in ("developer", "project", "district"):
            r[k] = " ".join(r[k])
        rows.append(r)

# group rows by the printed subtotal that closes each block, and require an exact match
events = sorted([(r["pdf_page"], r["y"], "row", r) for r in rows] +
                [(p, y, "sub", (k, v)) for p, y, k, v in subtotals], key=lambda e: (e[0], e[1]))
cur, blocks = [], []
for pg, y, kind, v in events:
    if kind == "row":
        cur.append(v)
    else:
        blocks.append((cur, v)); cur = []
labels = ["operating: NEA subsidiaries", "operating: IPP hydro", "operating: solar", "operating: other", None,
          "under construction: GoN/NEA subsidiaries", "under construction: IPP hydro", "under construction: solar", None,
          "third table (PPA-signed): hydro IPPs", "third table (PPA-signed): solar IPPs", None]
problems = []
for i, (rs, (kind, printed)) in enumerate(blocks):
    if kind == "TOTAL":
        continue
    s = sum(r["capacity_kw"] or 0 for r in rs)
    for r in rs:
        r["block"] = labels[i] if i < len(labels) else f"block {i}"
    if abs(s - printed) > 0.5:
        problems.append(f"block {i} ({labels[i] if i < len(labels) else '?'}): parsed {s:,.1f} kW, printed {printed:,.1f} kW")
assert not problems, "capacity does not reconcile with the report's subtotals:\n  " + "\n  ".join(problems)
def to_ad(bs):
    if not nepali_datetime or not bs:
        return ""
    try:
        y, m, d = map(int, bs.split("."))
        return nepali_datetime.date(y, m, d).to_datetime_date().isoformat()
    except Exception:
        return ""

out = CLEANED_DIR / "nea_ppa_projects_fy2026.csv"
flag = lambda r: "COD before PPA date (check)" if r["ppa_bs"] and r["cod_bs"] and r["cod_bs"] < r["ppa_bs"] else ""
with open(out, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["block", "sn", "developer", "project", "district", "capacity_kw", "ppa_date_bs", "cod_bs",
                "cod_ad_approx", "flag", "pdf_page"])
    for rs, (kind, printed) in blocks:
        if kind == "TOTAL":
            continue
        for r in rs:
            w.writerow([r["block"], r["sn"], r["developer"], r["project"], r["district"], r["capacity_kw"],
                        r["ppa_bs"], r["cod_bs"], to_ad(r["cod_bs"]), flag(r), r["pdf_page"]])

print(f"{'block':44} {'rows':>5} {'kW parsed':>13} {'kW printed':>13}")
for i, (rs, (kind, printed)) in enumerate(blocks):
    if kind == "TOTAL":
        continue
    print(f"{rs[0]['block'] if rs else '-':44} {len(rs):5d} {sum(r['capacity_kw'] or 0 for r in rs):13,.1f} {printed:13,.1f}")
op = [r for rs, (k, p) in blocks if k != "TOTAL" for r in rs if r["block"].startswith("operating")]
print(f"\noperating projects: {len(op)}, {sum(r['capacity_kw'] for r in op)/1000:,.2f} MW (report TOTAL line: see below)")
print("report TOTAL lines:", [v for p, y, k, v in subtotals if k == "TOTAL"])
print("rows flagged COD-before-PPA:", sum(1 for rs, (k, p) in blocks if k != "TOTAL" for r in rs if flag(r)))
print(f"wrote {out.name}")
