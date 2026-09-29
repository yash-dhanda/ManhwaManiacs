// Haptic assets and motion-name unions for every skin (glass/DESIGN.md §5.3, §4.10, §15.1
// "Generator ownership", §15.10 G2; cinematic/DESIGN.md §4.5, §5). Called by build.mjs, which writes
// or (with --check) compares what this returns. Stdlib only.
//   mobile/assets/haptics/<skin>/<pattern>.ahap.json     Apple AHAP, read by gaimon's patternFromData
//   frontend/src/skins/<skin>/motion.generated.ts        MOTION_NAMES, MotionName, MOTION_LABELS
//   mobile/lib/skins/<skin>/motion_names.g.dart          enum MotionName { id('LABEL') }
import { DART_RESERVED_WORDS } from "./lib/naming.mjs";

// AHAP numbers: integers keep one decimal (1.0, 0.0), everything else prints as JavaScript does.
const n = (x) => (Number.isInteger(x) ? x.toFixed(1) : String(x));
const params = (e, ind) =>
  `"EventParameters": [ { "ParameterID": "HapticIntensity", "ParameterValue": ${n(e.i)} },\n${ind}                     { "ParameterID": "HapticSharpness", "ParameterValue": ${n(e.s)} } ]`;

// Transients become HapticTransient (no duration); continuous events HapticContinuous with EventDuration.
export function ahapJson(skin, name, events) {
  const ev = events.map((e) => {
    const head = e.type === "C"
      ? `{ "Event": { "Time": ${n(e.t)}, "EventType": "HapticContinuous", "EventDuration": ${n(e.dur)},`
      : `{ "Event": { "Time": ${n(e.t)}, "EventType": "HapticTransient",`;
    if (e.type !== "C" && e.type !== "T") throw new Error(`${skin} ${name}: event type ${e.type}`);
    return `    ${head}\n      ${params(e, "      ")} } }`;
  });
  return `{\n  "Version": 1.0,\n  "Metadata": { "Project": "ManhwaManiacs", "Description": "${skin} ${name}" },\n  "Pattern": [\n${ev.join(",\n")}\n  ]\n}\n`;
}

// "Column wipe" → columnWipe, "Count-up" → countUp.
export const motionId = (name) =>
  name.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean).map((w, i) => (i ? w[0].toUpperCase() + w.slice(1) : w)).join("");
const ENUM_TAKEN = new Set(["index", "values", "name", "hashCode", "runtimeType"]);
export const dartMotionId = (name) => { const id = motionId(name); return DART_RESERVED_WORDS.has(id) || ENUM_TAKEN.has(id) ? id + "Move" : id; };

export function motionTs(names, header) {
  const ids = names.map(motionId);
  return `// ${header}

/** The named moves of the motion table; play(name) accepts only these. */
export const MOTION_NAMES = [
${ids.map((id) => `  ${JSON.stringify(id)},`).join("\n")}
] as const;

export type MotionName = (typeof MOTION_NAMES)[number];

/** The label the motion-timings overlay prints. */
export const MOTION_LABELS: Record<MotionName, string> = {
${names.map((nm) => `  ${motionId(nm)}: ${JSON.stringify(nm.toUpperCase())},`).join("\n")}
};
`;
}

export function motionDart(names, header) {
  const q = (s) => `'${s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$")}'`;
  return `// ${header}
// ignore_for_file: type=lint

/// The named moves of the motion table; each label is what the motion-timings overlay prints.
enum MotionName {
${names.map((nm, i) => `  ${dartMotionId(nm)}(${q(nm.toUpperCase())})${i === names.length - 1 ? ";" : ","}`).join("\n")}

  const MotionName(this.label);

  final String label;
}
`;
}

// All outputs for the given skins ({id, src, t}) as a Map of repo path → content; errors collect problems.
export function hapticsOutputs(skins, head, errors) {
  const out = new Map();
  for (const { id, src, t } of skins) {
    for (const [name, events] of Object.entries(t.ahap ?? {})) out.set(`mobile/assets/haptics/${id}/${name}.ahap.json`, ahapJson(id, name, events));
    const names = t.motionNames ?? [];
    if (!names.length) { errors.push(`${id}: motionNames is empty`); continue; }
    for (const ids of [names.map(motionId), names.map(dartMotionId)]) {
      const dup = ids.find((x, i) => ids.indexOf(x) !== i);
      if (dup) errors.push(`${id}: motion id ${dup} is not unique`);
    }
    out.set(`frontend/src/skins/${id}/motion.generated.ts`, motionTs(names, head(src)));
    out.set(`mobile/lib/skins/${id}/motion_names.g.dart`, motionDart(names, head(src)));
  }
  return out;
}
