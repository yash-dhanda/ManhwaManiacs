// Glass: frontend/src/skins/glass/tokens.generated.ts (glass/DESIGN.md §2.8, §4.3, §15.1). Springs are
// physical Motion transitions (§15.10 G1); everything else mirrors glass.json with colour keys resolved.
import { tsMember } from "./naming.mjs";
import { motionPhysical, physicalSpringCss } from "./spring.mjs";
import { glassSprings } from "./emit-glass-css.mjs";

const J = (v) => JSON.stringify(v);
const key = (k) => (/^[A-Za-z_$][\w$]*$/.test(k) ? k : J(k));
// A value as a TS literal with unquoted keys where possible.
const lit = (v) => (v === null || typeof v !== "object" ? J(v) : Array.isArray(v) ? `[${v.map(lit).join(", ")}]` : `{ ${Object.entries(v).map(([k, x]) => `${key(k)}: ${lit(x)}`).join(", ")} }`);
const obj = (entries) => `{\n${entries.map(([k, v]) => `  ${key(k)}: ${v},`).join("\n")}\n}`;
const colorOf = (t, c) => (typeof c === "string" && c.startsWith("color.") ? c.slice(6).split(".").reduce((o, p) => o[p], t.color) : c);

export function emitGlassTs(t, header) {
  const colors = (o, p) => Object.entries(o).flatMap(([k, v]) => (typeof v === "string" ? [[`${p}.${k}`, v]] : colors(v, `${p}.${k}`)));
  const layout = Object.entries(t.layout).flatMap(([k, v]) => {
    if (typeof v === "number") return [[k, String(v)]];
    if ("fraction" in v) return [[k, lit(v)]];
    if ("android" in v) return [[k, String(v.value)], [`${k}Android`, String(v.android)]];
    return [[`${k}${v.unit === "ch" ? "Ch" : ""}`, String(v.value)]];
  });
  const border = Object.entries(t.border).map(([k, b]) =>
    [k, lit(Object.fromEntries(Object.entries(b).filter(([p]) => p !== "colorVar").map(([p, v]) => [p, /color$/i.test(p) ? colorOf(t, v) : v])))]);
  const hap = (v) => (typeof v === "string" ? J(v) : Array.isArray(v) ? `[${v.map((s) => (typeof s === "string" ? J(s) : `{ after: ${s.after}, then: ${J(s.then)} }`)).join(", ")}]` : `{ repeat: ${J(v.repeat)}, every: ${v.every}, max: ${v.max} }`);
  const ahap = (e) => (e.type === "C" ? `{ type: "C", t: ${e.t}, dur: ${e.dur}, i: ${e.i}, s: ${e.s} }` : `{ type: "T", t: ${e.t}, i: ${e.i}, s: ${e.s} }`);
  const { snap, ...materials } = t.glass;
  return `// ${header}

import type { AhapEvent, HapticEvent, HapticValue, SoundEvent } from "../contract.generated";

export const color = ${obj(colors(t.color, "color").map(([k, v]) => [tsMember(k), J(v)]))} as const;

export const space = ${obj(Object.entries(t.space).map(([k, v]) => [k, String(v)]))} as const;

/** Lengths in px; readerStripMax is clamp(min, fraction × viewport width, max); measureMaxCh is in ch. */
export const layout = ${obj(layout)} as const;

export const bp = ${obj(Object.entries(t.bp).map(([k, v]) => [k, String(v)]))} as const;

export const radius = ${obj(Object.entries(t.radius).map(([k, v]) => [k, String(v)]))} as const;

/** Blur radii in px (CSS) and σ (Flutter). */
export const blur = ${obj(Object.entries(t.blur).map(([k, v]) => [k, String(v)]))} as const;

export const border = ${obj(border)} as const;

/** Degrees: the resting light angle and its live range (±). */
export const light = ${lit(t.light)} as const;

export const z = ${obj(Object.entries(t.z).map(([k, v]) => [k, String(v)]))} as const;

/** Tiers t1 to t5, finishes, solids and materials; snap is the free-size tier snap of §2.4.3 (< 36 T1, 36–56 T2, 57–96 T3, ≥ 97 T4). */
export const glass = ${obj([...Object.entries(materials).map(([k, v]) => [k, lit(v)]), ["snap", lit(snap)]])} as const;

export const glassSnap = glass.snap;

export const dim = ${lit(t.dim)} as const;

export const caustic = ${lit(t.caustic)} as const;

/** Motion transitions: physical springs keep inherited velocity (§4.3). */
export const spring = ${obj(glassSprings(t).map(([k, s]) => [k, lit(motionPhysical(s.ms, s.bounce))]))} as const;

/** The CSS pair: settle time in ms and the 60-sample linear() curve. */
export const springCss = ${obj(glassSprings(t).map(([k, s]) => { const c = physicalSpringCss(s.ms, s.bounce); return [k, `{ ms: ${c.ms}, easing: ${J(c.easing)} }`]; }))} as const;

/** Timed values: { ms, bezier } or { ms, curve: "linear" | "step" }; a bare { ms } is a per-grapheme step. */
export const curve = ${obj(Object.entries(t.curve).map(([k, v]) => [k, lit(v)]))} as const;

export const physics = ${obj(Object.entries(t.physics).map(([k, v]) => [k, String(v)]))} as const;

export const threshold = ${obj(Object.entries(t.threshold).map(([k, v]) => [k, String(v)]))} as const;

/** Type roles: [size, line] px per breakpoint (null: the role does not exist there), tracking in em, capAt in px. */
export const type = ${obj(Object.entries(t.type).map(([k, v]) => [k, lit(v)]))} as const;

export const haptics = ${obj(Object.entries(t.haptics).map(([k, v]) => [k, hap(v)]))} as const satisfies Record<HapticEvent, HapticValue>;

/** navigator.vibrate patterns for Android Chrome; every other event vibrates nothing. */
export const hapticsWeb = ${obj(Object.entries(t.hapticsWeb).map(([k, v]) => [k, J(v).replace(/,/g, ", ")]))} as const satisfies Partial<Record<HapticEvent, readonly number[]>>;

export const ahap = ${obj(Object.entries(t.ahap).map(([k, v]) => [k, `[${v.map(ahap).join(", ")}]`]))} as const satisfies Record<string, readonly AhapEvent[]>;

/** Cue → file stem under sounds/glass/ (the web adds .ogg or .m4a). */
export const sounds = ${obj(Object.entries(t.sounds).map(([k, v]) => [k, J(v)]))} as const;
export type SoundCue = keyof typeof sounds;

/** nav.push lists one cue per depth 1 to 4. */
export const soundEvents = ${obj(Object.entries(t.soundEvents).map(([k, v]) => [k, lit(v)]))} as const satisfies Record<SoundEvent, SoundCue | readonly SoundCue[] | null>;
`;
}
