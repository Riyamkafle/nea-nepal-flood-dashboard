BEGIN;
-- FY2020/21: 5.08 million = 4.53 million NEA consumers + ~0.55 million Community Rural Electrification consumers.
-- Table value (4,528,411) matches the NEA-only basis used in every other year.
UPDATE nea_annual_data SET consumers_million = 4.53 WHERE fiscal_year = 2021 AND consumers_million = 5.08;
-- FY2021/22: 4,766,021 consumers (FY2021/22 report; the FY2022/23 report's +7.72% reproduces from it).
UPDATE nea_annual_data SET consumers_million = 4.77 WHERE fiscal_year = 2022 AND consumers_million IS NULL;
COMMIT;
