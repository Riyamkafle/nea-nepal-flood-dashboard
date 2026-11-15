const test = require('node:test'), assert = require('node:assert'), fs = require('fs'), path = require('path');
const s = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 'data.js'), 'utf8');
const D = JSON.parse(s.slice(s.indexOf('{'), s.lastIndexOf('}') + 1));
const src = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 's4.js'), 'utf8');
test('s4: FY2025/26 approved export capacity adds to 1,200.01 MW', () => {
  const t = D.trade.filter(r => r.fiscal_year === 2026 && r.export_capacity_mw != null).reduce((a, r) => a + r.export_capacity_mw, 0);
  assert.ok(Math.abs(t - 1200.01) < 0.005);
});
test('s4: Bangladesh has no volumes and India FY2025/26 export is not loaded', () => {
  assert.ok(D.trade.filter(r => r.country === 'Bangladesh').every(r => r.export_gwh == null && r.import_gwh == null));
  assert.ok(D.trade.filter(r => r.country === 'India' && r.fiscal_year === 2026).every(r => r.export_gwh == null));
});
test('s4: file is built, registered, and states the limits', () => {
  assert.ok(!/not built yet/.test(src));
  assert.ok(/App\.register\('s4-body'/.test(src));
  assert.ok(/permission, not flow/.test(src) && /No trade record exists after the flood/.test(src));
});
