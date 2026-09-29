#!/usr/bin/env node
// Writes the SVG glyph masters of cinematic §2.7 and glass §2.7 (shared/02 item 4):
// brand/cinematic/glyphs/{name}-{light,regular,fill}.svg (30),
// brand/glass/glyphs/{name}-{regular,duotone,fill}.svg (39) and brand/cinematic/monogram.json.
// Deterministic: stdlib plus fontkit (monogram, "18", "No."). Run: node brand/make-glyph-masters.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as fontkit from 'fontkit';
import { monogram } from './cinematic/monogram.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const K = '#000000';
const WH = '#FFFFFF';
const r2 = (n) => Math.round(n * 100) / 100;
const roundD = (d) => d.replace(/-?\d+\.?\d*(?:e-?\d+)?/g, (n) => String(r2(Number(n))));

// ---------- SVG helpers ----------
const svg = (body, defs = '') =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">\n` +
  (defs ? `<defs>\n${defs}\n</defs>\n` : '') +
  `${body}\n</svg>\n`;
const st = (w) => `fill="none" stroke="${K}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"`;
const fl = `fill="${K}"`;
// a filled closed shape whose silhouette matches the Regular outline (fill + the same stroke)
const flSt = (w) => `fill="${K}" stroke="${K}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"`;
const P = (d, a) => `<path d="${d}" ${a}/>`;
const rect = (x0, y0, x1, y1, a, rx = 0) =>
  `<rect x="${x0}" y="${y0}" width="${r2(x1 - x0)}" height="${r2(y1 - y0)}"${rx ? ` rx="${rx}"` : ''} ${a}/>`;
const circle = (cx, cy, r, a) => `<circle cx="${cx}" cy="${cy}" r="${r}" ${a}/>`;
const line = (x1, y1, x2, y2, a) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" ${a}/>`;
const poly = (pts, a) => `<polyline points="${pts.map((p) => p.join(',')).join(' ')}" ${a}/>`;
// white = keep, black = remove
const mask = (id, cuts) =>
  `<mask id="${id}" maskUnits="userSpaceOnUse" x="0" y="0" width="256" height="256">` +
  `<rect x="0" y="0" width="256" height="256" fill="${WH}"/>${cuts}</mask>`;
const masked = (id, body) => `<g mask="url(#${id})">${body}</g>`;
const duo = (primary, secondary) => `<g id="secondary" opacity="0.2">${secondary}</g>\n<g id="primary">${primary}</g>`;

// uniform scale about an anchor for absolute M L H V C A Z paths
function scalePath(d, s, ax, ay) {
  const X = (x) => r2(ax + (x - ax) * s);
  const Y = (y) => r2(ay + (y - ay) * s);
  return d.replace(/([MLCAHVZ])([^MLCAHVZ]*)/g, (_, c, args) => {
    const n = (args.match(/-?\d+\.?\d*/g) || []).map(Number);
    if (c === 'Z') return 'Z';
    if (c === 'H') return `H${X(n[0])} `;
    if (c === 'V') return `V${Y(n[0])} `;
    if (c === 'A') return `A${r2(n[0] * s)} ${r2(n[1] * s)} ${n[2]} ${n[3]} ${n[4]} ${X(n[5])} ${Y(n[6])} `;
    const out = [];
    for (let i = 0; i < n.length; i += 2) out.push(`${X(n[i])} ${Y(n[i + 1])}`);
    return `${c}${out.join(' ')} `;
  }).trim();
}

