// tokens.generated.css (per skin) and theme.generated.css (shared by both skins).
import { cssName, leaves } from "./naming.mjs";
import { springCss } from "./spring.mjs";
import { LEGACY_FALLBACKS } from "./legacy-fallbacks.mjs";
import { isGlassTokens, glassThemeEntries } from "./emit-glass-css.mjs";

export const BPS = ["phone", "tablet", "desktop", "wide"]; // type-role breakpoints (wide covers cinema)
export const GRID_MIN = (t) => ({ phone: 0, tablet: t.bp.tablet, desktop: t.bp.desktop, wide: t.bp.wide, cinema: t.bp.cinema });
const num = (x) => String(Number(x.toFixed(4)));
const px = (n) => `${num(n)}px`;
const rem = (n) => `${num(n / 16)}rem`;
const isScalar = (v) => v && typeof v === "object" && "value" in v;
const rgba = (c) => c; // colours are emitted as authored (hex or rgba())
const block = (sel, decls, ind = "") => (decls.length ? `${ind}${sel} {\n${decls.map((d) => `${ind}  ${d};`).join("\n")}\n${ind}}\n` : "");
const media = (q, sel, decls) => (decls.length ? `@media ${q} {\n${block(sel, decls, "  ")}}\n` : "");

export const colorLeaves = (t) => leaves(t.color, (v) => typeof v === "string", "color");
// scalar.* leaves: a {value, unit} scalar, or a stagger (an object of ms scalars named item, row, cap, startDelay, fade).
const STAGGER_KEYS = ["item", "row", "cap", "startDelay", "fade"];
export const isStagger = (v) => !isScalar(v) && Object.entries(v).every(([k, x]) => STAGGER_KEYS.includes(k) && isScalar(x) && x.unit === "ms");
export const scalarLeaves = (t) => leaves(t.scalar ?? {}, (v) => isScalar(v) || isStagger(v), "scalar");
export const roleLeaves = (t) => leaves(t.type, (v) => "font" in v, "type");
export const roleSlug = (key) => cssName(key).replace(/^--mm-type-/, "");
const fontVar = (t, fontKey) => `var(${cssName("font." + fontKey)})`;

// The 13-stop eased gradient of §2.1.4 for a complete-value scrim.
function easedGradient(t, s) {
  const from = s.from ?? 0;
  const stops = t.scrim.stops.map((p, i) => {
    const a = t.scrim.alpha[i];
    const color = s.end === "#000000" ? `rgb(0 0 0 / ${num(a)})` : `color-mix(in srgb, ${s.end} ${num(a * 100)}%, transparent)`;
    return `${color} ${num((from + p * (1 - from)) * 100)}%`;
  });
  return `linear-gradient(${s.direction}, ${stops.join(", ")})`;
}
function scrimValue(t, s) {
  if (s.kind === "eased") return easedGradient(t, s);
  if (s.kind === "linear") return `linear-gradient(${s.direction}, ${s.colors.map(rgba).join(", ")})`;
  if (s.kind === "radial") return `radial-gradient(${num(s.size[0] * 100)}% ${num(s.size[1] * 100)}% at ${num(s.at[0] * 100)}% ${num(s.at[1] * 100)}%, ${s.colors.map((c, i) => `${c} ${num(s.stops[i] * 100)}%`).join(", ")})`;
  if (s.kind === "color") return s.value;
  return null; // utility-only
}
export const scrimLeaves = (t) => leaves(Object.fromEntries(Object.entries(t.scrim).filter(([k]) => k !== "stops" && k !== "alpha")), (v) => "kind" in v, "scrim");

