BEGIN;
-- COD dates: printed Bikram Sambat dates converted to AD (nepali-datetime). Source: NEA FY2025/26 report (SRC-006).
UPDATE projects SET commissioned_date = '2024-12-31',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.188): Rasuwagadhi Hydropower Company Ltd., 111,000 kW, Rasuwa, COD BS 2081.09.16.'
WHERE project_id = 'PRJ-001' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET commissioned_date = '2025-02-11', owner_type = 'IPP',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.191): listed as Sanjen Khola, Salasungi Power Limited, 78,000 kW, Rasuwa, IPP table, COD BS 2081.10.29. Matched to this row by developer name and capacity.'
WHERE project_id = 'PRJ-002' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET commissioned_date = '2023-10-08',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.188): Sanjen Hydropower Co. Limited, 14,800 kW, Rasuwa, COD BS 2080.06.21.'
WHERE project_id = 'PRJ-003' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET commissioned_date = '2024-12-16',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.188): Sanjen Hydropower Company Limited, 42,500 kW, Rasuwa, COD BS 2081.09.01.'
WHERE project_id = 'PRJ-004' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET commissioned_date = '2014-07-03', owner_type = 'IPP',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.189): Mailung Khola Hydro Power Company, 5,000 kW, Rasuwa, IPP table, COD BS 2071.03.19.'
WHERE project_id = 'PRJ-005' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

-- PRJ-006: NOT changed (phase stays as is). Conflict recorded in notes.
UPDATE projects SET
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'CONFLICT: NEA FY2025/26 report appendix (PDF p.198) lists Langtang Khola, Multi Energy Development Pvt. Ltd., 20,000 kW, Rasuwa, in the UNDER CONSTRUCTION table as of FY 2082/83 (PPA BS 2072.09.29, no COD). Seed says operating. Check RDNA Table 34.'
WHERE project_id = 'PRJ-006' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET commissioned_date = '2003-08-25',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.188): Chilime Hydro Power Company Ltd., 22,100 kW, Rasuwa, COD BS 2060.05.08.'
WHERE project_id = 'PRJ-007' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

-- PRJ-008: capacity 14.80 -> 14.30, district, phase and owner filled from the NEA list. Delete this block to skip it.
UPDATE projects SET capacity_mw = 14.30, district = 'Rasuwa', pre_flood_phase = 'operating', owner_type = 'IPP',
  commissioned_date = '2024-02-11',
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.191): Mathillo Mailung Khola Jalbidhyut Ltd., Upper Mailung, 14,300 kW, Rasuwa, operating, COD BS 2080.10.28. Previous seed values: capacity 14.80 (equals Upper Sanjen), district blank, phase unknown. A different project, Upper Mailung A, 6,420 kW, Energy Engineering Pvt. Ltd., is under construction (PDF p.194). Verify in RDNA.'
WHERE project_id = 'PRJ-008' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

-- NEA-owned plants: not in the IPP/subsidiary list. Year only, so commissioned_date is left empty.
UPDATE projects SET
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 60 MW, year 2019, design generation 489.8 GWh; 2 units of 30 MW (PDF p.26). FY2020/21 report: commissioned July 2019. District not stated there.'
WHERE project_id = 'PRJ-009' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 24 MW, year 1967, design generation 163.8 GWh. District not stated there.'
WHERE project_id = 'PRJ-010' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 15.1 MW (seed 15.00), year 1984, design generation 113.0 GWh. District not stated there.'
WHERE project_id = 'PRJ-011' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%');

UPDATE projects SET
  notes = CASE WHEN notes IS NULL OR notes = '' THEN '' ELSE notes || ' ' END ||
  'UNMATCHED in NEA FY2025/26 report appendix: no operating solar project in Nuwakot and no single 25 MW solar plant. The list has Dharamnagar Solar Farm 10 MW and Dharamnagar Solar Farm-I 15 MW (Pashupati Renewables, Kapilvastu). Name and district unverified; check RDNA.'
WHERE project_id = 'PRJ-012' AND (notes IS NULL OR notes NOT LIKE '%NEA FY2025/26 report appendix%' AND notes NOT LIKE '%UNMATCHED in NEA%');

COMMIT;
