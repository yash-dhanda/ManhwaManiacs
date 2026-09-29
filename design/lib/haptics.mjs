// The haptic pattern grammar shared by both skins (shared/00; glass adds its values in shared/01).
//   pattern  = "none" | primitive [":" (0..1 | "velocity" | "velocity<=" 0..1)] | "ahap:" name ["{depth}"]
//   value    = pattern | [pattern, {after: ms, then: pattern}, …] | {repeat: pattern, every: ms, max: n}
// "{depth}" is a placeholder the runtime fills with the depth 1 to 4, so name1 … name4 must exist.

export const PRIMITIVES = ["selection", "light", "medium", "heavy", "rigid", "soft", "success", "warning", "error", "toggleOn", "toggleOff", "dragStart", "rigidBack"];

const unit = (s) => /^(0(\.\d+)?|1(\.0+)?)$/.test(s);

// Returns {kind: "none"} | {kind: "primitive", name, intensity?, velocity?, velocityMax?} | {kind: "ahap", name, depth} | null.
export function parsePattern(p) {
  if (typeof p !== "string") return null;
  if (p === "none") return { kind: "none" };
  const a = /^ahap:([A-Za-z][\w-]*)(\{depth\})?$/.exec(p);
  if (a) return { kind: "ahap", name: a[1], depth: !!a[2] };
  const [name, mod, ...rest] = p.split(":");
  if (!PRIMITIVES.includes(name) || rest.length) return null;
  if (mod === undefined) return { kind: "primitive", name };
  if (unit(mod)) return { kind: "primitive", name, intensity: Number(mod) };
  if (mod === "velocity") return { kind: "primitive", name, velocity: true };
  const v = /^velocity<=(.+)$/.exec(mod);
  if (v && unit(v[1])) return { kind: "primitive", name, velocity: true, velocityMax: Number(v[1]) };
  return null;
}

const ms = (n) => Number.isInteger(n) && n >= 0;

// Every problem with one haptics value, as strings; [] when valid.
export function hapticErrors(value, ahapNames) {
  const errs = [];
  const check = (p) => {
    const r = parsePattern(p);
    if (!r) errs.push(`bad pattern ${JSON.stringify(p)}`);
    else if (r.kind === "ahap" && r.depth) { for (const d of [1, 2, 3, 4]) if (!ahapNames.has(r.name + d)) errs.push(`unknown ahap ${r.name}${d}`); }
    else if (r.kind === "ahap" && !ahapNames.has(r.name)) errs.push(`unknown ahap ${r.name}`);
  };
  if (Array.isArray(value)) {
    if (!value.length) errs.push("empty sequence");
    value.forEach((s, i) => {
      if (i === 0) return check(s);
      if (!s || typeof s !== "object" || !ms(s.after)) errs.push(`step ${i} needs {after: ms, then}`);
      else check(s.then);
    });
  } else if (value && typeof value === "object") {
    check(value.repeat);
    if (!ms(value.every) || !(Number.isInteger(value.max) && value.max > 0)) errs.push("repeat needs every: ms and max: n");
  } else check(value);
  return errs;
}

// A value as a list of steps: [{pattern, afterMs, repeatEveryMs?, maxRepeats?}]; "none" is [].
export function hapticSteps(value) {
  if (value === "none") return [];
  if (Array.isArray(value)) return value.map((s, i) => (i === 0 ? { pattern: s, afterMs: 0 } : { pattern: s.then, afterMs: s.after }));
  if (typeof value === "object") return [{ pattern: value.repeat, afterMs: 0, repeatEveryMs: value.every, maxRepeats: value.max }];
  return [{ pattern: value, afterMs: 0 }];
}
