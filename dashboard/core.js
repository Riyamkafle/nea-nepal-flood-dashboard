(function () {
  'use strict';
  var D = window.NEA_DATA;
  var App = window.App = { D: D };

  App.C = { base: '#1f5f8b', light: '#a9cbe3', teal: '#1d8a8a', warn: '#c77a00', grey: '#8a93a3', bad: '#b23a3a', ok: '#2e8b57' };

  /* ---------- small helpers ---------- */
  App.esc = function (s) {
    return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  };
  var esc = App.esc;
  App.fmt = function (v, d) {
    if (v == null || v === '' || isNaN(Number(v))) return 'n/a';
    d = d || 0;
    return Number(v).toLocaleString('en-US', { minimumFractionDigits: d, maximumFractionDigits: d });
  };
  App.mw = function (v) {
    if (v == null || v === '' || isNaN(Number(v))) return 'n/a';
    return Number(v).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 3 });
  };
  App.sum = function (a) { var t = 0; (a || []).forEach(function (x) { if (x != null && !isNaN(Number(x))) t += Number(x); }); return t; };
  App.uniq = function (a) { var o = [], s = {}; (a || []).forEach(function (x) { if (!s[x]) { s[x] = 1; o.push(x); } }); return o; };
  App.fyLabel = function (fy) { return 'FY' + (fy - 1) + '/' + String(fy).slice(2); };
  App.badge = function (text, kind) { return '<span class="badge b-' + esc(kind || 'unv') + '">' + esc(text) + '</span>'; };
  var badge = App.badge;

  /* ---------- lookups ---------- */
  App.P = {}; D.projects.forEach(function (p) { App.P[p.project_id] = p; });
  App.S = {}; D.sources.forEach(function (s) { App.S[s.source_id] = s; });
  App.A = {}; D.assets.forEach(function (a) { App.A[a.asset_id] = a; });
  App.eventsOf = function (pid) { return App.uniq(D.status_log.filter(function (r) { return r.project_id === pid; }).map(function (r) { return r.event_id; })); };
  App.statusFor = function (pid, eid) {
    var r = D.status_log.filter(function (x) { return x.project_id === pid && x.event_id === eid; })[0];
    if (!r) return null;
    var o = {}; for (var k in r) o[k] = r[k];
    o.physical = r.physical_condition; o.gen = r.generation_status; o.evac = r.evacuation_status; o.rest = r.restoration_status;
    return o;
  };
  App.findConflict = function (metric, period) {
    var c = D.conflicts.filter(function (x) { return x.metric === metric && String(x.period || '').indexOf(period) >= 0; })[0];
    if (!c) c = D.conflicts.filter(function (x) { return /export/i.test(x.metric) && String(x.period || '').indexOf(period) >= 0; })[0];
    return c || null;
  };
  App.pLink = function (pid) {
    var p = App.P[pid];
    return '<button class="lnk" data-pid="' + esc(pid) + '">' + esc(p ? p.project_name : pid) + '</button>';
  };
  App.srcLink = function (sid) {
    if (!sid) return '';
    return '<button class="lnk" data-sid="' + esc(sid) + '">' + esc(sid) + '</button>';
  };

  /* ---------- building blocks ---------- */
  App.card = function (title, cap, body) {
    return '<div class="card"><h3>' + esc(title) + '</h3>' + (cap ? '<div class="cap">' + cap + '</div>' : '') + (body || '') + '</div>';
  };
  App.table = function (cols, rows, opts) {
    opts = opts || {};
    if (!rows || !rows.length) return '<div class="empty">No rows to show.</div>';
    var h = '<div class="tablewrap"><table><thead><tr>' + cols.map(function (c) { return '<th' + (c.cls ? ' class="' + c.cls + '"' : '') + '>' + esc(c.h) + '</th>'; }).join('') + '</tr></thead><tbody>';
    rows.forEach(function (r) {
      h += '<tr' + (opts.rowAttr ? ' ' + opts.rowAttr(r) : '') + '>' + cols.map(function (c) {
        var v = c.f(r); return '<td' + (c.cls ? ' class="' + c.cls + '"' : '') + '>' + (v == null ? '' : v) + '</td>';
      }).join('') + '</tr>';
    });
    return h + '</tbody></table></div>';
  };

  /* ---------- state, sections ---------- */
  var fys = D.annual.map(function (r) { return r.fiscal_year; });
  App.state = { event: 'all', phase: 'all', district: 'all', fy: Math.max.apply(null, fys), plant: 'Upper Trishuli 3A' };
  var sections = [];
  App.register = function (id, fn) { sections.push({ id: id, fn: fn }); };
  App.render = function () {
    sections.forEach(function (s) {
      var el = document.getElementById(s.id); if (!el) return;
      try { s.fn(el, App.state); }
      catch (e) { el.innerHTML = '<div class="warnbox">This section failed to draw: ' + esc(e.message) + '</div>'; if (window.console) console.error(s.id, e); }
    });
  };

  /* ---------- filters ---------- */
  function buildFilters() {
    var st = App.state;
    var dists = App.uniq(D.projects.map(function (p) { return p.district || '(not stated)'; })).sort();
    function sel(id, label, opts, cur) {
      return '<label>' + label + ' <select id="' + id + '">' + opts.map(function (o) {
        return '<option value="' + esc(o[0]) + '"' + (String(o[0]) === String(cur) ? ' selected' : '') + '>' + esc(o[1]) + '</option>';
      }).join('') + '</select></label>';
    }
    document.getElementById('filters').innerHTML =
      sel('f-event', 'Event', [['all', 'All events']].concat(D.events.map(function (e) { return [e.event_id, e.event_id + ' ' + e.event_date]; })), st.event) +
      sel('f-phase', 'Phase', [['all', 'All'], ['operating', 'Operating'], ['under_construction', 'Under construction'], ['unknown', 'Unknown']], st.phase) +
      sel('f-district', 'District', [['all', 'All districts']].concat(dists.map(function (d) { return [d, d]; })), st.district) +
      sel('f-fy', 'Fiscal year', fys.map(function (y) { return [y, App.fyLabel(y)]; }), st.fy);
    function bind(id, key, num) {
      document.getElementById(id).addEventListener('change', function (e) { st[key] = num ? Number(e.target.value) : e.target.value; App.render(); });
    }
    bind('f-event', 'event'); bind('f-phase', 'phase'); bind('f-district', 'district'); bind('f-fy', 'fy', true);
  }

  /* ---------- detail drawer ---------- */
  function kv(k, v) { return '<tr><th style="width:36%">' + esc(k) + '</th><td>' + (v == null || v === '' ? '<span class="cap">not stated</span>' : v) + '</td></tr>'; }
  function pre(s) { return '<div style="white-space:pre-wrap">' + esc(s) + '</div>'; }
  App.openDrawer = function (html) {
    document.getElementById('drawer-body').innerHTML = html;
    document.getElementById('drawer').classList.add('open');
    document.getElementById('overlay').classList.add('open');
    document.getElementById('drawer').scrollTop = 0;
  };
  App.closeDrawer = function () {
    document.getElementById('drawer').classList.remove('open');
    document.getElementById('overlay').classList.remove('open');
  };
  function projectDrawer(pid) {
    var p = App.P[pid]; if (!p) return;
    var h = '<h3>' + esc(p.project_name) + ' <span class="cap">' + esc(p.project_id) + '</span></h3>' +
      '<table><tbody>' + kv('Type', esc(p.asset_type)) + kv('Phase before flood', esc(p.pre_flood_phase)) + kv('Capacity (MW)', App.fmt(p.capacity_mw, 2)) +
      kv('District', esc(p.district)) + kv('Owner type', esc(p.owner_type)) + kv('Commissioned', esc(p.commissioned_date)) + '</tbody></table>';
    h += '<h4>Notes</h4>' + pre(p.notes || 'none');
    var logs = D.status_log.filter(function (r) { return r.project_id === pid; });
    h += '<h4>Status entries (' + logs.length + ')</h4>';
    if (!logs.length) h += '<div class="empty">No status entries.</div>';
    logs.forEach(function (r) {
      h += '<div class="card" style="margin-bottom:8px"><b>' + esc(r.event_id) + '</b> ' + badge(r.verified === 'Yes' ? 'verified' : 'not verified', r.verified === 'Yes' ? 'ok' : 'unv') +
        '<table><tbody>' + kv('Physical condition', esc(r.physical_condition)) + kv('Generation status', esc(r.generation_status)) + kv('Evacuation status', esc(r.evacuation_status)) +
        kv('Restoration status', esc(r.restoration_status)) + kv('Affected MW', r.affected_mw == null ? null : App.mw(r.affected_mw)) + kv('Available MW', r.available_mw == null ? null : App.mw(r.available_mw)) +
        kv('What the MW means', esc(r.mw_definition)) + kv('Source', App.srcLink(r.source_id)) + kv('Status date', esc(r.status_date)) + '</tbody></table>' +
        (r.notes ? pre(r.notes) : '') + '</div>';
    });
    var ev = D.evacuation.filter(function (r) { return r.project_id === pid; });
    h += '<h4>Evacuation links (' + ev.length + ')</h4>';
    h += ev.length ? ev.map(function (r) {
      var a = App.A[r.asset_id];
      return '<div style="margin-bottom:6px"><b>' + esc(a ? a.asset_name : r.asset_id) + '</b> <span class="cap">' + esc(r.asset_id) + '</span> ' + App.srcLink(r.source_id) + (r.notes ? pre(r.notes) : '') + '</div>';
    }).join('') : '<div class="empty">No evacuation link is recorded (the report states none).</div>';
    var bl = D.baseline.filter(function (r) { return r.project_id === pid; }).sort(function (a, b) { return a.fiscal_year - b.fiscal_year; });
    if (bl.length) h += '<h4>Annual generation, GWh</h4>' + App.table([{ h: 'Fiscal year', f: function (r) { return esc(App.fyLabel(r.fiscal_year)); } }, { h: 'GWh', cls: 'num', f: function (r) { return App.fmt(r.generation_gwh, 2); } }, { h: 'Source', f: function (r) { return App.srcLink(r.source_id); } }], bl);
    App.openDrawer(h);
  }
  function conflictDrawer(cid) {
    var c = D.conflicts.filter(function (x) { return x.conflict_id === cid; })[0]; if (!c) return;
    var h = '<h3>' + esc(c.conflict_id) + ' ' + badge(c.resolution_status || 'open', /resolved/i.test(c.resolution_status || '') ? 'ok' : 'prov') + '</h3><table><tbody>' +
      kv('Metric', esc(c.metric)) + kv('Period', esc(c.period)) + kv('Value A', esc(c.value_a)) + kv('Source A', esc(c.source_a) + ' ' + badge(c.source_a_type, 'unv')) +
      kv('Value B', esc(c.value_b)) + kv('Source B', esc(c.source_b) + ' ' + badge(c.source_b_type, 'unv')) + kv('Definition note', pre(c.definition_note)) +
      kv('Value used', esc(c.value_used)) + kv('Reason', pre(c.reason)) + '</tbody></table>';
    App.openDrawer(h);
  }
  function sourceDrawer(sid) {
    var s = App.S[sid]; if (!s) return;
    var url = s.url ? (/^https?:\/\//.test(s.url) ? '<a href="' + esc(s.url) + '" target="_blank" rel="noopener">' + esc(s.url) + '</a>' : esc(s.url)) : null;
    App.openDrawer('<h3>' + esc(s.source_id) + '</h3><table><tbody>' + kv('Title', esc(s.title)) + kv('Publisher', esc(s.publisher)) + kv('Type', esc(s.source_type)) +
      kv('Source date', esc(s.source_date)) + kv('Snapshot date', esc(s.snapshot_date)) + kv('URL', url) + '</tbody></table>');
  }

  /* ---------- start ---------- */
  App.start = function () {
    buildFilters();
    document.addEventListener('click', function (e) {
      var t = e.target.closest ? e.target.closest('[data-cid],[data-sid],[data-ev],[data-pid]') : null;
      if (!t) return;
      if (t.hasAttribute('data-cid')) conflictDrawer(t.getAttribute('data-cid'));
      else if (t.hasAttribute('data-sid')) sourceDrawer(t.getAttribute('data-sid'));
      else if (t.hasAttribute('data-ev')) { App.state.event = t.getAttribute('data-ev'); document.getElementById('f-event').value = App.state.event; App.render(); }
      else if (t.hasAttribute('data-pid')) projectDrawer(t.getAttribute('data-pid'));
    });
    document.getElementById('drawer-close').addEventListener('click', App.closeDrawer);
    document.getElementById('overlay').addEventListener('click', App.closeDrawer);
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') App.closeDrawer(); });
    App.render();
  };
})();
