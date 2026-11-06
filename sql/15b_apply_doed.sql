-- 15b_apply_doed.sql : DO NOT RUN until 15a output has been reviewed.
-- Nothing here confirms the RDNA project list. Notes carry [UNVERIFIED].
\set ON_ERROR_STOP on
BEGIN;

-- A. Sources (skipped if id, title or url already present)
INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date)
SELECT v.source_id, v.title, v.publisher, v.url, v.source_type, v.source_date, v.snapshot_date
FROM (VALUES
 ('SRC-012','DoED Power Plants: Hydro (More than 1MW), operating list, page updated 2 Oct 2026 - read via web fetch, unverified','Department of Electricity Development (DoED)','https://doed.gov.np/pages/powerplantsmorethan1/','Primary',DATE '2026-10-02',DATE '2026-10-13'),
 ('SRC-013','DoED Power Plants: Solar, operating list, page updated 2 Oct 2026 - read via web fetch, unverified','Department of Electricity Development (DoED)','https://doed.gov.np/pages/powerplantssolar/','Primary',DATE '2026-10-02',DATE '2026-10-13'),
 ('SRC-014','DoED Construction Licence: Hydro (More than 1MW), page updated 2 Oct 2026 - read via web fetch to row 201 only, unverified','Department of Electricity Development (DoED)','https://doed.gov.np/pages/clhydromorethan1/','Primary',DATE '2026-10-02',DATE '2026-10-13'),
 ('SRC-015','Rapid Damage and Needs Assessment (RDNA), Rasuwa-Bhotekoshi Flood 2026, cut-off 3 Sep 2026','NDRRMA and National Planning Commission (Nepal)',NULL,'Primary',NULL,DATE '2026-10-13')
) AS v(source_id, title, publisher, url, source_type, source_date, snapshot_date)
WHERE NOT EXISTS (SELECT 1 FROM sources s
                   WHERE s.source_id = v.source_id OR s.title = v.title
                      OR (v.url IS NOT NULL AND s.url = v.url));

-- B. New projects (skipped if id, name pattern or same-capacity hydro already present)
INSERT INTO projects (project_id, project_name, asset_type, capacity_mw, basin, district,
                      commissioned_date, pre_flood_phase, owner_type, notes)
SELECT v.project_id, v.project_name, 'hydro', v.capacity_mw, NULL, v.district,
       v.commissioned_date, v.pre_flood_phase, v.owner_type, v.notes
FROM (VALUES
 ('PRJ-013','Upper Trishuli-1',216.00,'Rasuwa',NULL,'under_construction','IPP','^upper[ -]*trishuli[ -]*(1|i)$',
  '[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 209, issued BS 2074-07-23, Nepal Water & Energy Development Co. P. Ltd, Dhunche/Haku (Rasuwa), 216.000 MW. Named as affected in press (SRC-004). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only; the RDNA names no projects. No damage state, status date, restoration date or unavailable MW recorded.'),
 ('PRJ-014','Rasuwa Bhotekoshi',120.00,'Rasuwa',NULL,'under_construction','IPP','rasuwa[ -]*bhote',
  '[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 223, issued BS 2074-11-03, Langtang Bhotekosi Hydropower Company Pvt. Ltd, Thuman/Briddhim/Goljung (Rasuwa), 120.000 MW. Named as affected in press (SRC-004). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. No damage state or restoration data recorded.'),
 ('PRJ-015','Super Trishuli',100.00,NULL,NULL,'under_construction','IPP','super[ -]*trishuli',
  '[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 218, issued BS 2074-10-02, Blue Energy Ltd., 100.000 MW. DoED prints no district, so district is NULL. Not named in SRC-001 to SRC-004; listed as under construction in a myRepublica article whose text says July 11 (date unclear; article not in sources table). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. Affected status NOT established.'),
 ('PRJ-016','Upper Trishuli 3B',37.00,'Nuwakot',NULL,'under_construction','NEA','^upper[ -]*trishuli[ -]*3b$',
  '[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 104, issued BS 2070-04-27, promoter Nepal Electricity Authority, Manakamana (Nuwakot), 37.000 MW. Named as affected in press (SRC-004). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. No damage state or restoration data recorded.'),
 ('PRJ-017','Middle Trishuli Ganga',15.63,'Nuwakot',NULL,'under_construction','IPP','trishuli[ -]*ganga',
  '[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 379, issued BS 2079-05-17, Perfect Energy Development Pvt. Ltd, Gerkhu/Manakamana/Tupche (Nuwakot). Exact capacity 15.625 MW (DoED; NEA list SRC-006 PDF p.197); stored as 15.63 because capacity_mw is numeric(10,2). Named as affected in press (SRC-004, which prints 15.5). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. No damage state or restoration data recorded.'),
 ('PRJ-018','Upper Tadi',11.00,'Nuwakot',DATE '2025-07-28','operating','IPP','upper[ -]*tadi',
  '[UNVERIFIED][DoED review 2026-10-13] Operating per DoED operating list (SRC-012): licence 144, Surya Kund Hydro Electric Pvt. Ltd, Rautbesi (Nuwakot), 11.000 MW, COD BS 2082-04-12. NEA list (SRC-006 PDF p.192) shows the same capacity and COD BS 2082.04.12; AD date 2025-07-28 is an approximate conversion by script 09. Not named in any press list reviewed and not in either arithmetic set. NOT classified as damaged or as excluded from the RDNA; membership unknown.')
) AS v(project_id, project_name, capacity_mw, district, commissioned_date, pre_flood_phase, owner_type, dup_regex, notes)
WHERE NOT EXISTS (SELECT 1 FROM projects p
                   WHERE p.project_id = v.project_id
                      OR p.project_name ~* v.dup_regex
                      OR (p.asset_type = 'hydro' AND p.capacity_mw = v.capacity_mw));

