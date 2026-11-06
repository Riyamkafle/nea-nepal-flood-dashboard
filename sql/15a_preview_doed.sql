-- 15a_preview_doed.sql : READ ONLY. Changes nothing.
\echo '=== 1. Existing projects (reference) ==='
SELECT project_id, project_name, capacity_mw, district, commissioned_date, pre_flood_phase, owner_type
FROM projects ORDER BY 1;

\echo '=== 2. Proposed NEW projects + duplicate check ==='
WITH prop(project_id, project_name, capacity_mw, district, pre_flood_phase, owner_type, dup_regex) AS (VALUES
 ('PRJ-013','Upper Trishuli-1',216.00,'Rasuwa','under_construction','IPP','^upper[ -]*trishuli[ -]*(1|i)$'),
 ('PRJ-014','Rasuwa Bhotekoshi',120.00,'Rasuwa','under_construction','IPP','rasuwa[ -]*bhote'),
 ('PRJ-015','Super Trishuli',100.00,NULL,'under_construction','IPP','super[ -]*trishuli'),
 ('PRJ-016','Upper Trishuli 3B',37.00,'Nuwakot','under_construction','NEA','^upper[ -]*trishuli[ -]*3b$'),
 ('PRJ-017','Middle Trishuli Ganga',15.63,'Nuwakot','under_construction','IPP','trishuli[ -]*ganga'),
 ('PRJ-018','Upper Tadi',11.00,'Nuwakot','operating','IPP','upper[ -]*tadi')
)
SELECT t.*,
       CASE WHEN t.id_already_used OR t.possible_duplicate IS NOT NULL
            THEN 'WILL SKIP - CHECK' ELSE 'WILL INSERT' END AS action
FROM (
  SELECT pr.project_id, pr.project_name, pr.capacity_mw, pr.district, pr.pre_flood_phase, pr.owner_type,
         EXISTS (SELECT 1 FROM projects p WHERE p.project_id = pr.project_id) AS id_already_used,
         (SELECT string_agg(p.project_id || ' ' || p.project_name, '; ')
            FROM projects p
           WHERE p.project_name ~* pr.dup_regex
              OR (p.asset_type = 'hydro' AND p.capacity_mw = pr.capacity_mw)) AS possible_duplicate
  FROM prop pr
) t ORDER BY 1;

\echo '=== 3. Proposed NEW sources ==='
WITH prop(source_id, title, url) AS (VALUES
 ('SRC-012','DoED Power Plants: Hydro (More than 1MW), operating list, page updated 2 Oct 2026 - read via web fetch, unverified','https://doed.gov.np/pages/powerplantsmorethan1/'),
 ('SRC-013','DoED Power Plants: Solar, operating list, page updated 2 Oct 2026 - read via web fetch, unverified','https://doed.gov.np/pages/powerplantssolar/'),
 ('SRC-014','DoED Construction Licence: Hydro (More than 1MW), page updated 2 Oct 2026 - read via web fetch to row 201 only, unverified','https://doed.gov.np/pages/clhydromorethan1/'),
 ('SRC-015','Rapid Damage and Needs Assessment (RDNA), Rasuwa-Bhotekoshi Flood 2026, cut-off 3 Sep 2026',NULL)
) 
SELECT p.source_id, p.title, p.url,
       EXISTS (SELECT 1 FROM sources s WHERE s.source_id = p.source_id OR s.title = p.title
               OR (p.url IS NOT NULL AND s.url = p.url)) AS already_present
FROM (SELECT source_id, title, url, NULL::boolean AS already_present FROM prop) p ORDER BY 1;

\echo '=== 4. Proposed changes to EXISTING projects ==='
SELECT p.project_id, p.project_name, p.capacity_mw AS current_capacity_mw,
       p.pre_flood_phase AS current_phase, p.district AS current_district,
       CASE p.project_id
         WHEN 'PRJ-006' THEN 'CHANGE pre_flood_phase operating -> under_construction (+ note, old value kept in note)'
         WHEN 'PRJ-007' THEN 'NOTE ONLY: DoED capacity 22.0 vs stored 22.10; DoED COD BS 2065-05-07 vs NEA list BS 2060.05.08. capacity_mw unchanged'
         WHEN 'PRJ-011' THEN 'NOTE ONLY: DoED capacity 14.1 vs stored 15.00. capacity_mw unchanged'
         WHEN 'PRJ-009' THEN 'NOTE ONLY: DoED locality says Rasuwa; stored Nuwakot kept'
         WHEN 'PRJ-012' THEN 'NOTE ONLY: may be five NEA solar farms = 24.36 MW; record not split or replaced'
       END AS proposed_change,
       (p.notes LIKE '%[DoED review 2026-10-13]%') AS already_applied
FROM projects p
WHERE p.project_id IN ('PRJ-006','PRJ-007','PRJ-009','PRJ-011','PRJ-012')
ORDER BY 1;

\echo '=== 5. Arithmetic checks (literal DoED values vs RDNA Table 34) ==='
SELECT 'operating hydro, 7 DoED capacities' AS check_name, SUM(mw) AS sum_mw, 250.400 AS rdna_mw
  FROM (VALUES (111.000),(60.000),(24.000),(22.000),(14.300),(14.100),(5.000)) t(mw)
UNION ALL
SELECT 'construction hydro, 6 DoED capacities', SUM(mw), 508.625
  FROM (VALUES (216.000),(120.000),(100.000),(37.000),(20.000),(15.625)) t(mw)
UNION ALL
SELECT 'solar, 5 NEA Nuwakot farms', SUM(mw), 24.360
  FROM (VALUES (5.100),(8.300),(1.370),(3.090),(6.500)) t(mw);

\echo '=== 6. Same 7 operating projects using STORED database capacities ==='
SELECT SUM(capacity_mw) AS stored_sum_mw, 250.400 AS rdna_mw,
       SUM(capacity_mw) - 250.400 AS difference
FROM projects
WHERE project_id IN ('PRJ-001','PRJ-005','PRJ-007','PRJ-008','PRJ-009','PRJ-010','PRJ-011');
