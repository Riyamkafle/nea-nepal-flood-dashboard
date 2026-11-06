'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const s = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 's5.js'), 'utf8');
test('s5.js reuses the RQ6 components from questions.js', () => {
  assert.ok(s.includes('NEA_QUESTIONS') && s.includes("'RQ6'") && s.includes('Q.evaluate('));
});
test('s5.js carries the required warnings and states exportable power is not computed', () => {
  ['Peak supply minus peak demand is not a valid surplus', 'not additive', 'Approved export capacity is not actual exports', 'Exportable power: not computed', 'No data in current dataset'].forEach(x => assert.ok(s.includes(x), x));
});
test('s5.js does not compute an exportable figure or add limits to approvals', () => {
  assert.ok(!/Math\.(min|max)\(/.test(s));
  assert.ok(!/LIMITS\.(reduce|map)\([^)]*\)\s*\+/.test(s));
  assert.ok(!/sum\(\s*LIMITS/.test(s));
});
test('s5.js: statuses come from the checks, no stale Section 3 sentence', () => {
  assert.ok(!s.includes('not built yet'));
  assert.ok(!s.includes('c.i.word') && !s.includes('c.i.kind'));
  assert.ok(s.includes("c.have ? (c.name === 'Export approvals'"));
});
test('s5.js cites the report pages for the line limits and keeps the values', () => {
  assert.ok(s.includes('PDF pp.15 and 109'));
  assert.ok(!s.includes('stated in report text, page to confirm'));
  assert.ok(!s.includes('Report page to confirm'), 'old demand-note caveat must be gone now that 12,394 is located');
  assert.ok(s.includes('12,394 GWh') && s.includes('C-022') && s.includes('PDF pp.149 and 158'), 'demand note must cite 12,394, C-022 and its pages');
  assert.ok(/exp: 200, imp: 130/.test(s) && /exp: 1650, imp: 1400/.test(s));
});
