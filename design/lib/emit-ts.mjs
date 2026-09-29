// contract.generated.ts (shared) and <skin>/tokens.generated.ts.
import { leaves, tsMember } from "./naming.mjs";
import { buildRoute, optionalSegment } from "./route.mjs";
import { springCss } from "./spring.mjs";
import { colorLeaves, roleLeaves, scalarLeaves } from "./emit-css.mjs";

const J = (v) => JSON.stringify(v);
const obj = (entries, ind = "  ") => `{\n${entries.map(([k, v]) => `${ind}${/^[A-Za-z_$][\w$]*$/.test(k) ? k : J(k)}: ${v},`).join("\n")}\n${ind.slice(2)}}`;
const lit = (v) => (typeof v === "string" ? J(v) : String(v));
const isScalar = (v) => v && typeof v === "object" && "value" in v;

function queryType(c, s) {
  const global = { sheet: c.globalQuery.sheet, view: c.globalQuery.view };
  const names = [...s.query, ...Object.keys(global).filter((n) => !s.query.includes(n))];
  const req = new Set(s.requiredQuery ?? []);
  const t = (n) => {
    const closed = s.query.includes(n) ? c.queryValues[s.id]?.[n] : typeof global[n] === "string" ? null : global[n];
    if (!s.query.includes(n) && typeof global[n] === "string") return "SheetId | null";
    return closed ? closed.map(lit).join(" | ") + " | null" : "QueryValue";
  };
  return `{ ${names.map((n) => `${n}${req.has(n) ? "" : "?"}: ${t(n)}`).join("; ")} }`;
}

