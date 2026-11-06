-- =============================================================================
-- PROJECT  : NEA Nepal - baseline queries (national annual layer)
-- FILE     : 03_queries.sql
-- NOTE     : Numbering kept from the original file for traceability.
--            PARKED (see sql/parked/): Q4, Q9-Q13, Q19 (depended on the seasonal
--            allocation, which is not data) and Q31+ (policy-target projections
--            built on PPA-signed capacity, which is not installed capacity).
--            "Revenue" here is NEA company revenue, NOT export revenue.
-- =============================================================================

-- QUERY 1: Was Nepal a net exporter or net importer of electricity, by year?
SELECT fiscal_year_label, export_gwh, import_gwh, net_export_gwh,
       CASE WHEN net_export_gwh > 0 THEN 'NET EXPORTER' ELSE 'NET IMPORTER' END AS energy_status
FROM nea_annual_data
ORDER BY fiscal_year;

-- QUERY 2: System loss in energy terms.
-- Basis: energy available (production + imports). From FY2021/22 the reported loss
-- equals (available - domestic - exports)/available; FY2019/20 and 2020/21 differ by ~0.4 pp.
SELECT fiscal_year_label, system_loss_pct, total_available_gwh,
       ROUND(total_available_gwh * system_loss_pct / 100, 2) AS implied_lost_gwh
FROM nea_annual_data
ORDER BY fiscal_year;

-- QUERY 3: IPP purchases vs NEA own generation.
-- Caution: ipp_purchase_gwh is author-constructed (IPP + NEA subsidiaries) from FY2021/22.
SELECT fiscal_year_label, nea_generation_gwh, ipp_purchase_gwh, total_production_gwh,
       ROUND(nea_generation_gwh * 100.0 / total_production_gwh, 1) AS nea_share_pct,
       ROUND(ipp_purchase_gwh  * 100.0 / total_production_gwh, 1) AS ipp_share_pct
FROM nea_annual_data
ORDER BY fiscal_year;

-- QUERY 5: NEA company profitability alongside export volume (association only, no causal claim).
SELECT fiscal_year_label, export_gwh, nea_revenue_npr_million, nea_profit_npr_million,
       nea_profit_margin_pct,
       nea_profit_npr_million - LAG(nea_profit_npr_million) OVER (ORDER BY fiscal_year) AS yoy_profit_change_mnpr
FROM nea_annual_data
ORDER BY fiscal_year;

-- QUERY 6: Consumers and consumption per consumer (FY2021/22 consumers not reported).
SELECT fiscal_year_label, consumers_million, domestic_consumption_gwh,
       ROUND(domestic_consumption_gwh / consumers_million, 2) AS gwh_per_million_consumers,
       ROUND((consumers_million - LAG(consumers_million) OVER (ORDER BY fiscal_year)) * 100.0
             / LAG(consumers_million) OVER (ORDER BY fiscal_year), 1) AS consumer_growth_pct
FROM nea_annual_data
WHERE consumers_million IS NOT NULL
ORDER BY fiscal_year;

-- QUERY 7: Peak supply vs peak demand (MW). Definitions per each annual report; unverified.
SELECT fiscal_year_label, peak_demand_mw, peak_supply_mw,
       ROUND(peak_supply_mw - peak_demand_mw, 2) AS supply_minus_demand_mw,
       CASE WHEN peak_supply_mw IS NULL THEN 'Data not reported'
            WHEN peak_supply_mw >= peak_demand_mw THEN 'Supply >= demand'
            ELSE 'Supply < demand' END AS peak_status
FROM nea_annual_data
ORDER BY fiscal_year;

-- QUERY 8: Trade volumes with the India row.
-- The India row currently holds the NATIONAL total (all destinations); see volume_scope.
SELECT a.fiscal_year_label, a.export_gwh AS national_export_gwh, a.import_gwh AS national_import_gwh,
       t.export_revenue_npr_million AS india_row_export_revenue_mnpr, t.trade_status, t.trade_mechanism,
       t.volume_scope,
       ROUND(a.export_gwh * 100.0 / NULLIF(a.export_gwh + a.import_gwh, 0), 1) AS export_share_of_gross_trade_pct
