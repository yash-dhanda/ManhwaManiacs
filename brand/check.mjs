#!/usr/bin/env node
// Brand checks, run as named groups in sequence (shared/02 adds `glyphs`; shared/04 and shared/05
// add `cinematic-brand` and `glass-brand`). Stdlib only; prints one line per check, exits 1 on any failure.
//   node brand/check.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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

const GROUPS = { glyphs };
for (const [name, run] of Object.entries(GROUPS)) {
  try {
    run();
  } catch (e) {
    report(name, 'group crashed', [e.message]);
  }
}
console.log(failed ? `brand check: ${failed} failed` : 'brand check: all passed');
process.exit(failed ? 1 : 0);
