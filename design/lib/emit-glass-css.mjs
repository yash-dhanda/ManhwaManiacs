// Glass: frontend/src/skins/glass/tokens.generated.css and Glass's share of the shared theme
// (glass/DESIGN.md §2.8, §3.6, §3.7, §4.11, §15.1). Imports only naming and spring so emit-css.mjs
// can import the theme entries back without a cycle.
import { cssName } from "./naming.mjs";
import { physicalSpringCss } from "./spring.mjs";

export const GLASS_BPS = ["phone", "tablet", "desktop", "wide"];
const num = (x) => String(Number(x.toFixed(4)));
const px = (n) => `${num(n)}px`;
const rem = (n) => `${num(n / 16)}rem`;
const block = (sel, decls, ind = "") => (decls.length ? `${ind}${sel} {\n${decls.map((d) => `${ind}  ${d};`).join("\n")}\n${ind}}\n` : "");
const media = (q, sel, decls) => (decls.length ? `@media ${q} {\n${block(sel, decls, "  ")}}\n` : "");
const ref = (c) => (c.startsWith("color.") ? `var(${cssName(c)})` : c);
const short = (c) => (c === "#000000" ? "#000" : c);
const kebab = (k) => cssName(`x.${k}`).slice(7);

export const isGlassTokens = (t) => "glass" in t;
export const TIERS = ["t1", "t2", "t3", "t4", "t5"];
const TIER_PROPS = [["thickness", num], ["bezel", px], ["displacement", num], ["blur", px], ["saturate", num], ["fill", String], ["rim", String], ["specular", num], ["shadow", String], ["dispersion", px], ["rond", num]];
// §4.11 Reduce Transparency / Solid glass: the rim every solid surface wears and the pressed solid tint.
const SOLID_RIM = "rgba(255,255,255,0.10)";
const SOLID_TINT_PRESSED = "#4A3CB0";

// A role's [size, line] per breakpoint, a null inheriting the previous one (the phone takes the tablet's).
export function roleSizes(r) {
  const out = {};
  let prev = r.phone ?? GLASS_BPS.map((b) => r[b]).find(Boolean);
  for (const b of GLASS_BPS) out[b] = prev = r[b] ?? prev;
  return out;
}
const glassRoles = (t) => Object.entries(t.type);
const slug = (role) => kebab(role);

function roleDecls(t, role, r, bp, prev) {
  const s = slug(role), sizes = roleSizes(r), [size, line] = sizes[bp];
  if (prev) {
    const [ps, pl] = sizes[prev];
    return [...(size !== ps ? [`--mm-type-${s}-size: ${rem(size)}`] : []), ...(line !== pl ? [`--mm-type-${s}-lh: ${rem(line)}`] : [])];
  }
  return [
    `--mm-type-${s}-size: ${rem(size)}`, `--mm-type-${s}-lh: ${rem(line)}`, `--mm-type-${s}-wght: ${r.wght}`,
    ...(r.rond === null ? [] : [`--mm-type-${s}-rond: ${r.rond}`]),
    `--mm-type-${s}-track: ${num(r.tracking)}em`, `--mm-type-${s}-tracking: ${num(r.tracking)}em`, `--mm-type-${s}-family: var(${t.font[r.font].css})`,
  ];
}

function borderDecls(t) {
  const out = [];
  for (const [k, b] of Object.entries(t.border)) {
    const name = cssName(`border.${k}`);
    out.push(`${name}: ${b.inset ? `inset 0 0 0 ${px(b.width)} ${ref(b.color)}` : `${px(b.width)} solid ${ref(b.color)}`}`);
    if (b.colorVar) out.push(`${name}-color: ${b.color}`);
    if ("offset" in b) out.push(`--mm-focus-offset: ${px(b.offset)}`, `--mm-focus-glow: 0 0 0 ${px(b.innerWidth)} ${short(b.innerColor)}, 0 0 0 ${px(b.glow)} ${b.glowColor}`);
  }
  return out;
}

export const glassSprings = (t) => Object.entries(t.spring).filter(([k]) => k !== "format");

