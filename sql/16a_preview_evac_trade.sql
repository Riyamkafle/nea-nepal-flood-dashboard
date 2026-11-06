-- 16a_preview_evac_trade.sql : READ ONLY. Changes nothing.
\echo '=== 1. Existing assets and evacuation rows (reference) ==='
SELECT asset_id, asset_name, asset_type, voltage_kv FROM transmission_assets ORDER BY 1;
SELECT project_id, asset_id, source_id FROM project_evacuation ORDER BY 1,2;

\echo '=== 2. Proposed NEW asset TA-012 + duplicate check ==='
SELECT 'TA-012' AS asset_id,
       'SJCL 132 kV line (Sanjen and Upper Sanjen) to Chilime Hub' AS asset_name,
       EXISTS (SELECT 1 FROM transmission_assets
                WHERE asset_id = 'TA-012' OR asset_name ILIKE '%SJCL%' OR asset_name ILIKE '%Sanjen%') AS already_present;

\echo '=== 3. Proposed evacuation links ==='
SELECT v.project_id, p.project_name, v.asset_id,
       (v.asset_id = 'TA-012' OR EXISTS (SELECT 1 FROM transmission_assets a WHERE a.asset_id = v.asset_id)) AS asset_ok,
       EXISTS (SELECT 1 FROM project_evacuation e WHERE e.project_id = v.project_id AND e.asset_id = v.asset_id) AS already_linked
FROM (VALUES ('PRJ-003','TA-012'),('PRJ-003','TA-009'),('PRJ-003','TA-008'),
             ('PRJ-004','TA-012'),('PRJ-004','TA-009'),('PRJ-004','TA-008')) AS v(project_id, asset_id)
LEFT JOIN projects p ON p.project_id = v.project_id
ORDER BY 1,3;

\echo '=== 4. Proposed trade rows, fiscal_year 2026 + duplicate and FK check ==='
SELECT p.country, p.export_capacity_mw,
       EXISTS (SELECT 1 FROM nea_country_trade t WHERE t.fiscal_year = 2026 AND t.country = p.country) AS already_present,
       EXISTS (SELECT 1 FROM nea_annual_data a WHERE a.fiscal_year = 2026) AS fy2026_row_exists
FROM (VALUES ('India', 1160.01), ('Bangladesh', 40.00)) AS p(country, export_capacity_mw);

\echo '=== 5. Sum checks against report p.109 ==='
SELECT 486.57 + 70.00 + 603.44 AS india_mw,
       486.57 + 70.00 + 603.44 + 40.00 AS all_mw,
       1200.01 AS report_total_mw,
       11 + 2 + 22 + 2 AS approvals,
       37 AS report_approvals;

\echo '=== 6. Id counter check for nea_country_trade ==='
SELECT (SELECT max(id) FROM nea_country_trade) AS max_id, last_value, is_called
FROM nea_country_trade_id_seq;
