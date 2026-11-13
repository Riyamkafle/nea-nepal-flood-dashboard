BEGIN;
DO $$
BEGIN
  IF (SELECT count(*) FROM sources) <> 23 THEN RAISE EXCEPTION 'expected 23 sources before'; END IF;
  IF (SELECT count(*) FROM sources WHERE source_id IN ('SRC-015','SRC-023')) <> 2 THEN RAISE EXCEPTION 'SRC-015/SRC-023 not both present'; END IF;
  IF (SELECT count(*) FROM project_status_log WHERE source_id='SRC-023') + (SELECT count(*) FROM project_baseline WHERE source_id='SRC-023') + (SELECT count(*) FROM project_evacuation WHERE source_id='SRC-023') <> 0 THEN RAISE EXCEPTION 'SRC-023 is referenced'; END IF;
END $$;
UPDATE sources SET url = (SELECT url FROM sources WHERE source_id='SRC-023'), snapshot_date = DATE '2026-11-05' WHERE source_id='SRC-015';
DELETE FROM sources WHERE source_id='SRC-023';
DO $$
BEGIN
  IF (SELECT count(*) FROM sources) <> 22 THEN RAISE EXCEPTION 'expected 22 sources after'; END IF;
  IF (SELECT count(*) FROM sources WHERE source_type='Primary') <> 10 THEN RAISE EXCEPTION 'expected 10 Primary after'; END IF;
  IF EXISTS (SELECT 1 FROM sources WHERE source_id='SRC-023') THEN RAISE EXCEPTION 'SRC-023 still present'; END IF;
  IF (SELECT url FROM sources WHERE source_id='SRC-015') NOT LIKE 'https://ndrrma.gov.np/mediafiles/rasuwa/%' THEN RAISE EXCEPTION 'SRC-015 url wrong'; END IF;
  IF (SELECT snapshot_date FROM sources WHERE source_id='SRC-015') <> DATE '2026-11-05' THEN RAISE EXCEPTION 'SRC-015 snapshot wrong'; END IF;
  IF (SELECT publisher FROM sources WHERE source_id='SRC-015') <> 'NDRRMA and National Planning Commission (Nepal)' THEN RAISE EXCEPTION 'publisher changed'; END IF;
END $$;
COMMIT;
