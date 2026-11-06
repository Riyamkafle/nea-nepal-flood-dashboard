-- FILE    : 05_seed_flood_layer.sql
-- PURPOSE : First seed of the project layer (sources, events, projects, status log).
-- RULE    : Every row is verified = 'No' (secondary/tertiary sources only).
--           Unknown stays unknown. snapshot_date = 2026-09-30.

INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date) VALUES
('SRC-001','Massive flood in Bhotekoshi and Trishuli puts 900 MW of power projects at risk','myRepublica','https://myrepublica.nagariknetwork.com/news/floods-in-the-bhotekoshi-and-trishuli-put-900-mw-of-power-projects-in-risk-17-10.html','Secondary','2026-08-27','2026-09-30'),
('SRC-002','BHOTEKOSHI FLOOD: Blow To Hydropower Sector','Spotlight Nepal','https://www.spotlightnepal.com/2026/09/07/bhotekoshi-flood-blow-hydropower-sector/','Secondary','2026-09-07','2026-09-30'),
('SRC-003','Bhotekoshi floods halt Nepal''s electricity exports to Bangladesh','The Kathmandu Post','https://kathmandupost.com/money/2026/09/02/bhotekoshi-floods-halt-nepal-s-electricity-exports-to-bangladesh','Secondary','2026-09-02','2026-09-30'),
('SRC-004','Floods in Bhotekoshi Damage 12 Hydropower Projects','Spotlight Nepal','https://www.spotlightnepal.com/2026/09/01/floods-bhotekoshi-damage-12-hydropower-projects/','Secondary','2026-09-01','2026-09-30'),
('SRC-005','List of power stations in Nepal','Wikipedia','https://en.wikipedia.org/wiki/List_of_power_stations_in_Nepal','Tertiary',NULL,'2026-09-30');

INSERT INTO events (event_id, event_date, description, location, notes) VALUES
('EVT-001','2025-07-08','Lende River flood from Tibet merged with the Bhotekoshi (previous-year event)','Rasuwa','Damaged Rasuwagadhi area infrastructure. Possible baseline contamination: Rasuwagadhi had only recently resumed full operation before EVT-002 (SRC-001).'),
('EVT-002','2026-08-26','Bhotekoshi/Trishuli flash flood from Tibet: hydropower, solar and transmission damage','Rasuwa and Nuwakot districts','Date per SRC-004 (Bhadra 10 = 26 Aug 2026).'),
('EVT-003','2026-09-28','Kaligandaki corridor transmission disruption (landslides)','Kaligandaki corridor','NOT VERIFIED: reported by Kathmandu Post on 28 Sep; article not opened. Separate event from EVT-002: never add MW across events.');

INSERT INTO projects (project_id, project_name, asset_type, capacity_mw, district, pre_flood_phase, owner_type, notes) VALUES
('PRJ-001','Rasuwagadhi','hydro',111,'Rasuwa','operating','unknown','Ministry list (SRC-001). Wikipedia list (SRC-005): commissioned 2024. Recently back at full operation after EVT-001.'),
('PRJ-002','Salasungi Sanjen','hydro',78,'Rasuwa','operating','unknown','Ministry list (SRC-001).'),
('PRJ-003','Upper Sanjen','hydro',14.8,'Rasuwa','operating','unknown','Ministry list (SRC-001).'),
('PRJ-004','Sanjen','hydro',42.5,'Rasuwa','operating','unknown','Ministry list (SRC-001).'),
('PRJ-005','Mailung Khola','hydro',5,'Rasuwa','operating','unknown','Ministry list (SRC-001).'),
('PRJ-006','Langtang Khola','hydro',20,'Rasuwa','operating','IPP','Ministry list (SRC-001). Described as private in SRC-002.'),
('PRJ-007','Chilime','hydro',22,'Rasuwa','operating','unknown','Ministry list 22 MW. Kathmandu Post 2 Sep gives 22.1 MW (SRC-003).'),
('PRJ-008','Upper Mailung','hydro',14.8,NULL,'unknown','unknown','CONFLICT: the ministry list (SRC-001) shows it among the 12 operational projects (14.8 MW) AND among the 15 under-construction projects. Wikipedia list (SRC-005) gives 14.3 MW, commissioned 2024. Phase left unknown.'),
('PRJ-009','Upper Trishuli 3A','hydro',60,'Nuwakot','operating','unknown','Ministry list (SRC-001) says Nuwakot; Wikipedia list (SRC-005) says Rasuwa. District unresolved.'),
('PRJ-010','Trishuli','hydro',24,'Nuwakot','operating','unknown','Ministry list (SRC-001). Wikipedia list: commissioned 1967.'),
('PRJ-011','Devighat','hydro',14,'Nuwakot','operating','unknown','Ministry list 14 MW; SRC-004 gives 14.1 MW.'),
('PRJ-012','Saurya solar (name unconfirmed)','solar',25,'Nuwakot','operating','unknown','Ministry list gives only a 25 MW solar project in Nuwakot (SRC-001). SRC-004 names Saurya (25 MW): identification inferred, unverified.');

-- Row set 1: what the 27 Aug ministry list says (all 12 projects). Statuses stay unknown.
INSERT INTO project_status_log (project_id, event_id, status_date, affected_mw, mw_definition, source_id, verified, snapshot_date, notes)
SELECT project_id, 'EVT-002', '2026-08-27', capacity_mw,
       'Ministry list: operational project affected. Installed MW, NOT unavailable MW',
       'SRC-001', 'No', '2026-09-30',
       'List does not say what state each project is in, so all four status columns are unknown.'
FROM projects;

-- Row set 2: five projects that SRC-002 describes as completely destroyed.
INSERT INTO project_status_log (project_id, event_id, status_date, physical_condition, source_id, verified, snapshot_date, notes)
SELECT project_id, 'EVT-002', '2026-09-07', 'destroyed', 'SRC-002', 'No', '2026-09-30',
       'Single secondary source describes this project as completely destroyed; SRC-004 (1 Sep) uses the word damaged for the same group.'
FROM projects
WHERE project_name IN ('Rasuwagadhi','Chilime','Langtang Khola','Upper Trishuli 3A','Trishuli');

-- Row set 3: three projects reported to be in isolated mode because of damaged transmission lines.
INSERT INTO project_status_log (project_id, event_id, status_date, evacuation_status, source_id, verified, snapshot_date, notes)
SELECT project_id, 'EVT-002', '2026-09-02', 'blocked', 'SRC-003', 'No', '2026-09-30',
       'Kept in isolated mode because transmission lines were damaged (SRC-003). blocked = not delivering to the national grid. SRC-004 (1 Sep) says isolated operation was still being prepared. Generation status not stated.'
FROM projects
WHERE project_name IN ('Salasungi Sanjen','Upper Sanjen','Sanjen');

-- Checks
SELECT 'sources' AS tbl, COUNT(*) AS n FROM sources
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'project_status_log', COUNT(*) FROM project_status_log;

SELECT SUM(capacity_mw) FILTER (WHERE asset_type = 'hydro') AS hydro_mw,
       SUM(capacity_mw) AS hydro_plus_solar_mw
FROM projects;