-- C. PRJ-006 Langtang Khola: phase change (old value kept in note)
UPDATE projects
SET pre_flood_phase = 'under_construction',
    notes = COALESCE(NULLIF(notes,'') || ' ', '') ||
      '[DoED review 2026-10-13] PHASE CHANGE operating -> under_construction (supersedes the earlier line saying operating was left unchanged). Old value came from the 27 Aug energy-ministry list (SRC-001), which did not state phase. New basis: DoED construction-licence list (SRC-014): licence 142, Langtang Khola Small Hydropower Project, Multi Energy Development Pvt. Ltd, 20.000 MW, Syafru (Rasuwa); not on DoED operating list (SRC-012); NEA list (SRC-006 PDF p.198) also under construction, no COD. Press (SRC-004) says testing phase: UNVERIFIED, kept as a separate claim, not evidence of operation. RDNA Table 34 sums are consistent with this but do not name the project.'
WHERE project_id = 'PRJ-006'
  AND pre_flood_phase = 'operating'
  AND (notes IS NULL OR notes NOT LIKE '%[DoED review 2026-10-13]%');

-- D. Note-only updates (no value is overwritten)
UPDATE projects p
SET notes = COALESCE(NULLIF(p.notes,'') || ' ', '') || v.note
FROM (VALUES
 ('PRJ-012','[DoED review 2026-10-13] POSSIBLE identity, NOT confirmed: DoED solar list (SRC-013) shows five NEA solar farms in Nuwakot: Block 1 5.1 MW, Block 2 8.3 MW, Block 4 1.37 MW, Grid Tied Solar Farm 3.09 MW, Block 5 6.5 MW (Charghare/Bidur), COD BS 2079-10-01. Total 24.36 MW = RDNA Table 34 solar (SRC-015: 5 plants, 24.36 MW). This record (25 MW, owner unknown) may be those five combined (press: 25 MW Nuwakot Solar Power Project, SRC-004). Record kept as is; not split or replaced. The NEA PPA appendix CSV lists no Nuwakot solar, consistent with NEA ownership (my inference).'),
 ('PRJ-007','[DoED review 2026-10-13] DoED operating list (SRC-012, licence 6): Chilime 22.000 MW, COD BS 2065-05-07. NEA list (SRC-006 PDF p.188): 22,100 kW, COD BS 2060.05.08. Stored 22.10 and 2003-08-25 kept; conflict logged. Proposed capacity correction to 22.00 NOT applied.'),
 ('PRJ-011','[DoED review 2026-10-13] DoED operating list (SRC-012, licence 1_gtd): Devighat 14.100 MW, NEA, Nuwakot, COD BS 2041-08-16. Stored 15.00 and NEA report p.177 (15.1) kept; status log holds 14.00 (press). Proposed correction to 14.10 NOT applied.'),
 ('PRJ-009','[DoED review 2026-10-13] DoED operating list (SRC-012, licence 43): Upper Trishuli 3A 60.000 MW, NEA, locality printed as Dandagoun, Laharepouwa, Thulogoun, Ramche (Rasuwa), COD BS 2076-05-13. Stored district Nuwakot kept (press); conflict logged. commissioned_date left NULL.')
) AS v(project_id, note)
WHERE p.project_id = v.project_id
  AND (p.notes IS NULL OR p.notes NOT LIKE '%[DoED review 2026-10-13]%');

-- E. Proposed capacity corrections: NOT RUN. Existing values are kept.
-- UPDATE projects SET capacity_mw = 22.00 WHERE project_id = 'PRJ-007';
-- UPDATE projects SET capacity_mw = 14.10 WHERE project_id = 'PRJ-011';

COMMIT;

\echo '=== VALIDATION (read only) ==='
\echo 'Expected: projects 18, sources 15, no status-log rows for PRJ-013 and above'
SELECT (SELECT count(*) FROM projects) AS projects_total,
       (SELECT count(*) FROM sources)  AS sources_total,
       (SELECT count(*) FROM project_status_log WHERE project_id >= 'PRJ-013') AS new_status_rows;
SELECT pre_flood_phase, count(*) AS n, SUM(capacity_mw) AS mw FROM projects GROUP BY 1 ORDER BY 1;
SELECT source_id, left(title,70) AS title, source_type, source_date, snapshot_date
FROM sources WHERE source_id >= 'SRC-012' ORDER BY 1;
SELECT project_id, project_name, capacity_mw, district, commissioned_date, pre_flood_phase, owner_type,
       left(notes,50) AS notes_start
FROM projects WHERE project_id IN ('PRJ-006') OR project_id >= 'PRJ-013' ORDER BY 1;
\echo 'Six construction candidates (PRJ-006, 013 to 017), stored values. Expect 508.63 (15.625 rounded to 15.63)'
SELECT SUM(capacity_mw) AS stored_sum_mw FROM projects
WHERE project_id IN ('PRJ-006','PRJ-013','PRJ-014','PRJ-015','PRJ-016','PRJ-017');
\echo 'Seven operating candidates, stored values. Expect 251.40 (22.10 and 15.00 are 1.0 MW above DoED 22.0 and 14.1)'
SELECT SUM(capacity_mw) AS stored_sum_mw FROM projects
WHERE project_id IN ('PRJ-001','PRJ-005','PRJ-007','PRJ-008','PRJ-009','PRJ-010','PRJ-011');
