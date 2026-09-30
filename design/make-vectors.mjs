// Shared tint + panel parity vectors (web/23 A0). Node stdlib only, deterministic.
import zlib from 'node:zlib';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = path.dirname(fileURLToPath(import.meta.url));
function mulberry32(a) { return () => { a |= 0; a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }

// ---- HLS (Python colorsys on 8-bit / 255)
function hls(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
  if (mx === mn) return { l, s: 0 };
  const s = l <= 0.5 ? (mx - mn) / (mx + mn) : (mx - mn) / (2 - mx - mn);
  return { l, s };
}
function hlsToRgb(h, l, s) {
  const f = (n) => { const k = (n + h * 12) % 12; const a = s * Math.min(l, 1 - l); return l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)); };
  return [0, 8, 4].map((n) => Math.round(f(n) * 255));
}
function pick(px) {
  let best = null, bs = -1;
  for (let i = 0; i < px.length; i += 4) {
    const { l, s } = hls(px[i], px[i + 1], px[i + 2]);
    if (!(l > 0.10 && l < 0.90)) continue;
    if (s > bs) { bs = s; best = i; }
  }
  if (best === null || bs < 0.08) return null;
  return '#' + [0, 1, 2].map((k) => px[best + k].toString(16).padStart(2, '0')).join('').toUpperCase();
}
const hex = (c) => '#' + c.map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase();

// find an RGB whose quantised HLS hits the wanted range
function colourFor(h, l, sMin, sMax, rnd) {
  for (let t = 0; t < 5000; t++) {
    const s = sMin + (sMax - sMin) * rnd();
    const c = hlsToRgb(h, l, s);
    const q = hls(...c);
    if (q.s >= sMin && q.s < sMax && Math.abs(q.l - l) < 0.02) return c;
  }
  throw new Error(`no colour h=${h} l=${l}`);
}
function colourExact(h, l, sMin, sMax, lMin, lMax, rnd) {
  for (let t = 0; t < 20000; t++) {
    const c = hlsToRgb(h, lMin + (lMax - lMin) * rnd(), sMin + (sMax - sMin) * rnd());
    const q = hls(...c);
    if (q.s >= sMin && q.s < sMax && q.l >= lMin && q.l <= lMax) return c;
  }
  throw new Error('no colour');
}
function grid(fill) { const a = new Uint8Array(1024); for (let i = 0; i < 256; i++) a.set([...fill(i), 255], i * 4); return a; }
const samples = [];
const add = (id, px, exp) => samples.push({ id, px, exp });

for (let i = 0; i < 16; i++) {
  const rnd = mulberry32(1000 + i), h = (i * 22.5) / 360;
  const bg = []; for (let k = 0; k < 256; k++) bg.push(colourExact(h, 0, 0.20, 0.55, 0.25, 0.75, rnd));
  const px = grid((k) => bg[k]);
  const pos = Math.floor(rnd() * 256);
  const seed = colourExact(h, 0, 0.80, 0.95, 0.48, 0.52, rnd);
  px.set([...seed, 255], pos * 4);
  add(`colour-${String(i + 1).padStart(2, '0')}`, px, hex(seed));
}
for (let i = 0; i < 10; i++) {
  const rnd = mulberry32(2000 + i);
  const px = i === 0 ? grid(() => [129, 128, 128]) : grid(() => { const v = 40 + Math.floor(rnd() * 180); return [v, Math.max(0, v - (i % 2)), Math.max(0, v - (i % 2))]; });
  add(`screentone-${String(i + 1).padStart(2, '0')}`, px, null);
}
for (let i = 0; i < 8; i++) {
  const rnd = mulberry32(3000 + i);
  const px = grid(() => { if (rnd() < 0.5) { const v = Math.floor(rnd() * 26); return [v, v, v]; } return [255, 250 + Math.floor(rnd() * 6), 250 + Math.floor(rnd() * 6)]; });
  const d = colourExact(i / 8, 0, 0.3, 0.9, 0.06, 0.09, rnd);
  px.set([...d, 255], Math.floor(rnd() * 256) * 4);
  add(`splash-${String(i + 1).padStart(2, '0')}`, px, null);
}
for (let i = 0; i < 8; i++) {
  const rnd = mulberry32(4000 + i), h = (30 + rnd() * 10) / 360;
  const bg = []; for (let k = 0; k < 256; k++) bg.push(colourExact(h, 0, 0.15, 0.35, 0.30, 0.80, rnd));
  const px = grid((k) => bg[k]);
  const seed = colourExact(h, 0, 0.40, 0.50, 0.40, 0.60, rnd);
  px.set([...seed, 255], Math.floor(rnd() * 256) * 4);
  add(`sepia-${String(i + 1).padStart(2, '0')}`, px, hex(seed));
}
const grey = () => [128, 128, 128];
{ // edge-01 saturated at L .95 excluded, S .30 L .5 wins
  const rnd = mulberry32(5001); const px = grid(grey);
  px.set([...colourExact(0.6, 0, 0.9, 1, 0.94, 0.96, rnd), 255], 0);
  const w = colourExact(0.1, 0, 0.30, 0.31, 0.49, 0.51, rnd); px.set([...w, 255], 4);
  add('edge-01', px, hex(w));
}
{ // edge-02 L exactly 0.10 excluded: (51,0,0)? L=(51/255)/2=0.1
  const px = grid(grey); px.set([51, 0, 0, 255], 0);
  add('edge-02', px, null);
}
{ // edge-03 equal S, first wins
  const px = grid(grey); px.set([200, 100, 100, 255], 8); px.set([100, 200, 200, 255], 4);
  // both S = 100/255 / (300/255)... compute: ensure equal
  const a = hls(200, 100, 100), b = hls(100, 200, 200);
  if (a.s !== b.s) throw new Error('edge-03 unequal ' + a.s + ' ' + b.s);
  add('edge-03', px, '#64C8C8');
}
{ // edge-04 all S in [0.075,0.080)
  const rnd = mulberry32(5004); const px = grid(() => colourExact(0.3, 0, 0.075, 0.080, 0.4, 0.6, rnd));
  add('edge-04', px, null);
}
{ // edge-05 one pixel S in [0.080,0.085)
  const rnd = mulberry32(5005); const px = grid(grey); const c = colourExact(0.3, 0, 0.080, 0.085, 0.4, 0.6, rnd);
  px.set([...c, 255], 40 * 4); add('edge-05', px, hex(c));
}
{ // edge-06 only kept pixel is grey
  const px = grid(() => [255, 255, 255]); px.set([128, 128, 128, 255], 0); add('edge-06', px, null);
}
if (samples.length !== 48) throw new Error('samples ' + samples.length);
for (const s of samples) if (pick(s.px) !== s.exp) { console.error('tint mismatch', s.id, pick(s.px), s.exp); process.exit(1); }
const tintJson = {
  version: 1,
  rule: 'Keep pixels with 0.10 < L < 0.90 (strict, HLS as Python colorsys on 8-bit/255); the seed is the kept pixel with the highest S, ties to the first in row-major order; greyscale (null) when none is kept or the best S < 0.08; result upper-case #RRGGBB.',
  samples: samples.map((s) => ({ id: s.id, rgba: Buffer.from(s.px).toString('base64'), expected: s.exp })),
};
fs.writeFileSync(path.join(dir, 'tint-vectors.json'), JSON.stringify(tintJson, null, 1) + '\n');

