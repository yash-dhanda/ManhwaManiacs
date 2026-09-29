#!/usr/bin/env node
// Fails on Tailwind utilities outside a skin's token names (cinematic/DESIGN.md §2.8 "Lint scope",
// §15.10 S2). Scans frontend/src/skins/<skin>/**/*.{ts,tsx,css} except *.generated.*, collecting
// class-like tokens from string literals and @apply lines. Prints file:line token per failure.
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { themeEntries } from "./lib/emit-css.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const CHECKED = /^(bg|text|border|outline|fill|stroke|font|tracking|leading|rounded|blur|backdrop|ease|duration|z|animate)-/;
const STRUCT = [
  /^text-(left|center|right|justify|start|end|wrap|nowrap|balance|pretty|ellipsis|clip)$/,
  /^border-(0|2|3|4|solid|dashed|dotted|none)$/, /^border-[trblxy](-(0|2|3))?$/,
  /^outline-(none|hidden|0|1|2)$/, /^outline-offset-(0|1|2|4)$/,
  /^bg-(none|cover|contain|center|top|bottom|left|right|no-repeat|repeat|fixed|local|scroll)$/, /^bg-(clip|origin)-[a-z]+$/, /^bg-\[url\(.*\)\]$/,
  /^(fill|stroke)-none$/, /^stroke-(0|1|2)$/, /^animate-none$/,
  /^[a-z]+(-[a-z]+)*-\(--mm-[\w-]+\)$/, // any arbitrary (--mm-*) reference
];
const walk = (d) => readdirSync(d).flatMap((f) => { const p = join(d, f); return statSync(p).isDirectory() ? walk(p) : [p]; });
// Strips variants (anything before a top-level ':'), a leading ! or -, a trailing !, and an /NN opacity.
function bare(tok) {
  let depth = 0, cut = 0;
  for (let i = 0; i < tok.length; i++) { const c = tok[i]; if (c === "[" || c === "(") depth++; else if (c === "]" || c === ")") depth--; else if (c === ":" && !depth) cut = i + 1; }
  return tok.slice(cut).replace(/^[!-]/, "").replace(/!$/, "").replace(/\/(\d+|\[[^\]]*\]|\([^)]*\))$/, "");
}

let failures = 0, scanned = 0;
for (const skin of readdirSync(join(root, "design/tokens")).filter((f) => f.endsWith(".json")).map((f) => f.slice(0, -5))) {
  const dir = join(root, "frontend/src/skins", skin);
  if (!existsSync(dir)) continue;
  const t = JSON.parse(readFileSync(join(root, `design/tokens/${skin}.json`), "utf8"));
  const names = themeEntries(t).map(([n]) => n);
  const pick = (ns) => names.filter((n) => n.startsWith(`--${ns}-`)).map((n) => n.slice(ns.length + 3));
  const colors = pick("color"), roles = pick("text").filter((n) => !n.includes("--"));
  const allowed = new Set([
    ...["bg", "text", "border", "outline", "fill", "stroke"].flatMap((p) => colors.map((c) => `${p}-${c}`)),
    ...colors.map((c) => `border-[trblxy]-${c}`).flatMap((x) => "trblxy".split("").map((s) => x.replace("[trblxy]", s))),
    ...roles.map((r) => `text-${r}`), ...pick("font").map((f) => `font-${f}`), ...pick("radius").map((r) => `rounded-${r}`),
    ...pick("blur").map((b) => `blur-${b}`), ...pick("ease").map((e) => `ease-${e}`), "ease-linear",
  ]);
  const motion = join(dir, "motion.css");
  if (existsSync(motion)) for (const m of readFileSync(motion, "utf8").matchAll(/--animate-([\w-]+)\s*:/g)) allowed.add(`animate-${m[1]}`);
  for (const file of walk(dir).filter((f) => /\.(ts|tsx|css)$/.test(f) && !/\.generated\./.test(f))) {
    scanned++;
    readFileSync(file, "utf8").split("\n").forEach((line, i) => {
      const chunks = [...line.matchAll(/(["'`])((?:\\.|(?!\1).)*)\1/g)].map((m) => m[2]);
      const apply = /@apply\s+([^;]+)/.exec(line);
      if (apply) chunks.push(apply[1]);
      for (const tok of chunks.flatMap((c) => c.split(/\s+/)).filter(Boolean)) {
        const b = bare(tok);
        if (!CHECKED.test(b) || b.startsWith("backdrop-")) { if (!b.startsWith("backdrop-")) continue; }
        else if (allowed.has(b) || STRUCT.some((r) => r.test(b))) continue;
        console.error(`${relative(root, file)}:${i + 1} ${tok}`);
        failures++;
      }
    });
  }
}
if (failures) { console.error(`lint-utilities: ${failures} utilities outside the token names`); process.exit(1); }
console.log(`lint-utilities: ${scanned} skin files clean`);