export function emitContractTs(c, header) {
  const ids = c.screens.map((s) => s.id);
  const body = buildRoute.toString().replace(/^[^{]*\{/, "").replace(/\}\s*$/, "");
  const routes = c.screens.map((s) => {
    const opt = optionalSegment(s);
    const q = `query${s.requiredQuery ? "" : "?"}: ${queryType(c, s)}`;
    if (opt) return [s.id, `(${opt.name}?: SettingsSection, query?: ${queryType(c, s)}): string =>\n    ${opt.name} === undefined ? buildRoute(${J(s.path)}, [], query) : buildRoute(${J(opt.pattern)}, [${opt.name}], query)`];
    const ps = s.params.map((p) => `${p}: PathValue`);
    return [s.id, `(${[...ps, q].join(", ")}): string => buildRoute(${J(s.path)}, [${s.params.join(", ")}], query)`];
  });
  const screens = c.screens.map((s) => [s.id, `{ path: ${J(s.path)}, params: ${J(s.params)}, query: ${J(s.query)}, aliases: ${J(s.aliases).replace(/"(path|platforms)":/g, "$1: ")}, redirect: ${J(s.redirect)?.replace(/"(web|app)":/g, "$1: ")} }`]);
  return `// ${header}

export const SCREEN_IDS = ${J(ids)} as const;
export type ScreenId = (typeof SCREEN_IDS)[number];

export interface ScreenSpec {
  readonly path: string;
  readonly params: readonly string[];
  readonly query: readonly string[];
  readonly aliases: readonly { readonly path: string; readonly platforms: readonly ("web" | "app")[] }[];
  readonly redirect: { readonly web?: string; readonly app?: string } | null;
}

export const SCREENS = ${obj(screens)} as const satisfies Record<ScreenId, ScreenSpec>;

export const SETTINGS_SECTIONS = ${J(c.settingsSections.map((s) => s.slug))} as const;
export type SettingsSection = (typeof SETTINGS_SECTIONS)[number];
export const SETTINGS_SECTION_SPECS = ${obj(c.settingsSections.map((s) => [s.slug, J({ platforms: s.platforms, pushed: s.pushed, ...(s.webDebugOnly ? { webDebugOnly: true } : {}) }).replace(/"(\w+)":/g, "$1: ")]))} as const satisfies Record<SettingsSection, { platforms: readonly string[]; pushed: boolean; webDebugOnly?: boolean }>;

export const SHEET_IDS = ${J(c.sheets)} as const;
export type SheetId = (typeof SHEET_IDS)[number];

export const FLAGS = { glassAvailable: ${c.flags.glass_available} } as const;

export const HAPTIC_EVENTS = ${J(c.hapticEvents)} as const;
export type HapticEvent = (typeof HAPTIC_EVENTS)[number];
export const SOUND_EVENTS = ${J(c.soundEvents)} as const;
export type SoundEvent = (typeof SOUND_EVENTS)[number];

/** A haptic value (design/lib/haptics.mjs grammar): a pattern, a sequence or a repeat. */
export type HapticPattern = string;
export type HapticValue =
  | HapticPattern
  | readonly [HapticPattern, ...{ readonly after: number; readonly then: HapticPattern }[]]
  | { readonly repeat: HapticPattern; readonly every: number; readonly max: number };
export type AhapEvent =
  | { readonly type: "T"; readonly t: number; readonly i: number; readonly s: number }
  | { readonly type: "C"; readonly t: number; readonly dur: number; readonly i: number; readonly s: number };

type PathValue = string | number;
type QueryValue = string | number | boolean | null;

// The builder of design/lib/route.mjs: segments through encodeURIComponent, the query through
// URLSearchParams in insertion order, undefined and null values skipped.
function buildRoute(pattern: string, params: readonly PathValue[], query?: Readonly<Record<string, unknown>>): string {${body}}

export const ROUTES = ${obj(routes)} as const;
`;
}

export function emitTokensTs(t, header) {
  const colors = colorLeaves(t).map(([k, v]) => [tsMember(k), J(v)]);
  const num = (g) => Object.entries(t[g]).map(([k, v]) => [k, String(v)]);
  const durs = leaves(t.dur, isScalar, "dur");
  const scalars = scalarLeaves(t).map(([k, v]) =>
    [tsMember(k), isScalar(v) ? String(v.value) : `{ ${Object.entries(v).map(([a, b]) => `${a}: ${b.value}`).join(", ")} }`]);
  const role = ([k, r]) => [tsMember(k), r.size
    ? `{ family: ${J(r.font)}, italic: ${r.italic}, wght: ${r.wght}, axes: ${J(r.axes).replace(/"(\w+)":/g, "$1: ")}, sizes: ${J(Object.values(r.size).map((x) => x[0]))}, lines: ${J(Object.values(r.size).map((x) => x[1]))}, trackingEm: ${r.tracking}, cap: ${r.scaleCap}, upper: ${r.upper}${r.fluid ? `, fluid: ${J(r.fluid)}, lhRatio: ${J(Object.values(r.lhRatio))}` : ""} }`
    : `{ family: ${J(r.font)}, wght: ${r.wght}, trackingEm: ${r.tracking}, sizeRule: ${J(r.sizeRule)} }`];
  const hap = (v) => (typeof v === "string" ? J(v) : Array.isArray(v) ? `[${v.map((s) => (typeof s === "string" ? J(s) : `{ after: ${s.after}, then: ${J(s.then)} }`)).join(", ")}]` : `{ repeat: ${J(v.repeat)}, every: ${v.every}, max: ${v.max} }`);
  const ahap = (e) => (e.type === "C" ? `{ type: "C", t: ${e.t}, dur: ${e.dur}, i: ${e.i}, s: ${e.s} }` : `{ type: "T", t: ${e.t}, i: ${e.i}, s: ${e.s} }`);
  return `// ${header}

import type { AhapEvent, HapticEvent, HapticValue, SoundEvent } from "../contract.generated";

export const color = ${obj(colors)} as const;

export const space = ${obj(num("space"))} as const;

export const grid = ${obj(Object.entries(t.grid).map(([k, [c, m, g, max]]) => [k, `{ columns: ${c}, margin: ${m}, gutter: ${g}, max: ${max ?? null} }`]))} as const;

export const bp = ${obj(num("bp"))} as const;

export const radius = ${obj(num("radius"))} as const;

export const blur = ${obj(num("blur"))} as const;

export const z = ${obj(num("z"))} as const;

/** Durations in seconds (Motion). */
export const dur = ${obj(durs.map(([k, v]) => [tsMember(k), String(v.value / 1000)]))} as const;

/** Durations in milliseconds (timers). */
export const durMs = ${obj(durs.map(([k, v]) => [tsMember(k), String(v.value)]))} as const;

export const ease = ${obj(Object.entries(t.ease).map(([k, v]) => [k, v === "linear" ? J(v) : J(v.bezier).replace(/,/g, ", ")]))} as const;

/** Motion spring transitions. */
export const spring = ${obj(Object.entries(t.spring).map(([k, s]) => [k, `{ type: "spring", visualDuration: ${s.ms / 1000}, bounce: ${s.bounce} }`]))} as const;

/** The CSS pair: settle time in ms and the linear() curve (design/lib/spring.mjs). */
export const springCss = ${obj(Object.entries(t.spring).map(([k, s]) => { const c = springCss(s.ms, s.bounce); return [k, `{ ms: ${c.ms}, easing: ${J(c.easing)} }`]; }))} as const;

export const scalar = ${obj(scalars)} as const;

export const type = ${obj(roleLeaves(t).map(role))} as const;

export const haptics = ${obj(Object.entries(t.haptics).map(([k, v]) => [k, hap(v)]))} as const satisfies Record<HapticEvent, HapticValue>;

/** navigator.vibrate patterns for Android Chrome; every other event vibrates nothing. */
export const hapticsWeb = ${obj(Object.entries(t.hapticsWeb).map(([k, v]) => [k, J(v).replace(/,/g, ", ")]))} as const satisfies Partial<Record<HapticEvent, readonly number[]>>;

export const ahap = ${obj(Object.entries(t.ahap).map(([k, v]) => [k, `[${v.map(ahap).join(", ")}]`]))} as const satisfies Record<string, readonly AhapEvent[]>;

/** Cue → file stem under sounds/${Object.keys(t.sounds).length ? "<skin>" : ""}/ (the web adds .ogg or .m4a). */
export const sounds = ${obj(Object.entries(t.sounds).map(([k, v]) => [k, J(v)]))} as const;
export type SoundCue = keyof typeof sounds;

export const soundEvents = ${obj(Object.entries(t.soundEvents).map(([k, v]) => [k, J(v)]))} as const satisfies Record<SoundEvent, SoundCue | null>;
`;
}
