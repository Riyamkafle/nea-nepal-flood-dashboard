(function () {
  'use strict';
  var App = window.App, D = App.D, esc = App.esc, fmt = App.fmt, badge = App.badge, Q = window.NEA_QUESTIONS;
  // Interim cross-border line limits. NOT in the database: taken from the research notes (FY2025/26 report text,
  // 13th JWG/JSC 14-15 Jul 2026). Located in the report text on PDF pp.15 and 109; printed page number to confirm. Never added to approvals.
  var LIMITS = [
    { route: 'Butwal\u2013Gorakhpur (220 kV)', exp: 200, imp: 130 },
    { route: 'Dhalkebar\u2013Muzaffarpur and Dhalkebar\u2013Sitamarhi, combined', exp: 1650, imp: 1400 }
  ];
  // Context shown beside each of the four inputs (evidence that exists but is NOT the input itself).
  var INFO = {
    'Available generation': { period: 'No post-flood period in the dataset', kind: 'bad', word: 'Unavailable',
      has: 'Conditional three-plant scenarios exist (gap scenarios in the dataset). They estimate energy not generated under assumptions; they are not system-wide available generation.' },
    'Domestic demand and actual surplus': { period: 'FY2025/26 (pre-flood, provisional)', kind: 'bad', word: 'Unavailable',
      has: 'Annual consumption and peak demand are loaded (see below), but no surplus series exists.' },
    'Transmission and evacuation capacity': { period: 'No post-flood line or evacuation data', kind: 'bad', word: 'Unavailable',
      has: 'The line and substation structure is recorded (which plants connect to which lines). The cross-border limits in the card below are not domestic evacuation capacity, and there is no post-flood line status.' },
    'Export approvals': { period: 'FY2025/26', kind: 'prov', word: 'Known (approval only)',
      has: 'Approved export quantum by country. This is permission, not flow, and not currently available capacity.' }
  };
  App.register('s5-body', function (root) {
    if (!Q) { root.innerHTML = '<div class="warnbox">questions.js did not load, so the exportability panel cannot be shown.</div>'; return; }
    var rq = Q.QUESTIONS.filter(function (q) { return q.id === 'RQ6'; })[0], ev = Q.evaluate(rq, D);
    var knownNames = ev.known.map(function (c) { return c.name; });
    var comps = rq.components.map(function (c) {
      var i = INFO[c.name] || { period: 'not stated', kind: 'bad', word: 'Unavailable', has: '' }, have = knownNames.indexOf(c.name) >= 0;
      return { name: c.name, have: have, i: i, gap: c.gap, note: c.note };
    });
    var nMissing = comps.filter(function (c) { return !c.have; }).length;

    var h = '<div class="warnbox"><b>Read this before the numbers.</b> Generation restored does not mean exports restored. Approved export capacity is not actual exports. Peak supply minus peak demand is not a valid surplus estimate and not exportable power. No exportable-power figure is calculated here, because the four inputs are not all established for the same period.</div>';

    h += '<h3 style="margin:14px 0 6px">The four inputs to exportable power</h3>' +
      '<div class="cap">Exportable power is limited by the smallest of these four, all for the same period. Status is derived from the same checks as research question RQ6 in the coverage table (Section 6).</div>' +
      App.table([
        { h: 'Input', f: function (c) { return '<b>' + esc(c.name) + '</b>'; } },
        { h: 'Status', f: function (c) { return badge(c.have ? (c.name === 'Export approvals' ? 'Known (approval only)' : 'Known') : 'Unavailable', c.have ? (c.name === 'Export approvals' ? 'prov' : 'ok') : 'bad'); } },
        { h: 'Period of the evidence', f: function (c) { return esc(c.i.period); } },
        { h: 'What exists (not the input itself)', f: function (c) { return esc(c.i.has); } },
        { h: 'What is missing', f: function (c) { return c.have ? (c.name === 'Export approvals' ? '<span class="cap">Approval only; no flows, no post-flood approvals.</span>' : '<span class="cap">Check the evidence column and confirm the period matches the other inputs.</span>') : esc(c.gap); } }
      ], comps);

    h += '<div class="grid g2" style="margin-top:12px">';
    var tr = D.trade.filter(function (r) { return r.fiscal_year === 2026 && r.export_capacity_mw != null; });
    h += App.card('Export approvals, FY2025/26', badge('stated in report', 'stated') + ' Approved quantum in MW. Approval is not exports and not available capacity.',
      App.table([
        { h: 'Country', f: function (r) { return esc(r.country); } },
        { h: 'Mechanism', f: function (r) { return esc(r.trade_mechanism || 'not stated'); } },
        { h: 'Approved export MW', cls: 'num', f: function (r) { return fmt(r.export_capacity_mw, 2); } }
      ], tr) + '<div class="note">List total of the rows above: <b>' + fmt(App.sum(tr.map(function (r) { return r.export_capacity_mw; })), 2) + ' MW</b> of approvals. Do not read it as exports or as export room.</div>');
    h += App.card('Interim cross-border line limits', badge('stated in report, PDF pp.15 and 109', 'stated') + ' Approved at the 13th JWG/JSC meeting, 14 to 15 Jul 2026. Not in the database. Printed page numbers to confirm. The report words the Dhalkebar figure as a restriction on p.109 and as increased cross-border capacity on p.15, so it is shown as a limit.',
      App.table([
        { h: 'Route', f: function (r) { return esc(r.route); } },
        { h: 'Export MW', cls: 'num', f: function (r) { return fmt(r.exp, 0); } },
        { h: 'Import MW', cls: 'num', f: function (r) { return fmt(r.imp, 0); } }
      ], LIMITS) + '<div class="warnbox">These limits are not additive, and they are not added to the approvals shown beside this table. They cover cross-border lines only, not the domestic corridor.</div>');
    h += '</div>';

    var a = D.annual.filter(function (r) { return r.fiscal_year === 2026; })[0] || {};
    h += '<div style="margin-top:12px">' + App.card('Domestic demand context, FY2025/26', badge('provisional', 'prov') + ' Demand is known; surplus is not.',
      '<span class="stat"><b>' + fmt(a.domestic_consumption_gwh) + '</b> GWh domestic consumption</span><span class="stat"><b>' + fmt(a.peak_demand_mw) + '</b> MW national peak demand</span>' +
      '<div class="note">The report text also gives 12,394 GWh as energy utilized in Nepal (PDF pp.149 and 158; printed pages unconfirmed). The two figures differ by 18 GWh and the report does not explain why (open conflict C-022). The 12,376 figure (PDF pp.13 and 61) is the one loaded.</div>' +
      '<div class="warnbox">Peak supply minus peak demand is not a surplus. The two peaks can fall on different days, peak supply includes exports, and neither is a measure of what could be exported. No difference is calculated here.</div>') + '</div>';

    h += '<div style="margin-top:12px">' + App.card('Exportable power', '',
      '<div class="val" style="font-size:1.3rem">Exportable power: not computed</div>' +
      '<div class="note">Formula: the minimum of available generation, domestic surplus, transmission and evacuation capacity, and approved export capacity, all for the same period. ' +
      nMissing + ' of ' + comps.length + ' inputs are missing, so no MW or GWh figure is given. ' +
      badge('No data in current dataset', 'bad') + ' This does not mean the data does not exist elsewhere.</div>') + '</div>';
    var RC = D.rdna_claims || [];
    if (!RC.length) {
      h += '<div class="warnbox">The RDNA claims table is not loaded, so the RDNA card cannot be shown.</div>';
    } else {
      var RCAT = [
        ['damage', 'Physical asset damage', 'Assessment estimate'],
        ['loss', 'Estimated economic losses', 'Assessment estimate'],
        ['generation_loss', 'Estimated annual generation loss', 'Assessment estimate'],
        ['recovery_need', 'Indicative recovery needs', 'Assessment estimate'],
        ['portfolio', 'Assessed portfolio before the flood (installed MW)', 'Reported inventory']
      ];
      var rdna = '<div class="warnbox"><b>Assessment estimates, not observed losses.</b> These figures come from the NDRRMA Rapid Damage and Needs Assessment (SRC-023, sector cut-off 3 Sep 2026). Locating a figure in the report does not verify it. Damage is not economic loss, economic loss is not recovery cost, installed MW is not damaged or unavailable MW, and estimated GWh is not observed generation lost. The four blocks are not additive.</div>';
      RCAT.forEach(function (c) {
        var rows = RC.filter(function (r) { return r.category === c[0]; });
        if (!rows.length) { return; }
        rdna += '<h4 style="margin:14px 0 6px">' + esc(c[1]) + ' ' + badge(c[2], 'prov') + '</h4>' +
          App.table([
            { h: 'Item', f: function (r) { return esc(r.item); } },
            { h: 'Value', cls: 'num', f: function (r) { return fmt(Number(r.value), r.unit === 'MW' ? 3 : 2); } },
            { h: 'Unit', f: function (r) { return esc(r.unit); } },
            { h: 'Evidence', f: function (r) { return esc(r.evidence_type); } },
            { h: 'Source reference', f: function (r) { return esc(String(r.source_id)) + ': ' + esc(String(r.report_ref)) + ', PDF p.' + esc(String(r.pdf_page)) + ', printed p.' + esc(String(r.printed_page)) + (r.also_in ? '<div class="cap">Also: ' + esc(String(r.also_in)) + '</div>' : ''); } }
          ], rows) +
          '<div class="note">' + esc(String(rows[0].claim_id)) + ' definition and limits: ' + esc(String(rows[0].definition_note)) + '</div>';
      });
      h += '<div style="margin-top:12px">' + App.card('RDNA energy-sector estimates, Rasuwa-Bhotekoshi flood (EVT-002)', badge('Not independently verified', 'unv'), rdna) + '</div>';
    }
    root.innerHTML = h;
  });
})();
