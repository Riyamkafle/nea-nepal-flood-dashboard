-- =============================================================================
-- PROJECT  : NEA Nepal — Business Problem Queries
-- FILE     : 03_queries.sql
-- PURPOSE  : Answer 8 core business problems using SQL
-- DATABASE : nea_nepal
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUERY 1: Is Nepal energy self-sufficient or still dependent on India?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    export_gwh,
    import_gwh,
    net_export_gwh,
    CASE
        WHEN net_export_gwh > 0 THEN 'NET EXPORTER'
        ELSE 'NET IMPORTER'
    END AS energy_status
FROM nea_annual_data
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 2: What is the true cost of Nepal's system loss problem?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    system_loss_pct,
    total_production_gwh,
    ROUND(total_production_gwh * (system_loss_pct / 100), 2)
        AS estimated_lost_gwh,
    ROUND(revenue_npr_million * (system_loss_pct / 100), 2)
        AS estimated_revenue_lost_mnpr
FROM nea_annual_data
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 3: How fast is IPP growing vs NEA own generation?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    nea_generation_gwh,
    ipp_purchase_gwh,
    total_production_gwh,
    ROUND(nea_generation_gwh * 100.0 / total_production_gwh, 1)
        AS nea_share_pct,
    ROUND(ipp_purchase_gwh * 100.0 / total_production_gwh, 1)
        AS ipp_share_pct
FROM nea_annual_data
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 4: Which season drives Nepal's import dependency?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    season,
    season_type,
    import_gwh,
    export_gwh,
    net_export_gwh,
    import_dependency_pct
FROM nea_seasonal_data
ORDER BY fiscal_year, import_dependency_pct DESC;


-- -----------------------------------------------------------------------------
-- QUERY 5: Is NEA becoming more profitable as exports grow?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    export_gwh,
    revenue_npr_million,
    profit_npr_million,
    profit_margin_pct,
    profit_npr_million - LAG(profit_npr_million)
        OVER (ORDER BY fiscal_year) AS yoy_profit_change_mnpr
FROM nea_annual_data
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 6: How fast is Nepal electrifying its population?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    consumers_million,
    domestic_consumption_gwh,
    ROUND(domestic_consumption_gwh / consumers_million, 2)
        AS gwh_per_million_consumers,
    ROUND((consumers_million - LAG(consumers_million)
        OVER (ORDER BY fiscal_year)) * 100.0 /
        LAG(consumers_million) OVER (ORDER BY fiscal_year), 1)
        AS consumer_growth_pct
FROM nea_annual_data
WHERE consumers_million IS NOT NULL
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 7: Can Nepal's grid handle peak demand without importing?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    peak_demand_mw,
    peak_supply_mw,
    peak_supply_mw - peak_demand_mw AS supply_buffer_mw,
    CASE
        WHEN peak_supply_mw >= peak_demand_mw THEN 'Supply Adequate'
        WHEN peak_supply_mw IS NULL THEN 'Data Not Available'
        ELSE 'Supply Deficit'
    END AS grid_status,
    total_capacity_mw,
    capacity_utilization_pct
FROM nea_annual_data
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 8: Nepal cross border electricity trade trend with India
-- -----------------------------------------------------------------------------
SELECT
    a.fiscal_year,
    a.export_gwh          AS total_export_gwh,
    a.import_gwh          AS total_import_gwh,
    t.net_flow_gwh,
    t.export_revenue_npr_million,
    t.trade_status,
    t.trade_mechanism,
    ROUND(a.export_gwh * 100.0 /
        NULLIF(a.export_gwh + a.import_gwh, 0), 1)
        AS export_share_pct
FROM nea_annual_data a
JOIN nea_country_trade t
    ON a.fiscal_year = t.fiscal_year
WHERE t.country = 'India'
ORDER BY a.fiscal_year;


-- -----------------------------------------------------------------------------
-- BONUS: Full summary dashboard view
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    total_production_gwh,
    import_gwh,
    export_gwh,
    net_export_gwh,
    domestic_consumption_gwh,
    system_loss_pct,
    revenue_npr_million,
    profit_npr_million,
    profit_margin_pct,
    consumers_million,
    CASE
        WHEN net_export_gwh > 0 THEN 'NET EXPORTER'
        ELSE 'NET IMPORTER'
    END AS energy_status
