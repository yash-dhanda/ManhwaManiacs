#!/usr/bin/env node
// Glass recorded soundscape layers: the intake (glass/DESIGN.md §9.4.2, §12.7; shared/03 item 6).
//
//   node design/sounds/trim-loop.mjs           process every file in design/sounds/incoming/glass/
//                                              named {scene}-{layer}.<ext> whose SOURCES.md row has a
//                                              Freesound URL and "CC0 1.0": decode to 48 kHz stereo,
//                                              take 96 s (at the row's Start (s), else the steadiest
//                                              window), make the 90 s equal-power loop, normalise
//                                              (bed -26, detail -30, tone -32 LUFS; true peak <= -3 dBTP),
//                                              encode Opus + AAC into backend/media/soundscapes/glass/,
//                                              and fill the row's Processing, LUFS, Size and SHA-256
//   node design/sounds/trim-loop.mjs --check   name every missing file and incomplete row, exit 0
//   node design/sounds/trim-loop.mjs --strict  the same, exit 1 when anything is missing
//
// Also exports the ffmpeg, loudness and SOURCES.md table helpers render.mjs and check.mjs use.
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync, mkdirSync, rmSync } from "node:fs";
import { join, dirname, extname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { readWav, writeWav, makeLoop, rmsDb } from "./wav.mjs";

export const root = join(dirname(fileURLToPath(import.meta.url)), "../..");
export const GLASS_DIR = "backend/media/soundscapes/glass";
export const GLASS_SOURCES = `${GLASS_DIR}/SOURCES.md`;
export const INCOMING = "design/sounds/incoming/glass";
export const SCENES = ["rain", "wind", "ocean", "hearth", "stream", "deep"];
export const LAYERS = ["bed", "detail", "tone"];
export const LAYER_LUFS = { bed: -26, detail: -30, tone: -32 };
export const FFMPEG = process.env.FFMPEG || "ffmpeg";
const RATE = 48000;

// ---- tools ----
/** Run a command, append its line to `log`, throw on failure. Returns stdout+stderr text. */
export function run(cmd, args, log) {
  log?.push([cmd, ...args].map((a) => (/[\s"']/.test(a) ? JSON.stringify(a) : a)).join(" "));
  const r = spawnSync(cmd, args, { cwd: root, encoding: "utf8", maxBuffer: 1 << 28 });
  if (r.status !== 0) throw new Error(`${cmd} ${args.join(" ")} failed:\n${r.stderr}`);
  return r.stdout + r.stderr;
}
export function toolVersions() {
  const ff = spawnSync(FFMPEG, ["-version"], { encoding: "utf8" }).stdout?.split("\n")[0] ?? "ffmpeg: not found";
  const sox = spawnSync("sox", ["--version"], { encoding: "utf8" });
  return {
    sox: sox.status === 0 ? sox.stdout.trim() : `not installed (no sudo on the render box, so apt/pacman could not run); fallback: node design/sounds/synth.mjs (Node ${process.version})`,
    ffmpeg: ff,
  };
}
const BITEXACT = ["-fflags", "+bitexact", "-flags:a", "+bitexact", "-map_metadata", "-1"];
export const encodeArgs = {
  opus: (wav, out, mono) => ["-y", "-v", "error", "-i", wav, "-c:a", "libopus", "-b:a", "96k", ...(mono ? ["-ac", "1"] : []), ...BITEXACT, out],
  vorbis: (wav, out) => ["-y", "-v", "error", "-i", wav, "-c:a", "libvorbis", "-b:a", "96k", ...BITEXACT, out],
  aac: (wav, out, mono, kbps = 96) => ["-y", "-v", "error", "-i", wav, "-c:a", "aac", "-b:a", `${kbps}k`, ...(mono ? ["-ac", "1"] : []), "-movflags", "+faststart", ...BITEXACT, out],
};
/** Integrated loudness (LUFS) and true peak (dBTP) of a file, via ffmpeg's ebur128. */
export function loudness(file, log) {
  const out = run(FFMPEG, ["-hide_banner", "-nostats", "-i", file, "-af", "ebur128=peak=true", "-f", "null", "-"], log);
  const sum = out.slice(out.lastIndexOf("Summary:"));
  const I = Number(/I:\s+(-?[\d.]+|-inf) LUFS/.exec(sum)?.[1]);
  const tp = /True peak:[\s\S]*?Peak:\s+(-?[\d.]+|-inf) dBFS/.exec(sum)?.[1];
  return { lufs: I, truePeak: tp === "-inf" ? -Infinity : Number(tp) };
}
/** Decoded frame count (48 kHz) of any audio file. */
export function decodedFrames(file, channels = 1) {
  const r = spawnSync(FFMPEG, ["-v", "error", "-i", file, "-f", "s16le", "-ac", String(channels), "-ar", "48000", "-"], { cwd: root, maxBuffer: 1 << 30 });
  if (r.status !== 0) throw new Error(`decode ${file}: ${r.stderr}`);
  return r.stdout.length / (2 * channels);
}
export const sha256 = (file) => createHash("sha256").update(readFileSync(join(root, file))).digest("hex");
export const sizeOf = (file) => statSync(join(root, file)).size;
const scale = (chs, db) => chs.map((x) => x.map((v) => v * 10 ** (db / 20)));
const peakOf = (chs) => chs.reduce((m, x) => x.reduce((mm, v) => Math.max(mm, Math.abs(v)), m), 0);

/** Seam figures of a 90 s loop: per-channel RMS of the last and first 250 ms, and the jump across the seam. */
export function seam(chs) {
  const q = RATE / 4, n = chs[0].length;
  return chs.map((x) => {
    const end = rmsDb([x], n - q, n), start = rmsDb([x], 0, q);
    const diff = end === -Infinity && start === -Infinity ? 0 : Math.abs(end - start);
    return { endRms: end, startRms: start, rmsDiff: diff, jump: Math.abs(x[n - 1] - x[0]) };
  });
}
/** Seam of the decoded (stereo, 48 kHz) file, so codec noise is counted. */
export function decodedSeam(file) {
  const r = spawnSync(FFMPEG, ["-v", "error", "-i", file, "-f", "f32le", "-ac", "2", "-ar", "48000", "-"], { cwd: root, maxBuffer: 1 << 30 });
  if (r.status !== 0) throw new Error(`decode ${file}: ${r.stderr}`);
  const f = new Float32Array(r.stdout.buffer.slice(r.stdout.byteOffset, r.stdout.byteOffset + r.stdout.length)), n = f.length / 2;
  return seam([0, 1].map((c) => Float64Array.from({ length: n }, (_, i) => f[2 * i + c])));
}
/** Encode a loop's AAC, raising the bitrate until the decoded seam meets the 0.02 jump limit. */
export function encodeLoopAac(wav, out, log, maxJump = 0.02) {
  for (const kbps of [96, 112, 128, 144, 160, 192]) {
    run(FFMPEG, encodeArgs.aac(wav, out, false, kbps), log);
    if (decodedSeam(out).every((c) => c.jump < maxJump)) return kbps;
  }
  throw new Error(`${out}: decoded AAC seam jump stays above ${maxJump}`);
}
export const seamOk = (s, maxJump = 0.02) => s.every((c) => (c.endRms < -90 && c.startRms < -90) || c.rmsDiff <= 1.5) && s.every((c) => c.jump < maxJump);
/**
 * 99.9th percentile of |x[i+1] - x[i]| over all channels: how rough the audio itself is.
 * Broadband recordings (rain, surf) step by more than 0.02 between ordinary samples, so for them
 * the seam may jump as much as the audio already does anywhere else.
 */
export function naturalJump(chs) {
  const d = [];
  for (const x of chs) for (let i = 1; i < x.length; i += 7) d.push(Math.abs(x[i] - x[i - 1]));
  d.sort((a, b) => a - b);
  return d[Math.floor(d.length * 0.999)];
}

/**
 * Loudness-normalise a float stereo loop and write it as a 16-bit master at `wavOut`.
 * `cmdFor(gainDb)` is the command line recorded for the write at that gain.
 * Steps: bring the peak to -6 dBFS, measure, add the delta to `target`, lower until true peak <= -3.
 */
export function normaliseLoop(chs, target, wavOut, log, cmdFor) {
  const g0 = +(-6 - 20 * Math.log10(peakOf(chs))).toFixed(2);
  writeFileSync(join(root, wavOut), writeWav({ rate: RATE, samples: scale(chs, g0) }));
  const m0 = loudness(wavOut, log);
  let g = +(g0 + target - m0.lufs).toFixed(2);
  let final;
  for (let i = 0; i < 20; i++) {
    log.push(cmdFor(g));
    writeFileSync(join(root, wavOut), writeWav({ rate: RATE, samples: scale(chs, g) }));
    final = loudness(wavOut, log);
    if (final.truePeak <= -3) break;
    g = +(g - (final.truePeak + 3) - 0.1).toFixed(2);
  }
  if (!(final.truePeak <= -3)) throw new Error(`${wavOut}: true peak ${final.truePeak} dBTP stays above -3`);
  if (final.lufs > target + 1) // lower is allowed: the true-peak rule wins and the LUFS is recorded
    throw new Error(`${wavOut}: ${final.lufs} LUFS, target ${target}`);
  const w = readWav(readFileSync(join(root, wavOut)));
  return { gain: g, ...final, seam: seam(w.samples), samples: w.samples };
}

// ---- SOURCES.md table ----
export const COLUMNS = ["Id", "Scene", "Layer", "What to look for", "Freesound URL", "Author", "Licence", "Original file", "Start (s)", "Processing", "LUFS", "Size", "SHA-256"];
const LOOK_FOR = {
  rain: ["steady rain on a roof", "drips on a window pane", "low room tone"],
  wind: ["wind through trees", "leaves and a creaking branch", "far drone"],
  ocean: ["waves on sand", "shingle drawback", "distant gulls"],
  hearth: ["fire bed", "crackles and embers", "night wind"],
  stream: ["running water", "pebbles and a small fall", "birds far off"],
  deep: ["synthesised drone in A (sines 55 + 82.41 Hz, 0.03 Hz chorus, pink noise under 300 Hz)", "synthesised slow shimmer (A6 + E7, tremolo, reverb)", "synthesised soft pulses (110 Hz, 16 per loop)"],
};
export const layerIds = () => SCENES.flatMap((s) => LAYERS.map((l) => ({ scene: s, layer: l, id: `glass-${s}-${l}`, stem: `${s}-${l}` })));

export function parseSources(text) {
  const rows = new Map();
  for (const line of text.split("\n")) {
    if (!line.startsWith("| glass-")) continue;
    const cells = line.slice(1, -1).split(" | ").map((c) => c.trim());
    rows.set(cells[0], Object.fromEntries(COLUMNS.map((c, i) => [c, cells[i] ?? ""])));
  }
  return rows;
}
const cell = (v) => String(v ?? "").replace(/\|/g, "\\|").replace(/\n/g, " ");
export function formatTable(rows) {
  const lines = [`| ${COLUMNS.join(" | ")} |`, `|${COLUMNS.map(() => "---").join("|")}|`];
  for (const { id, scene, layer } of layerIds()) {
    const r = rows.get(id) ?? {};
    const base = { Id: id, Scene: scene, Layer: layer, "What to look for": LOOK_FOR[scene][LAYERS.indexOf(layer)] };
    lines.push(`| ${COLUMNS.map((c) => cell(base[c] ?? r[c] ?? "")).join(" | ")} |`);
  }
  return lines.join("\n");
}
/** Rewrite the table in SOURCES.md with `rows` (keeping everything else), creating the file if needed. */
export function writeSources(rows, extraSections = null) {
  const p = join(root, GLASS_SOURCES);
  let text = existsSync(p) ? readFileSync(p, "utf8") : SOURCES_TEMPLATE;
  const start = text.indexOf("| Id |"), end = text.indexOf("\n\n", start);
  text = text.slice(0, start) + formatTable(rows) + (end < 0 ? "\n" : text.slice(end));
  if (extraSections) for (const [heading, body] of extraSections) {
    const h = `\n## ${heading}\n`, i = text.indexOf(h);
    const j = i < 0 ? -1 : text.indexOf("\n## ", i + h.length);
    const block = `${h}\n${body.trim()}\n`;
    text = i < 0 ? text.trimEnd() + "\n" + block : text.slice(0, i) + block + (j < 0 ? "" : text.slice(j));
  }
  mkdirSync(dirname(p), { recursive: true });
  writeFileSync(p, text.trimEnd() + "\n");
}
const SOURCES_TEMPLATE = `# Glass soundscape layers: sources

Glass's six scenes (glass/DESIGN.md §9.4.2) each have three recorded layers, \`bed\`, \`detail\` and \`tone\`: 90 s seamless loops served as \`/app/soundscapes/glass-{scene}-{layer}.{ogg,m4a}\` (alias \`/app/soundscapes/glass/{scene}-{layer}.{ext}\`). Until a layer's two files exist, the apps play Glass's procedural layer for it (web/44, mobile/44).

**Deep** is synthesised by \`design/sounds/render.mjs\` (no third-party material). The other fifteen layers are **CC0 1.0 field recordings from freesound.org only**: no CC-BY, no Sampling+, nothing imitating a named work. For each one:

1. Pick a recording on freesound.org whose licence reads "Creative Commons 0" and that matches "What to look for". It must be at least 96 s long.
2. Download the original and save it as \`design/sounds/incoming/glass/{scene}-{layer}.<its extension>\` (for example \`rain-bed.wav\`). That folder is git-ignored: raw downloads never enter the repo.
3. Fill the row below: Freesound URL, Author, Licence (\`CC0 1.0\`), Original file name, and optionally Start (s) to choose where the 96 s window begins (empty: the steadiest 96 s is found automatically).
4. Run \`node design/sounds/trim-loop.mjs\`. It trims, loops, normalises (bed −26, detail −30, tone −32 LUFS, true peak ≤ −3 dBTP) and encodes the two files into \`backend/media/soundscapes/glass/\`, and fills Processing, LUFS, Size and SHA-256.
5. Commit the two new files and this file. \`node design/sounds/trim-loop.mjs --check\` lists what is still missing.

| Id |

`;

// ---- the missing list ----
export function missingList() {
  const rows = existsSync(join(root, GLASS_SOURCES)) ? parseSources(readFileSync(join(root, GLASS_SOURCES), "utf8")) : new Map();
  const files = [], rowsMissing = [];
  for (const { id, scene, stem } of layerIds()) {
    for (const ext of ["ogg", "m4a"]) if (!existsSync(join(root, GLASS_DIR, `${stem}.${ext}`))) files.push(`${stem}.${ext}`);
    if (scene === "deep") continue; // synthesised: no URL, no licence
    const r = rows.get(id);
    if (!r || !/^https:\/\/freesound\.org\//.test(r["Freesound URL"]) || r.Licence !== "CC0 1.0") rowsMissing.push(id);
  }
  return { files, rows: rowsMissing };
}
export function missingText({ files, rows }) {
  const lines = [];
  if (files.length) lines.push(`missing files (${files.length}): ${files.join(", ")}`);
  if (rows.length) lines.push(`rows without a Freesound URL or a CC0 1.0 licence (${rows.length}): ${rows.join(", ")}`);
  return lines;
}

// ---- processing ----
function steadiestStart(chs, total) {
  const secs = Math.floor(total / RATE), rms = [];
  for (let s = 0; s < secs; s++) rms.push(rmsDb(chs, s * RATE, (s + 1) * RATE));
  let best = 0, bestVar = Infinity;
  for (let s = 0; s + 96 <= secs; s++) {
    const w = rms.slice(s, s + 96).map((v) => (v === -Infinity ? -120 : v)), m = w.reduce((a, b) => a + b, 0) / 96;
    const v = w.reduce((a, b) => a + (b - m) ** 2, 0) / 96;
    if (v < bestVar) { bestVar = v; best = s; }
  }
  return best;
}

function processIncoming() {
  const dir = join(root, INCOMING);
  const rows = parseSources(readFileSync(join(root, GLASS_SOURCES), "utf8"));
  const files = existsSync(dir) ? readdirSync(dir).filter((f) => !f.startsWith(".")) : [];
  let done = 0;
  for (const f of files.sort()) {
    const stem = basename(f, extname(f)), id = `glass-${stem}`, r = rows.get(id);
    const layer = stem.split("-")[1];
    if (!r || stem.startsWith("deep-")) { console.log(`skip ${f}: not one of the fifteen recorded layers ({scene}-{layer})`); continue; }
    if (!/^https:\/\/freesound\.org\//.test(r["Freesound URL"]) || r.Licence !== "CC0 1.0") {
      console.log(`skip ${f}: its SOURCES.md row needs a freesound.org URL and the licence "CC0 1.0"`); continue;
    }
    const log = [], tmp = join("design/sounds/.build", `${stem}`);
    mkdirSync(join(root, tmp), { recursive: true });
    run(FFMPEG, ["-y", "-v", "error", "-i", `${INCOMING}/${f}`, "-ac", "2", "-ar", "48000", "-c:a", "pcm_s16le", `${tmp}/decoded.wav`], log);
    const w = readWav(readFileSync(join(root, tmp, "decoded.wav")));
    if (w.frames < 96 * RATE) { console.log(`skip ${f}: ${(w.frames / RATE).toFixed(1)} s long, needs at least 96 s`); continue; }
    const start = r["Start (s)"] !== "" ? Number(r["Start (s)"]) : steadiestStart(w.samples, w.frames);
    if (!(start >= 0 && (start + 96) * RATE <= w.frames)) { console.log(`skip ${f}: Start (s) ${r["Start (s)"]} leaves less than 96 s`); continue; }
    const cut = w.samples.map((x) => Float64Array.from(x.subarray(start * RATE, (start + 96) * RATE)));
    const loop = makeLoop(cut, RATE, 90, 6);
    const res = normaliseLoop(loop, LAYER_LUFS[layer], `${tmp}/loop.wav`, log,
      (g) => `node: 96 s from ${start} s of decoded.wav, 90 s equal-power loop (6 s), gain ${g} dB -> ${tmp}/loop.wav`);
    const maxJump = Math.max(0.02, naturalJump(res.samples));
    if (!seamOk(res.seam, maxJump)) throw new Error(`${f}: seam check failed (jump limit ${maxJump.toFixed(4)}) ${JSON.stringify(res.seam)}`);
    const out = { ogg: `${GLASS_DIR}/${stem}.ogg`, m4a: `${GLASS_DIR}/${stem}.m4a` };
    run(FFMPEG, encodeArgs.opus(`${tmp}/loop.wav`, out.ogg), log);
    encodeLoopAac(`${tmp}/loop.wav`, out.m4a, log, maxJump);
    rows.set(id, {
      ...r,
      Processing: `trim-loop.mjs: 96 s from ${start} s, 90 s equal-power loop, gain ${res.gain} dB, Opus + AAC (96k, raised until the decoded seam jump is under 0.02)`,
      LUFS: `${res.lufs.toFixed(1)} (TP ${res.truePeak.toFixed(1)} dBTP)`,
      Size: `ogg ${sizeOf(out.ogg)} B, m4a ${sizeOf(out.m4a)} B`,
      "SHA-256": `ogg ${sha256(out.ogg)}, m4a ${sha256(out.m4a)}`,
    });
    writeSources(rows);
    rmSync(join(root, tmp), { recursive: true, force: true });
    console.log(`${f} -> ${out.ogg}, ${out.m4a} (${res.lufs.toFixed(1)} LUFS, TP ${res.truePeak.toFixed(1)} dBTP)`);
    done++;
  }
  console.log(`trim-loop: processed ${done} of ${files.length} incoming files`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const strict = process.argv.includes("--strict");
  if (strict || process.argv.includes("--check")) {
    const m = missingList();
    for (const l of missingText(m)) console.log(l);
    const n = m.files.length + m.rows.length;
    console.log(n ? `WARN trim-loop: ${m.files.length} of 36 Glass layer files missing, ${m.rows.length} rows incomplete (procedural layers play meanwhile)` : "trim-loop: all 36 Glass layer files present");
    process.exit(strict && n ? 1 : 0);
  }
  processIncoming();
}
