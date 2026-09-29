#!/usr/bin/env node
// Pure-Node stand-in for sox (shared/03 fallback: sox could not be installed on the render box).
// It interprets the sox-style chains in design/sounds/recipes.json, covering exactly the
// operations those recipes use, deterministically (seeded noise, no dither):
//
//   synth <sec> <gen> [<gen> ...]   gen: sine <f> | sine <f1>:<f2>[/<glideSec>] (exponential sweep,
//                                   then held at f2) | whitenoise | pinknoise | brownnoise
//                                   (one channel per generator; `remix` folds them to mono)
//   remix 1v<g>,2v<g>,...           weighted sum of the generator channels to mono
//   channels 1                      average to mono (a no-op on mono)
//   lowpass <f> | highpass <f>      2-pole Butterworth (RBJ biquad, Q 0.7071), as sox's default
//   bandpass <f> <q>q               RBJ band-pass, 0 dB peak
//   sinc <f1>-<f2>                  band-pass as 4th-order Butterworth high-pass + low-pass
//   tremolo <hz> <depth%>           sine amplitude modulation between 1 - depth and 1
//   chorus <gin> <gout> <ms> <decay> <hz> <depthMs> -s   one sine-modulated voice
//   reverb [<rev%> [<hf%> [<room%> [<stereo%> [<predelayMs> [<wetDb>]]]]]]   Freeverb (8 combs, 4 all-pass), tail appended
//   fade [t|l|h|q|p] <in> [<stop> [<out>]]   sox fade: shapes linear, logarithmic (-100 dB), half-sine,
//                                   quarter-sine, parabola; truncates at <stop>
//   exp <d> [<attack>]              = fade l <attack=0.001> <d> <d>   (exponential decay of length d)
//   swell <d>                       = fade h <d/2> <d> <d/2>
//   steplp <f1> <f2> [<n=12>] [<splice=0.005>]   time-varying low-pass: n equal segments, cut-off
//                                   interpolated exponentially, joined with a linear splice
//   windbp <f0> <amp> <hz> <q> [<seg=1>] [<splice=0.05>]  band-pass whose centre follows
//                                   f0 + amp * sin(2 pi hz t), per segment, spliced
//   pad <before> [<after>] | trim <start> [<len>] | gain <dB> | norm <dB>
//
// CLI (the command recorded in the SOURCES.md files and cue-commands.txt):
//   node design/sounds/synth.mjs <skin>/<stem> <out.wav>            one cue master
//   node design/sounds/synth.mjs loop/<id> <out.wav> [--gain <dB>]  one 90 s loop master (48 kHz stereo)
import { writeFileSync } from "node:fs";
import { writeWav, makeLoop } from "./wav.mjs";

export const RATE = 48000;

// ---- deterministic randomness ----
export function fnv1a(str) {
  let h = 0x811c9dc5;
  for (const b of Buffer.from(str, "utf8")) { h ^= b; h = Math.imul(h, 0x01000193) >>> 0; }
  return h >>> 0;
}
export function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---- generators ----
function gen(kind, arg, n, rand) {
  const x = new Float64Array(n);
  if (kind === "sine") {
    const m = /^([\d.]+)(?::([\d.]+)(?:\/([\d.]+))?)?$/.exec(arg);
    if (!m) throw new Error(`bad sine ${arg}`);
    const f1 = +m[1], f2 = m[2] ? +m[2] : f1, T = m[3] ? Math.round(+m[3] * RATE) : n;
    let ph = 0;
    for (let i = 0; i < n; i++) {
      x[i] = Math.sin(ph);
      const f = f1 === f2 || i >= T ? f2 : f1 * (f2 / f1) ** (i / T);
      ph += (2 * Math.PI * f) / RATE;
    }
  } else if (kind === "whitenoise") {
    for (let i = 0; i < n; i++) x[i] = rand() * 2 - 1;
  } else if (kind === "pinknoise") { // Paul Kellet's refined pink filter
    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (let i = 0; i < n; i++) {
      const w = rand() * 2 - 1;
      b0 = 0.99886 * b0 + w * 0.0555179; b1 = 0.99332 * b1 + w * 0.0750759; b2 = 0.969 * b2 + w * 0.153852;
      b3 = 0.8665 * b3 + w * 0.3104856; b4 = 0.55 * b4 + w * 0.5329522; b5 = -0.7616 * b5 - w * 0.016898;
      x[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11; b6 = w * 0.115926;
    }
  } else if (kind === "brownnoise") { // leaky integrator
    let b = 0;
    for (let i = 0; i < n; i++) { b = (b + 0.02 * (rand() * 2 - 1)) / 1.02; x[i] = b * 3.5; }
  } else throw new Error(`unknown generator ${kind}`);
  return x;
}

// ---- filters ----
function biquad(type, f, q = Math.SQRT1_2) {
  const w = (2 * Math.PI * Math.min(f, RATE * 0.49)) / RATE, cs = Math.cos(w), al = Math.sin(w) / (2 * q);
  let b;
  if (type === "lp") b = [(1 - cs) / 2, 1 - cs, (1 - cs) / 2];
  else if (type === "hp") b = [(1 + cs) / 2, -(1 + cs), (1 + cs) / 2];
  else b = [al, 0, -al]; // band-pass, 0 dB peak
  const a0 = 1 + al;
  return { b0: b[0] / a0, b1: b[1] / a0, b2: b[2] / a0, a1: (-2 * cs) / a0, a2: (1 - al) / a0 };
}
function filt(x, c, from = 0, to = x.length) {
  const y = new Float64Array(to - from);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = from; i < to; i++) {
    const v = x[i], o = c.b0 * v + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2;
    x2 = x1; x1 = v; y2 = y1; y1 = o; y[i - from] = o;
  }
  return y;
}