FROM nea_annual_data
ORDER BY fiscal_year;

-- -----------------------------------------------------------------------------
-- QUERY 9: Seasonal production vs consumption gap
-- Which season has biggest energy deficit?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    season,
    season_type,
    production_gwh,
    consumption_gwh,
    ROUND(production_gwh - consumption_gwh, 2) AS prod_vs_cons_gap,
    CASE
        WHEN production_gwh > consumption_gwh THEN 'Surplus'
        ELSE 'Deficit'
    END AS seasonal_status
FROM nea_seasonal_data
ORDER BY fiscal_year, production_gwh DESC;


-- -----------------------------------------------------------------------------
-- QUERY 10: Which season exports the most? — Export pattern analysis
-- -----------------------------------------------------------------------------
SELECT
    season,
    season_type,
    ROUND(AVG(export_gwh), 2)             AS avg_export_gwh,
    ROUND(AVG(import_gwh), 2)             AS avg_import_gwh,
    ROUND(AVG(net_export_gwh), 2)         AS avg_net_export,
    ROUND(AVG(import_dependency_pct), 2)  AS avg_import_dependency_pct,
    ROUND(AVG(export_utilization_pct), 2) AS avg_export_utilization_pct
FROM nea_seasonal_data
GROUP BY season, season_type
ORDER BY avg_export_gwh DESC;


-- -----------------------------------------------------------------------------
-- QUERY 11: Monsoon vs Dry season — head to head comparison
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    MAX(CASE WHEN season = 'Monsoon'
        THEN production_gwh END)      AS monsoon_production,
    MAX(CASE WHEN season = 'Winter'
        THEN production_gwh END)      AS winter_production,
    MAX(CASE WHEN season = 'Monsoon'
        THEN import_gwh END)          AS monsoon_import,
    MAX(CASE WHEN season = 'Winter'
        THEN import_gwh END)          AS winter_import,
    MAX(CASE WHEN season = 'Monsoon'
        THEN import_dependency_pct END) AS monsoon_import_dep_pct,
    MAX(CASE WHEN season = 'Winter'
        THEN import_dependency_pct END) AS winter_import_dep_pct
FROM nea_seasonal_data
GROUP BY fiscal_year
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 12: Seasonal energy balance trend — is Nepal improving?
-- Are we exporting more in monsoon every year?
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    season,
    export_gwh,
    import_gwh,
    net_export_gwh,
    import_dependency_pct,
    ROUND(export_gwh - LAG(export_gwh)
        OVER (PARTITION BY season ORDER BY fiscal_year), 2)
        AS export_growth_gwh,
    ROUND(import_gwh - LAG(import_gwh)
        OVER (PARTITION BY season ORDER BY fiscal_year), 2)
        AS import_change_gwh
FROM nea_seasonal_data
ORDER BY season, fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 13: Peak demand vs seasonal production
-- Can Nepal meet peak demand from its own seasonal generation?
-- -----------------------------------------------------------------------------
SELECT
    s.fiscal_year,
    s.season,
    s.production_gwh,
    a.peak_demand_mw,
    ROUND(s.production_gwh / 3, 2)    AS avg_monthly_production_gwh,
    ROUND(a.peak_demand_mw * 720 / 1000, 2) AS monthly_demand_gwh,
    CASE
        WHEN s.production_gwh / 3 > a.peak_demand_mw * 720 / 1000
        THEN 'Self Sufficient'
        ELSE 'Needs Import'
    END AS seasonal_sufficiency
FROM nea_seasonal_data s
JOIN nea_annual_data a ON s.fiscal_year = a.fiscal_year
ORDER BY s.fiscal_year, s.season;

-- -----------------------------------------------------------------------------
-- QUERY 14: Nepal electricity trade status by country — all years
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    country,
    trade_status,
    export_gwh,
    import_gwh,
    net_flow_gwh,
    export_revenue_npr_million,
    export_capacity_mw,
    season_active
FROM nea_country_trade
ORDER BY fiscal_year, country;


