'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const txt = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 'data.js'), 'utf8');
const D = JSON.parse(txt.replace(/^window\.NEA_DATA = /, '').replace(/;\s*$/, ''));
const C = D.rdna_claims;
const r2 = x => Math.round(x * 100) / 100;
const val = id => Number(C.find(r => r.claim_id === id).value);
const COLS = ['claim_id','source_id','event_id','category','item','value','unit','evidence_type','report_ref','pdf_page','printed_page','also_in','definition_note','located_in_source','verified'];
const EXP = {
  'RDNA-01': [13469.76, 'NPR crore', 'estimated', 52, 92], 'RDNA-02': [11995.56, 'NPR crore', 'estimated', 52, 92],
  'RDNA-03': [472.5, 'NPR crore', 'estimated', 52, 92], 'RDNA-04': [346.95, 'NPR crore', 'estimated', 52, 92],
  'RDNA-05': [337.5, 'NPR crore', 'estimated', 52, 92], 'RDNA-06': [162, 'NPR crore', 'estimated', 52, 92],
  'RDNA-07': [155.25, 'NPR crore', 'estimated', 52, 92], 'RDNA-08': [1634.69, 'NPR crore', 'estimated', 52, 92],
  'RDNA-09': [1482, 'NPR crore', 'estimated', 52, 92], 'RDNA-10': [123.84, 'NPR crore', 'estimated', 52, 92],
  'RDNA-11': [28.85, 'NPR crore', 'estimated', 52, 92], 'RDNA-12': [2730.48, 'GWh/year', 'estimated', 52, 92],
  'RDNA-13': [2520, 'GWh/year', 'estimated', 52, 92], 'RDNA-14': [210.48, 'GWh/year', 'estimated', 52, 92],
  'RDNA-15': [39062.3, 'NPR crore', 'estimated', 52, 93], 'RDNA-16': [105, 'NPR crore', 'estimated', 52, 93],
  'RDNA-17': [38957.3, 'NPR crore', 'estimated', 52, 93], 'RDNA-18': [759.025, 'MW', 'reported', 51, 91],
  'RDNA-19': [250.4, 'MW', 'reported', 51, 91], 'RDNA-20': [508.625, 'MW', 'reported', 51, 91],
  'RDNA-21': [24.36, 'MW', 'reported', 51, 91]
};
test('rdna_claims: 21 unique claims with the 15 approved columns', () => {
  assert.equal(C.length, 21);
  assert.equal(new Set(C.map(r => r.claim_id)).size, 21);
  C.forEach(r => assert.deepEqual(Object.keys(r).sort(), COLS.slice().sort()));
});
test('rdna_claims: fixed values, SRC-023 is a Primary source, EVT-002 only', () => {
  C.forEach(r => { assert.equal(r.source_id, 'SRC-023'); assert.equal(r.event_id, 'EVT-002'); assert.equal(r.located_in_source, 'Yes'); assert.equal(r.verified, 'No'); });
  const s = D.sources.find(x => x.source_id === 'SRC-023');
  assert.ok(s && s.source_type === 'Primary');
  assert.ok(D.events.some(e => e.event_id === 'EVT-002'));
});
test('rdna_claims: values, units, evidence types and pages match the approved inventory', () => {
  Object.keys(EXP).forEach(id => {
    const r = C.find(x => x.claim_id === id), e = EXP[id];
    assert.ok(r, id);
    assert.equal(Number(r.value), e[0], id + ' value'); assert.equal(r.unit, e[1], id + ' unit');
    assert.equal(r.evidence_type, e[2], id + ' type'); assert.equal(Number(r.pdf_page), e[3], id + ' pdf'); assert.equal(Number(r.printed_page), e[4], id + ' printed');
  });
  assert.equal(r2(['02','03','04','05','06','07'].reduce((a, n) => a + val('RDNA-' + n), 0)), val('RDNA-01'));
  assert.equal(r2(val('RDNA-09') + val('RDNA-10') + val('RDNA-11')), val('RDNA-08'));
  assert.equal(r2(val('RDNA-13') + val('RDNA-14')), val('RDNA-12'));
  assert.equal(r2(val('RDNA-16') + val('RDNA-17')), val('RDNA-15'));
  assert.equal(Math.round((val('RDNA-19') + val('RDNA-20')) * 1000) / 1000, val('RDNA-18'));
});
test('rdna_claims: no analyst-derived figures stored, estimates carry an analyst caveat', () => {
  C.forEach(r => {
    const all = [r.value, r.definition_note, r.also_in, r.item].join(' ');
    ['2,193', '2193', '5.88', '98.2', '2.90'].forEach(x => assert.ok(!all.includes(x), r.claim_id + ' contains ' + x));
    assert.ok(String(r.definition_note).includes('Analyst note'), r.claim_id + ' needs an analyst note');
  });
});
test('s5.js RDNA card reads the claims table and keeps the warnings and the exportability panel', () => {
  const s5 = fs.readFileSync(path.join(__dirname, '..', 'dashboard', 's5.js'), 'utf8');
  ['D.rdna_claims', 'RDNA energy-sector estimates', 'Assessment estimates, not observed losses', 'Not independently verified', 'Locating a figure in the report does not verify it', 'not additive'].forEach(x => assert.ok(s5.includes(x), x));
  ['Exportable power: not computed', "'RQ6'", 'Q.evaluate('].forEach(x => assert.ok(s5.includes(x), x));
  ['2,193', '5.88', '98.2%'].forEach(x => assert.ok(!s5.includes(x), 'derived figure in s5.js: ' + x));
});
