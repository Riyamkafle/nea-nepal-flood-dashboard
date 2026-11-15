(function () {
  'use strict';
  var App = window.App, D = App.D;
  var IC = {
    home: '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
    chart: '<path d="M12 20V10M18 20V4M6 20v-4"/>',
    wave: '<path d="M2 8c2.5 0 2.5-2 5-2s2.5 2 5 2 2.5-2 5-2 2.500 2 5 2M2 15c2.5 0 2.5-2 5-2s2.5 2 5 2 2.5-2 5-2 2.5 2 5 2"/>',
    zap: '<path d="M13 2 3 14h9l-1 8 10-12h-9z"/>',
    swap: '<path d="M8 3 4 7l4 4M4 7h16M16 21l4-4-4-4M20 17H4"/>',
    cycle: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8M3 3v5h5"/>',
    file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M16 13H8M16 17H8"/>',
    db: '<ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5v14c0 1.7 4 3 9 3s9-1.3 9-3V5M3 12c0 1.7 4 3 9 3s9-1.3 9-3"/>',
    book: '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2zM22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>',
    down: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>'
  };
  var PAGES = [
    { id: 'overview', n: 1, label: 'Overview', icon: 'home', group: 'Overview' },
    { id: 'baseline', n: 2, label: 'Pre-flood electricity baseline', icon: 'chart' },
    { id: 'flood', n: 3, label: 'Flood events and damage', icon: 'wave' },
    { id: 'grid', n: 4, label: 'Generation and grid impact', icon: 'zap' },
    { id: 'trade', n: 5, label: 'Electricity trade', icon: 'swap' },
    { id: 'recovery', n: 6, label: 'Recovery and export capacity', icon: 'cycle' },
    { id: 'paper', n: 7, label: 'Research paper', icon: 'file', group: 'Research' },
    { id: 'sources', n: 8, label: 'Sources and evidence', icon: 'db', group: 'Data and documentation' },
    { id: 'method', n: 9, label: 'Methodology', icon: 'book' },
    { id: 'downloads', n: 10, label: 'Data downloads', icon: 'down' }
  ];
  var OLD = { s1: 'baseline', s2: 'flood', s3: 'grid', s4: 'trade', s5: 'recovery', s6: 'sources' };
  var nav = document.getElementById('side-nav'), h = '';
  PAGES.forEach(function (p) {
    if (p.group) h += '<div class="grp">' + p.group + '</div>';
    h += '<a href="#' + p.id + '" data-page="' + p.id + '"><svg class="ic" viewBox="0 0 24 24" aria-hidden="true">' + IC[p.icon] + '</svg><span class="lbl">' + p.n + '. ' + p.label + '</span></a>';
  });
  nav.innerHTML = h;
  var m = '';
  (D.sources || []).forEach(function (s) { if (s.snapshot_date && String(s.snapshot_date) > m) m = String(s.snapshot_date); });
  document.getElementById('stamp').textContent = m ? 'Latest source snapshot: ' + m : '';
  function show(id, draw) {
    if (!document.getElementById('page-' + id)) id = 'overview';
    PAGES.forEach(function (p) { document.getElementById('page-' + p.id).classList.toggle('on', p.id === id); });
    Array.prototype.forEach.call(nav.querySelectorAll('a'), function (a) {
      if (a.getAttribute('data-page') === id) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
    });
    document.title = PAGES.filter(function (p) { return p.id === id; })[0].label + ' | Nepal Electricity and Flood Research Dashboard';
    document.body.classList.remove('side-open');
    if (draw) App.render();
    window.scrollTo(0, 0);
  }
  function fromHash() { var k = (location.hash || '').replace('#', ''); return OLD[k] || k || 'overview'; }
  window.addEventListener('hashchange', function () { show(fromHash(), true); });
  document.getElementById('side-toggle').addEventListener('click', function () { document.body.classList.toggle('side-collapsed'); });
  document.getElementById('menu-btn').addEventListener('click', function () { document.body.classList.toggle('side-open'); });
  show(fromHash(), false);
})();