export function emitGlassCss(skin, t, header) {
  const sel = `[data-skin="${skin}"]`;
  const base = [];
  const colors = (o, p) => Object.entries(o).flatMap(([k, v]) => (typeof v === "string" ? [[`${p}.${k}`, v]] : colors(v, `${p}.${k}`)));
  for (const [k, v] of colors(t.color, "color")) base.push(`${cssName(k)}: ${v}`);
  for (const [k, v] of Object.entries(t.space)) base.push(`${cssName(`space.${k}`)}: ${px(v)}`);
  for (const [k, v] of Object.entries(t.layout)) {
    const name = cssName(`layout.${k}`);
    if (typeof v === "number") base.push(`${name}: ${px(v)}`);
    else if ("fraction" in v) base.push(`${name}: clamp(${px(v.min)}, ${num(v.fraction * 100)}vw, ${px(v.max)})`);
    else base.push(`${name}: ${num(v.value)}${v.unit ?? "px"}`);
  }
  for (const g of ["bp", "radius", "blur"]) for (const [k, v] of Object.entries(t[g])) base.push(`${cssName(`${g}.${k}`)}: ${px(v)}`);
  base.push(...borderDecls(t));
  base.push(`--mm-light-angle: ${num(t.light.angle)}deg`);
  for (const [k, v] of Object.entries(t.z)) base.push(`${cssName(`z.${k}`)}: ${v}`);
  for (const tier of TIERS) for (const [p, f] of TIER_PROPS) base.push(`--mm-glass-${tier}-${p}: ${f(t.glass[tier][p])}`);
  for (const fin of ["clear", "tinted"]) for (const [p, v] of Object.entries(t.glass[fin]))
    base.push(`--mm-glass-${fin}-${kebab(p)}: ${typeof v === "string" ? v : p === "blur" ? px(v) : num(v)}`);
  for (const k of ["solid1", "solid2"]) base.push(`--mm-glass-${k}: ${t.glass[k]}`);
  for (const k of ["materialThin", "materialRegular", "materialThick"]) base.push(`--mm-glass-${kebab(k)}: ${t.glass[k].fill}`, `--mm-glass-${kebab(k)}-blur: ${px(t.glass[k].blur)}`);
  const L = t.dim.legibility;
  base.push(`--mm-dim-min: ${num(L.min)}`, `--mm-dim-slope: ${num(L.slope)}`, `--mm-dim-max: ${num(L.max)}`, `--mm-dim-min-hc: ${num(L.minHc)}`, `--mm-dim-max-hc: ${num(L.maxHc)}`);
  base.push(`--mm-grad-slope: ${num(t.dim.grad.slope)}`, `--mm-dim-edge-plateau: ${num(t.dim.edgePlateau)}`, `--mm-dim-edge-fade: ${px(t.dim.edgeFade)}`);
  for (const [k, v] of Object.entries(t.caustic)) base.push(`${cssName(`caustic.${k}`)}: ${k === "blur" || k === "offset" ? px(v) : num(v)}`);
  for (const [k, s] of glassSprings(t)) { const c = physicalSpringCss(s.ms, s.bounce); base.push(`${cssName(`spring.${k}`)}: ${c.easing}`, `${cssName(`spring.${k}`)}-ms: ${c.ms}ms`); }
  for (const [k, c] of Object.entries(t.curve)) {
    if (c.bezier) base.push(`--mm-ease-${kebab(k)}: cubic-bezier(${c.bezier.join(", ")})`);
    base.push(`--mm-dur-${kebab(k)}: ${c.ms}ms`);
  }
  for (const g of ["physics", "threshold"]) for (const [k, v] of Object.entries(t[g])) base.push(`${cssName(`${g}.${k}`)}: ${num(v)}`);
  for (const [k, f] of Object.entries(t.font)) if (cssName(`font.${k}`) !== f.css) base.push(`${cssName(`font.${k}`)}: var(${f.css})`);
  for (const [role, r] of glassRoles(t)) base.push(...roleDecls(t, role, r, "phone", null));

  let css = `/* ${header} */\n\n` + block(sel, base);
  const min = { tablet: t.bp.frame, desktop: t.bp.desktop, wide: t.bp.wide };
  for (const bp of GLASS_BPS.slice(1))
    css += media(`(min-width: ${min[bp]}px)`, sel, glassRoles(t).flatMap(([role, r]) => roleDecls(t, role, r, bp, GLASS_BPS[GLASS_BPS.indexOf(bp) - 1])));

  // §3.6 Legible text (attribute only: the setting has no media query).
  css += block(`html${sel}[data-legible="on"]`, [`--mm-font-sans: var(${t.font.legible.css})`, "--mm-tracking-legible: 0.01em"]);
  // §4.11 Reduce Transparency and Solid glass.
  const solid = [];
  for (const k of [...TIERS, "clear"]) {
    const fill = k === "t4" || k === "t5" ? t.glass.solid2 : t.glass.solid1;
    solid.push(`--mm-glass-${k}-fill: ${fill}`, `--mm-glass-${k}-blur: 0px`, `--mm-glass-${k}-saturate: 1`, `--mm-glass-${k}-displacement: 0`, `--mm-glass-${k}-dispersion: 0px`,
      `--mm-glass-${k}-rim: ${SOLID_RIM}`, `--mm-glass-${k}-specular: ${num(t.glass[k].specular * 0.5)}`);
  }
  solid.push(`--mm-glass-tinted-fill: ${t.color.iris700}`, `--mm-glass-tinted-fill-pressed: ${SOLID_TINT_PRESSED}`, "--mm-glass-tinted-blur: 0px", `--mm-glass-tinted-rim: ${SOLID_RIM}`,
    "--mm-caustic-alpha: 0", "--mm-caustic-alpha-pressed: 0");
  css += media("(prefers-reduced-transparency: reduce)", sel, solid) + block(`html${sel}[data-solid="on"]`, solid);
  // §4.11 Increase Contrast: label2 → label1, label3 → label2, accent iris400 → iris300, the hc dim clamp, 3 px rings.
  const fr = t.border.focusRing;
  const hc = [`--mm-color-label2: ${t.color.label1}`, `--mm-color-label3: ${t.color.label2}`, `--mm-color-iris400: ${t.color.iris300}`,
    `--mm-dim-min: ${num(L.minHc)}`, `--mm-dim-max: ${num(L.maxHc)}`, `--mm-border-focus-ring: ${px(fr.width + 1)} solid ${ref(fr.color)}`];
  css += media("(prefers-contrast: more)", sel, hc) + block(`html${sel}[data-contrast="more"]`, hc);
  // §4.11 Reduce Motion: every CSS spring becomes the 150 ms cross-fade (curve.reducedCrossfade).
  const rm = glassSprings(t).flatMap(([k]) => [`${cssName(`spring.${k}`)}: linear`, `${cssName(`spring.${k}`)}-ms: ${t.curve.reducedCrossfade.ms}ms`]);
  css += media("(prefers-reduced-motion: reduce)", sel, rm) + block(`html${sel}[data-motion="reduced"]`, rm);
  return css;
}

