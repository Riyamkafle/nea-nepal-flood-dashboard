\set ON_ERROR_STOP on
BEGIN;
INSERT INTO sources (source_id, title, publisher, url, source_type, source_date, snapshot_date)
VALUES (
  'SRC-023',
  'Rapid Damage and Needs Assessment (RDNA), Rasuwa-Bhotekoshi Flood 2026 (NDRRMA, September 2026; sector cut-off 3 Sep 2026; estimates not independently verified)',
  'National Disaster Risk Reduction and Management Authority (NDRRMA)',
  'https://ndrrma.gov.np/mediafiles/rasuwa/Rapid_Damage_and_Needs_Assessment_RDNA_Rasuwa-Bhotekoshi_Flood_2026.pdf',
  'Primary', NULL, DATE '2026-11-05');
DO $$
BEGIN
  IF (SELECT count(*) FROM sources) <> 23 THEN RAISE EXCEPTION 'CHECK FAILED: sources count is not 23'; END IF;
  IF (SELECT count(*) FROM sources WHERE source_id <> 'SRC-023') <> 22 THEN RAISE EXCEPTION 'CHECK FAILED: old rows changed'; END IF;
  IF (SELECT count(*) FROM sources WHERE source_type = 'Primary') <> 11 THEN RAISE EXCEPTION 'CHECK FAILED: Primary count is not 11'; END IF;
  IF (SELECT count(*) FROM sources WHERE source_type = 'Secondary') <> 10 OR (SELECT count(*) FROM sources WHERE source_type = 'Tertiary') <> 2 THEN RAISE EXCEPTION 'CHECK FAILED: Secondary/Tertiary counts changed'; END IF;
  IF NOT EXISTS (SELECT 1 FROM sources WHERE source_id = 'SRC-023' AND source_type = 'Primary' AND source_date IS NULL AND snapshot_date = DATE '2026-11-05' AND publisher LIKE 'National Disaster Risk Reduction%') THEN RAISE EXCEPTION 'CHECK FAILED: SRC-023 values'; END IF;
END $$;
COMMIT;
\echo '--- after commit ---'
SELECT count(*) AS sources_total FROM sources;
SELECT source_type, count(*) FROM sources GROUP BY 1 ORDER BY 1;
SELECT source_id, source_type, source_date, snapshot_date, left(title,60) AS title FROM sources WHERE source_id = 'SRC-023';
