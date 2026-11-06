(function (root, factory) {
  var api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.NEA_CALC = api;
})(typeof window !== 'undefined' ? window : this, function () {
  'use strict';
  var LOW_RULE = 0.5; // same rule as scripts/13: flagged if below 50% of the median of the other years

  function isNum(v) { return v != null && v !== '' && !isNaN(Number(v)); }
  function median(a) {
    var s = (a || []).filter(isNum).map(Number).sort(function (x, y) { return x - y; }), n = s.length;
    if (!n) return null;
    return n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2;
  }
  // (observed / reference - 1) x 100; null when either input is missing or the reference is 0
  function pctDiff(obs, ref) {
    if (!isNum(obs) || !isNum(ref) || Number(ref) === 0) return null;
    return (Number(obs) / Number(ref) - 1) * 100;
  }
  // rows: {plant, fiscal_year, fiscal_month_no, generation_mwh}  ->  M[plant][fy][month] = MWh
  function index(rows) {
    var M = {};
    (rows || []).forEach(function (r) {
      if (!isNum(r.generation_mwh)) return;
      var p = M[r.plant] = M[r.plant] || {};
      var y = p[r.fiscal_year] = p[r.fiscal_year] || {};
      y[r.fiscal_month_no] = Number(r.generation_mwh);
    });
    return M;
  }
  function yearsOf(M, plant) { return Object.keys(M[plant] || {}).map(Number).sort(function (a, b) { return a - b; }); }

  function isFlagged(M, plant, fy, m, refYears) {
    var v = M[plant] && M[plant][fy] && M[plant][fy][m];
    if (!isNum(v)) return false;
    var others = (refYears || yearsOf(M, plant)).filter(function (y) { return y !== fy && M[plant][y] && isNum(M[plant][y][m]); })
      .map(function (y) { return M[plant][y][m]; });
    if (!others.length) return false;
    return Number(v) < LOW_RULE * median(others);
  }
  // 12 entries (fiscal months 1..12): clean-month count, low, median (base), high, in MWh
  function baseline(M, plant, years, refYears) {
    var out = [];
    for (var m = 1; m <= 12; m++) {
      var vals = [];
      (years || []).forEach(function (y) {
        var v = M[plant] && M[plant][y] && M[plant][y][m];
        if (isNum(v) && !isFlagged(M, plant, y, m, refYears)) vals.push(Number(v));
      });
      out.push({ m: m, n: vals.length, low: vals.length ? Math.min.apply(null, vals) : null, base: median(vals), high: vals.length ? Math.max.apply(null, vals) : null });
    }
    return out;
  }
  function pack(o, s, n, thin) {
    return { obsGwh: o / 1000, baseGwh: s / 1000, diffGwh: (o - s) / 1000, pct: n ? pctDiff(o, s) : null, months: n, thinMonths: thin };
  }
  // Observed year vs baseline. Combined uses only months where EVERY plant has an observation and a baseline.
  function compare(M, plants, obsFy, years, refYears) {
    var b = {}, res = { plants: {}, combined: null }, m;
    plants.forEach(function (p) { b[p] = baseline(M, p, years, refYears); });
    function ok(p, mm) { var o = M[p] && M[p][obsFy] && M[p][obsFy][mm]; return isNum(o) && b[p][mm - 1].base != null; }
    plants.forEach(function (p) {
      var o = 0, s = 0, n = 0, thin = 0;
      for (m = 1; m <= 12; m++) {
        if (!ok(p, m)) continue;
        o += M[p][obsFy][m]; s += b[p][m - 1].base; n++; if (b[p][m - 1].n < 3) thin++;
      }
      res.plants[p] = pack(o, s, n, thin);
    });
    var O = 0, S = 0, N = 0, T = 0;
    for (m = 1; m <= 12; m++) {
      if (!plants.length || !plants.every(function (p) { return ok(p, m); })) continue;
      var anyThin = false;
      plants.forEach(function (p) { O += M[p][obsFy][m]; S += b[p][m - 1].base; if (b[p][m - 1].n < 3) anyThin = true; });
      N++; if (anyThin) T++;
    }
    res.combined = pack(O, S, N, T);
    return res;
  }
  // The four baseline choices. allYears = fiscal years that have monthly tables.
  function scenarios(allYears, compareFy) {
    var recent = (allYears || []).slice(-3);
    function no(a) { return a.filter(function (y) { return y !== compareFy; }); }
    return [
      { id: 'recent_incl', label: 'Last three years with monthly tables, including the compared year (existing method)', years: recent },
      { id: 'recent_excl', label: 'Last three years with monthly tables, excluding the compared year (two years: thin)', years: no(recent) },
      { id: 'all_incl', label: 'All years with monthly tables, including the compared year', years: allYears || [] },
      { id: 'all_excl', label: 'All years with monthly tables, excluding the compared year', years: no(allYears || []) }
    ];
  }
  // Listed MW for ONE event, one value per project. Never combines events.
  // Several rows for a project: nulls are ignored, identical values count once,
  // different non-null values are flagged as a conflict and left out of the total.
  function eventListedMw(statusRows, eventId) {
    var by = {}, order = [];
    (statusRows || []).forEach(function (r) {
      if (r.event_id !== eventId) return;
      var p = by[r.project_id];
      if (!p) { p = by[r.project_id] = { rows: 0, vals: [] }; order.push(r.project_id); }
      p.rows++;
      if (isNum(r.affected_mw)) p.vals.push(Number(r.affected_mw));
    });
    var total = 0, listed = 0, conflicts = [], multi = [], unlisted = [];
    order.forEach(function (id) {
      var p = by[id], d = [];
      p.vals.forEach(function (v) { if (d.indexOf(v) < 0) d.push(v); });
      if (p.rows > 1) multi.push({ project_id: id, rows: p.rows });
      if (d.length === 0) unlisted.push(id);
      else if (d.length === 1) { total += d[0]; listed++; }
      else conflicts.push({ project_id: id, values: d });
    });
    return { event_id: eventId, projects: order.length, listedProjects: listed, totalMw: Math.round(total * 100) / 100,
      unlisted: unlisted, conflicts: conflicts, multiRowProjects: multi, complete: conflicts.length === 0 };
  }
  return { LOW_RULE: LOW_RULE, isNum: isNum, median: median, pctDiff: pctDiff, index: index, yearsOf: yearsOf,
    isFlagged: isFlagged, baseline: baseline, compare: compare, scenarios: scenarios, eventListedMw: eventListedMw };
});
