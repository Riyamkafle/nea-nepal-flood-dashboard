-- 16b_apply_evac_trade.sql : DO NOT RUN until 16a output has been reviewed.
\set ON_ERROR_STOP on
BEGIN;

-- A. New asset TA-012 (skipped if id exists or an SJCL asset exists)
INSERT INTO transmission_assets (asset_id, asset_name, asset_type, voltage_kv, capacity_mw, notes)
SELECT 'TA-012',
       'SJCL 132 kV line (Sanjen and Upper Sanjen) to Chilime Hub',
       'line', 132.0::numeric, NULL::numeric,
       'NEA FY2025/26 report PDF p.119 (printed 109), Sanjen Jalavidhyut Company section (SRC-006): power from Sanjen (Upper) 14.8 MW and Sanjen 42.5 MW is evacuated through the SJCL 132 kV transmission line to the Chilime Hub substation. The report prints kVA; read as kV (my inference). Length, conductor and circuit count are not stated, and the line is not in the line tables on PDF pp.207-209.'
WHERE NOT EXISTS (SELECT 1 FROM transmission_assets
                   WHERE asset_id = 'TA-012' OR asset_name ILIKE '%SJCL%');

-- B. Evacuation links (stated on p.119; skipped if the pair exists)
INSERT INTO project_evacuation (project_id, asset_id, source_id, notes)
SELECT v.project_id, v.asset_id, 'SRC-006', v.note
FROM (VALUES
 ('PRJ-003','TA-012','Stated: PDF p.119, power from both Sanjen plants goes through the SJCL 132 kV line to the Chilime Hub substation.'),
 ('PRJ-003','TA-009','Stated: PDF p.119, the SJCL line ends at the Chilime Hub substation.'),
 ('PRJ-003','TA-008','Stated: PDF p.119, the Chilime Hub then connects to the national grid through the Chilime-Trishuli 220 kV line. Mapping that line to TA-008 is by name (inference).'),
 ('PRJ-004','TA-012','Stated: PDF p.119, power from both Sanjen plants goes through the SJCL 132 kV line to the Chilime Hub substation.'),
 ('PRJ-004','TA-009','Stated: PDF p.119, the SJCL line ends at the Chilime Hub substation.'),
 ('PRJ-004','TA-008','Stated: PDF p.119, the Chilime Hub then connects to the national grid through the Chilime-Trishuli 220 kV line. Mapping that line to TA-008 is by name (inference).')
) AS v(project_id, asset_id, note)
WHERE EXISTS (SELECT 1 FROM projects p WHERE p.project_id = v.project_id)
  AND EXISTS (SELECT 1 FROM transmission_assets a WHERE a.asset_id = v.asset_id)
  AND NOT EXISTS (SELECT 1 FROM project_evacuation e
                   WHERE e.project_id = v.project_id AND e.asset_id = v.asset_id);

-- C. Append-only note on TA-008
UPDATE transmission_assets
SET notes = COALESCE(NULLIF(notes,'') || ' ', '') ||
 '[p.119 check 2026-10-13] PDF p.119 says the Chilime Hub substation connects to the grid through the Chilime-Trishuli 220 kV line. This supports reading Chilime Hub as an endpoint but does not prove it.'
WHERE asset_id = 'TA-008'
  AND (notes IS NULL OR notes NOT LIKE '%[p.119 check 2026-10-13]%');

-- D. Trade rows, fiscal_year 2026 (keep the id counter ahead of existing ids)
SELECT setval('nea_country_trade_id_seq',
              GREATEST((SELECT max(id) FROM nea_country_trade),
                       (SELECT last_value FROM nea_country_trade_id_seq)));

INSERT INTO nea_country_trade (fiscal_year, country, trade_status, trade_partner, trade_mechanism,
       export_gwh, import_gwh, export_revenue_npr_million, import_cost_npr_million,
       export_capacity_mw, import_capacity_mw, season_active, volume_scope, notes, data_source)