FROM nea_annual_data a
JOIN nea_country_trade t ON a.fiscal_year = t.fiscal_year
WHERE t.country = 'India'
ORDER BY a.fiscal_year;

-- BONUS: Summary view
SELECT fiscal_year_label, total_production_gwh, import_gwh, export_gwh, net_export_gwh,
       domestic_consumption_gwh, system_loss_pct, nea_revenue_npr_million, nea_profit_npr_million,
       nea_profit_margin_pct, consumers_million,
       CASE WHEN net_export_gwh > 0 THEN 'NET EXPORTER' ELSE 'NET IMPORTER' END AS energy_status
FROM nea_annual_data
ORDER BY fiscal_year;

-- QUERY 14: Trade status by country and year
SELECT fiscal_year, country, trade_status, export_gwh, import_gwh, export_revenue_npr_million,
       export_capacity_mw AS approved_or_planned_export_mw, season_active, volume_scope
FROM nea_country_trade
ORDER BY fiscal_year, country;

-- QUERY 15: India-row trade balance trend (national totals; see volume_scope)
SELECT fiscal_year, export_gwh, import_gwh, (export_gwh - import_gwh) AS net_flow_gwh,
       export_revenue_npr_million, trade_mechanism,
       CASE WHEN export_gwh - import_gwh > 0 THEN 'NET EXPORTER'
            WHEN export_gwh - import_gwh < 0 THEN 'NET IMPORTER' ELSE 'Balanced' END AS trade_position,
       ROUND(export_gwh - LAG(export_gwh) OVER (ORDER BY fiscal_year), 2) AS export_growth_gwh,
       ROUND(import_gwh - LAG(import_gwh) OVER (ORDER BY fiscal_year), 2) AS import_change_gwh
FROM nea_country_trade
WHERE country = 'India'
ORDER BY fiscal_year;

-- QUERY 16: Bangladesh progression (status and approved capacity only; no volumes loaded yet)
SELECT fiscal_year, trade_status, export_capacity_mw AS approved_or_planned_export_mw, season_active, notes
FROM nea_country_trade
WHERE country = 'Bangladesh'
ORDER BY fiscal_year;

-- QUERY 17: Active trading partners per year
SELECT fiscal_year, COUNT(*) AS active_partner_rows, STRING_AGG(country, ', ') AS active_partners
FROM nea_country_trade
WHERE trade_status = 'Active'
GROUP BY fiscal_year
ORDER BY fiscal_year;

-- QUERY 18: Export revenue relative to NEA total revenue (only years with export revenue loaded)
SELECT a.fiscal_year_label, t.export_revenue_npr_million, a.nea_revenue_npr_million,
       ROUND(t.export_revenue_npr_million * 100.0 / NULLIF(a.nea_revenue_npr_million, 0), 2) AS export_share_of_nea_revenue_pct
FROM nea_country_trade t
JOIN nea_annual_data a ON t.fiscal_year = a.fiscal_year
WHERE t.country = 'India' AND t.export_revenue_npr_million IS NOT NULL
ORDER BY a.fiscal_year;

-- QUERY 20: Cross-border summary
SELECT a.fiscal_year_label, a.total_production_gwh, a.import_gwh, a.export_gwh, a.net_export_gwh,
       a.nea_revenue_npr_million, ind.export_revenue_npr_million AS india_row_export_revenue_mnpr,
       ind.trade_status AS india_trade_status, ban.trade_status AS bangladesh_trade_status,
       CASE WHEN a.net_export_gwh > 0 THEN 'Net export year' ELSE 'Net import year' END AS national_trade_position
FROM nea_annual_data a
LEFT JOIN nea_country_trade ind ON a.fiscal_year = ind.fiscal_year AND ind.country = 'India'
LEFT JOIN nea_country_trade ban ON a.fiscal_year = ban.fiscal_year AND ban.country = 'Bangladesh'
ORDER BY a.fiscal_year;
