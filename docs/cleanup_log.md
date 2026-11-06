# Cleanup log (locked step 1)

| Item | Done | Evidence |
|---|---|---|
| `ppa_signed_capacity_mw` | Yes | Renamed in CSV, schema, queries and dictionary. The reports call it the combined capacity of signed PPAs (341, 392 and 455 projects in FY2019/20, 2022/23, 2023/24) |
| Capacity-utilisation and projection logic | Parked | Column dropped from schema; Q31+ moved to `sql/parked/`; `scripts/legacy/06_policy_targets.py` archived |
| Verification labels | Yes | "VERIFIED" removed; `data_notes.csv` uses `author_note`, `author_note_definition_unchecked`, `derived`. Presence in report text is tested separately |
| 60/40 seasonal assumption | Removed | Table dropped from schema; allocation CSV archived and relabelled `ASSUMED`; seasonal queries parked. No NEA report documents a 60/40 split (searched all six dumps) |
| Hand-entered values | Yes | Moved from scripts 02/03/05 to `data/cleaned/*.csv` (source of truth). Derived columns recomputed by script |
| Relative paths | Yes | `scripts/config.py`; `01_inspect_pdf.py` patched and no longer overwrites dumps without `--force` |
| SQL versions | Yes | Old dump (8 queries) and `sql/` had identical annual data but differed in queries; `sql/` was canonical. Load script is now generated from CSV. Two rounding slips (profit margin FY2021/22 18.56 vs 18.55; utilisation FY2022/23 and 2023/24) disappear with recomputation |
| Data dictionary | Yes | `docs/data_dictionary.md` |
| Raw files untouched | Yes | Nothing writes to `data/raw/`. SHA-256 of all six PDFs in `data/RAW_CHECKSUMS.sha256` |

## Findings during cleanup
- **Value presence:** 54 of 67 entered values are found in the source text with reasonable specificity, 8 are found but short (low specificity), 5 are not found and 5 are null. The not-found: FY2019/20 NEA generation (report says 3,021 GWh; decimals unexplained) and IPP purchase for FY2021/22 to 2024/25 (author-constructed sums).
- **Energy balance:** reported system loss reconciles exactly from FY2021/22; FY2019/20 and 2020/21 are off by about 0.4 pp.
- **Report totals:** the FY2024/25 report shows total available energy of 15,641 GWh (derived here: 15,640) and 13,966 GWh for FY2023/24 (derived: 13,967).

## Not done (deferred on purpose)
- Definitions and table locations are not checked page by page; presence in text is not verification.
- IPP and NEA-subsidiary components not separated.
- FY2025/26 not loaded (locked step 4). Bangladesh volumes and destination split still empty. Monthly data not started.
- SQL tested on DuckDB with `SERIAL` shimmed; not run on PostgreSQL itself.

## Cleanup you must do in your own repo
- Delete the outer `NEA_Projects/data/output/` and `NEA_Projects/NEA_Projects_sql_dump.sql`. The former is a stale duplicate (differently ordered sheets) and the latter is the 8-query dump. Copies of both are archived here.
- Keep `data/raw/` and `data/extracted/` exactly as they are.

## 2026-10-28 EVT-004 source review (controlled update)
- Opened four pages (My Republica, Khabarhub, SANDRP, Wikipedia). Added sources SRC-019 to SRC-022, all unverified; Wikipedia is a tertiary pointer only, revision ID not captured.
- Appended [UNVERIFIED] notes to EVT-004, status rows 23 (PRJ-021) and 24 (PRJ-022). No capacity, affected_mw or verified value changed. Stored EVT-004 total stays 412.09 MW; C-019 (412.41 MW) unchanged.
- Yaru Khola capacity seen in the sources: 30.59, 30.91 (Khabarhub; explains C-019) and 30.49 (SANDRP table, probable typo).
- Limitation: a 412.94 MW total and a five-project EVT-004 list appear in earlier research notes. Origin untraced, verification pending. Not used in any calculation. No conflict record (C-022) created.
- Backup: data/archive/nea_nepal_before_evt004_source_notes.dump. Script 15 expected sources count changed 18 -> 22.