// Utility bodies for scrims whose gradient reads variables set on the painting element (§2.8.3).
function scrimUtility(t, key, s) {
  const { stops, alpha } = t.scrim;
  if (s.kind === "utility" && key === "scrim.foot") {
    const g = stops.map((p, i) => `color-mix(in srgb, ${s.end} ${num(alpha[i] * 100)}%, transparent) calc(${num(s.from * 100)}% + ${num(p)} * (var(--scrim-solid-at, 100%) - ${num(s.from * 100)}%))`);
    return [`background-image: linear-gradient(to bottom, ${g.join(", ")})`];
  }
  if (s.kind === "utility") {
    const head = key === "scrim.head";
    const P = s.flat * 100;
    const base = (p) => `color-mix(in srgb, var(--scrim-base, #000000) ${num(p)}%, transparent)`;
    const g = [`${base(P)} 0`, ...stops.map((_, j) => stops.length - 1 - j).map((i) => `${base(P * alpha[i])} calc(100% - ${num(stops[i])} * var(--scrim-fade))`)];
    return ["position: absolute", head ? "inset: 0 0 calc(-1 * var(--scrim-fade)) 0" : "inset: calc(-1 * var(--scrim-fade)) 0 0 0", "z-index: -1", "pointer-events: none",
      `background-image: linear-gradient(${head ? "to bottom" : "to top"}, ${g.join(", ")})`];
  }
  if (s.kind === "color") return null;
  return [`background-image: var(${cssName(key)})`];
}

function typeDecls(t, key, r, bp, prev) {
  const slug = roleSlug(key);
  const out = [];
  const [size, line] = r.size[bp];
  if (!prev) {
    out.push(`--mm-type-${slug}-family: ${fontVar(t, r.font)}`, `--mm-type-${slug}-style: ${r.italic ? "italic" : "normal"}`);
    out.push(`--mm-type-${slug}-size: ${r.fluid ?? rem(size)}`);
    out.push(`--mm-type-${slug}-lh: ${r.fluid ? num(r.lhRatio[bp]) : rem(line)}`);
    out.push(`--mm-type-${slug}-tracking: ${num(r.tracking)}em`, `--mm-type-${slug}-wght: ${r.wght}`);
    const fvs = [...Object.entries(r.axes).map(([a, v]) => `"${a}" ${v}`), `"wght" ${r.wght}`].join(", ");
    out.push(`--mm-type-${slug}-fvs: ${fvs}`, `--mm-type-${slug}-transform: ${r.upper ? "uppercase" : "none"}`);
    return out;
  }
  const [ps, pl] = r.size[prev];
  if (!r.fluid && size !== ps) out.push(`--mm-type-${slug}-size: ${rem(size)}`);
  if (r.fluid ? r.lhRatio[bp] !== r.lhRatio[prev] : line !== pl) out.push(`--mm-type-${slug}-lh: ${r.fluid ? num(r.lhRatio[bp]) : rem(line)}`);
  return out;
}

