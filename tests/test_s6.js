'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const rd = f => fs.readFileSync(path.join(__dirname, '..', 'dashboard', f), 'utf8');
test('index.html loads questions.js before s6.js and after calc.js', () => {
  const h = rd('index.html'), a = h.indexOf('calc.js'), b = h.indexOf('questions.js'), c = h.indexOf('s6.js');
  assert.ok(a > 0 && b > a && c > b);
});
test('s6.js uses the single source of truth and has the five required columns', () => {
  const s = rd('s6.js');
  assert.ok(s.includes('NEA_QUESTIONS') && s.includes('evaluateAll'));
  ['Research question', 'Status', 'Evidence available', 'Missing evidence', 'Next verification step'].forEach(c => assert.ok(s.includes("'" + c + "'"), c));
  assert.ok(s.includes('does not mean the information does not exist anywhere'));
});
