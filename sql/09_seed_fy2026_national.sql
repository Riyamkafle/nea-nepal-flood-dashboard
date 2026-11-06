BEGIN;
INSERT INTO nea_annual_data
  (fiscal_year, fiscal_year_label, import_gwh, export_gwh, net_export_gwh, total_available_gwh,
   domestic_consumption_gwh, peak_demand_mw, peak_supply_mw, system_loss_pct, consumers_million, source_report)
VALUES
  (2026, '2025/26', 1171, 3965, 2794, 18624, 12376, 2479, 3226, 12.16, 5.927,
   'A Year In Review Annual Report 2025_2026_compressed.pdf');
COMMIT;
