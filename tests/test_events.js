'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const C = require('../dashboard/calc.js');
const dash = f => path.join(__dirname, '..', 'dashboard', f);
const rd = f => fs.readFileSync(dash(f), 'utf8');
const row = (e, p, mw) => ({ event_id: e, project_id: p, affected_mw: mw });

test('missing MW is not zero: unlisted project is reported, total not inflated', () => {
  const r = C.eventListedMw([row('E', 'P1', null), row('E', 'P2', 10)], 'E');
  assert.equal(r.totalMw, 10); assert.equal(r.listedProjects, 1); assert.deepEqual(r.unlisted, ['P1']); assert.equal(r.complete, true);
});
test('three different values for one project: flagged, none used', () => {
  const r = C.eventListedMw([row('E', 'P', 1), row('E', 'P', 2), row('E', 'P', 3), row('E', 'Q', 5)], 'E');
  assert.deepEqual(r.conflicts, [{ project_id: 'P', values: [1, 2, 3] }]); assert.equal(r.totalMw, 5); assert.equal(r.complete, false);
});
test('identical duplicate rows count once', () => {
  const r = C.eventListedMw([row('E', 'P', 7), row('E', 'P', 7), row('E', 'P', null)], 'E');
  assert.equal(r.totalMw, 7); assert.equal(r.multiRowProjects[0].rows, 3); assert.equal(r.complete, true);
});
test('empty or unknown event: zero projects, no throw', () => {
  const r = C.eventListedMw([row('E', 'P', 7)], 'NOPE');
  assert.equal(r.projects, 0); assert.equal(r.listedProjects, 0); assert.equal(r.totalMw, 0);
});
test('events are never combined', () => {
  const S = [row('E1', 'P', 10), row('E2', 'P', 99), row('E2', 'Q', 1)];
  assert.equal(C.eventListedMw(S, 'E1').totalMw, 10); assert.equal(C.eventListedMw(S, 'E2').totalMw, 100);
});
test('s2.js uses the project-level aggregation and shows the conflict flag', () => {
  const s2 = rd('s2.js');
  assert.ok(s2.includes('eventListedMw'));
  assert.ok(!/sum\(rows\.map\(function \(r\) \{ return r\.affected_mw; \}\)\)/.test(s2), 'old row-sum still present');
  assert.ok(s2.includes('Total needs review'));
});
test('first-load baseline default is all_excl and not set by state', () => {
  assert.ok(rd('s1.js').includes("st.base || 'all_excl'"));
  const m = rd('core.js').match(/App\.state = \{[^}]*\}/);
  assert.ok(m && !/base/.test(m[0]));
});
test('generation warning keeps EVT-002 sentence and adds EVT-001 as context only', () => {
  const s1 = rd('s1.js');
  assert.ok(s1.includes('ended before EVT-002 on 26 Aug 2026'));
  assert.ok(s1.includes('aftermath of EVT-001 (8 Jul 2025)'));
  assert.ok(s1.includes('does not show that EVT-001 caused any decline'));
  assert.ok(s1.includes('Historical comparison, not flood-attributed loss'));
});
test('real data: stored event totals, no conflicts (reads data.js only)', { skip: !fs.existsSync(dash('data.js')) }, () => {
  global.window = {}; require(dash('data.js'));
  const D = global.window.NEA_DATA;
  [['EVT-002', 431.1, 12], ['EVT-004', 412.09, 4]].forEach(([e, mw, n]) => {
    const r = C.eventListedMw(D.status_log, e);
    assert.equal(r.totalMw, mw); assert.equal(r.projects, n); assert.deepEqual(r.conflicts, []); assert.equal(r.complete, true);
  });
});
