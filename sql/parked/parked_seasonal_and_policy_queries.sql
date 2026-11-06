-- =============================================================================
-- PARKED QUERIES (verbatim from the original 03_queries.sql). DO NOT RUN FOR ANALYSIS.
-- Q4, Q9-Q13, Q19 : rest on nea_seasonal_data, which was a fixed % allocation of
--                   annual totals (not observations). Replace with real monthly data.
-- Q31+            : policy-target projections built on PPA-signed capacity
--                   (not installed/available capacity); out of scope for the flood project.
-- =============================================================================

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