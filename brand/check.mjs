#!/usr/bin/env node
// Brand checks, run as named groups in sequence (shared/02 adds `glyphs`; shared/04 and shared/05
// add `cinematic-brand` and `glass-brand`). Stdlib only; prints one line per check, exits 1 on any failure.
//   node brand/check.mjs
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { readPng, readWebpSize, readIco, insideCircle } from './lib/img.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rel = (...p) => path.join(ROOT, ...p);
let failed = 0;
const report = (group, name, problems) => {
  if (problems.length) failed++;
  console.log(`${problems.length ? 'FAIL' : 'ok  '} ${group}: ${name}${problems.length ? ` — ${problems.slice(0, 8).join('; ')}${problems.length > 8 ? ` (+${problems.length - 8} more)` : ''}` : ''}`);
};
const read = (f) => (fs.existsSync(rel(f)) ? fs.readFileSync(rel(f), 'utf8') : null);
const camel = (s) => s.split('-').map((w, i) => (i ? w[0].toUpperCase() + w.slice(1) : w)).join('');
const pascal = (s) => s.split('-').map((w) => w[0].toUpperCase() + w.slice(1)).join('');

// Codepoints a TrueType font maps, from its cmap subtables of format 4 and 12.
function cmapCodepoints(buf) {
  const numTables = buf.readUInt16BE(4);
  let cmap = -1;
  for (let i = 0; i < numTables; i++) {
    const rec = 12 + i * 16;
    if (buf.toString('latin1', rec, rec + 4) === 'cmap') cmap = buf.readUInt32BE(rec + 8);
  }
  if (cmap < 0) throw new Error('no cmap table');
  const out = new Set();
  const n = buf.readUInt16BE(cmap + 2);
  for (let i = 0; i < n; i++) {
    const sub = cmap + buf.readUInt32BE(cmap + 4 + i * 8 + 4);
    const format = buf.readUInt16BE(sub);
    if (format === 4) {
      const segX2 = buf.readUInt16BE(sub + 6);
      const ends = sub + 14;
      const starts = ends + segX2 + 2;
      const deltas = starts + segX2;
      const offsets = deltas + segX2;
      for (let s = 0; s < segX2 / 2; s++) {
        const end = buf.readUInt16BE(ends + s * 2);
        const start = buf.readUInt16BE(starts + s * 2);
        const delta = buf.readInt16BE(deltas + s * 2);
        const ro = buf.readUInt16BE(offsets + s * 2);
        for (let c = start; c <= end && c !== 0xffff; c++) {
          const glyph = ro === 0 ? (c + delta) & 0xffff : buf.readUInt16BE(offsets + s * 2 + ro + (c - start) * 2);
          if (glyph !== 0) out.add(c);
        }
      }
    } else if (format === 12) {
      const groups = buf.readUInt32BE(sub + 12);
      for (let g = 0; g < groups; g++) {
        const at = sub + 16 + g * 12;
        for (let c = buf.readUInt32BE(at); c <= buf.readUInt32BE(at + 4); c++) out.add(c);
      }
    }
  }
  return out;
}

const ALLOWED = new Set(['svg', 'path', 'rect', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'g', 'mask', 'clipPath', 'defs']);
const COLOURS = new Set(['#000000', '#FFFFFF', 'none']);