// ---- panels
const W = 360;
function png(w, h, g) {
  const raw = Buffer.alloc((w + 1) * h);
  for (let y = 0; y < h; y++) { raw[y * (w + 1)] = 0; g.subarray(y * w, (y + 1) * w).forEach((v, x) => (raw[y * (w + 1) + 1 + x] = v)); }
  const chunk = (t, d) => { const b = Buffer.alloc(12 + d.length); b.writeUInt32BE(d.length, 0); b.write(t, 4, 'ascii'); d.copy(b, 8); b.writeUInt32BE(zlib.crc32(b.subarray(4, 8 + d.length)) >>> 0, 8 + d.length); return b; };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 0;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
function unpng(buf) {
  const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20); let o = 8; const idat = [];
  while (o < buf.length) { const n = buf.readUInt32BE(o), t = buf.toString('ascii', o + 4, o + 8); if (t === 'IDAT') idat.push(buf.subarray(o + 8, o + 8 + n)); o += 12 + n; }
  const raw = zlib.inflateSync(Buffer.concat(idat)); const g = new Uint8Array(w * h);
  for (let y = 0; y < h; y++) { if (raw[y * (w + 1)] !== 0) throw new Error('filter'); g.set(raw.subarray(y * (w + 1) + 1, (y + 1) * (w + 1)), y * w); }
  return { w, h, g };
}
const R = (x, y, w, h) => ({ x, y, w, h });
const cases = [];
function mk(id, h, bgv, rects, expected, opts = {}) {
  const g = new Uint8Array(W * h).fill(bgv);
  for (const [x, y, w, hh, v = 128] of rects) for (let yy = y; yy < y + hh; yy++) g.fill(v, yy * W + x, yy * W + x + w);
  if (opts.post) opts.post(g, h);
  cases.push({ id, h, g, dir: opts.dir || 'ltr', expected });
}
const three = [[16, 16, 328, 160], [16, 192, 328, 160], [16, 368, 328, 156]];
const t3 = three.map((r) => R(...r));
const g22 = [[16, 16, 156, 248], [188, 16, 156, 248], [16, 280, 156, 244], [188, 280, 156, 244]];
const g22e = g22.map((r) => R(...r));
mk('single-full', 540, 255, [[16, 16, 328, 508]], [R(16, 16, 328, 508)]);
mk('three-rows', 540, 255, three, t3);
mk('grid-2x2', 540, 255, g22, g22e);
mk('grid-2x2-rtl', 540, 255, g22, [g22e[1], g22e[0], g22e[3], g22e[2]], { dir: 'rtl' });
mk('mixed-rows', 540, 255, [[16, 16, 328, 200], [16, 232, 96, 292], [128, 232, 104, 292], [248, 232, 96, 292]], [R(16, 16, 328, 200), R(16, 232, 96, 292), R(128, 232, 104, 292), R(248, 232, 96, 292)]);
mk('black-gutters', 540, 0, g22, g22e);
mk('gutter-12', 540, 255, [[16, 16, 328, 250], [16, 278, 328, 246]], [R(16, 16, 328, 250), R(16, 278, 328, 246)]);
mk('gutter-11', 540, 255, [[16, 16, 328, 250], [16, 277, 328, 247]], [R(16, 16, 328, 508)]);
mk('near-white-240', 540, 240, three, t3);
mk('near-white-230', 540, 230, three, [R(0, 0, 360, 540)]);
const noise = (n, xs) => (g, h) => { for (let y = 0; y < h; y++) { const inP = three.some(([, py, , ph]) => y >= py && y < py + ph); if (!inP) for (const x of xs) g[y * W + x] = 128; } };
mk('noise-5px', 540, 255, three, t3, { post: noise(5, [60, 120, 180, 240, 300]) });
mk('noise-11px', 540, 255, three, [R(16, 0, 328, 540)], { post: noise(11, Array.from({ length: 11 }, (_, k) => 40 + 30 * k)) });
mk('small-dropped-h', 540, 255, [[16, 16, 328, 200], [16, 232, 328, 40], [16, 288, 328, 236]], [R(16, 16, 328, 200), R(16, 288, 328, 236)]);
mk('narrow-47', 540, 255, [[16, 16, 47, 508], [79, 16, 265, 508]], [R(79, 16, 265, 508)]);
mk('narrow-48', 540, 255, [[16, 16, 48, 508], [80, 16, 264, 508]], [R(16, 16, 48, 508), R(80, 16, 264, 508)]);
mk('strip-tall', 1080, 255, [[16, 16, 328, 300], [16, 340, 150, 400], [182, 340, 162, 400], [16, 764, 328, 300]], [R(0, 16, 360, 300), R(0, 340, 360, 400), R(0, 764, 360, 300)]);
mk('strip-no-gutters', 900, 128, [], [R(0, 0, 360, 900)]);
mk('strip-white-gaps', 1200, 255, [[0, 0, 360, 380], [0, 420, 360, 380], [0, 840, 360, 360]], [R(0, 0, 360, 380), R(0, 420, 360, 380), R(0, 840, 360, 360)]);
mk('splash-black', 540, 10, [[40, 100, 280, 300]], [R(40, 100, 280, 300)]);
mk('all-white', 540, 255, [], []);
mk('all-grey', 540, 128, [], [R(0, 0, 360, 540)]);
mk('bubble-inside', 540, 255, three, t3, { post: (g) => { for (let y = 0; y < 540; y++) for (let x = 0; x < W; x++) { const dx = (x - 180) / 100, dy = (y - 96) / 40; if (dx * dx + dy * dy <= 1) g[y * W + x] = 255; } } });
mk('three-cols-rtl', 540, 255, [[16, 16, 96, 508], [128, 16, 104, 508], [248, 16, 96, 508]], [R(248, 16, 96, 508), R(128, 16, 104, 508), R(16, 16, 96, 508)], { dir: 'rtl' });
mk('uneven-band', 540, 255, [[16, 16, 156, 300], [188, 16, 156, 200], [16, 332, 328, 192]], [R(16, 16, 156, 300), R(188, 16, 156, 300), R(16, 332, 328, 192)]);
if (cases.length !== 24) throw new Error('cases ' + cases.length);
fs.mkdirSync(path.join(dir, 'panel-vectors'), { recursive: true });
const out = cases.map((c, i) => {
  const file = `${String(i + 1).padStart(2, '0')}-${c.id}.png`;
  const b = png(W, c.h, c.g); fs.writeFileSync(path.join(dir, 'panel-vectors', file), b);
  const back = unpng(b); if (back.w !== W || back.h !== c.h || Buffer.compare(Buffer.from(back.g), Buffer.from(c.g))) throw new Error('roundtrip ' + file);
  return { id: c.id, file: `panel-vectors/${file}`, height: c.h, direction: c.dir, expected: c.expected };
});
fs.writeFileSync(path.join(dir, 'panel-vectors.json'), JSON.stringify({
  version: 1, width: W,
  rule: 'L=(0.2126R+0.7152G+0.0722B)/255. A row (or column within a band) is a gutter line when >=98% of pixels have L>0.92 or >=98% have L<0.06; a gutter is a run of >=12 gutter lines; shorter runs stay content. Bands between gutters take full band height; each band splits once at its vertical gutters except on a strip page (height/width>2) where a band is one full-width rect. Rects under 48px on either side are dropped. Order top-to-bottom then left-to-right (right-to-left for rtl).',
  cases: out,
}, null, 1) + '\n');
console.log('ok');
