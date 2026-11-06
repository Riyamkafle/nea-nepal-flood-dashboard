\set ON_ERROR_STOP on
\echo '--- proposed SRC-023 row (READ-ONLY, nothing written) ---'
\x on
WITH p(source_id, title, publisher, url, source_type, source_date, snapshot_date) AS (
  VALUES (
    'SRC-023',
    'Rapid Damage and Needs Assessment (RDNA), Rasuwa-Bhotekoshi Flood 2026 (NDRRMA, September 2026; sector cut-off 3 Sep 2026; estimates not independently verified)',
    'National Disaster Risk Reduction and Management Authority (NDRRMA)',
    'https://ndrrma.gov.np/mediafiles/rasuwa/Rapid_Damage_and_Needs_Assessment_RDNA_Rasuwa-Bhotekoshi_Flood_2026.pdf',
    'Primary',
    NULL::date,
    DATE '2026-11-05'))
SELECT p.*,
       length(p.publisher) AS publisher_len,
       (p.source_type IN ('Primary','Secondary','Tertiary')) AS type_ok,
       NOT EXISTS (SELECT 1 FROM sources s WHERE s.source_id = p.source_id) AS id_free,
       NOT EXISTS (SELECT 1 FROM sources s WHERE s.url = p.url) AS url_not_used
FROM p;
\x off
\echo '--- sources count now (expect 22) ---'
SELECT count(*) FROM sources;
