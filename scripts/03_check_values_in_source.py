"""Check whether each hand-entered value appears in the matching report's text dump.

IMPORTANT: this proves PRESENCE of the number in the source text only.
It does NOT prove the number means what the column says (definition), that it is
the right row/table, or that units are right. Status vocabulary:
  found_in_source_text           number present, reasonably specific (>= 4 digits)
  found_low_specificity          number present but short (< 4 digits) -> could be coincidence
  not_found_in_source_text       not present in the text dump -> check the PDF manually
Output: data/cleaned/value_presence_check.csv  (with PDF page numbers of first hits)
"""
import re
import pandas as pd
from config import CLEANED_DIR, EXTRACTED_DIR, SOURCE_REPORTS

ENTERED = ["nea_generation_gwh", "ipp_purchase_gwh", "import_gwh", "export_gwh",
           "domestic_consumption_gwh", "peak_demand_mw", "peak_supply_mw",
           "revenue_npr_million", "profit_npr_million", "system_loss_pct",
           "consumers_million", "ppa_signed_capacity_mw"]

def variants(v):
    out = set()
    two = f"{v:.2f}"
    out.update({two, f"{v:,.2f}"})
    if float(v).is_integer():
        out.update({str(int(v)), f"{int(v):,}"})
    # trailing-zero forms, e.g. 1482.5 -> "1482.5"
    out.update({f"{v:g}", f"{float(f'{v:g}'):,}" if False else f"{v:g}"})
    return {x for x in out if x}

def pages(text):
    parts = re.split(r"=+ PAGE (\d+) =+", text)
    # parts: [pre, n1, txt1, n2, txt2, ...]
    return [(int(parts[i]), parts[i + 1]) for i in range(1, len(parts) - 1, 2)]

# Human-checked explanations for values that are not found as a single number.
KNOWN_REASONS = {
    (2020, "nea_generation_gwh"): "Report text states 3,021 GWh (rounded); the two decimals (3021.06) are not in the text dump. Source of decimals unknown - check the PDF table.",
    (2022, "ipp_purchase_gwh"): "Author-constructed: IPP + NEA subsidiaries combined (see data_notes.csv). Components not stored yet; cannot be found as one number.",
    (2023, "ipp_purchase_gwh"): "Author-constructed: IPP + NEA subsidiaries combined (see data_notes.csv). Components not stored yet; cannot be found as one number.",
    (2024, "ipp_purchase_gwh"): "Author-constructed: IPP + NEA subsidiaries combined (see data_notes.csv). Components not stored yet; cannot be found as one number.",
    (2025, "ipp_purchase_gwh"): "Author-constructed: IPP + NEA subsidiaries combined (see data_notes.csv). Components not stored yet; cannot be found as one number.",
}

d = pd.read_csv(CLEANED_DIR / "annual_national.csv")
rows = []
for _, r in d.iterrows():
    fy = int(r.fiscal_year)
    dump = EXTRACTED_DIR / f"{SOURCE_REPORTS[fy]}_text_dump.txt"
    pg = pages(dump.read_text(errors="ignore"))
    for col in ENTERED:
        v = r[col]
        if pd.isna(v):
            rows.append(dict(fiscal_year=fy, column=col, value=None, status="null_not_reported",
                             specificity="", hits=0, first_pdf_pages="", source_dump=dump.name))
            continue
        vs = variants(v)
        pats = [re.compile(r"(?<![\d,.])" + re.escape(x) + r"(?!\d)(?![.,]\d)") for x in vs]
        hit_pages = [n for n, txt in pg if any(p.search(txt) for p in pats)]
        digits = len(re.sub(r"\D", "", f"{v:.2f}".rstrip("0").rstrip(".")))
        spec = "high" if digits >= 4 else "low"
        if not hit_pages:
            status = "not_found_in_source_text"
        else:
            status = "found_in_source_text" if spec == "high" else "found_low_specificity"
        rows.append(dict(fiscal_year=fy, column=col, value=v, status=status, specificity=spec,
                         hits=len(hit_pages), first_pdf_pages=";".join(map(str, hit_pages[:5])),
                         source_dump=dump.name))
out = pd.DataFrame(rows)
out["note"] = "presence only; definition, table and unit not verified"
out["reason_if_not_found"] = [KNOWN_REASONS.get((r.fiscal_year, r.column), "") if r.status == "not_found_in_source_text" else "" for r in out.itertuples()]
out.to_csv(CLEANED_DIR / "value_presence_check.csv", index=False)
print(out.groupby("status").size().to_string())
print()
print(out[out.status.isin(["not_found_in_source_text", "found_low_specificity"])]
      [["fiscal_year", "column", "value", "status", "first_pdf_pages"]].to_string(index=False))
