(function () {
  'use strict';
  var App = window.App, D = App.D, esc = App.esc, badge = App.badge, Q = window.NEA_QUESTIONS;
  var KIND = { 'Answered': 'ok', 'Partly answered': 'prov', 'Conditional': 'disp', 'No data': 'bad' };
  function list(items, f) {
    return items.length ? '<ul style="margin:0;padding-left:16px">' + items.map(function (c) { return '<li>' + esc(f(c)) + '</li>'; }).join('') + '</ul>' : '<span class="cap">none</span>';
  }
  App.register('s6-body', function (root) {
    if (!Q) { root.innerHTML = '<div class="warnbox">questions.js did not load, so the coverage table cannot be shown.</div>'; return; }
    var res = Q.evaluateAll(D), n = {};
    Q.STATUSES.forEach(function (s) { n[s] = 0; });
    res.forEach(function (r) { n[r.status]++; });
    var h = '<h3 style="margin:0 0 6px">Research-question coverage</h3>' +
      '<div class="cap">Derived from the data loaded in this dashboard, not typed by hand. ' + Q.STATUSES.map(function (s) { return badge(s + ': ' + n[s], KIND[s]); }).join(' ') + '</div>' +
      '<div class="note"><b>Answered</b>: every needed component is present and nothing is assumed. <b>Partly answered</b>: some components are present, others missing. <b>Conditional</b>: the conclusion depends on an explicit assumption or scenario. <b>No data</b>: the required evidence is not in the current dataset.</div>' +
      '<div class="warnbox">&ldquo;No data in current dataset&rdquo; does not mean the information does not exist anywhere. It means it has not been found and loaded here. A chart or a number existing for a question does not make the question answered.</div>' +
      App.table([
        { h: 'Research question', f: function (r) { return '<b>' + esc(r.id) + ' ' + esc(r.title) + '</b><div class="cap">' + esc(r.text) + '</div>'; } },
        { h: 'Status', f: function (r) { return badge(r.status, KIND[r.status]); } },
        { h: 'Evidence available', f: function (r) { return list(r.known, function (c) { return c.note || c.name; }); } },
        { h: 'Missing evidence', f: function (r) { return list(r.missing, function (c) { return c.gap || c.name; }); } },
        { h: 'Next verification step', f: function (r) { return esc(r.next); } }
      ], res) +
      '<div class="cap" style="margin-top:8px">Known unresolved item (EVT-004): a 412.94 MW EVT-004 total and a five-project list appear in earlier notes; origin untraced, verification pending, not used in any calculation.</div>';
    var isRes = function (c) { return /^resolved/i.test(c.resolution_status || ''); };
    var cstat = App.state.cstatus || 'all';
    var cs = D.conflicts.filter(function (c) { return cstat === 'resolved' ? isRes(c) : cstat === 'open' ? !isRes(c) : true; });
    var nOpen = D.conflicts.filter(function (c) { return !isRes(c); }).length;
    function claim(v, s, t) { return esc(v) + '<div class="cap">' + esc(s) + (t ? ' ' + badge(t, 'unv') : '') + '</div>'; }
    h += '<h3 style="margin:22px 0 6px">Conflict register</h3>' +
      '<div class="cap">Where two sources differ, both claims are kept and the value used is stated with its reason. Click an ID for the full record. ' + badge(nOpen + ' open', 'prov') + ' ' + badge((D.conflicts.length - nOpen) + ' resolved or provisionally resolved', 'ok') + '</div>' +
      '<div class="row-select"><label>Show <select id="c-status">' + [['all', 'All'], ['open', 'Open'], ['resolved', 'Resolved (including provisional)']].map(function (o) { return '<option value="' + o[0] + '"' + (o[0] === cstat ? ' selected' : '') + '>' + o[1] + '</option>'; }).join('') + '</select></label><span class="cap">' + cs.length + ' of ' + D.conflicts.length + ' shown</span></div>' +
      App.table([
        { h: 'ID', f: function (c) { return '<button class="lnk" data-cid="' + esc(c.conflict_id) + '">' + esc(c.conflict_id) + '</button>'; } },
        { h: 'Metric and period', f: function (c) { return esc(c.metric) + '<div class="cap">' + esc(c.period || '') + '</div>'; } },
        { h: 'Claim A', f: function (c) { return claim(c.value_a, c.source_a, c.source_a_type); } },
        { h: 'Claim B', f: function (c) { return claim(c.value_b, c.source_b, c.source_b_type); } },
        { h: 'Status', f: function (c) { return badge(c.resolution_status || 'open', isRes(c) ? 'ok' : 'prov'); } },
        { h: 'Value used', f: function (c) { return esc(c.value_used) || '<span class="cap">none yet</span>'; } }
      ], cs);
    h += '<h3 style="margin:22px 0 6px">Sources</h3>' +
      '<div class="cap">Source type is Primary, Secondary or Tertiary. A source being listed does not mean its figures are verified. Click an ID for the title, URL and dates.</div>' +
      App.table([
        { h: 'ID', f: function (s) { return App.srcLink(s.source_id); } },
        { h: 'Publisher', f: function (s) { return esc(s.publisher || 'not stated'); } },
        { h: 'Title', f: function (s) { return esc(s.title); } },
        { h: 'Type', f: function (s) { return badge(s.source_type, s.source_type === 'Primary' ? 'ok' : 'unv'); } },
        { h: 'Source date', f: function (s) { return esc(s.source_date || 'not stated'); } },
        { h: 'Snapshot', f: function (s) { return esc(s.snapshot_date || 'not stated'); } }
      ], D.sources);
    var vy = D.status_log.filter(function (r) { return r.verified === 'Yes'; }).length;
    var vp = D.status_log.filter(function (r) { return r.verified === 'Partially verified'; }).length;
    var vn = D.status_log.filter(function (r) { return r.verified === 'No'; }).length;
    var ty = function (t) { return D.sources.filter(function (s) { return s.source_type === t; }).length; };
    var evU = D.events.filter(function (e) { return /UNVERIFIED|NOT VERIFIED/i.test((e.notes || '') + (e.description || '')); }).length;
    h += '<h3 style="margin:22px 0 6px">Verification summary</h3><div class="grid g4">' +
      App.card('Status entries', '', '<div class="val" style="font-size:1.3rem">' + D.status_log.length + '</div><div class="note">verified Yes ' + vy + ', Partially verified ' + vp + ', No ' + vn + '</div>') +
      App.card('Sources', '', '<div class="val" style="font-size:1.3rem">' + D.sources.length + '</div><div class="note">Primary ' + ty('Primary') + ', Secondary ' + ty('Secondary') + ', Tertiary ' + ty('Tertiary') + '</div>') +
      App.card('Conflicts', '', '<div class="val" style="font-size:1.3rem">' + D.conflicts.length + '</div><div class="note">open ' + nOpen + ', resolved ' + (D.conflicts.length - nOpen) + '</div>') +
      App.card('Events', '', '<div class="val" style="font-size:1.3rem">' + D.events.length + '</div><div class="note">marked unverified in notes: ' + evU + ' of ' + D.events.length + '</div>') + '</div>';
    root.innerHTML = h;
    var cSel = document.getElementById('c-status');
    if (cSel) cSel.addEventListener('change', function (e) { App.state.cstatus = e.target.value; App.render(); });
  });
})();
