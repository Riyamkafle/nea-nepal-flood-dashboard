(function () {
  'use strict';
  var App = window.App, D = App.D, esc = App.esc, fmt = App.fmt, badge = App.badge, K = window.NEA_CALC;
  var sel = null, ORDER = ['Rasuwa', 'Nuwakot', 'Gorkha'];
  function uniq(a) { return a.filter(function (x, i) { return x !== null && x !== undefined && a.indexOf(x) === i; }); }
  function num(id) { return String(id).replace(/^PRJ-0*/, '').replace(/^TA-0*/, 'T'); }
  function row(k, v) { return '<tr><th>' + k + '</th><td>' + v + '</td></tr>'; }
  function src(ids) { return uniq(ids).map(function (s) { return App.srcLink(s); }).join(', ') || 'none recorded'; }
  function detail(L, E) {
    if (!sel) return '<p class="empty">Select a project or grid asset in the diagram to see its recorded details.</p>';
    if (sel.kind === 'p') {
      var p = D.projects.filter(function (x) { return x.project_id === sel.id; })[0];
      var rows = L.filter(function (r) { return r.project_id === p.project_id; });
      var ev = uniq(rows.filter(function (r) { return r.affected_mw !== null; }).map(function (r) { return r.event_id + ': ' + fmt(r.affected_mw, 2) + ' MW listed'; }));
      var cond = uniq(rows.map(function (r) { return r.physical_condition; }));
      var dates = uniq(rows.map(function (r) { return r.status_date; })).sort();
      var cap = p.capacity_mw !== null && p.capacity_mw !== undefined ? fmt(p.capacity_mw, 2) + ' MW <span class="cap">installed or licensed, not unavailable MW</span>' : 'not recorded';
      var evid = !rows.length ? badge('no status entry', 'unv') : rows.every(function (r) { return r.verified === 'No'; }) ? badge('not verified', 'unv') : badge('partly verified', 'prov');
      return '<h4>' + esc(p.project_name) + '</h4><table class="kv">' + row('Category', esc(p.asset_type || 'not stated')) + row('District', esc(p.district || 'not stated')) +
        row('Phase before flood', esc((p.pre_flood_phase || 'unknown').replace(/_/g, ' '))) + row('Capacity', cap) + row('Listed in events', ev.length ? esc(ev.join('; ')) : 'none') +
        row('Reported condition', cond.length ? esc(cond.join(', ')) : 'not stated') + row('Source', src(rows.map(function (r) { return r.source_id; }))) +
        row('Reporting date', dates.length ? esc(dates[dates.length - 1]) : 'not stated') + row('Evidence status', evid) +
        '</table><p><button class="lnk" data-pid="' + esc(p.project_id) + '">Open full record</button></p>';
    }
    var a = D.assets.filter(function (x) { return x.asset_id === sel.id; })[0];
    var ev2 = E.filter(function (e) { return e.asset_id === a.asset_id; });
    var names = uniq(ev2.map(function (e) { var p = D.projects.filter(function (x) { return x.project_id === e.project_id; })[0]; return p ? p.project_name : e.project_id; }));
    return '<h4>' + esc(a.asset_name) + '</h4><table class="kv">' + row('Category', esc(a.asset_type)) + row('Voltage', a.voltage_kv !== null ? fmt(a.voltage_kv, 0) + ' kV' : 'not recorded') +
      row('Capacity', a.capacity_mw !== null && a.capacity_mw !== undefined ? fmt(a.capacity_mw, 1) + ' MW' : 'not recorded') + row('Linked projects', names.length ? esc(names.join(', ')) : 'none recorded') +
      row('Source', src(ev2.map(function (e) { return e.source_id; }))) + row('Reported condition', 'not recorded') + row('Evidence status', badge('structure only, no damage status', 'stated')) + '</table>';
  }
  App.register('ov-body', function (root, st) {
    var P = D.projects, A = D.assets, E = D.evacuation, L = D.status_log;
    var inEv = {};
    L.forEach(function (r) { if (st.event === 'all' || r.event_id === st.event) inEv[r.project_id] = 1; });
    var lanes = uniq(P.map(function (p) { return p.district || '(not stated)'; })).sort(function (a, b) {
      var i = ORDER.indexOf(a), j = ORDER.indexOf(b); return (i < 0 ? 9 : i) - (j < 0 ? 9 : j) || (a < b ? -1 : 1); });
    var LW = 600 / lanes.length, pos = {}, apos = {}, cnt = {}, svg = '', nodes = '', edges = '';
    lanes.forEach(function (ln, li) {
      cnt[ln] = 0;
      svg += '<rect x="' + (20 + li * LW) + '" y="8" width="' + (LW - 8) + '" height="222" rx="6" class="lane"/><text x="' + (26 + li * LW) + '" y="26" class="lanet">' + esc(ln) + '</text>';
    });
    function dim(p) {
      var d = p.district || '(not stated)';
      return (st.event !== 'all' && !inEv[p.project_id]) || (st.phase !== 'all' && (p.pre_flood_phase || 'unknown') !== st.phase) || (st.district !== 'all' && d !== st.district);
    }
    P.forEach(function (p) {
      var ln = p.district || '(not stated)', li = lanes.indexOf(ln), i = cnt[ln]++;
      var x = 20 + li * LW + 36 + (i % 2) * 62, y = 62 + Math.floor(i / 2) * 36;
      pos[p.project_id] = [x, y];
      var ph = p.pre_flood_phase || 'unknown';
      nodes += '<g class="node ph-' + ph + (dim(p) ? ' dim' : '') + (sel && sel.id === p.project_id ? ' sel' : '') + '" tabindex="0" role="button" data-k="p" data-id="' + esc(p.project_id) + '" aria-label="' + esc(p.project_name) + '"><title>' + esc(p.project_name) + '</title><circle cx="' + x + '" cy="' + y + '" r="11"/><text x="' + x + '" y="' + (y + 3) + '" text-anchor="middle">' + num(p.project_id) + '</text></g>';
    });
    A.forEach(function (a, i) {
      var x = 34 + i * (572 / Math.max(1, A.length - 1)), y = 292;
      apos[a.asset_id] = [x, y];
      nodes += '<g class="node asset' + (sel && sel.id === a.asset_id ? ' sel' : '') + '" tabindex="0" role="button" data-k="a" data-id="' + esc(a.asset_id) + '" aria-label="' + esc(a.asset_name) + '"><title>' + esc(a.asset_name) + '</title><rect x="' + (x - 12) + '" y="' + (y - 11) + '" width="24" height="22" rx="3"/><text x="' + x + '" y="' + (y + 3) + '" text-anchor="middle">' + num(a.asset_id) + '</text></g>';
    });
    E.forEach(function (e) {
      var p = pos[e.project_id], a = apos[e.asset_id]; if (!p || !a) return;
      var hi = sel && (sel.id === e.project_id || sel.id === e.asset_id);
      edges += '<line class="edge' + (hi ? ' hi' : '') + '" x1="' + p[0] + '" y1="' + (p[1] + 11) + '" x2="' + a[0] + '" y2="' + (a[1] - 11) + '"/>';
    });
    svg += '<text x="26" y="262" class="lanet">Grid assets: lines and substations (T1 to T' + A.length + ')</text>';
    var diagram = '<svg viewBox="0 0 640 316" role="group" aria-label="Schematic of projects by district and grid assets">' + svg + edges + nodes + '</svg>';
    var ann = D.annual.slice().sort(function (a, b) { return b.fiscal_year - a.fiscal_year; })[0];
    var e2 = K.eventListedMw(L, 'EVT-002'), e4 = K.eventListedMw(L, 'EVT-004');
    function item(t, s, b) { return '<li><b>' + t + '</b><span>' + s + '</span></li>' + (b || ''); }
    var left = '<ul class="evid">' +
      item('Pre-flood system baseline', esc(App.fyLabel(ann.fiscal_year)) + ' (provisional): exports ' + fmt(ann.export_gwh, 0) + ' GWh (disputed), imports ' + fmt(ann.import_gwh, 0) + ' GWh.') +
      item('Reported asset damage', 'EVT-002: ' + e2.projects + ' projects, ' + fmt(e2.totalMw, 1) + ' MW listed by the ministry. EVT-004: ' + e4.projects + ' projects, ' + fmt(e4.totalMw, 2) + ' MW licensed capacity. Listed MW is not damaged MW. Events are not added.') +
      item('Observed generation and trade', 'None after 26 Aug 2026. The FY2025/26 report ends before the flood.') +
      item('Recovery constraints', 'Exportable power is not computed: not all four inputs are known for the same period.') +
      '</ul><a class="btn" href="#recovery">Open recovery evidence</a>';
    var legend = '<div class="legend"><span><i class="lg ph-operating"></i>operating project</span><span><i class="lg ph-under_construction"></i>under construction</span><span><i class="lg ph-unknown"></i>phase unknown</span><span><i class="lg asset"></i>grid asset</span><span><i class="lg line"></i>recorded evacuation link</span></div>';
    root.innerHTML = '<div class="hero"><div class="hero-bar"><h2>Nepal&rsquo;s electricity system <span>| Baseline, flood impact and recovery</span></h2></div>' +
      '<div class="hero-body"><div class="hero-l"><h3>What the evidence shows</h3>' + left + '</div>' +
      '<div class="hero-c">' + diagram + legend + '<p class="cap">Schematic representation &mdash; not geographically accurate or to scale. Projects are placed by their stored district; no coordinates are held.</p></div>' +
      '<div class="hero-r"><h3>Selected asset</h3>' + detail(L, E) + '</div></div></div>';
    Array.prototype.forEach.call(root.querySelectorAll('.node'), function (n) {
      function pick() { sel = { kind: n.getAttribute('data-k'), id: n.getAttribute('data-id') }; App.render(); }
      n.addEventListener('click', pick);
      n.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(); } });
    });
  });
})();
