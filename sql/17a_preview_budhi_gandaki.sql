-- 17a_preview_budhi_gandaki.sql : READ ONLY. Changes nothing.
\echo '=== 1. Current maxima ==='
SELECT (SELECT max(project_id) FROM projects) AS max_project,
       (SELECT max(event_id) FROM events) AS max_event,
       (SELECT max(source_id) FROM sources) AS max_source,
       (SELECT count(*) FROM project_status_log) AS status_rows;

\echo '=== 2. Proposed event + duplicate check ==='
SELECT 'EVT-004' AS event_id, DATE '2026-10-11' AS event_date,
       EXISTS (SELECT 1 FROM events WHERE event_id = 'EVT-004' OR event_date = DATE '2026-10-11') AS already_present;

\echo '=== 3. Proposed sources + duplicate check ==='
SELECT p.source_id, p.url,
       EXISTS (SELECT 1 FROM sources s WHERE s.source_id = p.source_id OR s.url = p.url OR s.title LIKE p.title_key) AS already_present
FROM (VALUES
 ('SRC-016','https://peoplesreview.com.np/2026/10/11/budhigandaki-flood-damages-four-hydropower-projects-totalling-412-41-mw/','Budhigandaki flood damages four%'),
 ('SRC-017','https://english.clickmandu.com/2026/10/12009/','Budhigandaki floods wreak havoc%'),
 ('SRC-018','https://kathmandupost.com/gandaki-province/2026/10/11/what-we-know-so-far-about-the-damage-caused-by-budhi-gandaki-floods','What we know so far about the damage%')
) AS p(source_id, url, title_key) ORDER BY 1;

\echo '=== 4. Proposed projects + duplicate check ==='
SELECT t.*, CASE WHEN t.id_used OR t.possible_duplicate IS NOT NULL THEN 'WILL SKIP - CHECK' ELSE 'WILL INSERT' END AS action
FROM (
  SELECT pr.project_id, pr.project_name, pr.capacity_mw,
         EXISTS (SELECT 1 FROM projects p WHERE p.project_id = pr.project_id) AS id_used,
         (SELECT string_agg(p.project_id || ' ' || p.project_name, '; ') FROM projects p
           WHERE p.project_name ~* pr.dup_regex
              OR (p.asset_type = 'hydro' AND p.capacity_mw = pr.capacity_mw)) AS possible_duplicate
  FROM (VALUES
   ('PRJ-019','Budhi Gandaki HEP (Times Energy)',341.00,'budhi|times'),
   ('PRJ-020','Dobhan Khola HEP',24.50,'dobhan|dovan'),
   ('PRJ-021','Yaru Khola HEP',30.59,'yaru'),
   ('PRJ-022','Machhe Khola HEP',16.00,'machh')
  ) AS pr(project_id, project_name, capacity_mw, dup_regex)
) t ORDER BY 1;

\echo '=== 5. Proposed status rows (affected_mw = DoED licensed capacity) ==='
SELECT v.project_id, v.affected_mw, 'damaged' AS physical_condition, 'unknown' AS generation_status, 'No' AS verified
FROM (VALUES ('PRJ-019',341.00),('PRJ-020',24.50),('PRJ-021',30.59),('PRJ-022',16.00)) AS v(project_id, affected_mw) ORDER BY 1;

\echo '=== 6. Sum checks ==='
SELECT 341.00 + 24.50 + 30.59 + 16.00  AS doed_sum,
       341.00 + 24.50 + 30.91 + 16.00  AS if_yaru_30_91,
       341.00 + 24.50 + 30.542 + 16.00 AS if_yaru_30_542,
       412.41 AS press_total_peoples_review;
