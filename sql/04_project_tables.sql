-- FILE    : 04_project_tables.sql
-- PURPOSE : Project-level before/after layer (empty schema; seeded in step 3)
-- NOTE    : Four separate status columns. Unknown is a valid value: never guess.
DROP TABLE IF EXISTS project_status_log;
DROP TABLE IF EXISTS project_evacuation;
DROP TABLE IF EXISTS project_baseline;
DROP TABLE IF EXISTS transmission_assets;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS sources;

CREATE TABLE sources (
    source_id     VARCHAR(20) PRIMARY KEY,
    title         TEXT NOT NULL,
    publisher     VARCHAR(100),
    url           TEXT,
    source_type   VARCHAR(10) NOT NULL CHECK (source_type IN ('Primary','Secondary','Tertiary')),
    source_date   DATE,
    snapshot_date DATE
);

CREATE TABLE events (
    event_id      VARCHAR(20) PRIMARY KEY,
    event_date    DATE NOT NULL,
    description   TEXT NOT NULL,
    location      VARCHAR(200),
    notes         TEXT
);

CREATE TABLE projects (
    project_id        VARCHAR(20) PRIMARY KEY,
    project_name      VARCHAR(150) NOT NULL,
    asset_type        VARCHAR(20) NOT NULL CHECK (asset_type IN ('hydro','solar','other')),
    capacity_mw       NUMERIC(10,2),
    basin             VARCHAR(100),
    district          VARCHAR(100),
    commissioned_date DATE,
    pre_flood_phase   VARCHAR(20) NOT NULL DEFAULT 'unknown'
                      CHECK (pre_flood_phase IN ('operating','under_construction','unknown')),
    owner_type        VARCHAR(20) CHECK (owner_type IN ('NEA','NEA_subsidiary','IPP','unknown')),
    notes             TEXT
);

CREATE TABLE transmission_assets (
    asset_id      VARCHAR(20) PRIMARY KEY,
    asset_name    VARCHAR(150) NOT NULL,
    asset_type    VARCHAR(20) NOT NULL CHECK (asset_type IN ('line','substation','other')),
    voltage_kv    NUMERIC(6,1),
    capacity_mw   NUMERIC(10,2),
    notes         TEXT
);

CREATE TABLE project_evacuation (
    project_id    VARCHAR(20) NOT NULL REFERENCES projects(project_id),
    asset_id      VARCHAR(20) NOT NULL REFERENCES transmission_assets(asset_id),
    source_id     VARCHAR(20) REFERENCES sources(source_id),
    notes         TEXT,
    PRIMARY KEY (project_id, asset_id)
);

CREATE TABLE project_baseline (
    project_id     VARCHAR(20) NOT NULL REFERENCES projects(project_id),
    fiscal_year    INTEGER NOT NULL,
    generation_gwh NUMERIC(10,2),
    source_id      VARCHAR(20) REFERENCES sources(source_id),
    notes          TEXT,
    PRIMARY KEY (project_id, fiscal_year)
);

CREATE TABLE project_status_log (
    log_id              SERIAL PRIMARY KEY,
    project_id          VARCHAR(20) NOT NULL REFERENCES projects(project_id),
    event_id            VARCHAR(20) NOT NULL REFERENCES events(event_id),
    status_date         DATE NOT NULL,
    physical_condition  VARCHAR(20) NOT NULL DEFAULT 'unknown'
        CHECK (physical_condition IN ('undamaged','damaged','destroyed','unknown')),
    generation_status   VARCHAR(20) NOT NULL DEFAULT 'unknown'
        CHECK (generation_status IN ('operating','partial','offline','unknown')),
    evacuation_status   VARCHAR(20) NOT NULL DEFAULT 'unknown'
        CHECK (evacuation_status IN ('delivering','constrained','blocked','unknown')),
    restoration_status  VARCHAR(20) NOT NULL DEFAULT 'unknown'
        CHECK (restoration_status IN ('not_started','under_restoration','restored','unknown')),
    affected_mw         NUMERIC(10,2),
    available_mw        NUMERIC(10,2),
    mw_definition       TEXT,
    source_id           VARCHAR(20) REFERENCES sources(source_id),
    verified            VARCHAR(20) NOT NULL DEFAULT 'No'
        CHECK (verified IN ('Yes','No','Partially verified')),
    snapshot_date       DATE,
    notes               TEXT
);