/**
 * Time-varying filter as sox would do it with segments and `splice`: segment k covers
 * [k*seg, (k+1)*seg); each is filtered with its own coefficients (starting `warm` early so the
 * filter has settled), and consecutive segments overlap by `sp` with a linear cross-fade.
 */
function stepped(x, segLen, coefAt, sp) {
  const n = x.length, segs = Math.ceil(n / segLen), spN = Math.max(1, Math.round(sp * RATE));
  const warm = Math.round(0.05 * RATE), y = new Float64Array(n);
  for (let k = 0; k < segs; k++) {
    const s = k * segLen, e = Math.min(n, s + segLen + (k < segs - 1 ? spN : 0));
    const from = Math.max(0, s - warm), part = filt(x, coefAt(k, segs), from, e);
    for (let i = s; i < e; i++) {
      const v = part[i - from];
      const inFade = k > 0 && i < s + spN ? (i - s) / spN : 1;          // this segment fades in
      const outFade = k < segs - 1 && i >= s + segLen ? 1 - (i - s - segLen) / spN : 1;
      y[i] += v * inFade * outFade;
    }
  }
  return y;
}

// ---- envelopes (sox fade) ----
function fadeGain(type, x) { // x in [0, 1]: 0 = silent end, 1 = full
  switch (type) {
    case "t": return x;
    case "l": return x <= 0 ? 0 : 10 ** (-5 * (1 - x)); // logarithmic: -100 dB at the far end
    case "h": return (1 - Math.cos(Math.PI * x)) / 2;
    case "q": return Math.sin((Math.PI / 2) * x);
    case "p": return 1 - (1 - x) * (1 - x);
    default: throw new Error(`fade type ${type}`);
  }
}
function fade(x, type, inS, stopS, outS) {
  const n = stopS === undefined ? x.length : Math.min(x.length, Math.round(stopS * RATE));
  const y = Float64Array.from(x.subarray(0, n));
  const fi = Math.round(inS * RATE), fo = Math.round((outS ?? (stopS === undefined ? 0 : inS)) * RATE);
  for (let i = 0; i < fi && i < n; i++) y[i] *= fadeGain(type, i / fi);
  for (let i = Math.max(0, n - fo); i < n; i++) y[i] *= fadeGain(type, (n - 1 - i) / fo);
  return y;
}