export function emitSkinCss(skin, t, header) {
  const sel = `[data-skin="${skin}"]`;
  const base = [];
  for (const [k, v] of colorLeaves(t)) base.push(`${cssName(k)}: ${t.alias?.[k] ? `var(${cssName(t.alias[k])})` : v}`);
  for (const g of ["space", "bp", "radius", "blur"]) for (const [k, v] of Object.entries(t[g])) base.push(`${cssName(`${g}.${k}`)}: ${px(v)}`);
  const grid = (bp) => { const [c, m, g, max] = t.grid[bp]; return [`--mm-grid-columns: ${c}`, `--mm-grid-margin: ${px(m)}`, `--mm-grid-gutter: ${px(g)}`, `--mm-grid-max: ${max ? px(max) : "none"}`, `--mm-grid-template: repeat(${c}, minmax(0, 1fr))`]; };
  base.push(...grid("phone"));
  for (const [k, r] of Object.entries(t.rule)) {
    if ("width" in r) base.push(`${cssName(`rule.${k}`)}-width: ${px(r.width)}`);
    else base.push(`${cssName(`rule.${k}`)}-width: ${px(r.thick + r.gap + r.thin)}`, ...["thick", "gap", "thin"].map((p) => `${cssName(`rule.${k}`)}-${p}: ${px(r[p])}`));
  }
  base.push(`--mm-focus-width: ${px(t.focus.width)}`, `--mm-focus-offset: ${px(t.focus.offset)}`, `--mm-focus-halo: 0 0 0 ${px(t.focus.halo)} ${t.focus.haloColor === "#000000" ? "#000" : t.focus.haloColor}`);
  base.push(`--mm-hit-min: ${px(t.hit.min)}`);
  for (const [k, v] of Object.entries(t.z)) base.push(`${cssName(`z.${k}`)}: ${v}`);
  for (const [k, s] of scrimLeaves(t)) { const v = scrimValue(t, s); if (v) base.push(`${cssName(k)}: ${v}`); }
  for (const [k, v] of leaves(t.dur, isScalar, "dur")) base.push(`${cssName(k)}: ${v.value}ms`);
  for (const [k, v] of Object.entries(t.ease)) {
    if (v === "linear") base.push(`${cssName(`ease.${k}`)}: linear`);
    else { base.push(`${cssName(`ease.${k}`)}: cubic-bezier(${v.bezier.join(", ")})`); if ("ms" in v) base.push(`${cssName(`dur.${k}`)}: ${v.ms}ms`); }
  }
  for (const [k, s] of Object.entries(t.spring)) { const c = springCss(s.ms, s.bounce); base.push(`${cssName(`spring.${k}`)}: ${c.easing}`, `${cssName(`spring.${k}`)}-ms: ${c.ms}ms`); }
  for (const [k, f] of Object.entries(t.font)) if (cssName(`font.${k}`) !== f.css) base.push(`${cssName(`font.${k}`)}: var(${f.css})`);
  const roles = roleLeaves(t).filter(([, r]) => r.size); // dropcap has no fixed size: its utility computes it
  for (const [k, r] of roles) base.push(...typeDecls(t, k, r, "phone", null));

  let css = `/* ${header} */\n\n` + block(sel, base);
  const min = GRID_MIN(t);
  for (const [i, bp] of ["tablet", "desktop", "wide", "cinema"].entries()) {
    const decls = [...grid(bp)];
    if (BPS.includes(bp)) for (const [k, r] of roles) decls.push(...typeDecls(t, k, r, bp, BPS[BPS.indexOf(bp) - 1]));
    css += media(`(min-width: ${min[bp]}px)`, sel, decls);
  }
  css += media("(pointer: fine)", sel, [`--mm-hit-min: ${px(t.hit.fine)}`]);
  if (t.legible) {
    const lsel = `html[data-legible="on"]${sel}`;
    const swapped = roles.filter(([, r]) => r.font === t.legible.replaces);
    const lh = (bp, prev) => swapped.filter(([, r]) => !prev || r.size[bp][1] !== r.size[prev][1]).map(([k, r]) => `--mm-type-${roleSlug(k)}-lh: ${rem(r.size[bp][1] + t.legible.addLine)}`);
    css += block(lsel, [`${cssName(`font.${t.legible.replaces}`)}: ${fontVar(t, t.legible.font)}`, ...lh("phone")]);
    for (const bp of BPS.slice(1)) css += media(`(min-width: ${min[bp]}px)`, lsel, lh(bp, BPS[BPS.indexOf(bp) - 1]));
  }
  for (const s of Object.values(t.scope ?? {})) {
    const decls = Object.entries(s.set).map(([a, b]) => `${cssName(a)}: var(${cssName(b)})`);
    css += s.media ? media(s.media, sel, decls) : block(`${sel} ${s.selector}`, decls);
  }
  return css;
}

// Every @theme inline entry a skin contributes, as [name, value] (also read by lint-utilities.mjs).
export function themeEntries(t) {
  if (isGlassTokens(t)) return glassThemeEntries(t);
  const out = [];
  for (const [k] of colorLeaves(t)) out.push([cssName(k).replace("--mm-", "--"), `var(${cssName(k)})`]);
  for (const name of Object.keys(t.runtime ?? {})) out.push([`--color-${name}`, `var(--${name})`]);
  for (const g of ["radius", "blur"]) for (const k of Object.keys(t[g])) out.push([`--${g}-${cssName(`x.${k}`).slice(7)}`, `var(${cssName(`${g}.${k}`)})`]);
  for (const [k, v] of Object.entries(t.ease)) if (v !== "linear") out.push([`--ease-${k}`, `var(${cssName(`ease.${k}`)})`]);
  for (const k of Object.keys(t.spring)) out.push([`--ease-spring-${k}`, `var(${cssName(`spring.${k}`)})`]);
  const roles = roleLeaves(t);
  for (const f of new Set(roles.map(([, r]) => r.font))) out.push([cssName(`font.${f}`).replace("--mm-", "--"), `var(${cssName(`font.${f}`)})`]);
  for (const [k, r] of roles) {
    if (!r.size) continue;
    const s = roleSlug(k);
    out.push([`--text-${s}`, `var(--mm-type-${s}-size)`], [`--text-${s}--line-height`, `var(--mm-type-${s}-lh)`], [`--text-${s}--letter-spacing`, `var(--mm-type-${s}-tracking)`], [`--text-${s}--font-weight`, `var(--mm-type-${s}-wght)`]);
  }
  return out;
}