// @phosphor-icons/core 2.1.1 (MIT, brand/phosphor/SOURCE.md): assets/{regular,light,fill}/user-sound*.svg,
// assets/{regular,fill}/sparkle*.svg and the opacity-0.2 areas of assets/duotone/{user-sound,sparkle}-duotone.svg
const PHOSPHOR = {
  "user-sound":
    "M144,165.68a68,68,0,1,0-71.9,0c-20.65,6.76-39.23,19.39-54.17,37.17a8,8,0,0,0,12.25,10.3C50.25,189.19,77.91,176,108,176s57.75,13.19,77.88,37.15a8,8,0,1,0,12.25-10.3C183.18,185.07,164.6,172.44,144,165.68ZM56,108a52,52,0,1,1,52,52A52.06,52.06,0,0,1,56,108ZM207.36,65.6a108.36,108.36,0,0,1,0,84.8,8,8,0,0,1-7.36,4.86,8,8,0,0,1-7.36-11.15,92.26,92.26,0,0,0,0-72.22,8,8,0,0,1,14.72-6.29ZM248,108a139,139,0,0,1-11.29,55.15,8,8,0,0,1-14.7-6.3,124.43,124.43,0,0,0,0-97.7,8,8,0,1,1,14.7-6.3A139,139,0,0,1,248,108Z",
  "user-sound-light":
    "M139,166.26a66,66,0,1,0-62,0c-22,6.22-41.88,19.15-57.61,37.88a6,6,0,0,0,9.18,7.72C49.11,187.45,77.31,174,108,174s58.9,13.45,79.41,37.86a6,6,0,1,0,9.18-7.72C180.86,185.41,161,172.48,139,166.26ZM54,108a54,54,0,1,1,54,54A54.06,54.06,0,0,1,54,108ZM205.52,66.39a106.33,106.33,0,0,1,0,83.22,6,6,0,0,1-11-4.71,94.29,94.29,0,0,0,0-73.8,6,6,0,0,1,11-4.71ZM246,108a137.16,137.16,0,0,1-11.12,54.37,6,6,0,0,1-11-4.74,126.41,126.41,0,0,0,0-99.26,6,6,0,0,1,11-4.74A137.16,137.16,0,0,1,246,108Z",
  "user-sound-fill":
    "M198.13,202.85A8,8,0,0,1,192,216H24a8,8,0,0,1-6.12-13.15c14.94-17.78,33.52-30.41,54.17-37.17a68,68,0,1,1,71.9,0C164.6,172.44,183.18,185.07,198.13,202.85ZM196.86,61.39a8,8,0,0,0-4.22,10.5,92.26,92.26,0,0,1,0,72.22,8,8,0,1,0,14.72,6.29,108.36,108.36,0,0,0,0-84.8A8,8,0,0,0,196.86,61.39Zm39.85-8.54a8,8,0,1,0-14.7,6.3,124.43,124.43,0,0,1,0,97.7,8,8,0,1,0,14.7,6.3,140.34,140.34,0,0,0,0-110.3Z",
  "user-sound-duotone-area":
    "M168,108a60,60,0,1,1-60-60A60,60,0,0,1,168,108Z",
  "sparkle":
    "M197.58,129.06,146,110l-19-51.62a15.92,15.92,0,0,0-29.88,0L78,110l-51.62,19a15.92,15.92,0,0,0,0,29.88L78,178l19,51.62a15.92,15.92,0,0,0,29.88,0L146,178l51.62-19a15.92,15.92,0,0,0,0-29.88ZM137,164.22a8,8,0,0,0-4.74,4.74L112,223.85,91.78,169A8,8,0,0,0,87,164.22L32.15,144,87,123.78A8,8,0,0,0,91.78,119L112,64.15,132.22,119a8,8,0,0,0,4.74,4.74L191.85,144ZM144,40a8,8,0,0,1,8-8h16V16a8,8,0,0,1,16,0V32h16a8,8,0,0,1,0,16H184V64a8,8,0,0,1-16,0V48H152A8,8,0,0,1,144,40ZM248,88a8,8,0,0,1-8,8h-8v8a8,8,0,0,1-16,0V96h-8a8,8,0,0,1,0-16h8V72a8,8,0,0,1,16,0v8h8A8,8,0,0,1,248,88Z",
  "sparkle-fill":
    "M208,144a15.78,15.78,0,0,1-10.42,14.94L146,178l-19,51.62a15.92,15.92,0,0,1-29.88,0L78,178l-51.62-19a15.92,15.92,0,0,1,0-29.88L78,110l19-51.62a15.92,15.92,0,0,1,29.88,0L146,110l51.62,19A15.78,15.78,0,0,1,208,144ZM152,48h16V64a8,8,0,0,0,16,0V48h16a8,8,0,0,0,0-16H184V16a8,8,0,0,0-16,0V32H152a8,8,0,0,0,0,16Zm88,32h-8V72a8,8,0,0,0-16,0v8h-8a8,8,0,0,0,0,16h8v8a8,8,0,0,0,16,0V96h8a8,8,0,0,0,0-16Z",
  "sparkle-duotone-area":
    "M194.82,151.43l-55.09,20.3-20.3,55.09a7.92,7.92,0,0,1-14.86,0l-20.3-55.09-55.09-20.3a7.92,7.92,0,0,1,0-14.86l55.09-20.3,20.3-55.09a7.92,7.92,0,0,1,14.86,0l20.3,55.09,55.09,20.3A7.92,7.92,0,0,1,194.82,151.43Z",
};

