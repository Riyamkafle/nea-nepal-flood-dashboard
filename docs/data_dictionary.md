# Data dictionary (national annual layer)

**Status vocabulary.** *entered* = typed from an NEA annual report (source of truth: `data/cleaned/`). *derived* = recomputed by `scripts/02_validate_and_derive.py`, never typed. Nothing here is marked "verified": `data/cleaned/value_presence_check.csv` only shows whether a number appears in the report text; definitions and tables are not yet checked.

**Fiscal year.** `fiscal_year` is the Gregorian *end* year: 2025 = FY 2024/25 (Nepali fiscal year, roughly mid-July to mid-July). `fiscal_year_label` gives the AD label. Bikram Sambat dates are not stored yet; add `date_bs` when monthly data is loaded.

## `annual_national.csv` / table `nea_annual_data`

| Column | Unit | Status | Definition and caveats |
|---|---|---|---|
| fiscal_year | year | entered | End-year convention above |
| fiscal_year_label | text | entered | e.g. `2024/25` |
| nea_generation_gwh | GWh | entered | NEA-owned generation (Generation Directorate section). FY2025/26 report groups "NEA and subsidiaries"; map carefully when loading it |
| ipp_purchase_gwh | GWh | entered | FY2019/20-2020/21: Nepal-based independent producers. From FY2021/22 the author combined IPPs and NEA subsidiaries. Not found as a single number in the reports; components are not stored yet |
| total_production_gwh | GWh | derived | nea_generation + ipp_purchase. Excludes imports |
| import_gwh | GWh | entered | Energy imported (India) |
| export_gwh | GWh | entered | Energy exported, national total. Destination split unverified |
| net_export_gwh | GWh | derived | export - import. Positive = net exporter |
| total_available_gwh | GWh | derived | production + import. Report totals can differ by 1 GWh (see known_conflicts C-003/C-004) |
| domestic_consumption_gwh | GWh | entered | "Internal sold/utilized" from the Highlights table; excludes exports. The FY2025/26 report's domestic consumption includes NEA own use: check comparability |
| peak_demand_mw | MW | entered | Peak demand as reported. Definition per year not yet checked (FY2025/26 report separates "system peak" from "national peak") |
| peak_supply_mw | MW | entered | Peak supply as reported; NULL for FY2019/20 (not in that report) |
| ppa_signed_capacity_mw | MW | entered | Combined capacity of **signed PPAs**, including projects not yet built. **Not installed, available or operating capacity.** Reported only for some years. (Previously `total_capacity_mw`) |
| nea_revenue_npr_million | NPR million | entered | NEA company revenue. **Not export revenue** |
| nea_profit_npr_million | NPR million | entered | Net profit before tax |
| nea_cost_npr_million | NPR million | derived | revenue - profit (P&L format changed between years) |
| nea_profit_margin_pct | % | derived | profit / revenue x 100, 2 dp |
| system_loss_pct | % | entered | Reported system loss. From FY2021/22 it equals (available - domestic - exports) / available; FY2019/20 and 2020/21 differ by about 0.4 pp (validation flag) |
| consumers_million | million | entered | Consumers; NULL for FY2021/22 |
| source_report | text | entered | Raw PDF filename in `data/raw/` |

## `country_trade.csv` / table `nea_country_trade`

| Column | Unit | Definition and caveats |
|---|---|---|
| country, trade_status | text | India / Bangladesh; Active, Planned or No Trade |
| trade_partner, trade_mechanism | text | As described in the reports; not re-checked |
| export_gwh, import_gwh | GWh | **India rows currently hold the national total (all destinations).** Bangladesh volumes are empty even though exports began in FY2024/25 |
| export_revenue_npr_million | NPR million | Only FY2024/25 is loaded (17,471); conflict C-005 open |
| export_capacity_mw, import_capacity_mw | MW | Approved or planned capacity, **not actual flow**. Approval is not export |
| volume_scope | text | `national_total_all_destinations_split_unverified` (India) / `no_volume_reported` |
| season_active, notes, data_source | text | As described in the reports |

## Generated and audit files

| File | Purpose |
|---|---|
| `data/processed/annual_national_full.csv` | Entered + derived columns (input to SQL) |
| `data/processed/validation_checks.csv` | 41 checks: regression against the legacy workbook, energy-balance loss test, peak ordering |
| `data/cleaned/value_presence_check.csv` | Per value: found in the report's text dump? which PDF pages? specificity |
| `data/cleaned/known_conflicts.csv` | Conflicting numbers, both sources recorded, value used and why |
| `data/cleaned/data_notes.csv` | The original author's notes, with "VERIFIED" labels removed |
| `data/archive/` | Legacy workbook and parked seasonal allocation (not for analysis) |
