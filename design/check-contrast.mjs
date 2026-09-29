#!/usr/bin/env node
// The contrast gate (glass/DESIGN.md §15.8; cinematic/DESIGN.md §2.1.1, §2.1.4, §14.2). Reads the
// `contrast` array of every design/tokens/*.json, composites each case's ground bottom to top in
// sRGB floats and measures WCAG 2.x contrast. Prints one line per case, then a summary; exits 1 on
// any failure or forbidden declaration. A computed ratio more than 0.1 away from the case's
// `expect` (the figure the DESIGN file prints) is a warning, not a failure.
//
// Case: { id, fg, over: [bottom … top], kind: "text" | "large" | "nontext", expect?, ref?, exception? }
//   colour   = "#RRGGBB" | "rgba(…)" | a dotted key of the same token file ("color.onGlass", "glass.t3.fill")
//   fg       = colour | { color, alpha }                      (an alpha foreground composites over the ground)
//   over[i]  = colour | { black: a } | { white: a } | { color, alpha } | { mix: [colour, colour], at: 0..1 }
//              the first entry must be opaque.
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { parseColor, over, ratio, mix } from "./lib/composite.mjs";

export const MIN = { text: 4.5, large: 3, nontext: 3 };
const STATE = /^color\.(iris\d+|success|warning|danger|info|mature|streak|streakCore|bloom|machine)$/;
const TIER_FILL = /^glass\.t([1-5])\.fill$/;

const get = (t, key) => { const v = key.split(".").reduce((o, p) => o?.[p], t); return v && typeof v === "object" && "_" in v ? v._ : v; }; // "_" is a parent's own value
function colorOf(t, ref) {
  if (/^#|^rgba?\(/.test(ref)) return parseColor(ref);
  const v = get(t, ref);
  if (typeof v !== "string") throw new Error(`unknown colour key ${ref}`);
  return parseColor(v);
}
const withAlpha = (c, a) => [c[0], c[1], c[2], c[3] * a];
function layer(t, e) {
  if (typeof e === "string") return colorOf(t, e);
  if ("black" in e) return [0, 0, 0, e.black];
  if ("white" in e) return [1, 1, 1, e.white];
  if ("mix" in e) return mix(colorOf(t, e.mix[0]), colorOf(t, e.mix[1]), e.at);
  if ("color" in e) return withAlpha(colorOf(t, e.color), e.alpha);
  throw new Error(`bad ground entry ${JSON.stringify(e)}`);
}
const fgKey = (fg) => (typeof fg === "string" ? fg : fg.color);
const isDisc = (e) => e === "color.backingDisc" || (e && typeof e === "object" && e.black === 0.6);

// Rule checks on a declared case: [] when allowed, else the reasons.
export function forbidden(skin, c) {
  const why = [];
  const key = fgKey(c.fg);
  if (skin === "cinematic" && key === "color.ink.45") {
    if (!(c.over.length === 1 && (c.over[0] === "color.paper.0" || c.over[0] === "#000000")))
      why.push("ink.45 lives on a single opaque paper.0 or #000000 ground only (cinematic §2.1.1)");
  }
  if (skin === "glass") {
    const tiers = c.over.map((e, i) => [TIER_FILL.exec(typeof e === "string" ? e : "")?.[1], i]).filter(([n]) => n);
    if (STATE.test(key) && !c.exception)
      for (const [n, i] of tiers) if (n >= 2 && !c.over.slice(i + 1).some(isDisc))
        why.push(`state colour on T${n} without the backing disc and without an §2.1.2 exception (glass §2.1.2)`);
    if (/^color\.label[23]$/.test(key) && !c.id.startsWith("glass.wrapped."))
      for (const [n, i] of tiers) if (n >= 4 && !c.over.slice(i + 1).includes("color.wellOnGlass"))
        why.push(`${key.slice(6)} on a T${n} body outside wellOnGlass (glass §2.1.2, §15.8)`);
  }
  return why;
}

export function measure(t, c) {
  const first = layer(t, c.over[0]);
  if (first[3] !== 1) throw new Error(`${c.id}: the first ground entry must be opaque`);
  let ground = first.slice(0, 3);
  for (const e of c.over.slice(1)) ground = over(layer(t, e), ground);
  const fg = typeof c.fg === "string" ? colorOf(t, c.fg) : withAlpha(colorOf(t, c.fg.color), c.fg.alpha);
  return ratio(fg[3] === 1 ? fg.slice(0, 3) : over(fg, ground), ground);
}

// Evaluates every case of every token file; returns { lines, failures, warnings, counts }.
export function run(root) {
  const lines = [], warnings = [], counts = {};
  let failures = 0;
  for (const f of readdirSync(join(root, "design/tokens")).filter((x) => x.endsWith(".json")).sort()) {
    const skin = f.slice(0, -5);
    const t = JSON.parse(readFileSync(join(root, "design/tokens", f), "utf8"));
    const n = (counts[skin] = { pass: 0, fail: 0 });
    const ids = new Set();
    for (const c of t.contrast ?? []) {
      if (ids.has(c.id)) { lines.push(`${c.id}  duplicate id  FAIL`); failures++; n.fail++; continue; }
      ids.add(c.id);
      const r = measure(t, c);
      const min = MIN[c.kind];
      if (!min) throw new Error(`${c.id}: kind must be text, large or nontext`);
      const why = forbidden(skin, c);
      const ok = r >= min && !why.length;
      ok ? n.pass++ : (n.fail++, failures++);
      lines.push(`${c.id}  ${r.toFixed(2)}  ${min}  ${c.expect ?? "-"}  ${ok ? "PASS" : "FAIL"}${why.length ? "  " + why.join("; ") : ""}`);
      if (c.expect !== undefined && Math.abs(r - c.expect) > 0.1) warnings.push(`WARN ${c.id} computes ${r.toFixed(2)}, DESIGN prints ${c.expect}`);
    }
  }
  return { lines, failures, warnings, counts };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const { lines, failures, warnings, counts } = run(join(dirname(fileURLToPath(import.meta.url)), ".."));
  for (const l of lines) console.log(l);
  for (const w of warnings) console.log(w);
  const per = Object.entries(counts).map(([s, c]) => `${s} ${c.pass} pass / ${c.fail} fail`).join(", ");
  console.log(`check-contrast: ${lines.length} cases (${per}), ${warnings.length} expect warnings${failures ? `, ${failures} FAILED` : ""}`);
  process.exit(failures ? 1 : 0);
}
