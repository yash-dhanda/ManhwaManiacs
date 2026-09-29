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

function glass() {
  const G = 'glass-brand';
  const buf = (f) => fs.readFileSync(rel(f));
  const png = (f) => readPng(buf(f));
  const man = JSON.parse(read('brand/glass/export/manifest.json') ?? '{"outputs":[]}').outputs;

  const bad = [];
  for (const o of man) {
    if (!fs.existsSync(rel(o.path))) { bad.push(`missing ${o.path}`); continue; }
    const s = o.path.endsWith('.png') ? png(o.path) : o.path.endsWith('.webp') ? readWebpSize(buf(o.path)) : null;
    if (s && (s.width !== o.width || s.height !== o.height)) bad.push(`${o.path} is ${s.width}x${s.height}`);
  }
  const dens = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
  const leg = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
  const res = 'mobile/android/app/src/main/res';
  for (const [d, px] of Object.entries(dens)) for (const l of ['foreground', 'background', 'monochrome']) {
    const f = `${res}/drawable-${d}/ic_launcher_glass_${l}.png`;
    if (!fs.existsSync(rel(f))) bad.push(`missing ${f}`); else if (png(f).width !== px) bad.push(`${f} is ${png(f).width}, want ${px}`);
  }
  for (const [d, px] of Object.entries(leg)) {
    const f = `${res}/mipmap-${d}/ic_launcher_glass.png`;
    if (!fs.existsSync(rel(f))) bad.push(`missing ${f}`); else if (png(f).width !== px) bad.push(`${f} is ${png(f).width}, want ${px}`);
  }
  const X = 'mobile/ios/Runner/Assets.xcassets/AppIcon-Glass.appiconset';
  for (const n of ['AppIcon-Glass-1024', 'AppIcon-Glass-1024-dark', 'AppIcon-Glass-1024-tinted']) {
    const f = `${X}/${n}.png`;
    if (!fs.existsSync(rel(f))) bad.push(`missing ${f}`); else if (png(f).width !== 1024 || png(f).height !== 1024) bad.push(`${f} not 1024`);
  }
  if (!fs.existsSync(rel('frontend/public/glass/droplets.webp'))) bad.push('missing droplets.webp');
  else { const s = readWebpSize(buf('frontend/public/glass/droplets.webp')); if (s.width !== 480 || s.height !== 480) bad.push(`droplets.webp ${s.width}x${s.height}`); }
  report(G, `${man.length} exported files, ic_launcher_glass densities 108..432 / 48..192, appiconset 1024, droplets 480x480`, bad.length || !man.length ? bad.concat(man.length ? [] : ['empty manifest']) : []);

  const alpha = [];
  for (const f of ['brand/glass/export/icon-ios-1024.png', 'brand/glass/export/icon-ios-tinted-1024.png', `${X}/AppIcon-Glass-1024.png`, `${X}/AppIcon-Glass-1024-tinted.png`])
    if (png(f).colorType !== 2) alpha.push(`${f} is not colour type 2`);
  const dk = png(`${X}/AppIcon-Glass-1024-dark.png`), da = dk.rgba();
  for (const [x, y] of [[0, 0], [1023, 0], [0, 1023], [1023, 1023]]) if (da[(y * 1024 + x) * 4 + 3] !== 0) alpha.push('dark icon corner is not transparent');
  report(G, 'iOS light/tinted are colour type 2; dark has transparent corners', alpha);

  const circ = [];
  for (const f of ['android-foreground-1024.png', 'android-monochrome-1024.png']) {
    const p = png(`brand/glass/export/${f}`);
    const r = insideCircle(p.rgba(), p.width, p.height, 512, 512, 312.89, (_r, _g, _b, a) => a > 8);
    if (!r.ok) circ.push(`${f} ink at radius ${r.worst.toFixed(1)}`);
  }
  for (const l of ['foreground', 'monochrome']) {
    const f = `${res}/drawable-xxxhdpi/ic_launcher_glass_${l}.png`;
    const p = png(f);
    const r = insideCircle(p.rgba(), 432, 432, 216, 216, 132, (_r, _g, _b, a) => a > 8);
    if (!r.ok) circ.push(`${f} ink at radius ${r.worst.toFixed(1)}`);
  }
  report(G, 'Android foreground/monochrome inside the 66 dp circle (312.89 of 1024, 132 px at xxxhdpi)', circ);

  const mk = png('frontend/public/icons/maskable-512.png');
  const rm = insideCircle(mk.rgba(), 512, 512, 256, 256, 204.8, (R, Gc, B) => R > 8 || Gc > 8 || B > 8);
  report(G, 'PWA maskable-512 inside the 40 % safe circle (shared, skin-neutral)', rm.ok ? [] : [`ink at radius ${rm.worst.toFixed(1)}`]);

  const ic = [];
  const I = 'mobile/ios/Runner/AppIcon-Glass.icon';
  try {
    const j = JSON.parse(read(`${I}/icon.json`));
    const names = j.groups.map((g) => g.name).join();
    if (names !== 'top-m,gutter-bar,bottom-m,field') ic.push(`groups ${names}`);
    for (const g of j.groups) for (const l of g.layers) {
      if (!fs.existsSync(rel(`${I}/Assets/${l['image-name']}`))) ic.push(`missing Assets/${l['image-name']}`);
      if (l['image-name'].endsWith('.svg') && !/viewBox="0 0 1024 1024"/.test(read(`${I}/Assets/${l['image-name']}`) ?? '')) ic.push(`${l['image-name']} viewBox`);
    }
    const assets = fs.readdirSync(rel(`${I}/Assets`)).sort().join();
    if (assets !== 'bottom-m.svg,field.png,gutter-bar.svg,top-m.svg') ic.push(`Assets is ${assets}`);
  } catch (e) { ic.push(e.message); }
  report(G, 'AppIcon-Glass.icon: groups, images and 1024 viewBoxes', ic);

  const fv = read('frontend/public/favicon-glass.svg') ?? '';
  const fp = [];
  if (!/viewBox="0 0 32 32"/.test(fv)) fp.push('viewBox');
  if (!/class="full"/.test(fv) || !/class="small"/.test(fv)) fp.push('.full/.small groups');
  if (!/max-width:\s*31px/.test(fv)) fp.push('max-width: 31px rule');
  report(G, 'favicon-glass.svg: 32 box, .full and .small groups, 31px rule', fp);

  const flag = JSON.parse(read('design/contract.json')).flags.glass_available;
  const parts = {
    'activity-alias': (read('mobile/android/app/src/main/AndroidManifest.xml') ?? '').includes('activity-alias'),
    FlutterDynamicIconPlusService: (read('mobile/android/app/src/main/AndroidManifest.xml') ?? '').includes('FlutterDynamicIconPlusService'),
    'AppIcon-Glass': (read('mobile/ios/Runner.xcodeproj/project.pbxproj') ?? '').includes('AppIcon-Glass'),
    ALTERNATE_APPICON_NAMES: (read('mobile/ios/Runner.xcodeproj/project.pbxproj') ?? '').includes('ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES'),
  };
  report(G, `registration gate (glass_available=${flag})`, Object.entries(parts).filter(([, present]) => present !== flag).map(([k, present]) => (flag ? `${k} missing` : `${k} present while glass_available is false`)));

  const ids = 11;
  const styles = 'brand/onboarding/styles';
  const miss = ['painted', 'cel', 'screentone', 'manhua-3d', 'watercolour', 'sketch', 'retro', 'pastel', 'noir', 'chibi', 'dark-realism'].filter((i) => !fs.existsSync(rel(`${styles}/masters/${i}.png`))).length;
  console.log(`warn ${G}: art intake: ${miss} of ${ids} masters missing (node brand/onboarding/styles/intake.mjs --check)`);
}

const GROUPS = { glyphs, 'cinematic-brand': cinematic, 'glass-brand': glass };
for (const [name, run] of Object.entries(GROUPS)) {
  try {
    run();
  } catch (e) {
    report(name, 'group crashed', [e.message]);
  }
}
console.log(failed ? `brand check: ${failed} failed` : 'brand check: all passed');
process.exit(failed ? 1 : 0);
