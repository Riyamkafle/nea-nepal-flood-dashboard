-- FILE    : 06_seed_baseline_owner.sql
-- PURPOSE : Add NEA Annual Report FY2025/26 as a source; set owners; add plant baselines.
-- SOURCE  : SRC-006 (Primary). Page numbers are the printed report page numbers.

INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date) VALUES
('SRC-006','NEA Annual Report 2025/26 (A Year in Review)','Nepal Electricity Authority','https://nea.org.np/uploads/shares/td_tender/A%20Year%20In%20Review%20Annual%20Report%202025_2026_compressed.pdf','Primary','2026-08-18','2026-09-30');

-- Owners: the three NEA plants are in the Generation Directorate section (pp.16, 18, 19).
UPDATE projects SET owner_type = 'NEA' WHERE project_id IN ('PRJ-009','PRJ-010','PRJ-011');

-- Subsidiary group (p.5). Sanjen, Upper Sanjen and Rasuwagadhi are not named in the text:
-- identified because 111 + 42.5 + 14.8 + 102 (Madhya Bhotekoshi) = 270.3 MW exactly.
UPDATE projects
SET owner_type = 'NEA_subsidiary',
    notes = notes || ' Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name.'
WHERE project_id IN ('PRJ-001','PRJ-003','PRJ-004');

UPDATE projects
SET owner_type = 'NEA_subsidiary', capacity_mw = 22.1,
    notes = notes || ' SRC-006 p.5 gives 22.1 MW and names Chilime Hydropower Company as NEA''s first subsidiary; ministry list gave 22 MW.'
WHERE project_id = 'PRJ-007';

UPDATE projects
SET capacity_mw = 15,
    notes = notes || ' Installed 15 MW (3 x 5 MW) per SRC-006 p.19; ministry list said 14 MW, SRC-004 and Wikipedia 14.1 MW. The status log keeps the ministry figure in affected_mw.'
WHERE project_id = 'PRJ-011';

-- Baseline: FY2025/26 (fiscal_year = end year 2026). Earlier years come next from your own report dumps.
INSERT INTO project_baseline (project_id, fiscal_year, generation_gwh, source_id, notes) VALUES
('PRJ-009', 2026, 391.90, 'SRC-006', 'p.16: design 489.76 GWh; 80.02% of design; up 10.09% on previous year; 106.38% of target. Report mentions restoring gates after an earlier flash flood (undated; possibly EVT-001).'),
('PRJ-010', 2026, 80.35,  'SRC-006', 'p.18: design 163 GWh; 49.29% of design; down 17.76% on previous year; 72.61% of target. Report lists repairs to a landslide-damaged bypass canal and flood deposit clearance: this year may already be affected by earlier events.'),
('PRJ-011', 2026, 59.53,  'SRC-006', 'p.19: design 114 GWh; 52.22% of design; down 22.04% on previous year; 98.75% of target.');

-- Checks
SELECT project_id, project_name, capacity_mw, owner_type FROM projects ORDER BY project_id;

SELECT SUM(affected_mw) AS ministry_list_affected_mw
FROM project_status_log WHERE source_id = 'SRC-001';

SELECT p.project_name, p.capacity_mw, b.generation_gwh,
       ROUND(b.generation_gwh / (p.capacity_mw * 8.76) * 100, 1) AS implied_capacity_factor_pct
FROM project_baseline b JOIN projects p USING (project_id)
ORDER BY p.project_name;
