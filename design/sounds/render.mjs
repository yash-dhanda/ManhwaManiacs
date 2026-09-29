#!/usr/bin/env node
// Renders every shipped sound from design/sounds/recipes.json (shared/03).
//
//   node design/sounds/render.mjs cues     41 cue masters (48 kHz 16-bit mono WAV) -> mobile/assets/sounds/<skin>/,
//                                          Ogg Opus + AAC .m4a -> frontend/public/sounds/<skin>/;
//                                          commands -> design/sounds/cue-commands.txt
//   node design/sounds/render.mjs loops    8 Cinematic loops (Vorbis + AAC) and Glass Deep's 3 layers (Opus + AAC)
//                                          -> backend/media/soundscapes/, commands -> the SOURCES.md files
//   node design/sounds/render.mjs --proof  docs/redesign/proof/shared-03/{cues.svg, soundscapes.svg, levels.txt}
//
// sox is not installed on the render box (no sudo), so synthesis is design/sounds/synth.mjs (the
// shared/03 fallback); ffmpeg ($FFMPEG or PATH) encodes and measures loudness. Render-time checks
// fail the run: decoded web length within 2 ms of the master, loop seam, loudness and true peak.
import { readFileSync, writeFileSync, mkdirSync, readdirSync, rmSync, existsSync } from "node:fs";
import { join } from "node:path";
import { renderCue, renderLoop, timingChain, fnv1a, RATE, scaleBy } from "./synth.mjs";
import { readWav, writeWav, peakDbfs, rmsDb } from "./wav.mjs";
import {
  root, FFMPEG, run, toolVersions, encodeArgs, decodedFrames, normaliseLoop, seamOk, loudness, seam,
  sha256, sizeOf, parseSources, writeSources, missingList, missingText, GLASS_DIR, GLASS_SOURCES,
} from "./trim-loop.mjs";

const recipes = JSON.parse(readFileSync(join(root, "design/sounds/recipes.json"), "utf8"));
const tokens = (skin) => JSON.parse(readFileSync(join(root, `design/tokens/${skin}.json`), "utf8"));
const SKINS = ["cinematic", "glass"];
const BUILD = "design/sounds/.build";
const w = (p, data) => { mkdirSync(join(root, p, ".."), { recursive: true }); writeFileSync(join(root, p), data); };

/** Cue stems of a skin from its token file, checked against the recipes. */
export function stems(skin) {
  const s = [...new Set(Object.values(tokens(skin).sounds))];
  const r = Object.keys(recipes.cues[skin].cues);
  const miss = s.filter((x) => !r.includes(x)), extra = r.filter((x) => !s.includes(x));
  if (miss.length || extra.length) throw new Error(`${skin}: tokens and recipes differ (no recipe: ${miss}; no token: ${extra})`);
  return s;
}

const master = (skin, stem) => `mobile/assets/sounds/${skin}/${stem}.wav`;
const web = (skin, stem, ext) => `frontend/public/sounds/${skin}/${stem}.${ext}`;

function renderCues() {
  const v = toolVersions(), log = [`# shared/03 cue commands, in order (written by design/sounds/render.mjs cues)`, `# ${v.sox}`, `# ${v.ffmpeg}`, ""];
  for (const skin of SKINS) {
    const list = stems(skin);
    for (const dir of [`mobile/assets/sounds/${skin}`, `frontend/public/sounds/${skin}`]) { // no stale files
      if (existsSync(join(root, dir))) for (const f of readdirSync(join(root, dir))) if (!list.includes(f.replace(/\.[^.]+$/, ""))) rmSync(join(root, dir, f));
    }
    if (recipes.cues[skin].post) log.push(`# ${skin} post-chain: ${recipes.cues[skin].post}`);
    for (const stem of list) {
      const cue = recipes.cues[skin].cues[stem];
      log.push(`# ${skin}/${stem}: ${cue.length} ms, peak ${cue.peak} dBFS, timing: ${timingChain(cue)}`);
      log.push(`node design/sounds/synth.mjs ${skin}/${stem} ${master(skin, stem)}`);
      const buf = writeWav({ rate: RATE, samples: [renderCue(recipes, skin, stem)] });
      const again = writeWav({ rate: RATE, samples: [renderCue(recipes, skin, stem)] });
      if (!buf.equals(again)) throw new Error(`${skin}/${stem}: two renders differ`);
      w(master(skin, stem), buf);
      mkdirSync(join(root, `frontend/public/sounds/${skin}`), { recursive: true });
      run(FFMPEG, encodeArgs.opus(master(skin, stem), web(skin, stem, "ogg"), true), log);
      run(FFMPEG, encodeArgs.aac(master(skin, stem), web(skin, stem, "m4a"), true), log);
      const frames = readWav(buf).frames;
      for (const ext of ["ogg", "m4a"]) {
        const d = decodedFrames(web(skin, stem, ext));
        if (Math.abs(d - frames) > 0.002 * RATE) throw new Error(`${web(skin, stem, ext)} decodes to ${d} frames, master ${frames}`);
      }
      console.log(`${skin}/${stem}: ${cue.length} ms, ${peakDbfs(readWav(buf).samples).toFixed(2)} dBFS`);
    }
  }
  w("design/sounds/cue-commands.txt", log.join("\n") + "\n");
}

