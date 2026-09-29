#!/usr/bin/env node
// The sound files in the design contract check (shared/03 item 7). Stdlib only, reads the
// committed files (no sox or ffmpeg), so it runs in CI. Exit 1 on any failure; the Glass
// intake's missing list is printed as a warning, never a failure.
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join } from "node:path";
import { readWav, peakDbfs } from "./wav.mjs";
import { root, missingList, missingText, parseSources, GLASS_DIR, GLASS_SOURCES } from "./trim-loop.mjs";

const recipes = JSON.parse(readFileSync(join(root, "design/sounds/recipes.json"), "utf8"));
const errors = [], warnings = [];
const ls = (d) => (existsSync(join(root, d)) ? readdirSync(join(root, d)).filter((f) => !f.startsWith(".")) : []);
let cues = 0;

for (const skin of ["cinematic", "glass"]) {
  const tokens = JSON.parse(readFileSync(join(root, `design/tokens/${skin}.json`), "utf8"));
  const stems = [...new Set(Object.values(tokens.sounds))];
  const dirs = { wav: `mobile/assets/sounds/${skin}`, web: `frontend/public/sounds/${skin}` };
  const want = { wav: stems.map((s) => `${s}.wav`), web: stems.flatMap((s) => [`${s}.ogg`, `${s}.m4a`]) };
  for (const k of ["wav", "web"]) {
    for (const f of want[k]) if (!existsSync(join(root, dirs[k], f))) errors.push(`missing ${dirs[k]}/${f}`);
    for (const f of ls(dirs[k])) if (!want[k].includes(f)) errors.push(`extra file ${dirs[k]}/${f}`);
  }
  let total = 0;
  for (const stem of stems) {
    const p = `${dirs.wav}/${stem}.wav`, r = recipes.cues[skin].cues[stem];
    if (!r) { errors.push(`${skin}/${stem}: no recipe`); continue; }
    if (!existsSync(join(root, p))) continue;
    const buf = readFileSync(join(root, p)); total += buf.length; cues++;
    const w = readWav(buf), s = w.samples[0];
    if (w.rate !== 48000 || w.bits !== 16 || w.channels !== 1) errors.push(`${p}: ${w.rate} Hz ${w.bits}-bit ${w.channels} ch, want 48000 Hz 16-bit mono`);
    const ms = (w.frames / w.rate) * 1000, pk = peakDbfs(w.samples);
    if (Math.abs(ms - r.length) > 1) errors.push(`${p}: ${ms.toFixed(2)} ms, recipe ${r.length} ms`);
    if (Math.abs(pk - r.peak) > 0.5) errors.push(`${p}: peak ${pk.toFixed(2)} dBFS, recipe ${r.peak}`);
    if (Math.abs(s[0]) > 1e-3 || Math.abs(s[s.length - 1]) > 1e-3) errors.push(`${p}: does not start and end on the fades`);
  }
  if (skin === "cinematic" && total > 393216) errors.push(`Cinematic WAV set is ${total} bytes, over 393,216 (384 KB)`);
  if (skin === "glass" && total > 327680) warnings.push(`Glass WAV set is ${total} bytes against the 320 KB figure of glass §6 (its 5,682 ms of cues need ${total} bytes at 48 kHz 16-bit mono; reported, not enforced)`);
}

const cinSources = existsSync(join(root, "backend/media/soundscapes/SOURCES.md")) ? readFileSync(join(root, "backend/media/soundscapes/SOURCES.md"), "utf8") : "";
const glassRows = existsSync(join(root, GLASS_SOURCES)) ? parseSources(readFileSync(join(root, GLASS_SOURCES), "utf8")) : new Map();
let loops = 0;
for (const [id, r] of Object.entries(recipes.loops)) {
  const glass = r.skin === "glass", base = glass ? `${GLASS_DIR}/${id.replace(/^glass-/, "")}` : `backend/media/soundscapes/${id}`;
  for (const ext of ["ogg", "m4a"]) {
    const f = `${base}.${ext}`;
    if (!existsSync(join(root, f)) || statSync(join(root, f)).size === 0) errors.push(`missing ${f}`);
  }
  if (glass ? !glassRows.get(id)?.Processing : !cinSources.includes(`\n## ${id}\n`)) errors.push(`${id}: no SOURCES.md ${glass ? "row" : "section"}`);
  loops++;
}

for (const l of missingText(missingList())) warnings.push(`Glass intake: ${l}`);
for (const w of warnings) console.log(`WARN ${w}`);
for (const e of errors) console.error(`sounds: ${e}`);
console.log(errors.length ? `sounds: ${errors.length} problems` : `sounds: ${cues} cue masters and their web files, ${loops} soundscape loops ok`);
process.exit(errors.length ? 1 : 0);