// Phosphor artwork runs to x or y 8/248, outside the 16-unit safe inset: scaled 14/15 about the centre
const PH_FIT = 'transform="matrix(0.9333 0 0 0.9333 8.53 8.53)"';
const ph = (d) => `<g ${PH_FIT}>${P(d, fl)}</g>`;

// ---------- font outlines ----------
const fontFile = (f) => path.join(HERE, 'fonts', f);
function textPath(file, text, variation, fit) {
  let font = fontkit.openSync(fontFile(file));
  if (variation) font = font.getVariation(variation);
  const run = font.layout(text);
  const parts = [];
  let x = 0;
  run.glyphs.forEach((g, i) => {
    parts.push(g.path.translate(x, 0));
    x += run.positions[i].xAdvance;
  });
  const bbox = parts.map((p) => p.bbox).reduce((a, b) => ({
    minX: Math.min(a.minX, b.minX), minY: Math.min(a.minY, b.minY), maxX: Math.max(a.maxX, b.maxX), maxY: Math.max(a.maxY, b.maxY),
  }));
  const { s, tx, ty } = fit(bbox, font);
  return roundD(parts.map((p) => p.transform(s, 0, 0, -s, tx, ty).toSVG()).join(''));
}
// IBM Plex Mono SemiBold "18": cap height 80, bbox centred on (128,128)
const plex18 = textPath('IBMPlexMono-SemiBold.ttf', '18', null, (b, f) => {
  const s = 80 / f.capHeight;
  return { s, tx: 128 - ((b.minX + b.maxX) / 2) * s, ty: 128 + ((b.minY + b.maxY) / 2) * s };
});
// Bodoni Moda "No.": fit x 40–216, cap height ≤ 88, baseline y 152
const bodoniNo = textPath('BodoniModa[opsz,wght].ttf', 'No.', { opsz: 96, wght: 800 }, (b, f) => {
  const s = Math.min(88 / f.capHeight, 176 / (b.maxX - b.minX));
  return { s, tx: 128 - ((b.minX + b.maxX) / 2) * s, ty: 152 };
});
// Bodoni Moda's opsz-96 hairlines are 4 of 2000 units (≈ 0.16 at 256 in the monogram):
// a stroke of this width brings them to the 6-unit floor of cinematic §12.2 (24 units at 1024).
const HAIR = 5.84;

// ---------- monogram ----------
const mono = monogram();
const m256 = (d) => roundD(d.replace(/-?\d+\.?\d*/g, (n) => String(Number(n) / 4)));
const MU = m256(mono.upright);
const MI = m256(mono.italic);

// ---------- Cinematic ----------
const F1 = 'M128 32 C160 72 200 112 200 160 A72 72 0 0 1 56 160 C56 112 96 72 128 32 Z';
const F3_SRC = 'M128 24 C148 56 164 84 164 112 C170 100 176 88 180 76 C200 104 208 132 208 160 A80 80 0 0 1 48 160 C48 132 56 104 76 76 C80 88 86 100 92 112 C92 84 108 56 128 24 Z';
// the brief's flame-3 reaches y 240, so its 12/16 stroke would leave the inset: scaled 208/216 about its tip
const F3 = scalePath(F3_SRC, 208 / 216, 128, 24);
const BUBBLE_C = 'M32 40 H176 V136 H100 L56 176 L64 136 H32 Z';
const HL_BODY = 'M171 51 L205 85 L117 173 L83 139 Z';
const HL_TIP = 'M83 139 L117 173 L84 194 L62 172 Z';
const BRACKETS = [
  [[40, 88], [40, 56], [72, 56]],
  [[184, 56], [216, 56], [216, 88]],
  [[216, 168], [216, 200], [184, 200]],
  [[72, 200], [40, 200], [40, 168]],
];
const brackets = (w) => BRACKETS.map((b) => poly(b, st(w))).join('');

