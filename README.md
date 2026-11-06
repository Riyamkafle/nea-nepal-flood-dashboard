> **OUTDATED. Do not run the commands below: they can wipe later database changes. See docs/HANDOFF_UPDATE_RDNA.md for the current state.**

# NEA Nepal electricity - baseline and 2026 flood project

National annual baseline (FY2019/20-2024/25) built from NEA annual reports, ready to extend with the 2026 flood layers.

## Layout
```
data/raw/        NEA report PDFs (never modified; hashes in data/RAW_CHECKSUMS.sha256)
data/extracted/  page-tagged text dumps of the PDFs
data/cleaned/    hand-entered values (source of truth) + audit files
data/processed/  generated: derived columns and validation checks
data/archive/    legacy workbook and parked seasonal allocation (not for analysis)
scripts/         01 inspect PDFs | 02 validate + derive | 03 check values in source | 04 build SQL
sql/             01 schema | 02 generated load | 03 queries | parked/ (do not run)
docs/            data_dictionary.md, cleanup_log.md
```
## Run (from repo root)
```
pip install -r requirements.txt
python scripts/02_validate_and_derive.py
python scripts/03_check_values_in_source.py
python scripts/04_build_sql.py
psql -d nea_nepal -f sql/01_create_tables.sql -f sql/02_load_data.sql -f sql/03_queries.sql
```
## Rules
- Never edit `data/raw/`. Edit values only in `data/cleaned/*.csv`, then re-run the scripts.
- MW, GWh and NPR are separate quantities. Approved capacity is not actual export.
- Presence of a number in the report text is not verification.