// ---- time-based effects ----
function tremolo(x, hz, depth) {
  const d = depth / 100;
  return x.map((v, i) => v * (1 - d / 2 + (d / 2) * Math.sin((2 * Math.PI * hz * i) / RATE)));
}
function chorus(x, gin, gout, ms, decay, hz, depthMs) {
  const base = (ms * RATE) / 1000, dep = (depthMs * RATE) / 1000, y = new Float64Array(x.length);
  for (let i = 0; i < x.length; i++) {
    const d = base + (dep * (1 + Math.sin((2 * Math.PI * hz * i) / RATE))) / 2, p = i - d, j = Math.floor(p), fr = p - j;
    const del = j >= 0 && j + 1 < x.length ? x[j] * (1 - fr) + x[j + 1] * fr : 0;
    y[i] = (x[i] * gin + del * decay) * gout;
  }
  return y;
}
function reverb(x, rev, hf, room, _stereo, preMs, wetDb) {
  const scale = RATE / 44100, rs = 0.1 + 0.9 * (room / 100);
  const fb = 0.3 + 0.68 * (rev / 100), damp = 0.4 * (hf / 100), wet = 10 ** (wetDb / 20);
  const combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617].map((d) => Math.max(1, Math.round(d * scale * rs)));
  const aps = [556, 441, 341, 225].map((d) => Math.max(1, Math.round(d * scale)));
  const pre = Math.round((preMs * RATE) / 1000);
  const tail = Math.min(10 * RATE, pre + Math.ceil((Math.max(...combs) * 3) / -Math.log10(fb)));
  const n = x.length + tail, y = new Float64Array(n);
  const cb = combs.map((d) => ({ buf: new Float64Array(d), i: 0, lp: 0 }));
  const ab = aps.map((d) => ({ buf: new Float64Array(d), i: 0 }));
  for (let i = 0; i < n; i++) {
    const inp = (i - pre >= 0 && i - pre < x.length ? x[i - pre] : 0) * 0.015;
    let s = 0;
    for (const c of cb) {
      const o = c.buf[c.i];
      c.lp = o * (1 - damp) + c.lp * damp;
      c.buf[c.i] = inp + c.lp * fb;
      c.i = (c.i + 1) % c.buf.length; s += o;
    }
    for (const a of ab) {
      const o = a.buf[a.i];
      a.buf[a.i] = s + o * 0.5; a.i = (a.i + 1) % a.buf.length; s = o - s;
    }
    y[i] = (i < x.length ? x[i] : 0) + s * wet;
  }
  return y;
}

const peak = (x) => x.reduce((m, v) => Math.max(m, Math.abs(v)), 0);
export const scaleBy = (x, db) => x.map((v) => v * 10 ** (db / 20));

/**
 * Run one sox-style chain to a mono Float64Array. `seed` feeds the noise generators;
 * `input` (optional) is the signal an effect-only chain starts from.
 */