-- -----------------------------------------------------------------------------
-- QUERY 15: India trade balance trend — Nepal's journey
-- from heavy importer to net exporter
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    export_gwh,
    import_gwh,
    net_flow_gwh,
    export_revenue_npr_million,
    trade_mechanism,
    CASE
        WHEN net_flow_gwh > 0 THEN 'NET EXPORTER'
        WHEN net_flow_gwh < 0 THEN 'NET IMPORTER'
        ELSE 'Balanced'
    END AS trade_position,
    ROUND(export_gwh - LAG(export_gwh)
        OVER (ORDER BY fiscal_year), 2) AS export_growth_gwh,
    ROUND(import_gwh - LAG(import_gwh)
        OVER (ORDER BY fiscal_year), 2) AS import_change_gwh
FROM nea_country_trade
WHERE country = 'India'
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 16: Bangladesh trade progression — from no trade to active
-- -----------------------------------------------------------------------------
SELECT
    fiscal_year,
    country,
    trade_status,
    export_capacity_mw,
    season_active,
    notes
FROM nea_country_trade
WHERE country = 'Bangladesh'
ORDER BY fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 17: Total cross border trade value analysis
-- How much revenue did Nepal earn from exports?
-- -----------------------------------------------------------------------------
SELECT
    a.fiscal_year,
    SUM(t.export_gwh)                    AS total_export_gwh,
    SUM(t.import_gwh)                    AS total_import_gwh,
    SUM(t.net_flow_gwh)                  AS total_net_flow,
    SUM(t.export_revenue_npr_million)    AS total_export_revenue_mnpr,
    COUNT(DISTINCT t.country)            AS trade_partner_count,
    STRING_AGG(DISTINCT t.country, ', ') AS trade_partners
FROM nea_country_trade t
JOIN nea_annual_data a ON t.fiscal_year = a.fiscal_year
WHERE t.trade_status IN ('Active', 'Planned')
GROUP BY a.fiscal_year
ORDER BY a.fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 18: Export revenue vs total revenue — how important is export?
-- -----------------------------------------------------------------------------
SELECT
    a.fiscal_year,
    t.export_gwh,
    t.export_revenue_npr_million,
    a.revenue_npr_million          AS total_revenue_mnpr,
    ROUND(t.export_revenue_npr_million * 100.0 /
        NULLIF(a.revenue_npr_million, 0), 2)
        AS export_revenue_share_pct,
    t.trade_status,
    t.trade_mechanism
FROM nea_country_trade t
JOIN nea_annual_data a ON t.fiscal_year = a.fiscal_year
WHERE t.country = 'India'
ORDER BY a.fiscal_year;


-- -----------------------------------------------------------------------------
-- QUERY 19: Country trade vs seasonal pattern
-- Which season does Nepal export most to India?
-- -----------------------------------------------------------------------------
SELECT
    s.fiscal_year,
    s.season,
    s.season_type,
    s.export_gwh          AS seasonal_export_gwh,
    s.import_gwh          AS seasonal_import_gwh,
    s.net_export_gwh      AS seasonal_net_export,
    t.trade_status        AS india_trade_status,
    t.trade_mechanism
FROM nea_seasonal_data s
JOIN nea_country_trade t
    ON s.fiscal_year = t.fiscal_year
WHERE t.country = 'India'
ORDER BY s.fiscal_year, s.export_gwh DESC;


-- -----------------------------------------------------------------------------
-- QUERY 20: Complete cross border summary — the big picture
-- -----------------------------------------------------------------------------
SELECT
    a.fiscal_year,
    a.total_production_gwh,
    a.import_gwh,
    a.export_gwh,
    a.net_export_gwh,
    a.revenue_npr_million,
    ind.export_revenue_npr_million  AS india_export_revenue_mnpr,
    ind.trade_status                AS india_trade_status,
    ban.trade_status                AS bangladesh_trade_status,
    CASE
        WHEN a.net_export_gwh > 0 THEN 'Energy Surplus'
        ELSE 'Energy Deficit'
    END AS national_energy_status
FROM nea_annual_data a
LEFT JOIN nea_country_trade ind
    ON a.fiscal_year = ind.fiscal_year
    AND ind.country = 'India'