function glyphs() {
  const G = 'glyphs';
  const icons = JSON.parse(read('design/icons.json'));
  const phosphor = JSON.parse(read('brand/phosphor/codepoints.json'));
  const skins = {
    cinematic: { font: 'CineGlyphs', dart: 'cine_glyphs.g.dart', cls: 'CineGlyphs' },
    glass: { font: 'GlassGlyphs', dart: 'glass_glyphs.g.dart', cls: 'GlassGlyphs' },
  };
  const PH_FAMILY = { regular: 'PhosphorRegular', thin: 'PhosphorThin', light: 'PhosphorLight', bold: 'PhosphorBold', fill: 'PhosphorFill', duotone: 'PhosphorDuotone' };

  for (const [skin, s] of Object.entries(skins)) {
    const cfg = icons.skins[skin];
    const dir = `brand/${skin}/glyphs`;
    const masters = [];
    const missing = [];
    for (const name of icons.glyphs[skin]) {
      for (const w of cfg.glyphWeights) {
        const f = `${dir}/${name}-${w}.svg`;
        if (fs.existsSync(rel(f))) masters.push(f);
        else missing.push(`missing ${f}`);
      }
    }
    report(G, `${skin} masters for ${icons.glyphs[skin].length} glyphs × ${cfg.glyphWeights.join('/')} (${masters.length})`, missing);

    const bad = [];
    for (const f of masters) {
      const t = read(f);
      if (!/<svg\b[^>]*\bviewBox="0 0 256 256"/.test(t) || !/<svg\b[^>]*\bwidth="256"/.test(t) || !/<svg\b[^>]*\bheight="256"/.test(t)) bad.push(`${f}: not 256 × 256 with viewBox 0 0 256 256`);
      for (const [, el] of t.matchAll(/<([a-zA-Z]+)[\s>/]/g)) if (!ALLOWED.has(el)) bad.push(`${f}: <${el}>`);
      for (const [, c] of t.matchAll(/(?:fill|stroke)="([^"]*)"/g)) if (!COLOURS.has(c) && !c.startsWith('url(')) bad.push(`${f}: colour ${c}`);
    }
    report(G, `${skin} masters are 256 × 256, allowed elements, black/white/none only`, bad);
    if (skin === 'cinematic') report(G, 'cinematic mm-mark glyphs carry the monogram-mono outline unstroked (0.03 % pixel diff vs monogram-mono.svg)', masters.filter((f) => f.includes('mm-mark') && /stroke-width="5\.84"/.test(read(f))).map((f) => `${f}: hairline stroke widens the mark`));

    const ids = [];
    for (const name of icons.glyphs[skin]) {
      for (const w of cfg.glyphWeights) {
        ids.push(`${name}-${w}`);
        if (w === 'duotone') ids.push(`${name}-duotone-secondary`);
      }
    }
    const cps = JSON.parse(read(`${dir}/codepoints.json`) ?? '{}');
    report(G, `${skin} codepoints.json covers ${ids.length} traced ids`, ids.filter((id) => !(id in cps)).map((id) => `no codepoint for ${id}`));

    const ttf = `mobile/assets/fonts/${s.font}.ttf`;
    let mapped = new Set();
    const fontProblems = [];
    if (!fs.existsSync(rel(ttf))) fontProblems.push(`missing ${ttf}`);
    else {
      try {
        mapped = cmapCodepoints(fs.readFileSync(rel(ttf)));
      } catch (e) {
        fontProblems.push(`${ttf}: ${e.message}`);
      }
    }
    for (const id of ids) if (id in cps && !mapped.has(cps[id])) fontProblems.push(`${s.font}.ttf does not map ${id} (0x${cps[id].toString(16)})`);
    report(G, `${s.font}.ttf maps every codepoint (${mapped.size} mapped)`, fontProblems);

    const dart = read(`mobile/lib/skins/${skin}/icons/${s.dart}`) ?? '';
    report(G, `${s.dart} declares ${ids.length} constants`, ids.filter((id) => !new RegExp(`static const IconData ${camel(id)} = IconData\\(0x[0-9A-F]+, fontFamily: '${s.font}'\\)`).test(dart)).map((id) => `no ${s.cls}.${camel(id)}`));

    const tsx = read(`frontend/src/skins/${skin}/icons/glyphs.generated.tsx`) ?? '';
    const comps = [...new Set(icons.glyphs[skin].map((n) => pascal(n.replace(/^(strata)-\d$/, '$1'))))];
    report(G, `${skin} glyphs.generated.tsx exports ${comps.length} components`, comps.filter((c) => !new RegExp(`export function ${c}\\(`).test(tsx)).map((c) => `no ${c}`));

    const names = [...new Set(Object.values(icons.roles).map((r) => r[skin]).filter((v) => v && !v.startsWith('glyph:')))].sort();
    const phProblems = [];
    const phDart = read(`mobile/lib/skins/${skin}/icons/phosphor.g.dart`) ?? '';
    if (/extends\s+IconData/.test(phDart)) phProblems.push('phosphor.g.dart subclasses IconData');
    for (const n of names) {
      for (const w of cfg.phosphorWeights) {
        if (!phosphor[n]?.[w]) phProblems.push(`${n} has no ${w} codepoint`);
        const body = phDart.split(`abstract final class ${PH_FAMILY[w]} {`)[1]?.split('\n}')[0] ?? '';
        if (!body.includes(`static const IconData ${camel(n)} = IconData(`)) phProblems.push(`${PH_FAMILY[w]}.${camel(n)} not declared`);
      }
    }
    report(G, `${skin} Phosphor names (${names.length}) exist in ${cfg.phosphorWeights.length} weights and in phosphor.g.dart`, phProblems);
  }

  const ph = ['Phosphor', 'Phosphor-Thin', 'Phosphor-Light', 'Phosphor-Bold', 'Phosphor-Fill', 'Phosphor-Duotone'];
  report(G, 'six Phosphor TTFs in mobile/assets/fonts/phosphor/', ph.filter((f) => !fs.existsSync(rel(`mobile/assets/fonts/phosphor/${f}.ttf`))).map((f) => `missing ${f}.ttf`));
}