export function runChain(chain, seed = 0, input = null) {
  const tk = chain.trim().split(/\s+/).filter(Boolean);
  const rand = mulberry32(seed);
  let chs = input ? [input] : null, p = 0;
  const num = () => { const v = Number(tk[p++]); if (!Number.isFinite(v)) throw new Error(`number expected at ${p} in "${chain}"`); return v; };
  const optNum = () => (p < tk.length && /^-?[\d.]+$/.test(tk[p]) ? num() : undefined);
  const mono = () => { if (chs.length !== 1) throw new Error(`"${chain}": ${chs.length} channels, remix first`); return chs[0]; };
  const each = (fn) => { chs = chs.map(fn); };
  while (p < tk.length) {
    const op = tk[p++];
    if (op === "synth") {
      const n = Math.round(num() * RATE); chs = [];
      while (p < tk.length && /^(sine|whitenoise|pinknoise|brownnoise)$/.test(tk[p])) {
        const kind = tk[p++]; chs.push(gen(kind, kind === "sine" ? tk[p++] : null, n, rand));
      }
    } else if (op === "remix") {
      const parts = tk[p++].split(",").map((s) => { const [c, g] = s.split("v"); return [chs[+c - 1], +g]; });
      const y = new Float64Array(chs[0].length);
      for (const [c, g] of parts) for (let i = 0; i < y.length; i++) y[i] += c[i] * g;
      chs = [y];
    } else if (op === "channels") {
      num();
      const y = new Float64Array(chs[0].length);
      for (const c of chs) for (let i = 0; i < y.length; i++) y[i] += c[i] / chs.length;
      chs = [y];
    } else if (op === "lowpass" || op === "highpass") {
      const c = biquad(op === "lowpass" ? "lp" : "hp", num()); each((x) => filt(x, c));
    } else if (op === "bandpass") {
      const f = num(), q = parseFloat(tk[p++]); const c = biquad("bp", f, q); each((x) => filt(x, c));
    } else if (op === "sinc") {
      const [f1, f2] = tk[p++].split("-").map(Number);
      const hp = biquad("hp", f1), lp = biquad("lp", f2);
      each((x) => filt(filt(filt(filt(x, hp), hp), lp), lp));
    } else if (op === "tremolo") { const hz = num(), d = num(); each((x) => tremolo(x, hz, d)); }
    else if (op === "chorus") {
      const a = [num(), num(), num(), num(), num(), num()]; if (tk[p] === "-s") p++;
      each((x) => chorus(x, ...a));
    } else if (op === "reverb") {
      const d = [50, 50, 100, 100, 0, 0], a = d.map((v) => optNum() ?? v); // sox's defaults
      each((x) => reverb(x, ...a));
    } else if (op === "fade") {
      const type = /^[tlhqp]$/.test(tk[p]) ? tk[p++] : "l";
      const a = num(), b = optNum(), c = optNum(); each((x) => fade(x, type, a, b, c));
    } else if (op === "exp") {
      const d = num(), atk = optNum() ?? 0.001; each((x) => fade(x, "l", atk, d, d));
    } else if (op === "swell") { const d = num(); each((x) => fade(x, "h", d / 2, d, d / 2)); }
    else if (op === "steplp") {
      const f1 = num(), f2 = num(), n = optNum() ?? 12, sp = optNum() ?? 0.005;
      each((x) => stepped(x, Math.ceil(x.length / n), (k, segs) => biquad("lp", f1 * (f2 / f1) ** (segs > 1 ? k / (segs - 1) : 0)), sp));
    } else if (op === "windbp") {
      const f0 = num(), amp = num(), hz = num(), q = parseFloat(tk[p++]), seg = optNum() ?? 1, sp = optNum() ?? 0.05;
      each((x) => stepped(x, Math.round(seg * RATE), (k) => biquad("bp", f0 + amp * Math.sin(2 * Math.PI * hz * (k + 0.5) * seg), q), sp));
    } else if (op === "pad") {
      const a = Math.round(num() * RATE), b = Math.round((optNum() ?? 0) * RATE);
      each((x) => { const y = new Float64Array(a + x.length + b); y.set(x, a); return y; });
    } else if (op === "trim") {
      const s = Math.round(num() * RATE), l = optNum();
      each((x) => x.slice(s, l === undefined ? undefined : s + Math.round(l * RATE)));
    } else if (op === "gain") { const db = num(); each((x) => scaleBy(x, db)); }
    else if (op === "norm") {
      const db = num(), m = Math.max(...chs.map(peak));
      each((x) => (m ? x.map((v) => (v * 10 ** (db / 20)) / m) : x));
    } else throw new Error(`unknown op ${op} in "${chain}"`);
  }
  return mono();
}

/** Sum `parts` of [signal, startFrame] into one buffer of at least `minLen` frames. */
export function mix(parts, minLen = 0) {
  const n = Math.max(minLen, ...parts.map(([x, at]) => at + x.length));
  const y = new Float64Array(n);
  for (const [x, at] of parts) for (let i = 0; i < x.length; i++) y[at + i] += x[i];
  return y;
}

// ---- cues ----
/** Render a layer list (recursive: a layer is {chain} | {cue} | {layers, then}), before the post-chain. */
function renderLayers(layers, cues, key) {
  return mix(layers.map((l, i) => {
    const k = `${key}#${i}`;
    let x = l.chain ? runChain(l.chain, fnv1a(k))
      : l.cue ? renderLayers(cues[l.cue].layers, cues, k)
      : renderLayers(l.layers, cues, k);
    if (l.then) x = runChain(l.then, 0, x);
    if (l.gain) x = scaleBy(x, l.gain);
    return [x, Math.round((l.at ?? 0) * RATE)];
  }));
}

/** The timing step every cue master ends with (shared/03 item 1). */
export function timingChain(cue) {
  const L = cue.length / 1000, f = Math.min(0.005, L / 2);
  return `pad 0 1 trim 0 ${L} fade t ${f} ${L} ${f} norm ${cue.peak}`;
}

export function renderCue(recipes, skin, stem) {
  const set = recipes.cues[skin], cue = set.cues[stem];
  if (!cue) throw new Error(`no recipe ${skin}/${stem}`);
  let x = renderLayers(cue.layers, set.cues, `${skin}/${stem}`);
  if (set.post) x = runChain(set.post, 0, x);
  x = runChain(timingChain(cue), 0, x);
  return x;
}

