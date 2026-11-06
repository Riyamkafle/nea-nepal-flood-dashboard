-- 17b_apply_budhi_gandaki.sql : DO NOT RUN until 17a output has been reviewed.
\set ON_ERROR_STOP on
BEGIN;

-- A. Sources (skipped if id, url or title already present)
INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date)
SELECT v.source_id, v.title, v.publisher, v.url, v.source_type, v.source_date, v.snapshot_date
FROM (VALUES
 ('SRC-016','Budhigandaki flood damages four hydropower projects totalling 412.41 MW (Peoples Review, 11 Oct 2026) - read as search excerpt only, unverified','Peoples Review','https://peoplesreview.com.np/2026/10/11/budhigandaki-flood-damages-four-hydropower-projects-totalling-412-41-mw/','Secondary',DATE '2026-10-11',DATE '2026-10-13'),
 ('SRC-017','Budhigandaki floods wreak havoc on 4 under-construction hydropower projects totalling 413 MW (Clickmandu, October 2026) - page fetched, unverified','Clickmandu','https://english.clickmandu.com/2026/10/12009/','Secondary',NULL::date,DATE '2026-10-13'),
 ('SRC-018','What we know so far about the damage caused by Budhi Gandaki floods (Kathmandu Post, 11 Oct 2026) - read as search excerpt only, unverified','The Kathmandu Post','https://kathmandupost.com/gandaki-province/2026/10/11/what-we-know-so-far-about-the-damage-caused-by-budhi-gandaki-floods','Secondary',DATE '2026-10-11',DATE '2026-10-13')
) AS v(source_id, title, publisher, url, source_type, source_date, snapshot_date)
WHERE NOT EXISTS (SELECT 1 FROM sources s WHERE s.source_id = v.source_id OR s.title = v.title OR s.url = v.url);

-- B. Event EVT-004 (separate from EVT-002 and EVT-003)
INSERT INTO events (event_id, event_date, description, location, notes)
SELECT 'EVT-004', DATE '2026-10-11',
       'Budhi Gandaki River flash flood: damage reported at four under-construction hydropower projects',
       'Gorkha district (Budhi Gandaki)',
       '[UNVERIFIED] Preliminary press reports published 11-12 Oct 2026 (SRC-016, SRC-017, SRC-018); exact time not recorded. Cause not established: reports describe a suspected landslide dam and their locations differ. Separate event from EVT-002 (Bhotekoshi/Trishuli, 26 Aug 2026) and EVT-003 (Kaligandaki corridor, 28 Sep 2026): never add their damage together. All four projects named were under construction, so no operating generation is recorded as lost by this event; no operating plant is named in the reports read (inference: operating plants were not assessed). Other projects carry the Budhigandaki name (DoED licences 414, 425 and 426, and the proposed 1,200 MW storage project); they are different projects.'
WHERE NOT EXISTS (SELECT 1 FROM events WHERE event_id = 'EVT-004' OR event_date = DATE '2026-10-11');

-- C. Projects (skipped if id, name pattern or same-capacity hydro exists)
INSERT INTO projects (project_id, project_name, asset_type, capacity_mw, basin, district,
                      commissioned_date, pre_flood_phase, owner_type, notes)
SELECT v.project_id, v.project_name, 'hydro', v.capacity_mw, NULL, 'Gorkha',
       NULL::date, 'under_construction', 'IPP', v.notes
