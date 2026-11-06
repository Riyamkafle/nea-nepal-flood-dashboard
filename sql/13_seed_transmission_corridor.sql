BEGIN;
INSERT INTO transmission_assets (asset_id, asset_name, asset_type, voltage_kv, capacity_mw, notes) VALUES
('TA-001','Rasuwagadhi - Chilime Hub 132 kV line','line',132.0,NULL,'NEA FY2025/26 report PDF p.130 (SRC-006): 10.0 km, 132 kV, double circuit up to Chilime Hub (project key features). Not listed in the NEA grid line tables.'),
('TA-002','Chilime P/S - Trishuli P/S 66 kV line','line',66.0,NULL,'PDF p.209, section D (66 kV), row 1: single circuit, 39.00 circuit-km, conductor WOLF 150 sq.mm.'),
('TA-003','Trisuli P/S - Devighat P/S 66 kV line','line',66.0,NULL,'PDF p.209, section D (66 kV), row 3: single circuit, 4.56 circuit-km, WOLF 150.'),
('TA-004','Trisuli P/S - Balaju 66 kV line','line',66.0,NULL,'PDF p.209, section D (66 kV), row 2: double circuit, 58.00 circuit-km, DOG 100.'),
('TA-005','Devighat P/S - Okhaltar 66 kV line','line',66.0,NULL,'PDF p.209, section D (66 kV), row 4: double circuit, 53.00 circuit-km, DOG 100. Okhaltar-Chapali (row 5, double, 5.60 circuit-km, cable) not loaded.'),
('TA-006','Trishuli 3A - Trishuli 3B Hub 132 kV line','line',132.0,NULL,'PDF p.208, section A (132 kV), row 43: double circuit, 6.00 circuit-km, BISON 350.'),
('TA-007','Trishuli 3B Hub - Matatirtha 220 kV line','line',220.0,NULL,'PDF p.208, section B (220 kV), row 2: double circuit, 98.00 circuit-km, BISON 350.'),
('TA-008','Chilime - Trishuli 220 kV line','line',220.0,NULL,'PDF p.209, section B (220 kV), row 11: double circuit, 72 circuit-km, BISON 350. Endpoints as printed (Chilime-Trishuli); reading them as Chilime Hub and Trishuli 3B Hub is an inference.'),
('TA-009','Chilime Hub substation','substation',220.0,NULL,'PDF p.215, row 17: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA) and one 132/33 kV row of 50 MVA; no increment in FY2082/83. Rating is in MVA, so capacity_mw is left empty.'),
('TA-010','Trishuli 3B Hub substation','substation',220.0,NULL,'PDF p.215, row 16: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA) and one 132/33 kV row of 50 MVA; no increment in FY2082/83. Rating is in MVA, so capacity_mw is left empty.'),
('TA-011','Matatirtha substation','substation',220.0,NULL,'PDF p.215, row 13: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA); also 132/33 kV 30 MVA, 132/11 kV 22.5 and 45 MVA. Rating is in MVA, so capacity_mw is left empty.');

INSERT INTO project_evacuation (project_id, asset_id, source_id, notes) VALUES
('PRJ-001','TA-001','SRC-006','Stated: PDF p.130, line up to Chilime Hub.'),
('PRJ-009','TA-006','SRC-006','Stated: plant summary PDF p.187 (printed p.177), power transmitted to Trishuli 3B Hub - 2 Ckt.'),
('PRJ-010','TA-002','SRC-006','Plant summary p.187 says Chilime-1 Ckt; mapping to this line by name and circuit count is an inference.'),
('PRJ-010','TA-003','SRC-006','Plant summary p.187 says Devighat-1 Ckt; mapping by name and circuit count is an inference.'),
('PRJ-010','TA-004','SRC-006','Plant summary p.187 says Balaju-2 Ckt; mapping by name and circuit count is an inference.'),
('PRJ-011','TA-003','SRC-006','Plant summary p.187 says Trishuli-1 Ckt; mapping by name and circuit count is an inference.'),
('PRJ-011','TA-005','SRC-006','Plant summary p.187 says Chapali-2 Ckt; grid table lists Devighat-Okhaltar and Okhaltar-Chapali, so the link is an inference.'),
('PRJ-007','TA-002','SRC-006','Inference: line is named Chilime P/S - Trishuli P/S in the grid table; the report does not state it as this plant evacuation line.');

UPDATE events SET notes = notes || ' Evidence (SRC-006, NEA FY2025/26 report PDF pp.130-131): Rasuwagadhi COD 2024-12-31 (BS 2081.09.16); this flood (24 Asar 2082) halted generation. Unit 1 partial generation resumed 2025-12-06 (20 Mangsir 2082), unit 2 on 2025-12-25 (10 Poush 2082), unit 3 on 2026-05-14 (31 Baisakh 2083). The report states full restoration and rehabilitation is planned within FY2083/84, so the plant was not fully restored before EVT-002 (2026-08-26). Design energy 613.875 GWh a year (dry months 84.318, wet months 529.557).'
WHERE event_id = 'EVT-001' AND notes NOT LIKE '%SRC-006%';

UPDATE projects SET notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
 'NEA FY2025/26 report PDF p.130: design energy 613.875 GWh a year (dry 84.318, wet 529.557); line 10.0 km 132 kV double circuit to Chilime Hub.'
WHERE project_id = 'PRJ-001' AND notes NOT LIKE '%design energy 613.875%';
COMMIT;
