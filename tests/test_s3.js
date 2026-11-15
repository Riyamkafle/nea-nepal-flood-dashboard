const test = require('node:test'), assert = require('node:assert'), fs = require('fs'), path = require('path');
const s = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 'data.js'), 'utf8');
const D = JSON.parse(s.slice(s.indexOf('{'), s.lastIndexOf('}') + 1));
const src = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 's3.js'), 'utf8');
test('s3: scenario totals by profile (basis A) match the stored rows', () => {
  const t = {};
  D.gap.forEach(r => { t[r.profile] = (t[r.profile] || 0) + r.not_generated_A_mwh / 1000; });
  assert.ok(Math.abs(t.optimistic - 228.6) < 0.1 && Math.abs(t.precedent - 326.5) < 0.1 && Math.abs(t.pessimistic - 518.8) < 0.1);
});
test('s3: file is built, registered, and states the limits', () => {
  assert.ok(!/not built yet/.test(src));
  assert.ok(/App\.register\('s3-body'/.test(src));
  assert.ok(/not measured loss/.test(src) && /2,730\.48/.test(src));
});