function cinematic(name, weight) {
  const fill = weight === 'fill';
  const w = weight === 'light' ? 12 : 16;
  const thin = weight === 'light' ? 4 : 6; // the double rule and Oxford rule's thin line
  switch (name) {
    // Open design decision (cinematic §12.2/§2.7, left for the owner): monogram.json's upright and
    // italic M overlap by 22 % only as bounding boxes; the letterforms themselves intersect in just
    // ~119 px² at 1024. So the Light/Regular knock-out plus 12/16 band below is effectively empty and
    // all three weights trace to one identical outline (103007 opaque px at 1024 for each). Options:
    // accept one outline for all three weights, or apply the overlap rule to the letterforms instead of
    // the bounding boxes. Also: the mark does not read at 16 px (~9x4 px smudge). The geometry is kept
    // unchanged on purpose: shared/04 compares against monogram.json.
    case 'mm-mark': {
      const hair = `stroke="${K}" stroke-width="${HAIR}" stroke-linejoin="round"`;
      if (fill) return svg(P(MU, `${fl} ${hair}`) + P(MI, `${fl} ${hair}`));
      const band = w;
      const defs =
        `<clipPath id="cu"><path d="${MU}"/></clipPath><clipPath id="ci"><path d="${MI}"/></clipPath>` +
        mask('x', P(MI, `fill="${K}" clip-path="url(#cu)"`));
      const letters = masked('x', P(MU, `${fl} ${hair}`) + P(MI, `${fl} ${hair}`));
      const bands =
        `<g clip-path="url(#ci)">${P(MU, `fill="none" stroke="${K}" stroke-width="${band * 2}" stroke-linejoin="round"`)}</g>` +
        `<g clip-path="url(#cu)">${P(MI, `fill="none" stroke="${K}" stroke-width="${band * 2}" stroke-linejoin="round"`)}</g>`;
      return svg(letters + bands, defs);
    }
    case 'flame-1':
      return svg(P(F1, fill ? flSt(16) : st(w)));
    case 'flame-3':
      return svg(P(F3, fill ? flSt(16) : st(w)));
    case 'strip-scroll': {
      const chevron = poly([[104, 200], [128, 224], [152, 200]], st(fill ? 16 : w));
      if (fill) {
        const defs = mask('g', rect(80, 68, 176, 76, fl) + rect(80, 120, 176, 128, fl));
        return svg(masked('g', rect(88, 24, 168, 176, flSt(16))) + chevron, defs);
      }
      return svg(rect(88, 24, 168, 176, st(w)) + line(88, 72, 168, 72, st(w)) + line(88, 124, 168, 124, st(w)) + chevron);
    }
    case 'panel-focus':
      return svg(rect(72, 88, 184, 168, fill ? flSt(16) : st(w)) + brackets(fill ? 16 : w));
    case 'bubble-search': {
      const defs = mask('c', circle(168, 168, 44, fl));
      const bubble = masked('c', P(BUBBLE_C, fill ? flSt(16) : st(w)));
      const sw = fill ? 16 : w;
      return svg(bubble + circle(168, 168, 32, st(sw)) + line(191, 191, 224, 224, st(sw)), defs);
    }
    case 'certificate-18': {
      if (fill) return svg(masked('n', rect(40, 40, 216, 216, flSt(16))), mask('n', P(plex18, fl)));
      return svg(rect(40, 40, 216, 216, st(w)) + rect(56, 56, 200, 200, st(thin)) + P(plex18, fl));
    }
    case 'voice-31': {
      // clearance square x 148–240, y 148–240; the front card (plus a 4-unit gap) knocks out the back card
      const sw = fill ? 16 : w;
      const gap = sw / 2 + 4;
      const defs =
        mask('c', rect(148, 148, 240, 240, fl)) + mask('f', rect(164 - gap, 180 - gap, 212 + gap, 228 + gap, fl));
      const art = fill ? PHOSPHOR['user-sound-fill'] : weight === 'light' ? PHOSPHOR['user-sound-light'] : PHOSPHOR['user-sound'];
      const back = masked('f', rect(180, 164, 228, 212, st(sw)));
      const front = rect(164, 180, 212, 228, fill ? flSt(16) : st(sw));
      return svg(masked('c', ph(art)) + back + front, defs);
    }
    case 'annual': {
      const hair = `stroke="${K}" stroke-width="${HAIR}" stroke-linejoin="round"`;
      if (fill) return svg(P(bodoniNo, `${fl} ${hair}`) + rect(40, 176, 216, 206, fl));
      return svg(P(bodoniNo, `${fl} ${hair}`) + line(40, 184, 216, 184, st(w)) + line(40, 202, 216, 202, st(thin)));
    }
    case 'highlighter': {
      if (fill) {
        const defs = mask('f', line(66, 122, 134, 190, `stroke="${K}" stroke-width="6"`));
        return svg(masked('f', P(HL_BODY, flSt(16)) + P(HL_TIP, flSt(16))) + line(40, 224, 144, 224, st(16)), defs);
      }
      return svg(P(HL_BODY, st(w)) + P(HL_TIP, st(w)) + line(40, 224, 144, 224, st(w)));
    }
  }
  throw new Error(`unknown cinematic glyph ${name}`);
}

