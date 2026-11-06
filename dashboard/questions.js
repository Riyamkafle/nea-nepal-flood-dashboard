(function (root, factory) {
  var api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.NEA_QUESTIONS = api;
})(typeof window !== 'undefined' ? window : this, function () {
  'use strict';
  var STATUSES = ['Answered', 'Partly answered', 'Conditional', 'No data'];
  function rows(D, k) { return (D && D[k]) || []; }
  function filled(a, f) { return a.filter(function (r) { return r[f] != null && r[f] !== ''; }).length; }
  function fy(D, k, y) { return rows(D, k).filter(function (r) { return r.fiscal_year === y; }); }
  function table(k) { return function (D) { return rows(D, k).length > 0; }; }  // true only if the dataset contains such a table

  var QUESTIONS = [
    { id: 'RQ1', title: 'Pre-flood baseline',
      text: 'What were Nepal\u2019s pre-flood generation, demand, imports, exports, export revenue and dependence on particular projects, basins and transmission corridors?',
      conditional: false, needAll: false,
      components: [
        { name: 'National annual trade, peaks, losses', have: function (D) { var a = rows(D, 'annual'); return filled(a, 'export_gwh') > 0 && filled(a, 'import_gwh') > 0; },
          note: 'Annual exports, imports, peak demand and supply, losses, FY2019/20 to FY2025/26 (FY2025/26 provisional; export figure disputed).', gap: '' },
        { name: 'National generation FY2025/26', have: function (D) { var r = fy(D, 'annual', 2026)[0]; return !!r && r.nea_generation_gwh != null && r.total_production_gwh != null; },
          note: 'FY2025/26 national generation and production loaded.', gap: 'FY2025/26 NEA generation, purchases and production are not loaded (definitions unconfirmed).' },
        { name: 'Export revenue FY2025/26', have: function (D) { return filled(fy(D, 'trade', 2026), 'export_revenue_npr_million') > 0; },
          note: 'FY2025/26 export revenue loaded.', gap: 'FY2025/26 export revenue is not loaded; press and report figures differ.' },
        { name: 'Plant monthly output', have: table('monthly'),
          note: 'Monthly generation for three NEA plants on the Trishuli corridor (a limited sample, not national).', gap: '' },
        { name: 'Dependence on projects, basins, corridors', have: function (D) { return filled(rows(D, 'projects'), 'basin') > 0; },
          note: 'Basin recorded for projects.', gap: 'Basin is empty for all projects, and national project-level generation is missing, so dependence shares cannot be computed.' }
      ],
      next: 'Load FY2025/26 national generation once the report definitions are confirmed; fill basin from DoED; choose one comparison year for plant shares.' },

    { id: 'RQ2', title: 'Infrastructure damage',
      text: 'Which hydropower projects, transmission lines, substations and evacuation facilities were affected? What capacity was installed, operational, unavailable or unable to evacuate electricity?',
      conditional: false, needAll: false,
      components: [
        { name: 'Projects named as affected', have: table('status_log'),
          note: 'Projects named in event records (EVT-002 list, EVT-004 press reports). MW is listed or licensed capacity, not unavailable MW.', gap: '' },
        { name: 'Evacuation structure', have: table('evacuation'),
          note: 'Which lines and substations serve which plants (structure only, not damage).', gap: '' },
        { name: 'Verified damage', have: function (D) { return rows(D, 'status_log').some(function (r) { return r.verified === 'Yes'; }); },
          note: 'At least one verified damage entry.', gap: 'No damage entry is verified; all rest on press or a ministry list.' },
        { name: 'Available MW after the event', have: function (D) { return filled(rows(D, 'status_log'), 'available_mw') > 0; },
          note: 'Available MW recorded.', gap: 'Available MW is empty in every status row, so unavailable MW cannot be stated.' },
        { name: 'Line or substation damage or evacuation status', have: function (D) { return rows(D, 'status_log').some(function (r) { return r.evacuation_status && r.evacuation_status !== 'unknown'; }); },
          note: 'Evacuation status recorded for some projects.', gap: 'No record says which lines or substations were damaged, or which plants could generate but not deliver.' }
      ],
      next: 'Find the project-level RDNA or PDNA list and an NEA or ministry statement on lines, substations and plant status.' },

    { id: 'RQ3', title: 'Actual and potential energy loss',
      text: 'What observed generation decline can be established? What potential generation loss can be estimated under explicit assumptions? Can losses from generating facilities be distinguished from evacuation constraints?',
      conditional: true, needAll: false,
      components: [
        { name: 'Observed post-flood generation', have: function (D) { return rows(D, 'monthly').some(function (r) { return r.fiscal_year >= 2027; }) || table('post_flood_generation')(D); },
          note: 'Post-flood generation observations present.', gap: 'No observed generation after 26 Aug 2026; the FY2025/26 report ends before the flood.' },
        { name: 'Historical comparison (pre-flood)', have: table('monthly_baseline'),
          note: 'FY2025/26 against earlier years for three plants. Historical comparison, not flood-attributed loss.', gap: '' },
        { name: 'Scenario estimate of GWh not generated', have: table('gap'),
          note: 'Conditional scenarios assuming the plants were out from 26 Aug 2026 (status \u201cdestroyed\u201d rests on one unverified press source).', gap: '' },
        { name: 'Generation loss separated from evacuation loss', have: table('evacuation_loss'),
          note: '', gap: 'No data separates plant loss from evacuation loss.' }
      ],
      next: 'Obtain post-flood plant output (NEA, Load Dispatch Centre) and a plant-level outage list.' },

    { id: 'RQ4', title: 'Electricity trade',
      text: 'What do the available records show about imports, exports, net trade and export revenue? What is known about India and Bangladesh, and what constraints may limit actual exports?',
      conditional: false, needAll: false,
      components: [
        { name: 'Annual imports, exports, net', have: function (D) { return filled(rows(D, 'annual'), 'net_export_gwh') > 0; },
          note: 'Annual imports, exports and net export (FY2025/26 provisional; export figure disputed).', gap: '' },
        { name: 'Approved export quantum by country', have: function (D) { return filled(fy(D, 'trade', 2026), 'export_capacity_mw') > 0; },
          note: 'FY2025/26 approved MW for India and Bangladesh. Approved capacity is not actual exports.', gap: '' },
        { name: 'Monthly or country flows', have: table('trade_monthly'),
          note: 'Monthly trade flows present.', gap: 'No monthly trade table; India and Bangladesh actual GWh are not in the dataset.' },
        { name: 'Post-flood trade', have: function (D) { return rows(D, 'trade').some(function (r) { return r.fiscal_year >= 2027 && r.export_gwh != null; }); },
          note: 'Post-flood trade present.', gap: 'No trade record after the flood.' }
      ],
      next: 'Request monthly import, export and revenue data by country from NEA (probably an RTI request).' },

    { id: 'RQ5', title: 'Recovery',
      text: 'What must be restored across generation, transmission, evacuation and related infrastructure? Which bottlenecks are supported by evidence, and which remain unknown?',
      conditional: false, needAll: false,
      components: [
        { name: 'Restoration precedent', have: function (D) { return rows(D, 'events').some(function (e) { return e.event_id === 'EVT-001' && /resum|restor/i.test(e.notes || ''); }); },
          note: 'EVT-001 (8 Jul 2025): Rasuwagadhi units resumed in stages (precedent, not a forecast).', gap: '' },
        { name: 'Official recovery needs', have: function (D) { return rows(D, 'conflicts').some(function (c) { return /^rdna_/.test(c.metric); }); },
          note: 'RDNA totals by category, damage, losses and recovery needs (no project names).', gap: '' },
        { name: 'Project-level restoration status', have: function (D) { return rows(D, 'status_log').some(function (r) { return r.restoration_status && r.restoration_status !== 'unknown'; }); },
          note: 'Restoration status recorded for some projects.', gap: 'No project has a recorded restoration status or date for EVT-002 or EVT-004.' },
        { name: 'Evidence for the binding bottleneck', have: table('bottleneck_evidence'),
          note: '', gap: 'No evidence identifies whether generation, evacuation, lines or approvals limit recovery.' }
      ],
      next: 'Find restoration statements for plants and the Bhotekoshi and Trishuli corridor lines; track NEA and ministry updates.' },

    { id: 'RQ6', title: 'Exportable electricity',
      text: 'How much electricity could actually be exported after accounting for available generation, domestic demand and surplus, transmission capacity, and applicable export approvals?',
      conditional: false, needAll: true,
      components: [
        { name: 'Available generation', have: table('available_capacity'), note: '', gap: 'No post-flood available generation or capacity.' },
        { name: 'Domestic demand and actual surplus', have: table('surplus'), note: '', gap: 'No surplus series. Peak supply minus peak demand is not a surplus.' },
        { name: 'Transmission and evacuation capacity', have: table('line_limits'), note: '', gap: 'Interim cross-border line limits are in the report text, not as data; domestic evacuation capacity is missing.' },
        { name: 'Export approvals', have: function (D) { return filled(fy(D, 'trade', 2026), 'export_capacity_mw') > 0; },
          note: 'FY2025/26 approved quantum (not actual exports).', gap: '' }
      ],
      next: 'Do not compute a figure until all four inputs exist for the same period; start with post-flood available generation and monthly trade.' }
  ];

  function evaluate(q, D) {
    var known = [], missing = [], status;
    q.components.forEach(function (c) { var ok = false; try { ok = !!c.have(D); } catch (e) { ok = false; } (ok ? known : missing).push(c); });
    if (!known.length) status = 'No data';
    else if (q.needAll && missing.length) status = 'No data';
    else if (missing.length) status = q.conditional ? 'Conditional' : 'Partly answered';
    else status = q.conditional ? 'Conditional' : 'Answered';
    return { id: q.id, title: q.title, text: q.text, next: q.next, status: status, known: known, missing: missing };
  }
  function evaluateAll(D) { return QUESTIONS.map(function (q) { return evaluate(q, D); }); }
  return { STATUSES: STATUSES, QUESTIONS: QUESTIONS, evaluate: evaluate, evaluateAll: evaluateAll };
});
