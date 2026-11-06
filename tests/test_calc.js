'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const C = require('../dashboard/calc.js');
const k = 1000;
const near = (a, b, t) => assert.ok(Math.abs(a - b) <= (t || 0.01), a + ' vs ' + b);
const rows = (plant, fy, by) => Object.keys(by).map(m => ({ plant, fiscal_year: fy, fiscal_month_no: Number(m), generation_mwh: by[m] }));
const FIX = [].concat(
  rows('A', 2024, { 1: 100 * k, 2: 100 * k }), rows('A', 2025, { 1: 120 * k, 2: 100 * k }), rows('A', 2026, { 1: 80 * k, 2: 90 * k }),
  rows('B', 2024, { 1: 50 * k }), rows('B', 2025, { 1: 70 * k }), rows('B', 2026, { 1: 40 * k }));

test('pctDiff: normal, zero reference, missing inputs', () => {
  near(C.pctDiff(90, 100), -10);
  near(C.pctDiff(110, 100), 10);
  assert.equal(C.pctDiff(5, 0), null);
  assert.equal(C.pctDiff(null, 100), null);
  assert.equal(C.pctDiff('', 100), null);
  assert.equal(C.pctDiff(5, undefined), null);
});

test('baseline including vs excluding the compared year', () => {
  const M = C.index(FIX);
  assert.equal(C.baseline(M, 'A', [2024, 2025, 2026])[0].base, 100 * k);
  assert.equal(C.baseline(M, 'A', [2024, 2025])[0].base, 110 * k);
  assert.equal(C.baseline(M, 'A', [2024, 2025])[0].n, 2);
});

test('a month far below the other years is flagged and left out of the baseline', () => {
  const M = C.index([].concat(rows('F', 2024, { 1: 100 * k }), rows('F', 2025, { 1: 120 * k }), rows('F', 2026, { 1: 10 * k })));
  assert.equal(C.isFlagged(M, 'F', 2026, 1), true);
  assert.equal(C.isFlagged(M, 'F', 2024, 1), false);
  const b = C.baseline(M, 'F', [2024, 2025, 2026])[0];
  assert.equal(b.n, 2);
  assert.equal(b.base, 110 * k);
});

test('compare: per plant and combined (common months only)', () => {
  const M = C.index(FIX);
  const r = C.compare(M, ['A', 'B'], 2026, [2024, 2025]);
  assert.equal(r.plants.A.months, 2);
  near(r.plants.A.obsGwh, 170); near(r.plants.A.baseGwh, 210); near(r.plants.A.pct, -19.05);
  assert.equal(r.plants.B.months, 1);
  near(r.plants.B.pct, -33.33);
  assert.equal(r.combined.months, 1);            // B has no month 2, so month 2 is dropped for everyone
  near(r.combined.obsGwh, 120); near(r.combined.baseGwh, 170);
  near(r.combined.diffGwh, -50); near(r.combined.pct, -29.41);
  assert.equal(r.combined.thinMonths, 1);        // only 2 clean years
});

test('missing or null inputs do not throw and give null, not zero', () => {
  const e = C.compare(C.index([]), [], 2026, [2024]);
  assert.equal(e.combined.pct, null);
  const n = C.compare(C.index(null), ['Z'], 2026, [2024, 2025]);
  assert.equal(n.plants.Z.pct, null);
  assert.equal(n.plants.Z.months, 0);
  const M = C.index([{ plant: 'A', fiscal_year: 2026, fiscal_month_no: 1, generation_mwh: null }]);
  assert.equal(Object.keys(M).length, 0);
});

test('scenarios: four baselines, compared year excluded where stated', () => {
  const s = C.scenarios([2020, 2021, 2022, 2024, 2025, 2026], 2026);
  assert.deepEqual(s.map(x => x.id), ['recent_incl', 'recent_excl', 'all_incl', 'all_excl']);
  assert.deepEqual(s[0].years, [2024, 2025, 2026]);
  assert.deepEqual(s[1].years, [2024, 2025]);
  assert.equal(s[2].years.length, 6);
  assert.equal(s[3].years.length, 5);
  assert.ok(!s[3].years.includes(2026));
});

test('event MW: one value per project, conflicts flagged, events never combined', () => {
  const S = [
    { event_id: 'E1', project_id: 'P1', affected_mw: 22.0 }, { event_id: 'E1', project_id: 'P1', affected_mw: null },
    { event_id: 'E1', project_id: 'P2', affected_mw: 10 },   { event_id: 'E1', project_id: 'P2', affected_mw: 10 },
    { event_id: 'E1', project_id: 'P3', affected_mw: 5 },    { event_id: 'E1', project_id: 'P3', affected_mw: 6 },
    { event_id: 'E1', project_id: 'P4', affected_mw: null },
    { event_id: 'E2', project_id: 'P1', affected_mw: 100 }
  ];
  const r = C.eventListedMw(S, 'E1');
  assert.equal(r.totalMw, 32);
  assert.equal(r.projects, 4);
  assert.equal(r.listedProjects, 2);
  assert.deepEqual(r.conflicts, [{ project_id: 'P3', values: [5, 6] }]);
  assert.deepEqual(r.unlisted, ['P4']);
  assert.equal(r.complete, false);
  assert.equal(C.eventListedMw(S, 'E2').totalMw, 100);   // E2 is separate
  assert.equal(C.eventListedMw(null, 'E1').totalMw, 0);
});

const DATA = path.join(__dirname, '..', 'dashboard', 'data.js');
test('data check: stored recent3 baseline is reproduced from the monthly rows (reads data.js only)', { skip: !fs.existsSync(DATA) }, () => {
  global.window = {};
  require(DATA);
  const D = global.window.NEA_DATA, M = C.index(D.monthly);
  Object.keys(M).forEach(p => {
    const yrs = C.yearsOf(M, p).slice(-3), b = C.baseline(M, p, yrs);
    const stored = D.monthly_baseline.filter(r => r.plant === p && r.window === 'recent3');
    assert.equal(stored.length, 12, p + ' stored months');
    stored.forEach(r => {
      near((b[r.fiscal_month_no - 1].base || 0), (r.base_mwh || 0), 0.5);
      assert.equal(b[r.fiscal_month_no - 1].n, r.n_clean_years, p + ' month ' + r.fiscal_month_no + ' clean-year count');
    });
  });
});
