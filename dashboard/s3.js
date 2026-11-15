(function () {
  'use strict';
  var App = window.App, D = App.D, esc = App.esc, fmt = App.fmt, badge = App.badge;
  var PLANTS = ['Upper Trishuli 3A', 'Trishuli', 'Devighat'];
  var PROFILES = [['optimistic', 'Optimistic'], ['precedent', 'Precedent'], ['pessimistic', 'Pessimistic']];
  function num(v) { return typeof v === 'number' && isFinite(v) ? v : 0; }
  App.register('s3-body', function (root) {
    var gap = D.gap || [], assets = D.assets || [], evac = D.evacuation || [], projs = D.projects || [];
    var pname = {};
    projs.forEach(function (p) { pname[p.project_id] = p.project_name || p.name || p.project_id; });
    var t = {};
    gap.forEach(function (r) {
      var o = t[r.profile + '|' + r.plant] || (t[r.profile + '|' + r.plant] = { m: 0, a: 0, b: 0 });
      o.m += num(r.lost_month_units); o.a += num(r.not_generated_A_mwh) / 1000; o.b += num(r.not_generated_B_mwh) / 1000;
    });
    var rows = [], tot = [];
    PROFILES.forEach(function (pf) {
      var s = { label: pf[1], m: 0, a: 0, b: 0 };
      PLANTS.forEach(function (pl) {
        var o = t[pf[0] + '|' + pl] || { m: 0, a: 0, b: 0 };
        rows.push({ profile: pf[1], plant: pl, m: o.m, a: o.a, b: o.b });
        s.m += o.m; s.a += o.a; s.b += o.b;
      });
      tot.push(s);
    });
    var capN = assets.filter(function (a) { return a.capacity_mw !== null && a.capacity_mw !== undefined; }).length;
    var h = '<div class="warnbox"><b>Read this before the numbers.</b> No observed generation exists after the flood: the FY2025/26 report ends before 26 Aug 2026. The figures below are conditional energy not generated if each plant were out for an assumed time. They are not measured loss. The status &ldquo;destroyed&rdquo; behind these scenarios rests on one unverified press source. They cover three NEA plants only and are not added to the RDNA estimate (2,730.48 GWh a year), which has a different scope and method. No figure here separates plant loss from evacuation loss.</div>';
    h += '<div style="margin-top:12px">' + App.card('Lines and substations on the corridor (structure only)',
      badge('recorded structure', 'stated') + ' Which asset connects which plants. Capacity is recorded for ' + capN + ' of ' + assets.length + ' assets. No damage or status is recorded here.',
      App.table([
        { h: 'Asset', f: function (a) { return esc(a.asset_id) + '<div class="cap">' + esc(a.asset_name) + '</div>'; } },
        { h: 'Type', f: function (a) { return esc(a.asset_type); } },
        { h: 'kV', cls: 'num', f: function (a) { return fmt(a.voltage_kv, 0); } },
        { h: 'Linked projects', f: function (a) {
            var ids = [];
            evac.forEach(function (e) { if (e.asset_id === a.asset_id && ids.indexOf(e.project_id) < 0) ids.push(e.project_id); });
            return ids.length ? esc(ids.map(function (i) { return pname[i] + ' (' + i + ')'; }).join(', ')) : '<span class="cap">none recorded</span>'; } },
        { h: 'Source', f: function (a) {
            var s = [];
            evac.forEach(function (e) { if (e.asset_id === a.asset_id && s.indexOf(e.source_id) < 0) s.push(e.source_id); });
            return s.map(function (x) { return App.srcLink(x); }).join(', '); } }
      ], assets)) + '</div>';
    h += '<div style="margin-top:12px">' + App.card('Conditional energy not generated, three NEA plants, GWh',
      badge('conditional', 'disp') + ' Basis A uses last year&rsquo;s output; basis B uses the recent three years. Do not add A and B. Outage lengths are read from the stored scenario rows (not documented elsewhere).',
      App.table([
        { h: 'Profile', f: function (r) { return esc(r.profile); } },
        { h: 'Plant', f: function (r) { return esc(r.plant); } },
        { h: 'Month-equivalents out', cls: 'num', f: function (r) { return fmt(r.m, 2); } },
        { h: 'Basis A, GWh', cls: 'num', f: function (r) { return fmt(r.a, 1); } },
        { h: 'Basis B, GWh', cls: 'num', f: function (r) { return fmt(r.b, 1); } }
      ], rows)) + '</div>';
    h += '<div style="margin-top:12px">' + App.card('Range across the three profiles, GWh',
      badge('calculated', 'stated') + ' Sum of the three plants above, per profile and basis. Report the range, not one number.',
      App.table([
        { h: 'Profile', f: function (r) { return esc(r.label); } },
        { h: 'Month-equivalents (3 plants)', cls: 'num', f: function (r) { return fmt(r.m, 2); } },
        { h: 'Basis A, GWh', cls: 'num', f: function (r) { return fmt(r.a, 1); } },
        { h: 'Basis B, GWh', cls: 'num', f: function (r) { return fmt(r.b, 1); } }
      ], tot) + '<div class="note">Month-equivalents are the sum of the stored outage fractions of a month and are my reading of that column. A scenario assumes an outage; it does not show that one happened. Installed MW is not lost MW.</div>') + '</div>';
    root.innerHTML = h;
  });
})();