// Adds [name, value] to map, failing on a conflicting redefinition.
function union(map, name, value, what, errors) {
  if (map.has(name) && map.get(name) !== value) errors.push(`${what} ${name} defined twice with different values`);
  else map.set(name, value);
}

export function emitThemeCss(skins, header, errors) {
  const props = new Map(), bps = new Map(), theme = new Map(), utils = new Map();
  for (const { t } of skins) {
    for (const [name, r] of Object.entries(t.runtime ?? {})) if (r.syntax) union(props, name, `syntax: "${r.syntax}"; inherits: ${r.inherits ?? true}; initial-value: ${r.initial}`, "@property", errors);
    if (!isGlassTokens(t)) for (const [k, v] of Object.entries(t.bp)) union(bps, `--breakpoint-${k}`, `${num(v / 16)}rem`, "breakpoint", errors); // Glass uses these variants, defines none
    for (const [n, v] of themeEntries(t)) union(theme, n, LEGACY_FALLBACKS[n] ?? v, "@theme", errors);
    for (const [k, r] of roleLeaves(t)) {
      const s = roleSlug(k);
      const body = !r.sizeRule
        ? [`font-family: var(--mm-type-${s}-family)`, `font-style: var(--mm-type-${s}-style, normal)`, `font-size: var(--mm-type-${s}-size)`, `line-height: var(--mm-type-${s}-lh)`, `font-weight: var(--mm-type-${s}-wght)`,
           `letter-spacing: calc(var(--mm-type-${s}-tracking) + var(--mm-tracking-legible, 0em))`, `text-transform: var(--mm-type-${s}-transform, none)`,
           `font-variation-settings: var(--mm-type-${s}-fvs, "wght" calc(var(--mm-type-${s}-wght) + var(--press-wght, 0)), "ROND" var(--glass-rond, var(--mm-type-${s}-rond, 0)), "GRAD" var(--glass-grad, 0))`]
        : [`float: left`, `font-family: ${fontVar(t, r.font)}`, `font-weight: ${r.wght}`, `font-size: calc(var(--para-lh) * 3)`, `line-height: 1`, `letter-spacing: ${num(r.tracking)}em`, `font-optical-sizing: auto`, `font-variation-settings: "wght" ${r.wght}`, `@supports (initial-letter: 3) { initial-letter: 3; }`];
      union(utils, `type-${s}`, body.join(";\n  "), "@utility", errors);
    }
    if (t.scrim) for (const [k, s] of scrimLeaves(t)) { const body = scrimUtility(t, k, s); if (body) union(utils, cssName(k).slice(5), body.join(";\n  "), "@utility", errors); }
  }
  for (const [n, v] of Object.entries(LEGACY_FALLBACKS)) if (!theme.has(n)) theme.set(n, v);
  let css = `/* ${header} */\n\n`;
  for (const [n, d] of props) css += `@property --${n} {\n  ${d.split("; ").join(";\n  ")};\n}\n\n`;
  css += `@theme {\n${[...bps].map(([n, v]) => `  ${n}: ${v};`).join("\n")}\n}\n\n`;
  css += `@theme inline {\n${[...theme].map(([n, v]) => `  ${n}: ${v};`).join("\n")}\n}\n`;
  for (const [n, body] of utils) css += `\n@utility ${n} {\n  ${body.endsWith("}") ? body : body + ";"}\n}\n`;
  return css;
}