// Glass's @theme inline entries as [name, value] (§2.8 Tailwind column; also read by lint-utilities.mjs).
export function glassThemeEntries(t) {
  const out = [];
  const colors = (o, p) => Object.entries(o).flatMap(([k, v]) => (typeof v === "string" ? [`${p}.${k}`] : colors(v, `${p}.${k}`)));
  for (const k of colors(t.color, "color")) out.push([cssName(k).replace("--mm-", "--"), `var(${cssName(k)})`]);
  for (const [name, r] of Object.entries(t.runtime ?? {})) if (!r.syntax || r.syntax === "<color>") out.push([`--color-${name}`, `var(--${name})`]);
  for (const g of ["radius", "blur"]) for (const k of Object.keys(t[g])) out.push([`--${g}-${kebab(k)}`, `var(${cssName(`${g}.${k}`)})`]);
  for (const k of Object.keys(t.layout)) out.push([`--spacing-${kebab(k)}`, `var(${cssName(`layout.${k}`)})`]);
  for (const [k] of glassSprings(t)) out.push([`--ease-spring-${kebab(k)}`, `var(${cssName(`spring.${k}`)})`]);
  for (const [k, c] of Object.entries(t.curve)) if (c.bezier) out.push([`--ease-${kebab(k)}`, `var(--mm-ease-${kebab(k)})`]);
  for (const f of ["sans", "mono", "serif"]) out.push([`--font-${f}`, `var(${t.font[f].css})`]);
  for (const [role] of glassRoles(t)) {
    const s = slug(role);
    out.push([`--text-${s}`, `var(--mm-type-${s}-size)`], [`--text-${s}--line-height`, `var(--mm-type-${s}-lh)`], [`--text-${s}--letter-spacing`, `var(--mm-type-${s}-tracking)`], [`--text-${s}--font-weight`, `var(--mm-type-${s}-wght)`]);
  }
  return out;
}