LEFT JOIN nea_country_trade ban
    ON a.fiscal_year = ban.fiscal_year
    AND ban.country = 'Bangladesh'
ORDER BY a.fiscal_year;

-- =============================================================================
-- POLITICAL TARGET ANALYSIS QUERIES
-- =============================================================================

-- QUERY 31: Capacity growth rate — can Nepal hit targets?
SELECT
    fiscal_year,
    total_capacity_mw,
    total_capacity_mw - LAG(total_capacity_mw)
        OVER (ORDER BY fiscal_year) AS capacity_added_mw,
    ROUND((total_capacity_mw - LAG(total_capacity_mw)
        OVER (ORDER BY fiscal_year)) * 100.0 /
        NULLIF(LAG(total_capacity_mw)
        OVER (ORDER BY fiscal_year), 0), 1) AS growth_rate_pct,
    11000 - total_capacity_mw AS gap_to_govt_target_mw,
    15000 - total_capacity_mw AS gap_to_political_target_mw
FROM nea_annual_data
WHERE total_capacity_mw IS NOT NULL
ORDER BY fiscal_year;


-- QUERY 32: Is Nepal on track for 11,000 MW by 2030?
WITH growth AS (
    SELECT
        AVG(total_capacity_mw - LAG(total_capacity_mw)
            OVER (ORDER BY fiscal_year)) AS avg_annual_growth_mw
    FROM nea_annual_data
    WHERE total_capacity_mw IS NOT NULL
)
SELECT
    2024                          AS last_known_year,
    10301                         AS current_capacity_mw,
    ROUND(avg_annual_growth_mw,0) AS avg_growth_per_year_mw,
    ROUND(10301 + avg_annual_growth_mw * 6, 0)
                                  AS projected_2030_mw,
    11000                         AS govt_target_mw,
    15000                         AS political_target_mw,
    CASE
        WHEN 10301 + avg_annual_growth_mw * 6 >= 15000
        THEN '✅ Political target achievable'
        WHEN 10301 + avg_annual_growth_mw * 6 >= 11000
        THEN '✅ Govt target achievable'
        ELSE '❌ Targets at risk'
    END AS verdict
FROM growth;


-- QUERY 33: Production capacity vs consumption gap
-- Can Nepal absorb 15,000 MW domestically?
SELECT
    fiscal_year,
    total_capacity_mw,
    domestic_consumption_gwh,
    ROUND(total_capacity_mw * 8760 / 1000, 0)
        AS max_possible_generation_gwh,
    ROUND(total_capacity_mw * 8760 / 1000 -
        domestic_consumption_gwh, 0)
        AS surplus_for_export_gwh,
    ROUND((domestic_consumption_gwh /
        NULLIF(total_capacity_mw * 8760 / 1000, 0)) * 100, 1)
        AS domestic_absorption_pct,
    CASE
        WHEN domestic_consumption_gwh /
            NULLIF(total_capacity_mw * 8760 / 1000, 0) < 0.3
        THEN 'CRITICAL: Must export 70%+ of generation'
        WHEN domestic_consumption_gwh /
            NULLIF(total_capacity_mw * 8760 / 1000, 0) < 0.5
        THEN 'WARNING: Must export 50%+ of generation'
        ELSE 'OK: Domestic demand absorbing well'
    END AS market_risk
FROM nea_annual_data
WHERE total_capacity_mw IS NOT NULL
ORDER BY fiscal_year;


-- QUERY 34: The core political question
-- What revenue would 15,000 MW generate for Nepal?
SELECT
    'Current 2024'           AS scenario,
    10301                    AS capacity_mw,
    115798                   AS revenue_mnpr,
    13307                    AS profit_mnpr,
    11.49                    AS profit_margin_pct
UNION ALL
SELECT
    'Govt Target 11,000 MW',
    11000,
    ROUND(115798 * 11000.0 / 10301, 0),
    ROUND(13307 * 11000.0 / 10301, 0),
    11.49
UNION ALL
SELECT
    'Political Target 15,000 MW',
    15000,
    ROUND(115798 * 15000.0 / 10301, 0),
    ROUND(13307 * 15000.0 / 10301, 0),
    11.49;