// ---- loops ----
const loopFiles = (id) => {
  const r = recipes.loops[id];
  const base = r.skin === "glass" ? `${GLASS_DIR}/${id.replace(/^glass-/, "")}` : `backend/media/soundscapes/${id}`;
  return { ogg: `${base}.ogg`, m4a: `${base}.m4a` };
};
const fmtSeam = (s) => s.map((c, i) => `${["L", "R"][i]}: last ${c.endRms.toFixed(1)} / first ${c.startRms.toFixed(1)} dB RMS (diff ${c.rmsDiff.toFixed(2)}), jump ${c.jump.toFixed(4)}`).join("; ");

function renderLoops() {
  mkdirSync(join(root, BUILD), { recursive: true });
  const v = toolVersions(), results = {};
  for (const id of Object.keys(recipes.loops)) {
    const r = recipes.loops[id], files = loopFiles(id), wav = `${BUILD}/${id}.wav`, log = [];
    const target = r.lufs ?? -26;
    const chs = renderLoop(recipes, id);
    const res = normaliseLoop(chs, target, wav, log, (g) => `node design/sounds/synth.mjs loop/${id} ${wav} --gain ${g}`);
    // the recorded command must reproduce the master byte for byte
    const again = writeWav({ rate: RATE, samples: renderLoop(recipes, id).map((x) => scaleBy(x, res.gain)) });
    if (!again.equals(readFileSync(join(root, wav)))) throw new Error(`${id}: re-render with --gain ${res.gain} differs`);
    if (!seamOk(res.seam)) throw new Error(`${id}: seam check failed: ${fmtSeam(res.seam)}`);
    if (res.samples[0].length !== 90 * RATE) throw new Error(`${id}: ${res.samples[0].length} frames`);
    const glass = r.skin === "glass";
    run(FFMPEG, glass ? encodeArgs.opus(wav, files.ogg) : encodeArgs.vorbis(wav, files.ogg), log);
    run(FFMPEG, encodeArgs.aac(wav, files.m4a), log);
    for (const ext of ["ogg", "m4a"]) {
      const d = decodedFrames(files[ext], 2);
      if (Math.abs(d - 90 * RATE) > 0.002 * RATE) throw new Error(`${files[ext]} decodes to ${d} frames`);
    }
    results[id] = { ...res, log, files, seed: fnv1a(id), target, variants: (r.events ?? []).map((e) => [e.name, e.rendered]) };
    console.log(`${id}: ${res.lufs} LUFS, TP ${res.truePeak} dBTP, gain ${res.gain} dB; ${fmtSeam(res.seam)}; ogg ${sizeOf(files.ogg)} B, m4a ${sizeOf(files.m4a)} B`);
  }
  // Cinematic SOURCES.md
  const cin = Object.keys(results).filter((id) => recipes.loops[id].skin !== "glass");
  const md = [
    "# Cinematic soundscapes: sources",
    "",
    "The eight Cinematic ambient loops (cinematic/DESIGN.md §9.4.2), served as `/app/soundscapes/{id}.{ogg,m4a}`. Every file is synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material. The owner may replace a loop with a CC0 1.0 recording later (see `design/sounds/trim-loop.mjs`), updating its section here.",
    "",
    "Format: 90.000 s seamless loops, 48 kHz stereo, −26 LUFS integrated, true peak ≤ −3 dBTP; Ogg Vorbis 96 kb/s and AAC-LC 96 kb/s `.m4a`.",
    "",
    `- sox: ${v.sox}`,
    `- ffmpeg: ${v.ffmpeg}`,
    "",
    "Synthesis runs `node design/sounds/synth.mjs loop/<id> <wav> --gain <dB>`: the sox-style chains below (from `design/sounds/recipes.json`) rendered by the pure-Node interpreter at the top of `synth.mjs`; beds 96 s per channel, then the 90 s equal-power loop (last 6 s cross-faded into the first 6 s), then events on the 90 s timeline modulo 90 s. `ffmpeg … ebur128` lines are the loudness measurements.",
  ];
  for (const id of cin) md.push("", ...section(id, results[id]));
  w("backend/media/soundscapes/SOURCES.md", md.join("\n") + "\n");
  // Glass Deep: rows + a commands section in glass/SOURCES.md
  const path = join(root, GLASS_SOURCES);
  const rows = existsSync(path) ? parseSources(readFileSync(path, "utf8")) : new Map();
  const deep = Object.keys(results).filter((id) => recipes.loops[id].skin === "glass");
  for (const id of deep) {
    const x = results[id];
    rows.set(id, {
      "Freesound URL": "none (synthesised)", Author: "ManhwaManiacs (synthesised by design/sounds/render.mjs)", Licence: "no third-party material",
      "Original file": "none", "Start (s)": "",
      Processing: `Synthesised: node design/sounds/synth.mjs loop/${id} … --gain ${x.gain}, then Opus + AAC 96k (commands below)`,
      LUFS: `${x.lufs.toFixed(1)} (TP ${x.truePeak.toFixed(1)} dBTP)`,
      Size: `ogg ${sizeOf(x.files.ogg)} B, m4a ${sizeOf(x.files.m4a)} B`,
      "SHA-256": `ogg ${sha256(x.files.ogg)}, m4a ${sha256(x.files.m4a)}`,
    });
  }
  writeSources(rows, [
    ["Tools", `- sox: ${v.sox}\n- ffmpeg: ${v.ffmpeg}`],
    ["Deep: synthesised layers", deep.map((id) => section(id, results[id]).join("\n")).join("\n\n").replace(/^## /gm, "### ")],
  ]);
}

function section(id, x) {
  const r = recipes.loops[id];
  return [
    `## ${id}`,
    "",
    `- Origin: Synthesised for ManhwaManiacs by \`design/sounds/render.mjs\`; no third-party material.`,
    `- Description: ${r.description}`,
    `- PRNG seed: mulberry32(FNV-1a("${id}")) = ${x.seed} (0x${x.seed.toString(16).padStart(8, "0")})`,
    ...(r.beds ?? []).map((b, i) => `- Bed ${i + 1} (${b.gain ?? 0} dB): \`${b.chain}\``),
    ...(r.events ?? []).map((e) => `- Events \`${e.name}\` (${e.gain ?? 0} dB${e.pan ? ", random pan ±0.8" : ""}, schedule ${JSON.stringify(e.schedule)}): six variants ${x.variants.find(([n]) => n === e.name)[1].map((c) => `\`${c}\``).join(", ")}`),
    `- Integrated loudness ${x.lufs.toFixed(1)} LUFS (target ${x.target}), true peak ${x.truePeak.toFixed(1)} dBTP, gain ${x.gain} dB`,
    `- Seam: ${fmtSeam(x.seam)}`,
    `- \`${x.files.ogg}\`: ${sizeOf(x.files.ogg)} bytes, SHA-256 ${sha256(x.files.ogg)}`,
    `- \`${x.files.m4a}\`: ${sizeOf(x.files.m4a)} bytes, SHA-256 ${sha256(x.files.m4a)}`,
    "",
    "Commands, in order:",
    "",
    "```",
    ...x.log,
    "```",
  ];
}

// ---- proof ----
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;");
function proof() {
  const out = "docs/redesign/proof/shared-03";
  mkdirSync(join(root, out), { recursive: true });
  const v = toolVersions(), lines = [];
  // cues.svg: both skins side by side, common time scale (1600 ms = 600 px)
  const colW = 600, pxPerMs = colW / 1600, rowH = 46, left = 16, gap = 40, labelH = 18;
  const cols = SKINS.map((skin) => {
    const ev = tokens(skin).soundEvents, list = stems(skin);
    return list.map((stem) => {
      const events = Object.entries(ev).filter(([, c]) => [c].flat().includes(stem) || [c].flat().includes(Object.keys(tokens(skin).sounds).find((k) => tokens(skin).sounds[k] === stem))).map(([e]) => e);
      const wav = readWav(readFileSync(join(root, master(skin, stem))));
      return { skin, stem, wav, events, cue: recipes.cues[skin].cues[stem] };
    });
  });
  const rows = Math.max(...cols.map((c) => c.length));
  const W = left * 2 + colW * 2 + gap, H = 70 + rows * (rowH + labelH);
  const svg = [`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="ui-monospace, Menlo, monospace">`,
    `<rect width="100%" height="100%" fill="#0b0b0c"/>`,
    `<text x="${left}" y="26" fill="#f2efe8" font-size="16">shared/03 UI cues: Cinematic "Press Room" (warm, low-passed 5 kHz, small room) | Glass "Meniscus" (struck glass, A-major pentatonic)</text>`,
    `<text x="${left}" y="46" fill="#9a968c" font-size="11">Envelope = sample peak per 0.5 ms bin, each row scaled to its own peak; common time scale ${pxPerMs * 100} px per 100 ms (1600 ms = ${colW} px)</text>`];
  cols.forEach((col, ci) => {
    const x0 = left + ci * (colW + gap), color = ci ? "#8fd3ff" : "#e7b465";
    col.forEach(({ stem, wav, events, cue }, ri) => {
      const y0 = 64 + ri * (rowH + labelH), s = wav.samples[0], bin = RATE / 2000, mid = y0 + labelH + rowH / 2;
      let pk = 0; for (const vv of s) pk = Math.max(pk, Math.abs(vv));
      const top = [], bot = [];
      for (let b = 0; b * bin < s.length; b++) {
        let m = 0; for (let i = b * bin; i < Math.min(s.length, (b + 1) * bin); i++) m = Math.max(m, Math.abs(s[i]));
        const x = (x0 + b * 0.5 * pxPerMs).toFixed(1), h = ((m / pk) * (rowH / 2 - 2)).toFixed(1);
        top.push(`${x},${(mid - h).toFixed(1)}`); bot.unshift(`${x},${(mid + +h).toFixed(1)}`);
      }
      svg.push(`<text x="${x0}" y="${y0 + 13}" fill="#f2efe8" font-size="11">${esc(stem)} · ${cue.length} ms · ${peakDbfs(s).toFixed(1)} dBFS <tspan fill="#9a968c">${esc(events.join(", ") || "(no event)")}</tspan></text>`);
      svg.push(`<line x1="${x0}" x2="${x0 + colW}" y1="${mid}" y2="${mid}" stroke="#2a2a2e"/>`);
      svg.push(`<line x1="${(x0 + cue.length * pxPerMs).toFixed(1)}" x2="${(x0 + cue.length * pxPerMs).toFixed(1)}" y1="${y0 + labelH}" y2="${y0 + labelH + rowH}" stroke="#3a3a40" stroke-dasharray="2 2"/>`);
      svg.push(`<polygon points="${top.concat(bot).join(" ")}" fill="${color}" fill-opacity="0.85"/>`);
    });
  });
  svg.push("</svg>");
  w(`${out}/cues.svg`, svg.join("\n") + "\n");

  // levels: cues
  lines.push("shared/03 sound levels (written by node design/sounds/render.mjs --proof)", `sox: ${v.sox}`, `ffmpeg: ${v.ffmpeg}`, "");
  for (const [ci, col] of cols.entries()) {
    lines.push(`${SKINS[ci]} cues`, "stem            len ms  target  peak dBFS  wav B    ogg B   ogg ms    m4a B   m4a ms   wav sha256");
    let total = 0;
    for (const { skin, stem, wav, cue } of col) {
      const f = master(skin, stem), size = sizeOf(f); total += size;
      const o = web(skin, stem, "ogg"), m = web(skin, stem, "m4a");
      lines.push([stem.padEnd(15), String(wav.frames / 48).padStart(6), String(cue.peak).padStart(7), peakDbfs(wav.samples).toFixed(2).padStart(9),
        String(size).padStart(8), String(sizeOf(o)).padStart(7), (decodedFrames(o) / 48).toFixed(2).padStart(8), String(sizeOf(m)).padStart(8), (decodedFrames(m) / 48).toFixed(2).padStart(8), sha256(f)].join(" "));
    }
    const budget = SKINS[ci] === "cinematic" ? 393216 : 327680;
    lines.push(`${SKINS[ci]} WAV total: ${total} bytes (${(total / 1024).toFixed(1)} KB) against ${budget / 1024} KB: ${total <= budget ? "within" : `OVER by ${total - budget} bytes (the §6 lengths at 48 kHz 16-bit mono need ${total} bytes)`}`, "");
  }
  // soundscapes.svg + levels
  const ids = Object.keys(recipes.loops);
  const sw = 900, sh = 90, W2 = sw + 2 * left, H2 = 60 + ids.length * (sh + 30);
  const s2 = [`<svg xmlns="http://www.w3.org/2000/svg" width="${W2}" height="${H2}" viewBox="0 0 ${W2} ${H2}" font-family="ui-monospace, Menlo, monospace">`,
    `<rect width="100%" height="100%" fill="#0b0b0c"/>`,
    `<text x="${left}" y="26" fill="#f2efe8" font-size="16">shared/03 soundscape loops: 1 s RMS over 90 s (decoded .ogg), -60 to 0 dBFS</text>`,
    `<text x="${left}" y="44" fill="#9a968c" font-size="11">Shaded: the seam regions, last 6 s and first 6 s (the equal-power cross-fade)</text>`];
  lines.push("soundscape loops (measured on the shipped files)", "id                  file                                              seconds   LUFS  TP dBTP  bytes    seam (decoded)  sha256");
  mkdirSync(join(root, BUILD), { recursive: true });
  ids.forEach((id, i) => {
    const files = loopFiles(id), y0 = 60 + i * (sh + 30), dec = `${BUILD}/proof-${id}.wav`;
    run(FFMPEG, ["-y", "-v", "error", "-i", files.ogg, "-c:a", "pcm_s16le", "-ar", "48000", "-ac", "2", dec]);
    const wv = readWav(readFileSync(join(root, dec)));
    const pts = [];
    for (let s = 0; s < 90; s++) {
      const db = Math.max(-60, rmsDb(wv.samples, s * RATE, (s + 1) * RATE));
      pts.push(`${(left + (s + 0.5) * (sw / 90)).toFixed(1)},${(y0 + 16 + ((-db) / 60) * sh).toFixed(1)}`);
    }
    s2.push(`<rect x="${left}" y="${y0 + 16}" width="${sw}" height="${sh}" fill="#141417"/>`);
    s2.push(`<rect x="${left}" y="${y0 + 16}" width="${(6 * sw) / 90}" height="${sh}" fill="#8fd3ff" fill-opacity="0.12"/>`);
    s2.push(`<rect x="${left + (84 * sw) / 90}" y="${y0 + 16}" width="${(6 * sw) / 90}" height="${sh}" fill="#8fd3ff" fill-opacity="0.12"/>`);
    s2.push(`<polyline points="${pts.join(" ")}" fill="none" stroke="${recipes.loops[id].skin === "glass" ? "#8fd3ff" : "#e7b465"}" stroke-width="1.5"/>`);
    s2.push(`<text x="${left}" y="${y0 + 12}" fill="#f2efe8" font-size="11">${esc(id)} <tspan fill="#9a968c">${esc(recipes.loops[id].description)}</tspan></text>`);
    for (const ext of ["ogg", "m4a"]) {
      const f = files[ext], m = loudness(f);
      if (ext === "m4a") run(FFMPEG, ["-y", "-v", "error", "-i", f, "-c:a", "pcm_s16le", "-ar", "48000", "-ac", "2", dec]);
      const sm = seam(readWav(readFileSync(join(root, dec))).samples);
      lines.push([id.padEnd(19), f.padEnd(49), (decodedFrames(f, 2) / RATE).toFixed(3).padStart(7), m.lufs.toFixed(1).padStart(6), m.truePeak.toFixed(1).padStart(8),
        String(sizeOf(f)).padStart(8), `${Math.max(...sm.map((c) => c.rmsDiff)).toFixed(2)} dB/${Math.max(...sm.map((c) => c.jump)).toFixed(4)}`.padStart(15), sha256(f)].join(" "));
    }
    rmSync(join(root, dec));
  });
  s2.push("</svg>");
  w(`${out}/soundscapes.svg`, s2.join("\n") + "\n");
  lines.push("", "Glass recorded layers still missing (node design/sounds/trim-loop.mjs --check):", ...missingText(missingList()).map((l) => `  ${l}`));
  w(`${out}/levels.txt`, lines.join("\n") + "\n");
  console.log(`wrote ${out}/cues.svg, soundscapes.svg, levels.txt`);
}

const arg = process.argv[2];
if (arg === "cues") renderCues();
else if (arg === "loops") renderLoops();
else if (arg === "--proof") proof();
else { console.error("usage: node design/sounds/render.mjs cues|loops|--proof"); process.exit(2); }