SELECT 2026, 'India', 'Active', NULL, 'PEC / Day-Ahead / Medium Term Bilateral',
       NULL::numeric, NULL::numeric, NULL::numeric, NULL::numeric,
       1160.01::numeric, NULL::numeric, 'Year Round', 'volume_not_loaded_conflicting_figures',
       'Approved export quantum in MW (not flows): 1,160.01 MW = power exchange (DAM/RTM) 486.57 MW over 11 approvals via Dhalkebar-Muzaffarpur 400 kV + 70.00 MW over 2 approvals via Tanakpur-Mahendranagar 132 kV + medium-term bilateral 603.44 MW over 22 approvals (SRC-006 PDF p.109). Report total with Bangladesh: 1,200.01 MW, 37 approvals. Interim line limits from the 13th JWG/JSC, 14-15 Jul 2026 (PDF p.109), NOT additive to the quantum: Butwal-Gorakhpur run at 220 kV, import 130 MW and export 200 MW; Dhalkebar-Muzaffarpur plus Dhalkebar-Sitamarhi combined, export 1,650 MW and import 1,400 MW. The report calls both new lines on the verge of completion. Energy: PDF p.55 says about 3,962 GWh sold to India; PDF p.54 total exported 3,938 GWh; nea_annual_data holds 3,965 (conflict open, see known_conflicts). export_gwh left NULL. Agreements described on PDF pp.15 and 108: 2 x 200 MW to Haryana Discoms for 5 years; up to 200 MW to Bihar State Power Holding Co. for 3 years (extendable to 5). All figures provisional, subject to audit.',
       'NEA Annual Report 2025/26 (provisional)'
WHERE EXISTS (SELECT 1 FROM nea_annual_data WHERE fiscal_year = 2026)
  AND NOT EXISTS (SELECT 1 FROM nea_country_trade WHERE fiscal_year = 2026 AND country = 'India');

INSERT INTO nea_country_trade (fiscal_year, country, trade_status, trade_partner, trade_mechanism,
       export_gwh, import_gwh, export_revenue_npr_million, import_cost_npr_million,
       export_capacity_mw, import_capacity_mw, season_active, volume_scope, notes, data_source)
SELECT 2026, 'Bangladesh', 'Active', NULL, 'Medium Term Bilateral Agreement (Nepal-Bangladesh)',
       NULL::numeric, NULL::numeric, NULL::numeric, NULL::numeric,
       40.00::numeric, NULL::numeric, 'Round-the-clock from June (year inferred)', 'no_volume_reported',
       'Approved quantum 40.00 MW over 2 approvals via Dhalkebar-Muzaffarpur 400 kV (SRC-006 PDF p.109). PDF p.55: a round-the-clock quantum of 40 MW is exported to Bangladesh starting June. The year is not printed; my reading is June 2026, after the monsoon-only start on 15 Jun 2025 recorded for FY2024/25. Earlier years labelled the arrangement tripartite; the FY2025/26 table calls it a medium-term bilateral agreement. No Bangladesh volume stated. Provisional, subject to audit.',
       'NEA Annual Report 2025/26 (provisional)'
WHERE EXISTS (SELECT 1 FROM nea_annual_data WHERE fiscal_year = 2026)
  AND NOT EXISTS (SELECT 1 FROM nea_country_trade WHERE fiscal_year = 2026 AND country = 'Bangladesh');

COMMIT;

\echo '=== VALIDATION (read only) ==='
\echo 'Expected: transmission_assets 12, project_evacuation 14, nea_country_trade 14'
SELECT (SELECT count(*) FROM transmission_assets) AS assets,
       (SELECT count(*) FROM project_evacuation) AS evacuation_links,
       (SELECT count(*) FROM nea_country_trade) AS trade_rows;
SELECT e.project_id, p.project_name, e.asset_id, a.asset_name
FROM project_evacuation e
JOIN projects p ON p.project_id = e.project_id
JOIN transmission_assets a ON a.asset_id = e.asset_id
ORDER BY 1,3;
\echo 'Expected: FY2026 export capacity sum 1200.01'
SELECT fiscal_year, country, trade_status, export_capacity_mw, season_active, volume_scope
FROM nea_country_trade WHERE fiscal_year = 2026 ORDER BY country;
SELECT SUM(export_capacity_mw) AS fy2026_export_capacity_mw
FROM nea_country_trade WHERE fiscal_year = 2026;