// ---------- Glass ----------
// ellipse (112,104) rx 80 ry 60 joined to the tail triangle (80,150) (72,176) (104,158): one outline
function ellipseHit(a, b) {
  const f = (t) => {
    const x = a[0] + (b[0] - a[0]) * t;
    const y = a[1] + (b[1] - a[1]) * t;
    return ((x - 112) / 80) ** 2 + ((y - 104) / 60) ** 2 - 1;
  };
  let lo = 0;
  let hi = 1;
  for (let i = 0; i < 60; i++) {
    const mid = (lo + hi) / 2;
    if (Math.sign(f(mid)) === Math.sign(f(lo))) lo = mid;
    else hi = mid;
  }
  return [r2(a[0] + (b[0] - a[0]) * lo), r2(a[1] + (b[1] - a[1]) * lo)];
}
const T1 = ellipseHit([80, 150], [72, 176]);
const T2 = ellipseHit([72, 176], [104, 158]);
const BUBBLE_G = `M${T1[0]} ${T1[1]} L72 176 L${T2[0]} ${T2[1]} A80 60 0 1 0 ${T1[0]} ${T1[1]} Z`;

const DROPLET = 'M128 32 L182.14 117.87 A64 64 0 1 1 73.86 117.87 Z';
const SEAL = Array.from({ length: 24 }, (_, i) => {
  const a = ((-90 + i * 15) * Math.PI) / 180;
  const r = i % 2 === 0 ? 104 : 88;
  return `${r2(128 + r * Math.cos(a))},${r2(128 + r * Math.sin(a))}`;
}).join(' ');
const EIGHTEEN = (a) =>
  line(104, 92, 104, 164, a) + line(92, 104, 104, 92, a) + circle(148, 110, 18, a) + circle(148, 146, 18, a);
const TICKS = (a) =>
  [-90, -30, 30, 90, 150, 210]
    .map((deg) => {
      const t = (deg * Math.PI) / 180;
      return line(r2(128 + 40 * Math.cos(t)), r2(128 + 40 * Math.sin(t)), r2(128 + 64 * Math.cos(t)), r2(128 + 64 * Math.sin(t)), a);
    })
    .join('');
const STRATA = [
  [56, 124],
  [100, 136],
  [144, 148],
  [188, 160],
];
const capsule = ([cy, w], a) => rect(128 - w / 2, cy - 10, 128 + w / 2, cy + 10, a, 10);
const capsuleUnlit = ([cy, w]) => rect(128 - w / 2 + 3, cy - 7, 128 + w / 2 - 3, cy + 7, `fill="none" stroke="${K}" stroke-width="6"`, 7);
const MM_TOP = [[71, 109], [71, 59], [128, 96.5], [185, 59], [185, 109]];
const MM_BOT = [[71, 197], [71, 147], [128, 184.5], [185, 147], [185, 197]];

