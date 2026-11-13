BEGIN READ ONLY;
\echo '--- 1. both rows'
select source_id, source_type, publisher, url, source_date, snapshot_date, title from sources where source_id in ('SRC-015','SRC-023') order by 1;
\echo '--- 2. identical titles?'
select (select title from sources where source_id='SRC-015') = (select title from sources where source_id='SRC-023') as same_title;
\echo '--- 3. rows linked to SRC-023 (expect 0 each)'
select 'status_log' t, count(*) from project_status_log where source_id='SRC-023'
union all select 'baseline', count(*) from project_baseline where source_id='SRC-023'
union all select 'evacuation', count(*) from project_evacuation where source_id='SRC-023';
\echo '--- 4. sources now (expect 23 and 11)'
select count(*) total, count(*) filter (where source_type='Primary') primary_n from sources;
\echo '--- 5. sources after merge (expect 22 and 10)'
select count(*) total, count(*) filter (where source_type='Primary') primary_n from sources where source_id<>'SRC-023';
\echo '--- 6. proposed SRC-015 values'
select 'SRC-015' source_id, (select publisher from sources where source_id='SRC-015') publisher_kept, (select url from sources where source_id='SRC-023') new_url, date '2026-11-05' new_snapshot;
ROLLBACK;
