(function () {
  'use strict';
  var App = window.App, esc = App.esc;
  var W = 640, H = 300, M = { l: 58, r: 14, t: 12, b: 40 };

  function niceTicks(lo, hi, n) {
    if (hi === lo) { hi = lo + 1; }
    var raw = (hi - lo) / (n || 5), mag = Math.pow(10, Math.floor(Math.log(raw) / Math.LN10)), r = raw / mag;
    var step = (r <= 1 ? 1 : r <= 2 ? 2 : r <= 5 ? 5 : 10) * mag;
    var a = Math.floor(lo / step) * step, b = Math.ceil(hi / step) * step, t = [];
    for (var v = a; v <= b + step / 2; v += step) t.push(Math.round(v / step) * step);
    return t;
  }
  function isNum(v) { return v != null && v !== '' && !isNaN(Number(v)); }

  function frame(o, lo, hi, nCat) {
    var ticks = niceTicks(lo, hi, 5), y0 = ticks[0], y1 = ticks[ticks.length - 1];
    var iw = W - M.l - M.r, ih = H - M.t - M.b;
    var f = {
      ticks: ticks, iw: iw, ih: ih,
      y: function (v) { return M.t + ih - (v - y0) / (y1 - y0) * ih; },
      band: iw / Math.max(nCat, 1)
    };
    var s = '<svg viewBox="0 0 ' + W + ' ' + H + '" width="100%" role="img" aria-label="' + esc(o.title || 'chart') + '" style="max-width:100%;height:auto">';
    ticks.forEach(function (t) {
      s += '<line x1="' + M.l + '" x2="' + (W - M.r) + '" y1="' + f.y(t).toFixed(1) + '" y2="' + f.y(t).toFixed(1) + '" stroke="#e3e7ee"/>' +
        '<text x="' + (M.l - 6) + '" y="' + (f.y(t) + 4).toFixed(1) + '" text-anchor="end" font-size="11" fill="#5d6675">' + App.fmt(t, o.dec || 0) + '</text>';
    });
    var step = nCat > 14 ? Math.ceil(nCat / 14) : 1;
    (o.labels || []).forEach(function (l, i) {
      if (i % step) return;
      s += '<text x="' + (M.l + f.band * (i + 0.5)).toFixed(1) + '" y="' + (H - M.b + 16) + '" text-anchor="middle" font-size="11" fill="#5d6675">' + esc(l) + '</text>';
    });
    if (o.unit) s += '<text x="' + M.l + '" y="' + (H - 6) + '" font-size="11" fill="#5d6675">Unit: ' + esc(o.unit) + '</text>';
    f.head = s; return f;
  }
  function legend(items) {
    return '<div class="cap" style="margin-top:4px">' + items.map(function (it) {
      return '<span style="margin-right:12px;white-space:nowrap"><span style="display:inline-block;width:10px;height:10px;background:' + it.color + ';border-radius:2px;margin-right:4px"></span>' + esc(it.name) + '</span>';
    }).join('') + '</div>';
  }

  App.barChart = function (o) {
    var labels = o.labels || [], series = o.series || [], n = labels.length, hi = 0, i;
    for (i = 0; i < n; i++) {
      if (o.stacked) { var t = 0; series.forEach(function (s) { if (isNum(s.values[i])) t += Number(s.values[i]); }); hi = Math.max(hi, t); }
      else series.forEach(function (s) { if (isNum(s.values[i])) hi = Math.max(hi, Number(s.values[i])); });
    }
    var f = frame(o, 0, hi || 1, n), s = f.head, k = series.length;
    for (i = 0; i < n; i++) {
      var x0 = M.l + f.band * i, bw = f.band * 0.7, acc = 0;
      series.forEach(function (se, j) {
        var v = se.values[i]; if (!isNum(v)) return; v = Number(v);
        var tip = '<title>' + esc(labels[i] + ' | ' + se.name + ': ' + App.fmt(v, o.dec || 0) + ' ' + (o.unit || '')) + '</title>';
        if (o.stacked) {
          var ya = f.y(acc + v), yb = f.y(acc);
          s += '<rect x="' + (x0 + f.band * 0.15).toFixed(1) + '" y="' + ya.toFixed(1) + '" width="' + bw.toFixed(1) + '" height="' + Math.max(0, yb - ya).toFixed(1) + '" fill="' + se.color + '">' + tip + '</rect>';
          acc += v;
        } else {
          var w = bw / k, yy = f.y(v);
          s += '<rect x="' + (x0 + f.band * 0.15 + j * w).toFixed(1) + '" y="' + yy.toFixed(1) + '" width="' + (w - 1).toFixed(1) + '" height="' + Math.max(0, f.y(0) - yy).toFixed(1) + '" fill="' + se.color + '">' + tip + '</rect>';
        }
      });
    }
    return s + '</svg>' + (k > 1 ? legend(series) : '');
  };

  App.lineChart = function (o) {
    var labels = o.labels || [], series = o.series || [], n = labels.length, vals = [];
    series.forEach(function (s) { s.values.forEach(function (v) { if (isNum(v)) vals.push(Number(v)); }); });
    if (o.band) { o.band.low.concat(o.band.high).forEach(function (v) { if (isNum(v)) vals.push(Number(v)); }); }
    if (!vals.length) return '<div class="empty">No data to chart.</div>';
    var lo = Math.min.apply(null, vals), hi = Math.max.apply(null, vals);
    if (lo > 0 && lo / hi < 0.5) lo = 0;
    var f = frame(o, lo, hi, n), s = f.head;
    function cx(i) { return M.l + f.band * (i + 0.5); }
    if (o.band) {
      var seg = [];
      for (var i = 0; i <= n; i++) {
        var ok = i < n && isNum(o.band.low[i]) && isNum(o.band.high[i]);
        if (ok) seg.push(i);
        else if (seg.length) {
          var up = seg.map(function (j) { return cx(j).toFixed(1) + ',' + f.y(o.band.high[j]).toFixed(1); });
          var dn = seg.slice().reverse().map(function (j) { return cx(j).toFixed(1) + ',' + f.y(o.band.low[j]).toFixed(1); });
          s += '<polygon points="' + up.concat(dn).join(' ') + '" fill="' + o.band.color + '" opacity="0.45"/>';
          seg = [];
        }
      }
    }
    series.forEach(function (se) {
      var d = '', pen = false, dots = '';
      se.values.forEach(function (v, j) {
        if (!isNum(v)) { pen = false; return; }
        d += (pen ? 'L' : 'M') + cx(j).toFixed(1) + ' ' + f.y(Number(v)).toFixed(1) + ' '; pen = true;
        dots += '<circle cx="' + cx(j).toFixed(1) + '" cy="' + f.y(Number(v)).toFixed(1) + '" r="3" fill="' + se.color + '"><title>' + esc(labels[j] + ' | ' + se.name + ': ' + App.fmt(v, o.dec || 0) + ' ' + (o.unit || '')) + '</title></circle>';
      });
      s += '<path d="' + d + '" fill="none" stroke="' + se.color + '" stroke-width="' + (se.w || 1.8) + '"' + (se.dash ? ' stroke-dasharray="' + se.dash + '"' : '') + '/>' + dots;
    });
    var leg = series.slice(); if (o.band) leg.unshift({ name: o.band.name, color: o.band.color });
    return s + '</svg>' + legend(leg);
  };
})();