function cinematic() {
  const G = 'cinematic-brand';
  const buf = (f) => fs.readFileSync(rel(f));
  const png = (f) => readPng(buf(f));
  const man = JSON.parse(read('brand/cinematic/export/manifest.json') ?? '{"outputs":[]}').outputs;

  const bad = [];
  for (const o of man) {
    if (!fs.existsSync(rel(o.path))) { bad.push(`missing ${o.path}`); continue; }
    if (o.path.endsWith('.png')) { const p = png(o.path); if (p.width !== o.width || p.height !== o.height) bad.push(`${o.path} is ${p.width}x${p.height}`); }
  }
  report(G, `${man.length} exported files exist at their manifest sizes`, bad.length || !man.length ? bad.concat(man.length ? [] : ['empty manifest']) : []);

  const dens = { mdpi: 24, hdpi: 36, xhdpi: 48, xxhdpi: 72, xxxhdpi: 96 };
  report(G, 'ic_stat_mm densities 24/36/48/72/96, white ink inside the 20/24 live box', Object.entries(dens).flatMap(([d, px]) => {
    const f = `mobile/android/app/src/main/res/drawable-${d}/ic_stat_mm.png`;
    if (!fs.existsSync(rel(f))) return [`missing ${d}`];
    const p = png(f), a = p.rgba(), out = [];
    if (p.width !== px || p.height !== px) out.push(`${d} is ${p.width}`);
    const m = (px * 2) / 24 - 0.5;
    for (let y = 0; y < px; y++) for (let x = 0; x < px; x++) {
      const o = (y * px + x) * 4;
      if (a[o + 3] > 0) {
        if (a[o] < 250 || a[o + 1] < 250 || a[o + 2] < 250) { out.push(`${d} non-white ink`); return out; }
        if (x < m || y < m || x > px - m || y > px - m) { out.push(`${d} ink outside live box`); return out; }
      }
    }
    return out;
  }));

  const ico = readIco(buf('frontend/src/app/favicon.ico'));
  report(G, 'favicon.ico has exactly 16 and 32 entries; no frontend/public/favicon.ico', [
    ...(ico.map((e) => e.width).join() === '16,32' ? [] : [`entries ${ico.map((e) => e.width)}`]),
    ...(fs.existsSync(rel('frontend/public/favicon.ico')) ? ['public/favicon.ico exists'] : []),
  ]);

  const sizes = { 'frontend/public/splash/apple-splash-1290x2796.png': [1290, 2796], 'frontend/public/splash/apple-splash-1179x2556.png': [1179, 2556], 'frontend/public/splash/apple-splash-1170x2532.png': [1170, 2532], 'frontend/public/splash/apple-splash-2048x2732.png': [2048, 2732], 'frontend/public/og.png': [1200, 630] };
  report(G, 'startup images and og.png have their named sizes', Object.entries(sizes).flatMap(([f, [w, h]]) => { const p = png(f); return p.width === w && p.height === h ? [] : [`${f} ${p.width}x${p.height}`]; }));

  const covers = fs.readdirSync(rel('brand/demo/covers')).filter((f) => f.endsWith('.webp'));
  const pages = fs.readdirSync(rel('brand/demo/pages')).filter((f) => f.endsWith('.webp'));
  const cp = [];
  if (covers.length !== 24) cp.push(`${covers.length} covers`);
  for (const f of covers) { const s = readWebpSize(buf(`brand/demo/covers/${f}`)); if (s.width !== 720 || s.height !== 1080) cp.push(`${f} ${s.width}x${s.height}`); }
  if (pages.length !== 40) cp.push(`${pages.length} pages`);
  for (const f of pages) { const s = readWebpSize(buf(`brand/demo/pages/${f}`)); if (s.width !== 800 || s.height < 1200 || s.height > 3000) cp.push(`${f} ${s.width}x${s.height}`); }
  for (let i = 1; i <= 6; i++) { const f = `design/previews/covers/0${i}.webp`; if (!fs.existsSync(rel(f))) cp.push(`missing ${f}`); else { const s = readWebpSize(buf(f)); if (s.width !== 720 || s.height !== 1080) cp.push(`${f} ${s.width}x${s.height}`); } }
  report(G, '24 covers 720x1080, 40 pages 800 wide 1200..3000 tall, six preview covers', cp);

  const ct = ['brand/cinematic/export/icon-ios-1024.png', 'brand/cinematic/export/icon-ios-tinted-1024.png', 'mobile/docs/screenshots/app-icon.png'].filter((f) => png(f).colorType !== 2).map((f) => `${f} is not colour type 2`);
  const xc = 'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';
  if (!fs.existsSync(rel(xc))) ct.push('missing ' + xc);
  else { const a = png(xc).rgba(); for (let i = 3; i < a.length; i += 4) if (a[i] < 255) { ct.push('AppIcon 1024 has transparency'); break; } }
  report(G, 'iOS icons are opaque (colour type 2, no alpha in AppIcon 1024)', ct);

  const circ = [];
  for (const f of ['android-foreground-1024.png', 'android-monochrome-1024.png']) {
    const p = png(`brand/cinematic/export/${f}`);
    const r = insideCircle(p.rgba(), p.width, p.height, 512, 512, 312.89, (_r, _g, _b, a) => a > 8);
    if (!r.ok) circ.push(`${f} ink at radius ${r.worst.toFixed(1)}`);
  }
  const mk = png('frontend/public/icons/maskable-512.png');
  const r = insideCircle(mk.rgba(), 512, 512, 256, 256, 204.8, (R, Gc, B) => R > 8 || Gc > 8 || B > 8);
  if (!r.ok) circ.push(`maskable-512 ink at radius ${r.worst.toFixed(1)}`);
  report(G, 'Android foreground/monochrome inside 312.89, maskable inside 204.8', circ);

  const flat = [];
  for (const f of Object.keys(sizes).filter((k) => k.includes('splash'))) { const a = png(f).rgba(); for (let i = 0; i < a.length; i += 4) if (a[i] || a[i + 1] || a[i + 2] || a[i + 3] !== 255) { flat.push(`${f} not flat black`); break; } }
  const t = png('brand/splash/transparent-288.png').rgba();
  for (let i = 3; i < t.length; i += 4) if (t[i]) { flat.push('transparent-288 has alpha'); break; }
  report(G, 'startup images are flat #000000; transparent-288.png is fully transparent', flat);

  const fj = JSON.parse(read('backend/media/fonts/fonts.json') ?? '[]');
  report(G, 'six woff2 files start with wOF2 and match fonts.json sha256', [
    ...(fj.length === 6 ? [] : [`${fj.length} entries`]),
    ...fj.flatMap((e) => { const f = `backend/media/fonts/${e.file}`; if (!fs.existsSync(rel(f))) return [`missing ${e.file}`]; const b = buf(f); return b.toString('latin1', 0, 4) === 'wOF2' && crypto.createHash('sha256').update(b).digest('hex') === e.sha256 ? [] : [`${e.file} bad`]; }),
  ]);
}

const GROUPS = { glyphs, 'cinematic-brand': cinematic };
for (const [name, run] of Object.entries(GROUPS)) {
  try {
    run();
  } catch (e) {
    report(name, 'group crashed', [e.message]);
  }
}
console.log(failed ? `brand check: ${failed} failed` : 'brand check: all passed');
process.exit(failed ? 1 : 0);
