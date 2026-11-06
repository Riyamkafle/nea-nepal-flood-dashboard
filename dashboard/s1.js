(function () {
  'use strict';
  var App = window.App, D = App.D, C = App.C, esc = App.esc, fmt = App.fmt, badge = App.badge;

  function kpi(label, value, unit, o) {
    o = o || {};
    return '<div class="card kpi"><div class="label">' + esc(label) + '</div><div class="val">' + value + (value !== 'n/a' && unit ? '<span class="unit">' + esc(unit) + '</span>' : '') + '</div>' +
      (o.delta ? '<div class="delta">' + o.delta + '</div>' : '') + '<div>' + (o.badges || []).join('') + '</div>' + (o.note ? '<div class="note">' + o.note + '</div>' : '') + '</div>';
  }
  function delta(cur, prev, label) {
    if (cur == null || prev == null || prev === 0) return '';
    var p = (cur / prev - 1) * 100;
    return (p >= 0 ? '+' : '') + fmt(p, 1) + '% vs ' + label;
  }

  App.register('s1-body', function (root, st) {
    var A = D.annual, row = A.filter(function (r) { return r.fiscal_year === st.fy; })[0] || A[A.length - 1];
    var prev = A.filter(function (r) { return r.fiscal_year === row.fiscal_year - 1; })[0] || {};
    var prov = row.fiscal_year === 2026, pl = App.fyLabel(row.fiscal_year - 1);
    var cf = App.findConflict('nea_export_gwh', 'FY2025/26');
    var expNote = prov ? 'The report and press give 3,965, 3,938 and 3,962 GWh. 3,965 is loaded. ' + (cf ? '<button class="lnk" data-cid="' + esc(cf.conflict_id) + '">Open conflict ' + esc(cf.conflict_id) + '</button>' : '') : '';
    var share = row.total_production_gwh ? row.ipp_purchase_gwh / row.total_production_gwh * 100 : null;
    var pBadge = prov ? [badge('provisional', 'prov')] : [badge('stated in report', 'stated')];
    var h = '<h3 style="margin:0 0 8px">National position, FY' + esc(row.fiscal_year_label) + '</h3><div class="grid g4">' +
      kpi('Exports', fmt(row.export_gwh), 'GWh', { delta: delta(row.export_gwh, prev.export_gwh, pl), badges: prov ? [badge('disputed', 'disp'), badge('provisional', 'prov')] : pBadge, note: expNote }) +
      kpi('Imports', fmt(row.import_gwh), 'GWh', { delta: delta(row.import_gwh, prev.import_gwh, pl), badges: pBadge }) +
      kpi('Net export (exports minus imports)', fmt(row.net_export_gwh), 'GWh', { badges: prov ? [badge('conditional on loaded export figure', 'disp')] : pBadge }) +
      kpi('National peak demand', fmt(row.peak_demand_mw), 'MW', { delta: delta(row.peak_demand_mw, prev.peak_demand_mw, pl), badges: pBadge }) +
      kpi('System peak supply (includes exports)', fmt(row.peak_supply_mw), 'MW', { badges: pBadge, note: 'Not export room: peak supply minus peak demand is not exportable capacity (different days and definitions).' }) +
      kpi('System loss', fmt(row.system_loss_pct, 2), '%', { badges: pBadge }) +
      kpi('NEA consumers', fmt(row.consumers_million, 2), 'million', { badges: pBadge, note: 'Excludes community rural electrification consumers.' }) +
      kpi('IPP and subsidiary share of production', share == null ? 'n/a' : fmt(share, 1), '%', { badges: share == null ? [badge('FY2025/26 production not loaded', 'unv')] : pBadge }) +
      '</div>';

    var labels = A.map(function (r) { return r.fiscal_year_label; }), hat = A.map(function (r, i) { return r.fiscal_year === 2026 ? i : -1; }).filter(function (i) { return i >= 0; });
    h += '<div class="grid g2" style="margin-top:12px">' +
      App.card('Exports and imports, GWh', 'Hatched bars are provisional FY2025/26 figures; the export bar uses the disputed 3,965 GWh. Source: NEA annual reports (SRC-006 to SRC-011).',
        App.barChart({ title: 'Exports and imports', labels: labels, unit: 'GWh', hatch: hat, series: [{ name: 'Exports', color: C.teal, values: A.map(function (r) { return r.export_gwh; }) }, { name: 'Imports', color: C.warn, values: A.map(function (r) { return r.import_gwh; }) }] })) +
      App.card('Net export (exports minus imports), GWh', 'Below zero Nepal was a net importer; FY2023/24 was the first net-export year in this series. The FY2025/26 bar is conditional.',
        App.barChart({ title: 'Net export', labels: labels, unit: 'GWh', hatch: hat, series: [{ name: 'Net export', color: C.base, values: A.map(function (r) { return r.net_export_gwh; }) }] })) +
      App.card('Where the electricity came from, GWh', 'NEA own generation and purchases from IPPs and NEA subsidiaries. FY2025/26 production figures are not loaded because their definitions are not confirmed.',
        App.barChart({ title: 'Production composition', labels: labels, unit: 'GWh', stacked: true, series: [{ name: 'NEA generation', color: C.base, values: A.map(function (r) { return r.nea_generation_gwh; }) }, { name: 'IPP and subsidiary purchases', color: C.light, values: A.map(function (r) { return r.ipp_purchase_gwh; }) }] })) +
      App.card('Peak demand and peak supply, MW', 'Peak supply includes exports. The gap between the lines is not exportable capacity. FY2019/20 peak supply was not reported.',
        App.lineChart({ title: 'Peaks', labels: labels, unit: 'MW', series: [{ name: 'National peak demand', color: C.base, values: A.map(function (r) { return r.peak_demand_mw; }) }, { name: 'System peak supply', color: C.teal, values: A.map(function (r) { return r.peak_supply_mw; }) }] })) +
      '</div>';

    var K = window.NEA_CALC, M = K.index(D.monthly), pn = ['Upper Trishuli 3A', 'Trishuli', 'Devighat'];
    var allY = K.yearsOf(M, pn[0]), scs = K.scenarios(allY, 2026);
    var sc = scs.filter(function (s) { return s.id === (st.base || 'all_excl'); })[0] || scs[3];
    var cmp = K.compare(M, pn, 2026, sc.years), isComb = st.plant === 'combined', pl = isComb ? null : (pn.indexOf(st.plant) >= 0 ? st.plant : pn[0]);
    var labels = D.monthly.filter(function (r) { return r.plant === pn[0] && r.fiscal_year === 2026; }).sort(function (a, b) { return a.fiscal_month_no - b.fiscal_month_no; }).map(function (r) { return r.bs_month; });
    function mact(p, fy) { var o = []; for (var m = 1; m <= 12; m++) { var v = M[p] && M[p][fy] && M[p][fy][m]; o.push(K.isNum(v) ? v / 1000 : null); } return o; }
    var bc = {}; function bl(p) { return bc[p] || (bc[p] = K.baseline(M, p, sc.years)); }
    function bmed(p) { return bl(p).map(function (x) { return x.base == null ? null : x.base / 1000; }); }
    function comb(fn) { var o = []; for (var i = 0; i < 12; i++) { var t = 0, ok = true; pn.forEach(function (p) { var v = fn(p)[i]; if (v == null) ok = false; else t += v; }); o.push(ok ? t : null); } return o; }
    function pc(v) { return v == null ? 'n/a' : (v >= 0 ? '+' : '') + fmt(v, 1) + '%'; }
    var series, band = null, lab = labels;
    if (isComb) {
      series = [{ name: 'Sum of the three monthly medians', color: C.warn, dash: '2 3', values: comb(bmed) },
        { name: 'FY2024/25 actual, sum', color: C.grey, dash: '5 3', values: comb(function (p) { return mact(p, 2025); }) },
        { name: 'FY2025/26 actual, sum', color: C.base, w: 2.6, values: comb(function (p) { return mact(p, 2026); }) }];
    } else {
      var b = bl(pl);
      lab = labels.map(function (l, i) { return l + (b[i].n < 3 ? '*' : ''); });
      band = { name: 'Clean range, baseline years', color: C.light, low: b.map(function (x) { return x.low == null ? null : x.low / 1000; }), high: b.map(function (x) { return x.high == null ? null : x.high / 1000; }) };
      series = [{ name: 'Median of clean months', color: C.warn, dash: '2 3', values: bmed(pl) },
        { name: 'FY2024/25 actual', color: C.grey, dash: '5 3', values: mact(pl, 2025) }, { name: 'FY2025/26 actual', color: C.base, w: 2.6, values: mact(pl, 2026) }];
    }
    var rowsT = pn.map(function (p) { return { n: p, r: cmp.plants[p] }; }).concat([{ n: 'Three plants combined', r: cmp.combined }]);
    var sens = scs.map(function (s) { var c = K.compare(M, pn, 2026, s.years); return { s: s, c: c }; });
    h += '<h3 style="margin:18px 0 6px">Three NEA plants on the Trishuli corridor: FY2025/26 against earlier years</h3>' +
      '<div class="warnbox"><b>Historical comparison, not flood-attributed loss.</b> FY2025/26 (mid-July 2025 to mid-July 2026) ended before EVT-002 on 26 Aug 2026, so it is a pre-flood period. FY2025/26 also includes the aftermath of EVT-001 (8 Jul 2025); this is context only and does not show that EVT-001 caused any decline. These three plants are a limited sample, not national generation. The median is a reference value, not a forecast. FY2025/26 figures are provisional.</div>' +
      '<div class="row-select" style="margin-top:8px"><label>Plant <select id="plant-sel">' + pn.concat(['combined']).map(function (p) { return '<option value="' + esc(p) + '"' + (p === (isComb ? 'combined' : pl) ? ' selected' : '') + '>' + esc(p === 'combined' ? 'All three combined' : p) + '</option>'; }).join('') + '</select></label>' +
      '<label>Baseline <select id="base-sel">' + scs.map(function (s) { return '<option value="' + s.id + '"' + (s.id === sc.id ? ' selected' : '') + '>' + esc(s.label) + '</option>'; }).join('') + '</select></label></div>' +
      '<div class="cap">Baseline years: ' + esc(sc.years.map(App.fyLabel).join(', ')) + '. FY2022/23 has no monthly table. * = fewer than 3 clean years in that month.</div><div class="grid g2">' +
      App.card(isComb ? 'Month by month, three plants summed, GWh' : 'Month by month, ' + pl + ', GWh', 'Actual observations are solid or dashed lines; the dotted line is the median reference (my calculation).',
        App.lineChart({ title: 'Monthly generation', labels: lab, unit: 'GWh', dec: 1, band: band, series: series })) +
      App.card('FY2025/26 observed vs baseline (selected baseline)', badge('calculated', 'stated') + ' (observed / baseline - 1) x 100, months with data in both.',
        App.table([{ h: 'Plant', f: function (r) { return esc(r.n); } }, { h: 'Observed GWh', cls: 'num', f: function (r) { return fmt(r.r.obsGwh, 1); } },
          { h: 'Baseline GWh', cls: 'num', f: function (r) { return fmt(r.r.baseGwh, 1); } }, { h: 'Diff GWh', cls: 'num', f: function (r) { return fmt(r.r.diffGwh, 1); } },
          { h: 'Diff %', cls: 'num', f: function (r) { return pc(r.r.pct); } }, { h: 'Months (thin)', cls: 'num', f: function (r) { return r.r.months + ' (' + r.r.thinMonths + ')'; } }], rowsT) +
        (cmp.combined.thinMonths ? '<div class="warnbox">' + cmp.combined.thinMonths + ' of ' + cmp.combined.months + ' months rest on fewer than 3 clean years: treat this baseline as thin, not robust.</div>' : '')) + '</div>' +
      App.card('How much the answer depends on the baseline', 'Same observed FY2025/26 output, four baselines. Report the range, not one number. Trishuli and Devighat declined over several years, so long baselines mostly measure that earlier decline.',
        App.table([{ h: 'Baseline', f: function (r) { return esc(r.s.label); } }, { h: 'Years', cls: 'num', f: function (r) { return r.s.years.length; } },
          { h: 'UT3A', cls: 'num', f: function (r) { return pc(r.c.plants[pn[0]].pct); } }, { h: 'Trishuli', cls: 'num', f: function (r) { return pc(r.c.plants[pn[1]].pct); } },
          { h: 'Devighat', cls: 'num', f: function (r) { return pc(r.c.plants[pn[2]].pct); } }, { h: 'Combined', cls: 'num', f: function (r) { return pc(r.c.combined.pct); } },
          { h: 'Thin months', cls: 'num', f: function (r) { return r.c.combined.thinMonths; } }], sens));
    root.innerHTML = h;
    document.getElementById('plant-sel').addEventListener('change', function (e) { st.plant = e.target.value; App.render(); });
    document.getElementById('base-sel').addEventListener('change', function (e) { st.base = e.target.value; App.render(); });
  });
})();
