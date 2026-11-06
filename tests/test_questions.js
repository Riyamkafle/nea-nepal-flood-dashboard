'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Q = require('../dashboard/questions.js');
const T = () => true, F = () => false;
const q = (cs, o) => Object.assign({ id: 'X', components: cs.map(h => ({ have: h })), conditional: false, needAll: false }, o || {});

test('all present and no assumption: Answered', () => assert.equal(Q.evaluate(q([T, T]), {}).status, 'Answered'));
test('all present but conditional: Conditional, never Answered', () => assert.equal(Q.evaluate(q([T, T], { conditional: true }), {}).status, 'Conditional'));
test('some missing: Partly answered', () => assert.equal(Q.evaluate(q([T, F]), {}).status, 'Partly answered'));
test('some missing and conditional: Conditional', () => assert.equal(Q.evaluate(q([T, F], { conditional: true }), {}).status, 'Conditional'));
test('nothing present: No data', () => assert.equal(Q.evaluate(q([F, F]), {}).status, 'No data'));
test('needAll with one input missing: No data', () => assert.equal(Q.evaluate(q([T, T, F], { needAll: true }), {}).status, 'No data'));
test('a check that throws counts as missing', () => assert.equal(Q.evaluate(q([T, () => { throw new Error('x'); }]), {}).status, 'Partly answered'));
test('empty or null dataset: six questions, all No data, no throw', () => {
  [{}, null].forEach(D => { const r = Q.evaluateAll(D); assert.equal(r.length, 6); r.forEach(x => assert.equal(x.status, 'No data', x.id)); });
});
test('a status is always one of the four allowed values and ids are RQ1..RQ6', () => {
  const r = Q.evaluateAll({});
  assert.deepEqual(r.map(x => x.id), ['RQ1', 'RQ2', 'RQ3', 'RQ4', 'RQ5', 'RQ6']);
  r.forEach(x => assert.ok(Q.STATUSES.includes(x.status)));
});
test('adding a table to the data changes the status (not hard-coded)', () => {
  const D = { available_capacity: [1], surplus: [1], line_limits: [1], trade: [{ fiscal_year: 2026, export_capacity_mw: 5 }] };
  assert.equal(Q.evaluateAll(D)[5].status, 'Partly answered' === 'x' ? '' : 'Answered');
});
const DATA = path.join(__dirname, '..', 'dashboard', 'data.js');
test('real data: coverage statuses (reads data.js only)', { skip: !fs.existsSync(DATA) }, () => {
  global.window = {}; require(DATA);
  const r = Q.evaluateAll(global.window.NEA_DATA), s = {}; r.forEach(x => { s[x.id] = x.status; console.log(x.id, x.status, '| known', x.known.length, 'missing', x.missing.length); });
  assert.equal(s.RQ6, 'No data');
  assert.equal(s.RQ3, 'Conditional');
  assert.ok(r.every(x => x.status !== 'Answered'));
});
