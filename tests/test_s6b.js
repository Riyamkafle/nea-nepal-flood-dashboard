'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const s = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 's6.js'), 'utf8');
test('s6.js has conflict register, status filter, sources table and verification summary', () => {
  ['Conflict register', 'id="c-status"', 'Verification summary', "h: 'Claim A'", "h: 'Claim B'", "h: 'Value used'"].forEach(x => assert.ok(s.includes(x), x));
});
test('s6.js no longer claims the register is not built, and does not mutate the data', () => {
  assert.ok(!s.includes('not built yet'));
  assert.ok(!/D\.(conflicts|sources|status_log)\.(push|splice|sort|pop|shift)\(/.test(s));
});
