(function () {
  'use strict';
  var App = window.App, D = App.D, esc = App.esc, fmt = App.fmt, badge = App.badge, sum = App.sum, uniq = App.uniq;
  var K = window.NEA_CALC;
  // Event-level listed MW: one value per project; conflicts and missing values are flagged, never summed or treated as zero.
  function flag(ag) {
    var h = '';
    if (ag.conflicts.length) h += '<div class="warnbox"><b>Total needs review.</b> ' + ag.conflicts.length + ' project(s) have conflicting listed MW for this event and are left out of the total: ' + ag.conflicts.map(function (c) { return esc(c.project_id) + ' (' + c.values.join(' vs ') + ' MW)'; }).join('; ') + '.</div>';
    if (ag.unlisted.length) h += '<div class="note">' + ag.unlisted.length + ' project(s) have no MW listed for this event (not counted as zero): ' + ag.unlisted.map(esc).join(', ') + '.</div>';
    if (ag.multiRowProjects.length) h += '<div class="note">' + ag.multiRowProjects.length + ' project(s) have more than one status row for this event; each is counted once.</div>';
    return h;
  }

  function phaseBadge(ph) { return badge(String(ph).replace('_', ' '), ph === 'operating' ? 'ok' : 'prov'); }
  function condBadge(v) { return v === 'unknown' ? badge('unknown', 'unv') : badge(v, v === 'destroyed' || v === 'blocked' ? 'bad' : 'prov'); }

  App.register('s2-body', function (root, st) {
    /* ---- event cards ---- */
    var evHtml = D.events.map(function (e) {
      var rows = D.status_log.filter(function (r) { return r.event_id === e.event_id; });
      var pids = uniq(rows.map(function (r) { return r.project_id; }));
      var ag = K.eventListedMw(rows, e.event_id), mw = ag.totalMw;
      var defs = uniq(rows.filter(function (r) { return r.mw_definition; }).map(function (r) { return r.mw_definition; }));
      var ph = {}; pids.forEach(function (id) { var p = App.P[id]; if (p) ph[p.pre_flood_phase] = (ph[p.pre_flood_phase] || 0) + 1; });
      var ver = rows.filter(function (r) { return r.verified === 'Yes'; }).length;
      var stats = pids.length ?
        '<span class="stat"><b>' + pids.length + '</b> projects listed</span><span class="stat"><b>' + (ag.listedProjects ? App.mw(mw) : 'n/a') + '</b> MW listed' + (ag.complete ? '' : ' (excl. conflicts)') + '</span>' +
        '<span class="stat">' + Object.keys(ph).map(function (k) { return ph[k] + ' ' + k.replace('_', ' '); }).join(', ') + '</span>' +
        '<div style="margin-top:4px">' + badge(ver + ' of ' + rows.length + ' entries verified', ver ? 'ok' : 'unv') + '</div>' + flag(ag) :
        '<div class="empty" style="margin-top:6px">No project records yet for this event.</div>';
      var unver = /UNVERIFIED|NOT VERIFIED/i.test((e.notes || '') + (e.description || ''));
      return '<div class="card ev' + (st.event === e.event_id ? ' active' : '') + '"><h3>' + esc(e.event_id) + ' \u00b7 ' + esc(e.event_date) + (unver ? ' ' + badge('unverified', 'unv') : '') + '</h3>' +
        '<div class="meta">' + esc(e.location) + '</div><p style="margin:6px 0">' + esc(e.description) + '</p>' + stats +
        (defs.length ? '<div class="note" style="font-size:.78rem;color:#5d6675;margin-top:6px"><b>What the MW means:</b> ' + esc(defs[0]) + '</div>' : '') +
        '<details><summary>Notes and evidence status</summary><p class="n" style="white-space:pre-wrap;font-size:.82rem">' + esc(e.notes || 'none') + '</p></details>' +
        '<div style="margin-top:6px"><button class="lnk" data-ev="' + esc(e.event_id) + '">Filter projects to this event</button></div></div>';
    }).join('');
    var h = '<div class="grid g2">' + evHtml + '</div>';

    /* ---- RDNA reference ---- */
    var rd = D.conflicts.filter(function (c) { return /^rdna_/.test(c.metric); });
    h += '<div style="margin-top:14px">' + App.card('Official assessment (RDNA, cut-off 3 Sep 2026): totals only',
      'Stated in the Rapid Damage and Needs Assessment, printed pp.89 to 92 (' + App.srcLink('SRC-015') + '). It gives no project names, so which projects it counted is not confirmed. ' + badge('stated in report', 'stated'),
      '<div class="tablewrap"><table><thead><tr><th>Item</th><th class="num">Projects</th><th class="num">MW</th></tr></thead><tbody>' +
      '<tr><td>Hydropower operating before the disaster</td><td class="num">7</td><td class="num">250.4</td></tr>' +
      '<tr><td>Hydropower under construction</td><td class="num">6</td><td class="num">508.625</td></tr>' +
      '<tr><td>Solar operating</td><td class="num">5</td><td class="num">24.36</td></tr>' +
      '<tr><td><b>Total assessed</b></td><td class="num"><b>18</b></td><td class="num"><b>783.385</b></td></tr></tbody></table></div>' +
      '<div style="margin-top:8px"><span class="stat"><b>NPR 13,469.76 crore</b> energy-sector damage (US$889.21 m)</span><span class="stat"><b>NPR 1,634.69 crore</b> reported losses (US$107.91 m)</span><span class="stat"><b>NPR 39,062.30 crore</b> recovery needs (US$2,578.71 m)</span></div>' +
      '<div class="warnbox">The RDNA loss figure (2,730.48 GWh a year) uses assumed generation and outage periods; it is not measured loss. 67% of the hydropower capacity assessed was still under construction, so it was not producing electricity.' +
      (rd.length ? ' Matching the RDNA totals to named projects here is arithmetic only: ' + rd.map(function (c) { return '<button class="lnk" data-cid="' + esc(c.conflict_id) + '">' + esc(c.conflict_id) + '</button>'; }).join(', ') + '.' : '') + '</div>') + '</div>';

    /* ---- project explorer ---- */
    function inScope(p) {
      if (st.phase !== 'all' && p.pre_flood_phase !== st.phase) return false;
      if (st.district !== 'all' && (p.district || '(not stated)') !== st.district) return false;
      if (st.event !== 'all' && !D.status_log.some(function (r) { return r.project_id === p.project_id && r.event_id === st.event; })) return false;
      return true;
    }
    var ps = D.projects.filter(inScope), evShow = st.event === 'all' ? ['EVT-002', 'EVT-004'] : [st.event];
    var maxMw = Math.max.apply(null, ps.map(function (p) { return p.capacity_mw; }).concat([1]));
    h += '<h3 style="margin:18px 0 6px">Projects</h3><div class="grid g4" style="margin-bottom:10px">' +
      '<div class="card kpi"><div class="label">Projects shown</div><div class="val">' + ps.length + '</div></div>' +
      '<div class="card kpi"><div class="label">Installed MW, projects shown</div><div class="val">' + App.mw(sum(ps.map(function (p) { return p.capacity_mw; }))) + '<span class="unit">MW</span></div><div class="note">Capacity as stored; a few values conflict between sources (see project notes).</div></div>' +
      evShow.map(function (eid) {
        var rows = D.status_log.filter(function (r) { return r.event_id === eid && ps.some(function (p) { return p.project_id === r.project_id; }); });
        if (!rows.length) return '';
        return '<div class="card kpi"><div class="label">' + esc(eid) + ' listed MW (shown projects)</div><div class="val">' + App.mw(K.eventListedMw(rows, eid).totalMw) + '<span class="unit">MW</span></div><div class="note">' + (eid === 'EVT-004' ? 'Licensed capacity of under-construction projects; no generation lost.' : 'List total from the 27 Aug 2026 ministry list; not verified damage.') + '</div>' + flag(K.eventListedMw(rows, eid)) + '</div>';
      }).join('') + '</div>';
    h += App.table([
      { h: 'Project', f: function (p) { return App.pLink(p.project_id) + '<div class="cap" style="font-size:.72rem;color:#5d6675">' + esc(p.project_id) + '</div>'; } },
      { h: 'Phase', f: function (p) { return phaseBadge(p.pre_flood_phase); } },
      { h: 'District', f: function (p) { return esc(p.district || 'not stated'); } },
      { h: 'Owner', f: function (p) { return esc(p.owner_type || 'unknown'); } },
      { h: 'Capacity MW', cls: 'num', f: function (p) { return fmt(p.capacity_mw, 2) + '<span class="ibar" style="width:' + Math.max(2, p.capacity_mw / maxMw * 100).toFixed(0) + '%"></span>'; } },
      { h: 'Listed in event (MW)', f: function (p) {
        return App.eventsOf(p.project_id).filter(function (e) { return st.event === 'all' || e === st.event; }).map(function (e) {
          var s = App.statusFor(p.project_id, e); return '<div>' + esc(e) + (s && s.affected_mw != null ? ': ' + App.mw(s.affected_mw) : '') + '</div>';
        }).join('') || '<span class="cap">not listed</span>'; } },
      { h: 'Condition reported', f: function (p) {
        return App.eventsOf(p.project_id).filter(function (e) { return st.event === 'all' || e === st.event; }).map(function (e) {
          var s = App.statusFor(p.project_id, e); if (!s) return ''; return '<div>' + condBadge(s.physical) + (s.evac !== 'unknown' ? condBadge('evac ' + s.evac) : '') + '</div>';
        }).join(''); } },
      { h: 'Verified', f: function (p) {
        var v = App.eventsOf(p.project_id).filter(function (e) { return st.event === 'all' || e === st.event; }).map(function (e) { return App.statusFor(p.project_id, e).verified; });
        return v.length ? badge(v.every(function (x) { return x === 'Yes'; }) ? 'Yes' : 'No', v.every(function (x) { return x === 'Yes'; }) ? 'ok' : 'unv') : ''; } }
    ], ps, { rowAttr: function (p) { return 'class="clickable" data-pid="' + esc(p.project_id) + '"'; } });
    h += '<p class="cap" style="margin-top:6px">Click a project for its status entries, evacuation links and full source notes. Conditions such as "destroyed" come from one secondary source and are unverified.</p>';
    root.innerHTML = h;
  });
})();
