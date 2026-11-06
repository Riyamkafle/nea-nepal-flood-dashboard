"""Build sql/07_seed_plant_baseline.sql from data/cleaned/plant_generation_monthly.csv.
Annual totals only (FY2022, 2024, 2025) for PRJ-009/010/011. FY2026 rows already exist."""
import statistics
import pandas as pd
from config import CLEANED_DIR, SQL_DIR

PROJECT = {"Upper Trishuli 3A": "PRJ-009", "Trishuli": "PRJ-010", "Devighat": "PRJ-011"}
SOURCE = {2022: "SRC-007", 2024: "SRC-008", 2025: "SRC-009"}
FILES = {2022: "Annual_Report_2021-22.pdf", 2024: "2023-2024.pdf", 2025: "2024-2025.pdf"}
LABEL = {2022: "FY2021/22", 2024: "FY2023/24", 2025: "FY2024/25"}
SNAPSHOT = "2026-10-01"

def q(s):
    return "'" + str(s).replace("'", "''") + "'"

d = pd.read_csv(CLEANED_DIR / "plant_generation_monthly.csv")
out = ["BEGIN;", ""]
for fy, src in SOURCE.items():
    out.append(
        "INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date) "
        f"VALUES ({q(src)}, {q('NEA Annual Report ' + LABEL[fy])}, {q('Nepal Electricity Authority')}, "
        f"{q('data/raw/' + FILES[fy])}, 'Primary', NULL, {q(SNAPSHOT)});")
out.append("")
for (fy, plant), g in d.groupby(["fiscal_year", "plant"], sort=False):
    total = g["total_mwh"].iloc[0]
    assert abs(g["generation_mwh"].sum() - total) <= 3, (fy, plant)
    med = statistics.median(g["generation_mwh"])
    low = [f"{r.bs_month} {r.generation_mwh/1000:.1f}" for r in g.itertuples() if r.generation_mwh < 0.5 * med]
    note = (f"Dump page {int(g['pdf_page'].iloc[0])}, appendix generation table. Annual total equals the sum of the "
            f"12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.")
    if low:
        note += f" Unusually low months (under half the median, GWh): {', '.join(low)}. Cause not established."
    out.append(
        "INSERT INTO project_baseline (project_id, fiscal_year, generation_gwh, source_id, notes) "
        f"VALUES ({q(PROJECT[plant])}, {fy}, {total/1000:.2f}, {q(SOURCE[fy])}, {q(note)});")
out += ["", "COMMIT;", ""]
(SQL_DIR / "07_seed_plant_baseline.sql").write_text("\n".join(out), encoding="utf-8")
print(f"wrote sql/07_seed_plant_baseline.sql ({len(out)} lines)")
