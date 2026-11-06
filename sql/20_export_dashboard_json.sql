-- 20_export_dashboard_json.sql : READ ONLY. Writes JSON files for the dashboard. Changes nothing in the database.
-- Run from the repo root after: mkdir -p dashboard/json
\set ON_ERROR_STOP on
\encoding UTF8
\pset tuples_only on
\pset format unaligned
\o dashboard/json/annual.json
SELECT COALESCE(json_agg(to_jsonb(x) - 'id' - 'created_at' ORDER BY x.fiscal_year), '[]'::json) FROM nea_annual_data x;
\o dashboard/json/trade.json
SELECT COALESCE(json_agg(to_jsonb(x) - 'id' ORDER BY x.fiscal_year, x.country), '[]'::json) FROM nea_country_trade x;
\o dashboard/json/projects.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.project_id), '[]'::json) FROM projects x;
\o dashboard/json/status_log.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.log_id), '[]'::json) FROM project_status_log x;
\o dashboard/json/events.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.event_id), '[]'::json) FROM events x;
\o dashboard/json/sources.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.source_id), '[]'::json) FROM sources x;
\o dashboard/json/assets.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.asset_id), '[]'::json) FROM transmission_assets x;
\o dashboard/json/evacuation.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.project_id, x.asset_id), '[]'::json) FROM project_evacuation x;
\o dashboard/json/baseline.json
SELECT COALESCE(json_agg(to_jsonb(x) ORDER BY x.project_id, x.fiscal_year), '[]'::json) FROM project_baseline x;
\o
\pset format aligned
\pset tuples_only off
\echo 'Export finished. Row counts in the database (for comparison with the Python check):'
SELECT (SELECT count(*) FROM nea_annual_data) AS annual, (SELECT count(*) FROM nea_country_trade) AS trade,
       (SELECT count(*) FROM projects) AS projects, (SELECT count(*) FROM project_status_log) AS status_log,
       (SELECT count(*) FROM events) AS events, (SELECT count(*) FROM sources) AS sources,
       (SELECT count(*) FROM transmission_assets) AS assets, (SELECT count(*) FROM project_evacuation) AS evacuation,
       (SELECT count(*) FROM project_baseline) AS baseline;