function glass(name, weight) {
  const S = st(16);
  const reg = weight !== 'fill';
  const out = (primary, secondary, defs = '') => svg(weight === 'duotone' ? duo(primary, secondary) : primary, defs);
  const strataMatch = /^strata-(\d)$/.exec(name);
  if (strataMatch) {
    const lit = Number(strataMatch[1]);
    const isLit = (i) => i >= 4 - lit; // the lowest N capsules are lit
    if (weight === 'fill') return svg(STRATA.map((c) => capsule(c, fl)).join(''));
    const litShapes = STRATA.filter((_, i) => isLit(i)).map((c) => capsule(c, fl)).join('');
    // secondary: every capsule (the lit ones sit under the opaque primary), so strata-4 has one too
    if (weight === 'duotone') return svg(duo(litShapes, STRATA.map((c) => capsule(c, fl)).join('')));
    return svg(litShapes + STRATA.filter((_, i) => !isLit(i)).map(capsuleUnlit).join(''));
  }
  switch (name) {
    case 'mm-mark': {
      const ms = `fill="none" stroke="${K}" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"`;
      if (!reg) {
        const defs = mask('k', poly(MM_TOP, ms) + poly(MM_BOT, ms) + rect(60, 120, 196, 136, fl));
        return svg(masked('k', rect(60, 48, 196, 208, fl, 54)), defs);
      }
      return out(poly(MM_TOP, ms) + poly(MM_BOT, ms) + rect(60, 120, 196, 136, fl), rect(60, 48, 196, 208, fl, 54));
    }
    case 'strip-scroll': {
      const chevron = poly([[104, 212], [128, 232], [152, 212]], S);
      if (!reg) {
        const defs = mask('g', rect(72, 76, 184, 84, fl) + rect(72, 132, 184, 140, fl));
        return svg(masked('g', rect(80, 24, 176, 200, flSt(16), 16)) + chevron, defs);
      }
      return out(rect(80, 24, 176, 200, S, 16) + line(80, 80, 176, 80, S) + line(80, 136, 176, 136, S) + chevron, rect(80, 24, 176, 200, fl, 16));
    }
    case 'panel-focus':
      if (!reg) return svg(rect(72, 88, 184, 168, flSt(16)) + brackets(16));
      return out(rect(72, 88, 184, 168, S) + brackets(16), rect(72, 88, 184, 168, fl));
    case 'bubble-search': {
      const defs = mask('c', circle(176, 168, 40, fl));
      const tools = circle(176, 168, 28, S) + line(196, 188, 224, 216, S);
      if (!reg) return svg(masked('c', P(BUBBLE_G, flSt(16))) + tools, defs);
      return out(masked('c', P(BUBBLE_G, S)) + tools, masked('c', P(BUBBLE_G, fl)), defs);
    }
    case 'age-gate': {
      const seal = (a) => `<polygon points="${SEAL}" ${a}/>`;
      if (!reg) return svg(masked('n', seal(flSt(16))), mask('n', EIGHTEEN(S)));
      return out(seal(S) + EIGHTEEN(S), seal(fl));
    }
    case 'voice-31': {
      // the cards are offset by only 8: Regular knocks out exactly the front card's footprint (half-stroke 8),
      // Fill's front card is a plain filled rect with a 4-unit gap around it
      const gap = reg ? 8 : 4;
      const defs = mask('c', rect(156, 156, 244, 244, fl)) + mask('f', rect(168 - gap, 176 - gap, 224 + gap, 232 + gap, fl, 8 + gap));
      const back = masked('f', rect(176, 168, 232, 224, S, 8));
      if (!reg) return svg(masked('c', ph(PHOSPHOR['user-sound-fill'])) + back + rect(168, 176, 224, 232, fl, 8), defs);
      return out(
        masked('c', ph(PHOSPHOR['user-sound'])) + back + rect(168, 176, 224, 232, S, 8),
        masked('c', ph(PHOSPHOR['user-sound-duotone-area'])) + rect(168, 176, 224, 232, fl, 8),
        defs,
      );
    }
    case 'droplet':
      if (!reg) return svg(P(DROPLET, flSt(16)));
      return out(P(DROPLET, S), P(DROPLET, fl));
    case 'flywheel': {
      if (!reg) return svg(masked('h', circle(128, 128, 80, flSt(16))), mask('h', circle(128, 128, 16, fl) + TICKS(S)));
      return out(circle(128, 128, 80, S) + circle(128, 128, 16, fl) + TICKS(S), circle(128, 128, 80, fl));
    }
    case 'sparkle-slash': {
      const defs = mask('c', line(48, 48, 208, 208, `stroke="${K}" stroke-width="40" stroke-linecap="round"`));
      const slash = line(48, 48, 208, 208, S);
      if (!reg) return svg(masked('c', ph(PHOSPHOR['sparkle-fill'])) + slash, defs);
      return out(masked('c', ph(PHOSPHOR.sparkle)) + slash, masked('c', ph(PHOSPHOR['sparkle-duotone-area'])), defs);
    }
  }
  throw new Error(`unknown glass glyph ${name}`);
}

// ---------- write ----------
const icons = JSON.parse(fs.readFileSync(path.join(HERE, '..', 'design', 'icons.json'), 'utf8'));
const write = (skin, draw) => {
  const dir = path.join(HERE, skin, 'glyphs');
  fs.mkdirSync(dir, { recursive: true });
  let n = 0;
  for (const name of icons.glyphs[skin]) {
    for (const weight of icons.skins[skin].glyphWeights) {
      fs.writeFileSync(path.join(dir, `${name}-${weight}.svg`), draw(name, weight));
      n++;
    }
  }
  console.log(`${skin}: ${n} masters`);
};
fs.writeFileSync(path.join(HERE, 'cinematic', 'monogram.json'), JSON.stringify(mono, null, 2) + '\n');
write('cinematic', cinematic);
write('glass', glass);
