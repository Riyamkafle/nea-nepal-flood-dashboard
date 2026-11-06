-- =============================================================================
-- PROJECT  : NEA Nepal - baseline tables (national annual layer)
-- FILE     : 01_create_tables.sql
-- DATABASE : nea_nepal (PostgreSQL)
-- NOTES    : fiscal_year = Gregorian END year (2025 = FY 2024/25).
--            Values are loaded from data/cleaned + data/processed by
--            scripts/04_build_sql.py. Do not hand-edit 02_load_data.sql.
--            The seasonal table was REMOVED: its rows were a fixed percentage
--            allocation of annual totals, not observations (see docs/cleanup_log.md).
-- =============================================================================
DROP TABLE IF EXISTS nea_seasonal_data;   -- legacy table, intentionally not recreated
DROP TABLE IF EXISTS nea_country_trade;
DROP TABLE IF EXISTS nea_annual_data;

CREATE TABLE nea_annual_data (
    id                          SERIAL PRIMARY KEY,
    fiscal_year                 INTEGER NOT NULL UNIQUE,      -- end year
    fiscal_year_label           VARCHAR(10) NOT NULL,         -- e.g. 2024/25

    -- Energy (GWh)
    nea_generation_gwh          NUMERIC(10,2),
    ipp_purchase_gwh            NUMERIC(10,2),                -- author-constructed from FY2021/22 (IPP + NEA subsidiaries)
    total_production_gwh        NUMERIC(10,2),                -- DERIVED
    import_gwh                  NUMERIC(10,2),
    export_gwh                  NUMERIC(10,2),
    net_export_gwh              NUMERIC(10,2),                -- DERIVED = export - import
    total_available_gwh         NUMERIC(10,2),                -- DERIVED = production + import
    domestic_consumption_gwh    NUMERIC(10,2),

    -- Power (MW)
    peak_demand_mw              NUMERIC(10,2),
    peak_supply_mw              NUMERIC(10,2),
    ppa_signed_capacity_mw      NUMERIC(10,2),                -- combined capacity of SIGNED PPAs incl. projects not yet built. NOT installed or available capacity.

    -- Financial (million NPR) - NEA company level, NOT export revenue
    nea_revenue_npr_million     NUMERIC(12,2),
    nea_cost_npr_million        NUMERIC(12,2),                -- DERIVED = revenue - profit
    nea_profit_npr_million      NUMERIC(12,2),                -- profit before tax
    nea_profit_margin_pct       NUMERIC(6,2),                 -- DERIVED

    -- Operational
    system_loss_pct             NUMERIC(6,2),
    consumers_million           NUMERIC(6,2),

    source_report               VARCHAR(100),
    created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE nea_country_trade (
    id                          SERIAL PRIMARY KEY,
    fiscal_year                 INTEGER NOT NULL,
    country                     VARCHAR(50) NOT NULL,
    trade_status                VARCHAR(20),
    trade_partner               VARCHAR(100),
    trade_mechanism             VARCHAR(100),

    export_gwh                  NUMERIC(10,2),
    import_gwh                  NUMERIC(10,2),
    export_revenue_npr_million  NUMERIC(12,2),
    import_cost_npr_million     NUMERIC(12,2),
    export_capacity_mw          NUMERIC(10,2),                -- approved/planned capacity, NOT actual flow
    import_capacity_mw          NUMERIC(10,2),
    season_active               VARCHAR(50),
    volume_scope                VARCHAR(60),                  -- India rows currently hold the NATIONAL total (all destinations)
    notes                       TEXT,
    data_source                 VARCHAR(100),
    FOREIGN KEY (fiscal_year) REFERENCES nea_annual_data(fiscal_year)
);