FROM (VALUES
 ('PRJ-019','Budhi Gandaki HEP (Times Energy)',341.00,'budhi|times',
  '[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 420, issued BS 2080-09-05, Times Energy Ltd., Kerauja, Sirdibas, Uiya (Gorkha), 341.000 MW, river Budhi Gandaki. Press (SRC-017): main camp and machinery swept away. Not found in the NEA appendix by name search for budhi (only different projects: Naulo Nepal Ka and Kha, and Super Machha Khola 4.6 MW). NOT the 1,200 MW storage project, NOT Naulo Nepal Ka (DoED licence 426, 130 MW) or Kha (licence 425, 260 MW), NOT Super Machha Khola (licence 414). owner_type IPP is inferred from the promoter name.'),
 ('PRJ-020','Dobhan Khola HEP',24.50,'dobhan|dovan',
  '[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 429, issued BS 2080-12-05, Dobhan Khola Hydropower Ltd, Kerauja (Gorkha), 24.500 MW. NEA appendix (SRC-006 PDF p.198) lists Dovan khola, developer Upper Syange Hydropower Limited, 24,500 kW, PPA BS 2080.03.07, under construction: developer name differs, same capacity and district (likely the same project, my inference). Press (SRC-017): camp buildings and a Bailey bridge damaged. Different from Junbeshi 5.2 MW (Dobhan Hydropower, Solukhumbu).'),
 ('PRJ-021','Yaru Khola HEP',30.59,'yaru',
  '[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 435, issued BS 2080-12-25, Yaru Hydropower Pvt. Ltd, Kerauja, Sirdibas, Uiya (Gorkha), 30.590 MW (stored value). CAPACITY CONFLICT: NEA appendix (SRC-006 PDF p.198) 30,542 kW, PPA BS 2079.12.17; Peoples Review (SRC-016) 30.91 MW. Press (SRC-017): Bailey bridge and materials damaged.'),
 ('PRJ-022','Machhe Khola HEP',16.00,'machh',
  '[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 428, issued BS 2080-11-04, Water Energy Development Pvt. Ltd., Lapu, Gumda, Uiya (Gorkha), 16.000 MW. NEA appendix (SRC-006 PDF p.198) lists Machha Khola, 16,000 kW, PPA BS 2080.03.04, under construction. Press (SRC-017): access road and bridge damaged. Different from Upper Machha Khola Small 4.55 MW (operating) and Super Machha Khola 4.6 MW.')
) AS v(project_id, project_name, capacity_mw, dup_regex, notes)
WHERE NOT EXISTS (SELECT 1 FROM projects p
                   WHERE p.project_id = v.project_id
                      OR p.project_name ~* v.dup_regex
                      OR (p.asset_type = 'hydro' AND p.capacity_mw = v.capacity_mw));

-- D. Status rows: press-stated damage only. No generation, outage or restoration data.
INSERT INTO project_status_log (project_id, event_id, status_date, physical_condition, generation_status,
       evacuation_status, restoration_status, affected_mw, available_mw, mw_definition, source_id,
       verified, snapshot_date, notes)
SELECT v.project_id, 'EVT-004', DATE '2026-10-11', 'damaged', 'unknown', 'unknown', 'unknown',
       v.affected_mw, NULL::numeric,
       'Licensed capacity (DoED) of an under-construction project named as damaged in preliminary press reports. Not generation lost, not available capacity.',
       'SRC-017', 'No', DATE '2026-10-13', v.note
FROM (VALUES
 ('PRJ-019',341.00,'Press: main camp and machinery swept away. Condition of the dam and other main works not stated. Under construction: no pre-event generation.'),
 ('PRJ-020',24.50,'Press: camp buildings and a Bailey bridge damaged. Condition of main works not stated. Under construction: no pre-event generation.'),
 ('PRJ-021',30.59,'Press: Bailey bridge and materials damaged. Capacity conflict recorded on the project. Under construction: no pre-event generation.'),
 ('PRJ-022',16.00,'Press: access road and bridge damaged. Condition of main works not stated. Under construction: no pre-event generation.')
) AS v(project_id, affected_mw, note)
WHERE EXISTS (SELECT 1 FROM projects p WHERE p.project_id = v.project_id)
  AND EXISTS (SELECT 1 FROM events e WHERE e.event_id = 'EVT-004')
  AND NOT EXISTS (SELECT 1 FROM project_status_log l
                   WHERE l.project_id = v.project_id AND l.event_id = 'EVT-004' AND l.status_date = DATE '2026-10-11');

COMMIT;

\echo '=== VALIDATION (read only) ==='
\echo 'Expected: projects 22, events 4, sources 18, status rows 24'
SELECT (SELECT count(*) FROM projects) AS projects_total,
       (SELECT count(*) FROM events) AS events_total,
       (SELECT count(*) FROM sources) AS sources_total,
       (SELECT count(*) FROM project_status_log) AS status_rows;
SELECT pre_flood_phase, count(*) AS n, SUM(capacity_mw) AS mw FROM projects GROUP BY 1 ORDER BY 1;
\echo 'Expected: EVT-004 affected_mw sum 412.09'
SELECT l.project_id, p.project_name, l.physical_condition, l.generation_status, l.affected_mw, l.verified
FROM project_status_log l JOIN projects p ON p.project_id = l.project_id
WHERE l.event_id = 'EVT-004' ORDER BY 1;
SELECT SUM(affected_mw) AS evt004_affected_mw FROM project_status_log WHERE event_id = 'EVT-004';
SELECT event_id, event_date, location FROM events ORDER BY 1;
