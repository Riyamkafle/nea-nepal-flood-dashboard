BEGIN;
UPDATE projects p
SET notes = CASE WHEN p.notes IS NULL OR p.notes = '' THEN '' ELSE p.notes || ' ' END || v.note
FROM (VALUES
 ('PRJ-001', 'NEA list check (SRC-006 appendix PDF p.188): Rasuwagadhi Hydropower Company Ltd., 111,000 kW, PPA BS 2068.07.28, COD BS 2081.09.16 = 2024-12-31. Matches stored capacity and date.'),
 ('PRJ-002', 'NEA list check (SRC-006 appendix PDF p.191): project name in list is Sanjen Khola, developer Salasungi Power Limited, 78,000 kW, COD BS 2081.10.29 = 2025-02-11. Matches stored capacity and date.'),
 ('PRJ-003', 'NEA list check (SRC-006 appendix PDF p.188): Upper Sanjen, 14,800 kW, COD BS 2080.06.21 = 2023-10-08. Matches. Status log affected_mw 14.80 for PRJ-008 is NOT this plant.'),
 ('PRJ-004', 'NEA list check (SRC-006 appendix PDF p.188): Sanjen, 42,500 kW, COD BS 2081.09.01 = 2024-12-16. Matches stored capacity and date.'),
 ('PRJ-005', 'NEA list check (SRC-006 appendix PDF p.189): Mailung Khola, 5,000 kW, COD BS 2071.03.19 = 2014-07-03. Matches stored capacity and date.'),
 ('PRJ-006', 'CONFLICT, NEA list check (SRC-006 appendix PDF p.198): Langtang Khola, Multi Energy Development Pvt. Ltd., 20,000 kW, PPA BS 2072.09.29, listed under CONSTRUCTION with no COD. pre_flood_phase left as operating until RDNA Table 34 is checked.'),
 ('PRJ-007', 'NEA list check (SRC-006 appendix PDF p.188): Chilime, 22,100 kW, COD BS 2060.05.08 = 2003-08-25. Matches stored capacity and date. Status log has 22.00 MW.'),
 ('PRJ-008', 'NEA list check (SRC-006 appendix PDF p.191): printed as Upper Mailun, 14,300 kW, COD BS 2080.10.28 = 2024-02-11. Matches stored capacity and date. Status log 14.80 MW is not from the NEA list.')
) AS v(project_id, note)
WHERE p.project_id = v.project_id
  AND (p.notes IS NULL OR p.notes NOT LIKE '%NEA list check (SRC-006%');
COMMIT;
