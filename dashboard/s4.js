(function () {
  'use strict';
  var App = window.App, D = App.D, esc = App.esc, fmt = App.fmt, badge = App.badge;
  var SCOPE = {
    national_total_all_destinations_split_unverified: 'national total, all destinations; split by country unverified',
    no_volume_reported: 'no volume reported',
    volume_not_loaded_conflicting_figures: 'not loaded: report and press figures conflict'
  };
  function has(v) { return v !== null && v !== undefined && v !== ''; }
  function val(v, d) { return has(v) ? fmt(v, d) : '<span class="cap">not loaded</span>'; }
  function fy(n) { return 'FY' + (n - 1) + '/' + String(n).slice(2); }
  function cbtn(id) { return '<button class="lnk" data-cid="' + esc(id) + '">' + esc(id) + '</button>'; }
  App.register('s4-body', function (root) {
    var ann = (D.annual || []).slice().sort(function (a, b) { return a.fiscal_year - b.fiscal_year; });
    var tr = (D.trade || []).slice().sort(function (a, b) { return a.fiscal_year - b.fiscal_year || (a.country < b.country ? -1 : 1); });
    var caps = tr.filter(function (r) { return has(r.export_capacity_mw); });
    var cap26 = caps.filter(function (r) { return r.fiscal_year === 2026; });
    var tot26 = 0;
    cap26.forEach(function (r) { tot26 += Number(r.export_capacity_mw); });
    var rev = tr.filter(function (r) { return has(r.export_revenue_npr_million); });
    var h = '<div class="warnbox"><b>Read this before the numbers.</b> Approved export capacity is permission, not flow. It is not actual exports and not available capacity. No trade record exists after the flood: the FY2025/26 report ends before 26 Aug 2026. The FY2025/26 export figure is provisional and disputed (' + cbtn('C-017') + ', ' + cbtn('C-006') + '). Country rows labelled India hold national totals, so they are not an India-only figure. No exportable-power figure is calculated here (see Section 6).</div>';
    h += '<div style="margin-top:12px">' + App.card('Annual electricity trade, national, GWh',
      badge('stated in reports', 'stated') + ' Same series as Section 2. FY2025/26 is provisional.',
      App.table([
        { h: 'Fiscal year', f: function (a) { return esc(a.fiscal_year_label || a.fiscal_year); } },
        { h: 'Exports, GWh', cls: 'num', f: function (a) { return val(a.export_gwh, 0); } },
        { h: 'Imports, GWh', cls: 'num', f: function (a) { return val(a.import_gwh, 0); } },
        { h: 'Net export, GWh', cls: 'num', f: function (a) { return val(a.net_export_gwh, 0); } },
        { h: 'Status', f: function (a) { return a.fiscal_year === 2026 ? badge('provisional', 'prov') + ' ' + badge('disputed', 'disp') : ''; } }
      ], ann) + '<div class="note">Net export is exports minus imports. Below zero, Nepal was a net importer. The FY2025/26 net export depends on the disputed export figure.</div>') + '</div>';
    h += '<div style="margin-top:12px">' + App.card('Approved export capacity by country, MW',
      badge('permission, not flow', 'disp') + ' Rows show the capacity recorded in each report. Planned arrangements are not active trade. Rows from different years are not added.',
      App.table([
        { h: 'Fiscal year', f: function (r) { return esc(fy(r.fiscal_year)); } },
        { h: 'Country', f: function (r) { return esc(r.country); } },
        { h: 'Status in report', f: function (r) { return esc(r.trade_status || ''); } },
        { h: 'Mechanism', f: function (r) { return esc(r.trade_mechanism || ''); } },
        { h: 'Approved export MW', cls: 'num', f: function (r) { return fmt(r.export_capacity_mw, 2); } },
        { h: 'Source', f: function (r) { return esc(r.data_source || ''); } }
      ], caps) + '<div class="note">' + esc(fy(2026)) + ' list total: <b>' + fmt(tot26, 2) + ' MW</b> of approvals. Do not read it as exports or as export room.</div>') + '</div>';
    h += '<div style="margin-top:12px">' + App.card('What the country rows contain',
      badge('check the scope', 'unv') + ' The volume scope is stored with each row.',
      App.table([
        { h: 'Fiscal year', f: function (r) { return esc(fy(r.fiscal_year)); } },
        { h: 'Country', f: function (r) { return esc(r.country); } },
        { h: 'Volume scope', f: function (r) { return esc(SCOPE[r.volume_scope] || r.volume_scope || ''); } },
        { h: 'Exports, GWh', cls: 'num', f: function (r) { return val(r.export_gwh, 0); } },
        { h: 'Imports, GWh', cls: 'num', f: function (r) { return val(r.import_gwh, 0); } },
        { h: 'Export revenue, NPR million', cls: 'num', f: function (r) { return val(r.export_revenue_npr_million, 0); } }
      ], tr)) + '</div>';
    h += '<div style="margin-top:12px">' + App.card('What is missing for research question RQ4', '',
      '<ul style="margin:0;padding-left:16px">' +
      '<li>No monthly trade table.</li>' +
      '<li>No actual GWh by country: Bangladesh has no volume in any year, and the India rows are national totals.</li>' +
      '<li>Export revenue is loaded for ' + rev.length + ' row(s) only (open conflict ' + cbtn('C-005') + ').</li>' +
      '<li>No trade record after the flood, so nothing here shows whether exports were restored.</li>' +
      '</ul>') + '</div>';
    root.innerHTML = h;
  });
})();
