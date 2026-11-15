BEGIN;
DO $$
BEGIN
  IF (SELECT count(*) FROM events WHERE event_id='EVT-002') <> 1 THEN RAISE EXCEPTION 'EVT-002 not exactly one row'; END IF;
  IF (SELECT description FROM events WHERE event_id='EVT-002') <> 'Bhotekoshi/Trishuli flash flood from Tibet: hydropower, solar and transmission damage' THEN RAISE EXCEPTION 'description is not the expected old text'; END IF;
  IF (SELECT notes FROM events WHERE event_id='EVT-002') <> 'Date per SRC-004 (Bhadra 10 = 26 Aug 2026).' THEN RAISE EXCEPTION 'notes is not the expected old text'; END IF;
END $$;
DO $$
DECLARE n integer;
BEGIN
  UPDATE events SET
    description = 'Bhotekoshi/Trishuli debris-laden flood after an avalanche: hydropower, solar and transmission damage',
    notes = 'Date per SRC-004 (Bhadra 10 = 26 Aug 2026). [UNVERIFIED] Trigger wording: RDNA (SRC-015, PDF pp.6 and 11) states an ice-and-rock avalanche in the upper Lhende Khola watershed, about 20 km upstream of Rasuwagadhi, generated a debris flow. SRC-001 (27 Aug 2026) reports NDRRMA assessing a sudden release of an avalanche-blocked river in Tibet. The earlier wording "flash flood from Tibet" was incomplete. Whether the origin was inside Tibet is not established here. Not registered as a conflict.'
  WHERE event_id='EVT-002';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 row updated, got %', n; END IF;
  IF (SELECT event_date FROM events WHERE event_id='EVT-002') <> DATE '2026-08-26' THEN RAISE EXCEPTION 'event_date changed'; END IF;
  IF (SELECT location FROM events WHERE event_id='EVT-002') <> 'Rasuwa and Nuwakot districts' THEN RAISE EXCEPTION 'location changed'; END IF;
  IF (SELECT notes FROM events WHERE event_id='EVT-002') NOT LIKE 'Date per SRC-004 (Bhadra 10 = 26 Aug 2026). [UNVERIFIED]%' THEN RAISE EXCEPTION 'notes do not start as expected'; END IF;
  IF (SELECT count(*) FROM events) <> 4 THEN RAISE EXCEPTION 'event count changed'; END IF;
  IF (SELECT count(*) FROM events WHERE (coalesce(notes,'') || coalesce(description,'')) ~* 'UNVERIFIED|NOT VERIFIED') <> 3 THEN RAISE EXCEPTION 'expected 3 events marked unverified'; END IF;
END $$;
COMMIT;
