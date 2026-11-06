-- =============================================================================
-- PROJECT  : NEA Nepal — PostgreSQL Database Setup
-- FILE     : 01_create_tables.sql
-- PURPOSE  : Create all tables for NEA annual energy dataset
-- DATABASE : nea_nepal
-- =============================================================================

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS nea_seasonal_data;
DROP TABLE IF EXISTS nea_country_trade;
DROP TABLE IF EXISTS nea_annual_data;

-- -----------------------------------------------------------------------------
-- TABLE 1: nea_annual_data
-- Main annual dataset — 1 row per fiscal year
-- -----------------------------------------------------------------------------
CREATE TABLE nea_annual_data (
    id                          SERIAL PRIMARY KEY,
    fiscal_year                 INTEGER NOT NULL UNIQUE,

    -- Energy Generation (GWh)
    nea_generation_gwh          NUMERIC(10,2),
    ipp_purchase_gwh            NUMERIC(10,2),
    total_production_gwh        NUMERIC(10,2),

    -- Import / Export (GWh)
    import_gwh                  NUMERIC(10,2),
    export_gwh                  NUMERIC(10,2),
    net_export_gwh              NUMERIC(10,2),
    total_available_gwh         NUMERIC(10,2),

    -- Consumption & Demand
    domestic_consumption_gwh    NUMERIC(10,2),
    peak_demand_mw              NUMERIC(10,2),
    peak_supply_mw              NUMERIC(10,2),

    -- Financial (Million NPR)
    revenue_npr_million         NUMERIC(12,2),
    cost_npr_million            NUMERIC(12,2),
    profit_npr_million          NUMERIC(12,2),
    profit_margin_pct           NUMERIC(6,2),

    -- Operational
    system_loss_pct             NUMERIC(6,2),
    consumers_million           NUMERIC(6,2),
    total_capacity_mw           NUMERIC(10,2),
    capacity_utilization_pct    NUMERIC(6,2),

    -- Metadata
    created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- TABLE 2: nea_seasonal_data
-- Seasonal breakdown — 4 seasons x 6 years = 24 rows
-- -----------------------------------------------------------------------------
CREATE TABLE nea_seasonal_data (
    id                          SERIAL PRIMARY KEY,
    fiscal_year                 INTEGER NOT NULL,
    season                      VARCHAR(20) NOT NULL,
    season_type                 VARCHAR(10),
    nepali_months               VARCHAR(50),
    gregorian_months            VARCHAR(50),

    -- Energy (GWh)
    production_gwh              NUMERIC(10,2),
    import_gwh                  NUMERIC(10,2),
    export_gwh                  NUMERIC(10,2),
    consumption_gwh             NUMERIC(10,2),
    net_export_gwh              NUMERIC(10,2),

    -- Derived
    import_dependency_pct       NUMERIC(6,2),
    export_utilization_pct      NUMERIC(6,2),
    estimation_type             VARCHAR(50),

    -- Foreign key to annual data
    FOREIGN KEY (fiscal_year)
        REFERENCES nea_annual_data(fiscal_year)
);

-- -----------------------------------------------------------------------------
-- TABLE 3: nea_country_trade
-- Cross border trade — 2 countries x 6 years = 12 rows
-- -----------------------------------------------------------------------------
CREATE TABLE nea_country_trade (
    id                          SERIAL PRIMARY KEY,
    fiscal_year                 INTEGER NOT NULL,
    country                     VARCHAR(50) NOT NULL,
    trade_status                VARCHAR(20),
    trade_partner               VARCHAR(100),
    trade_mechanism             VARCHAR(100),

    -- Energy (GWh)
    export_gwh                  NUMERIC(10,2),
    import_gwh                  NUMERIC(10,2),
    net_flow_gwh                NUMERIC(10,2),

    -- Financial
    export_revenue_npr_million  NUMERIC(12,2),
    import_cost_npr_million     NUMERIC(12,2),

    -- Capacity
    export_capacity_mw          NUMERIC(10,2),
    import_capacity_mw          NUMERIC(10,2),

    -- Details
    season_active               VARCHAR(50),
    notes                       TEXT,
    data_source                 VARCHAR(100),

    -- Foreign key
    FOREIGN KEY (fiscal_year)
        REFERENCES nea_annual_data(fiscal_year)
);

-- -----------------------------------------------------------------------------
-- VERIFY TABLES CREATED
-- -----------------------------------------------------------------------------
SELECT table_name, 
       (SELECT COUNT(*) 
        FROM information_schema.columns 
        WHERE table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;

-- =============================================================================
-- PROJECT  : NEA Nepal — Load Data
-- FILE     : 02_load_data.sql
-- PURPOSE  : Insert all verified NEA data into PostgreSQL tables
-- DATABASE : nea_nepal
-- RUN AFTER: 01_create_tables.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TABLE 1: INSERT ANNUAL DATA
-- 6 rows — one per fiscal year (2020 → 2025)
-- -----------------------------------------------------------------------------
INSERT INTO nea_annual_data (
    fiscal_year,
    nea_generation_gwh, ipp_purchase_gwh, total_production_gwh,
    import_gwh, export_gwh, net_export_gwh, total_available_gwh,
    domestic_consumption_gwh, peak_demand_mw, peak_supply_mw,
    revenue_npr_million, cost_npr_million, profit_npr_million,
    profit_margin_pct, system_loss_pct, consumers_million,
    total_capacity_mw, capacity_utilization_pct
)
VALUES
-- 2020 = FY 2019/20
(2020, 3021.06, 2991.00, 6012.06,
 1729.00, 107.00, -1622.00, 7741.06,
 6422.00, 1407.94, NULL,
 73760.00, 62704.00, 11056.00,
 14.99, 15.27, 4.22,
 5978.13, 23.55),

-- 2021 = FY 2020/21
(2021, 2810.74, 3241.00, 6051.74,
 2826.21, 44.00, -2782.21, 8877.95,
 7275.00, 1482.00, 1481.85,
 76726.00, 70718.00, 6008.00,
 7.83, 17.18, 5.08,
 NULL, NULL),

-- 2022 = FY 2021/22
(2022, 3259.00, 6262.00, 9521.00,
 1543.00, 493.00, -1050.00, 11064.00,
 8870.00, 1747.53, 1963.98,
 87120.00, 70955.00, 16165.00,
 18.56, 15.38, NULL,
 NULL, NULL),

-- 2023 = FY 2022/23
(2023, 2930.00, 7606.00, 10536.00,
 1833.00, 1346.00, -487.00, 12369.00,
 9358.00, 1870.46, 2171.15,
 100032.00, 87639.00, 12393.00,
 12.39, 13.46, 5.13,
 7758.00, 24.10),

-- 2024 = FY 2023/24
(2024, 2911.00, 9161.00, 12072.00,
 1895.00, 1946.00, 51.00, 13967.00,
 10243.00, 2211.62, 2467.00,
 115798.00, 102491.00, 13307.00,
 11.49, 12.73, 5.46,
 10301.00, 21.46),

-- 2025 = FY 2024/25
(2025, 2953.00, 11006.00, 13959.00,
 1681.00, 2380.00, 699.00, 15640.00,
 11343.00, 2409.00, 2901.00,
 125277.00, 116210.00, 9067.00,
 7.24, 12.26, 5.71,
 NULL, NULL);


-- -----------------------------------------------------------------------------
-- TABLE 2: INSERT SEASONAL DATA
-- 24 rows — 4 seasons x 6 years
-- -----------------------------------------------------------------------------
INSERT INTO nea_seasonal_data (
    fiscal_year, season, season_type,
    nepali_months, gregorian_months,
    production_gwh, import_gwh, export_gwh,
    consumption_gwh, net_export_gwh,
    import_dependency_pct, export_utilization_pct,
    estimation_type
)
VALUES
-- 2020 Seasons
(2020,'Monsoon','Wet','Shrawan - Aswin','July - September',3607.24,172.90,64.20,1926.60,-108.70,8.97,1.78,'ESTIMATED (NEA 60/40 split model)'),
(2020,'Post-Monsoon','Dry','Kartik - Mangsir','October - November',480.96,259.35,16.05,1155.96,-243.30,22.43,3.34,'ESTIMATED (NEA 60/40 split model)'),
(2020,'Winter','Dry','Poush - Falgun','December - February',1082.17,778.05,5.35,1926.60,-772.70,40.39,0.49,'ESTIMATED (NEA 60/40 split model)'),
(2020,'Pre-Monsoon','Dry','Chaitra - Ashadh','March - June',841.69,518.70,21.40,1412.84,-497.30,36.71,2.54,'ESTIMATED (NEA 60/40 split model)'),

-- 2021 Seasons
(2021,'Monsoon','Wet','Shrawan - Aswin','July - September',3631.04,282.62,26.40,2182.50,-256.22,12.95,0.73,'ESTIMATED (NEA 60/40 split model)'),
(2021,'Post-Monsoon','Dry','Kartik - Mangsir','October - November',484.14,423.93,6.60,1309.50,-417.33,32.37,1.36,'ESTIMATED (NEA 60/40 split model)'),
(2021,'Winter','Dry','Poush - Falgun','December - February',1089.31,1271.80,2.20,2182.50,-1269.60,58.27,0.20,'ESTIMATED (NEA 60/40 split model)'),
(2021,'Pre-Monsoon','Dry','Chaitra - Ashadh','March - June',847.24,847.86,8.80,1600.50,-839.06,52.97,1.04,'ESTIMATED (NEA 60/40 split model)'),

-- 2022 Seasons
(2022,'Monsoon','Wet','Shrawan - Aswin','July - September',5712.60,154.30,295.80,2661.00,141.50,5.80,5.18,'ESTIMATED (NEA 60/40 split model)'),
(2022,'Post-Monsoon','Dry','Kartik - Mangsir','October - November',761.68,231.45,73.95,1596.60,-157.50,14.50,9.71,'ESTIMATED (NEA 60/40 split model)'),
(2022,'Winter','Dry','Poush - Falgun','December - February',1713.78,694.35,24.65,2661.00,-669.70,26.10,1.44,'ESTIMATED (NEA 60/40 split model)'),
(2022,'Pre-Monsoon','Dry','Chaitra - Ashadh','March - June',1332.94,462.90,98.60,1951.40,-364.30,23.72,7.40,'ESTIMATED (NEA 60/40 split model)'),

-- 2023 Seasons
(2023,'Monsoon','Wet','Shrawan - Aswin','July - September',6321.60,183.30,807.60,2807.40,624.30,6.53,12.78,'ESTIMATED (NEA 60/40 split model)'),
(2023,'Post-Monsoon','Dry','Kartik - Mangsir','October - November',842.88,274.95,201.90,1684.44,-73.05,16.32,23.96,'ESTIMATED (NEA 60/40 split model)'),
(2023,'Winter','Dry','Poush - Falgun','December - February',1896.48,824.85,67.30,2807.40,-757.55,29.38,3.55,'ESTIMATED (NEA 60/40 split model)'),
(2023,'Pre-Monsoon','Dry','Chaitra - Ashadh','March - June',1474.04,549.90,269.20,2058.76,-280.70,26.71,18.26,'ESTIMATED (NEA 60/40 split model)'),

-- 2024 Seasons
(2024,'Monsoon','Wet','Shrawan - Aswin','July - September',7243.20,189.50,1167.60,3072.90,978.10,6.17,16.12,'ESTIMATED (NEA 60/40 split model)'),
(2024,'Post-Monsoon','Dry','Kartik - Mangsir','October - November',965.76,284.25,291.90,1843.74,7.65,15.42,30.22,'ESTIMATED (NEA 60/40 split model)'),
(2024,'Winter','Dry','Poush - Falgun','December - February',2172.96,852.75,97.30,3072.90,-755.45,27.75,4.48,'ESTIMATED (NEA 60/40 split model)'),
(2024,'Pre-Monsoon','Dry','Chaitra - Ashadh','March - June',1689.08,568.50,389.20,2253.46,-179.30,25.23,23.04,'ESTIMATED (NEA 60/40 split model)'),

-- 2025 Seasons
(2025,'Monsoon','Wet','Shrawan - Aswin','July - September',8375.40,168.10,1428.00,3402.90,1259.90,4.94,17.05,'ESTIMATED (NEA 60/40 split model)'),
(2025,'Post-Monsoon','Dry','Kartik - Mangsir','October - November',1116.72,252.15,357.00,2041.74,104.85,12.35,31.97,'ESTIMATED (NEA 60/40 split model)'),
(2025,'Winter','Dry','Poush - Falgun','December - February',2512.62,756.45,119.00,3402.90,-637.45,22.23,4.74,'ESTIMATED (NEA 60/40 split model)'),
(2025,'Pre-Monsoon','Dry','Chaitra - Ashadh','March - June',1954.26,504.30,476.00,2495.46,-28.30,20.21,24.36,'ESTIMATED (NEA 60/40 split model)');


-- -----------------------------------------------------------------------------
-- TABLE 3: INSERT COUNTRY TRADE DATA
-- 12 rows — 2 countries x 6 years
-- -----------------------------------------------------------------------------
INSERT INTO nea_country_trade (
    fiscal_year, country, trade_status,
    trade_partner, trade_mechanism,
    export_gwh, import_gwh, net_flow_gwh,
    export_revenue_npr_million, import_cost_npr_million,
    export_capacity_mw, import_capacity_mw,
    season_active, notes, data_source
)
VALUES
-- INDIA
(2020,'India','Active','NVVN / PGCIL','Power Exchange / Bilateral',107.00,1729.00,-1622.00,NULL,NULL,NULL,NULL,'Year Round','Import via Dhalkebar-Muzaffarpur 400kV. Nepal net importer.','NEA Annual Report 2019/20'),
(2021,'India','Active','NVVN / PGCIL','Power Exchange / Bilateral',44.00,2826.21,-2782.21,NULL,NULL,NULL,NULL,'Year Round','High import due to delay in Upper Tamakoshi. COVID impact.','NEA Annual Report 2020/21'),
(2022,'India','Active','NVVN / PGCIL / IEX','Power Exchange / Day-Ahead Market',493.00,1543.00,-1050.00,NULL,NULL,452.00,NULL,'Year Round','First country in South Asia to join Indian Energy Exchange.','NEA Annual Report 2021/22'),
(2023,'India','Active','NVVN / PGCIL / IEX / PTC India','PEC / Day-Ahead / Medium Term',1346.00,1833.00,-487.00,NULL,NULL,NULL,NULL,'Year Round','200 MW to Haryana May 2023. PTC India 300 MW June 2023.','NEA Annual Report 2022/23'),
(2024,'India','Active','NVVN / PGCIL / IEX / PTC India','PEC / Day-Ahead / Medium Term',1946.00,1895.00,51.00,NULL,NULL,NULL,NULL,'Year Round','Nepal became NET EXPORTER for first time in history.','NEA Annual Report 2023/24'),
(2025,'India','Active','NVVN / PGCIL / IEX / NTPC','PEC / Day-Ahead / Medium Term',2380.00,1681.00,699.00,17471.00,NULL,NULL,NULL,'Year Round','Export revenue NRs 17,471 million. Export up 22%.','NEA Annual Report 2024/25'),

-- BANGLADESH
(2020,'Bangladesh','No Trade',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No trade. Discussions at study stage only.','NEA Annual Report 2019/20'),
(2021,'Bangladesh','No Trade',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No trade. COVID impacted cross-border discussions.','NEA Annual Report 2020/21'),
(2022,'Bangladesh','No Trade','BPDB (planned)','Tripartite (planned)',NULL,NULL,NULL,NULL,NULL,40.00,NULL,NULL,'40 MW export planned via Indian grid.','NEA Annual Report 2021/22'),
(2023,'Bangladesh','Planned','BPDB / NVVN','Tripartite Agreement (finalizing)',NULL,NULL,NULL,NULL,NULL,40.00,NULL,'Monsoon (planned)','Tripartite agreement in final stage. 40 MW via HVDC link.','NEA Annual Report 2022/23'),
(2024,'Bangladesh','Planned','BPDB / NVVN','Tripartite Agreement (signing soon)',NULL,NULL,NULL,NULL,NULL,40.00,NULL,'Monsoon (planned)','Agreement to be signed soon. Sunkoshi III JV agreed.','NEA Annual Report 2023/24'),
(2025,'Bangladesh','Active','BPDB / NVVN / India','Tripartite Agreement',NULL,NULL,NULL,NULL,NULL,40.00,NULL,'Monsoon only (June 15 - Oct 2025)','FIRST EVER export to Bangladesh. 40 MW from June 15 2025.','NEA Annual Report 2024/25');


-- -----------------------------------------------------------------------------
-- VERIFY ALL DATA LOADED
-- -----------------------------------------------------------------------------
SELECT 'nea_annual_data'  AS table_name, COUNT(*) AS rows FROM nea_annual_data
UNION ALL
SELECT 'nea_seasonal_data', COUNT(*) FROM nea_seasonal_data
UNION ALL
SELECT 'nea_country_trade', COUNT(*) FROM nea_country_trade;


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
