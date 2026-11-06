-- 03b_trade_position_fix.sql : READ ONLY. Volumes come from nea_annual_data, not the India row.
SELECT a.fiscal_year, a.fiscal_year_label, a.export_gwh, a.import_gwh, a.net_export_gwh,
       t.trade_mechanism,
       CASE WHEN a.export_gwh IS NULL OR a.import_gwh IS NULL THEN 'Not reported'
            WHEN a.export_gwh > a.import_gwh THEN 'NET EXPORTER'
            WHEN a.export_gwh < a.import_gwh THEN 'NET IMPORTER'
            ELSE 'Balanced' END AS trade_position,
       a.export_gwh - LAG(a.export_gwh) OVER (ORDER BY a.fiscal_year) AS export_growth_gwh,
       a.import_gwh - LAG(a.import_gwh) OVER (ORDER BY a.fiscal_year) AS import_change_gwh
FROM nea_annual_data a
LEFT JOIN nea_country_trade t ON t.fiscal_year = a.fiscal_year AND t.country = 'India'
ORDER BY a.fiscal_year;