// ---- loops ----
/** Render a 90 s stereo loop (before loudness): beds 96 s -> equal-power loop -> events modulo 90 s. */
export function renderLoop(recipes, id) {
  const r = recipes.loops[id];
  if (!r) throw new Error(`no loop ${id}`);
  const rand = mulberry32(fnv1a(id)), N = 90 * RATE, R96 = 96 * RATE;
  const L = [new Float64Array(R96), new Float64Array(R96)];
  (r.beds ?? []).forEach((b, bi) => {
    for (let c = 0; c < 2; c++) {
      const x = scaleBy(runChain(b.chain, fnv1a(`${id}/bed${bi}/ch${c}`)), b.gain ?? 0);
      for (let i = 0; i < R96; i++) L[c][i] += x[i] ?? 0;
    }
  });
  const out = makeLoop(L, RATE, 90, 6);
  for (const ev of r.events ?? []) {
    // six variants per event type, parameters drawn from the PRNG in declaration order
    const variants = Array.from({ length: 6 }, (_, vi) => {
      const params = {};
      for (const [k, spec] of Object.entries(ev.params ?? {})) {
        params[k] = Array.isArray(spec) ? spec[0] + (spec[1] - spec[0]) * rand() : spec.choose[Math.floor(rand() * spec.choose.length)];
      }
      const chain = ev.chain.replace(/\{(\w+)(?:\*([\d.]+))?\}/g, (_, k, m) => (+(params[k] * (m ? +m : 1)).toFixed(3)).toString());
      return { chain, x: scaleBy(runChain(chain, fnv1a(`${id}/${ev.name}/v${vi}`)), ev.gain ?? 0) };
    });
    ev.rendered = variants.map((v) => v.chain);
    for (const t of schedule(ev.schedule, rand)) {
      const v = variants[Math.floor(rand() * 6)].x;
      const pan = ev.pan ? -0.8 + 1.6 * rand() : 0, th = ((pan + 1) * Math.PI) / 4;
      const g = ev.pan ? [Math.cos(th), Math.sin(th)] : [1, 1];
      const at = Math.round(t * RATE);
      for (let c = 0; c < 2; c++) for (let i = 0; i < v.length; i++) out[c][(at + i) % N] += v[i] * g[c];
    }
  }
  return out;
}

/** Event start times (s) on the 90 s timeline. */
export function schedule(s, rand) {
  const T = 90, out = [];
  if (s.type === "periodic") {
    for (let k = 0; k * s.period < T; k++) out.push(Math.max(0, k * s.period + s.period * s.jitter * (2 * rand() - 1)));
  } else if (s.type === "poisson") {
    let t = 0, rate = 0, next = 0;
    const draw = () => (Array.isArray(s.rate) ? s.rate[0] + (s.rate[1] - s.rate[0]) * rand() : s.rate);
    rate = draw(); next = s.drift ?? Infinity;
    for (;;) {
      t += -Math.log(1 - rand()) / rate;
      while (t >= next) { rate = draw(); next += s.drift; }
      if (t >= T) break;
      if (s.group) {
        const n = s.group.size[0] + Math.floor(rand() * (s.group.size[1] - s.group.size[0] + 1));
        for (let j = 0; j < n; j++) out.push(t + j * s.group.gap);
      } else out.push(t);
    }
  } else if (s.type === "count") {
    for (let k = 0; k < s.n; k++) out.push(rand() * T);
  } else if (s.type === "interval") {
    for (let t = rand() * s.max; t < T; t += s.min + (s.max - s.min) * rand()) out.push(t);
  } else if (s.type === "even") {
    for (let k = 0; k < s.n; k++) out.push((((s.offset ?? 0) + (k * T) / s.n) % T + T) % T);
  } else throw new Error(`schedule ${s.type}`);
  return out;
}

// ---- CLI ----
if (import.meta.url === `file://${process.argv[1]}`) {
  const { readFileSync } = await import("node:fs");
  const recipes = JSON.parse(readFileSync(new URL("./recipes.json", import.meta.url), "utf8"));
  const [target, outPath] = process.argv.slice(2);
  const gi = process.argv.indexOf("--gain"), gainDb = gi > 0 ? Number(process.argv[gi + 1]) : 0;
  if (!target || !outPath) { console.error("usage: synth.mjs <skin>/<stem>|loop/<id> <out.wav> [--gain dB]"); process.exit(2); }
  const [kind, name] = target.split("/");
  if (kind === "loop") writeFileSync(outPath, writeWav({ rate: RATE, samples: renderLoop(recipes, name).map((x) => scaleBy(x, gainDb)) }));
  else writeFileSync(outPath, writeWav({ rate: RATE, samples: [renderCue(recipes, kind, name)] }));
}
