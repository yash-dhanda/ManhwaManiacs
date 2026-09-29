// One construction module for every Glass master (glass DESIGN §12.1, §12.2). Geometry comes from mark.json.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { token } from "../lib/tokens.mjs";
import { fontPath } from "../lib/fonts.mjs";
import { textPath } from "../lib/text.mjs";

const here = dirname(fileURLToPath(import.meta.url));
export const G = JSON.parse(readFileSync(join(here, "mark.json"), "utf8"));
export const FROST = token("glass", "color.brandFrost");
export const IRIS400 = token("glass", "color.iris400");
if (FROST.toUpperCase() !== G.frost || IRIS400.toUpperCase() !== G.iris400) throw new Error("mark.json colours drifted from glass tokens");
const r2 = (n) => Math.round(n * 100) / 100;
export const svg = (vb, body, extra = "") =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}"${extra}>${body}</svg>\n`;

const poly = (pts) => "M" + pts.map((p) => p.join(" ")).join(" L");
export const SLABS = [ // back to front
  { id: "bottom-m", d: poly(G.bottomM), w: G.stroke, film: 0.22 },
  { id: "gutter-bar", d: G.bar.d, w: G.bar.stroke, film: 0.10, bar: true },
  { id: "top-m", d: poly(G.topM), w: G.stroke, film: 0.30, top: true },
];
export const slab = (id) => SLABS.find((s) => s.id === id);
const stroked = (s, extra) => `<path d="${s.d}" fill="none" stroke-width="${s.w}" stroke-linecap="round" stroke-linejoin="round"${extra}/>`;
const strokedW = (s, w, stroke, extra = "") => `<path d="${s.d}" fill="none" stroke="${stroke}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"${extra}/>`;
const REGION = `filterUnits="userSpaceOnUse" x="-512" y="-512" width="2048" height="2048"`;

// ---- field: gradient + three blurred blobs, blur not clipped (user-space filter region) ----
export function fieldDefs(id = "field") {
  const f = G.field;
  const blobs = f.blobs.map((b, i) => `<radialGradient id="${id}-b${i}" gradientUnits="userSpaceOnUse" cx="${b.cx}" cy="${b.cy}" r="${b.r}"><stop offset="0" stop-color="${b.color}"/><stop offset="1" stop-color="${b.color}" stop-opacity="0"/></radialGradient>`).join("");
  return `<linearGradient id="${id}-g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${f.top}"/><stop offset="1" stop-color="${f.bottom}"/></linearGradient>` + blobs +
    `<filter id="${id}-blur" ${REGION}><feGaussianBlur stdDeviation="${f.blur}"/></filter>` +
    `<g id="${id}"><rect width="1024" height="1024" fill="url(#${id}-g)"/><g opacity="${f.blobOpacity}" filter="url(#${id}-blur)">` +
    G.field.blobs.map((b, i) => `<circle cx="${b.cx}" cy="${b.cy}" r="${b.r}" fill="url(#${id}-b${i})"/>`).join("") + `</g></g>`;
}
export const fieldSvg = () => svg("0 0 1024 1024", `<defs>${fieldDefs()}</defs><use href="#field"/>`, ` width="1024" height="1024"`);

// ---- flat slab layers (Icon Composer) ----
export const slabLayerSvg = (id) => {
  const s = slab(id);
  return svg("0 0 1024 1024", strokedW(s, s.w, FROST), ` width="1024" height="1024"`);
};

// ---- flattened slabs with shadow, rim, refraction and film (icon.svg, icon-foreground.svg) ----
export function glassSlabsBody() {
  const defs = fieldDefs() +
    `<filter id="shadow" ${REGION}><feGaussianBlur stdDeviation="20"/></filter>` +
    `<filter id="refract" ${REGION}><feGaussianBlur stdDeviation="6"/><feComponentTransfer><feFuncR type="linear" slope="1.35"/><feFuncG type="linear" slope="1.35"/><feFuncB type="linear" slope="1.35"/></feComponentTransfer></filter>` +
    `<linearGradient id="rim-top" gradientUnits="userSpaceOnUse" x1="240" y1="192" x2="784" y2="480"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0.20"/></linearGradient>` +
    SLABS.map((s) => `<mask id="m-${s.id}" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">${strokedW(s, s.w, "#FFFFFF")}</mask>`).join("");
  const layers = SLABS.map((s) => {
    const t = s.bar ? "translate(512 512) scale(1.10) translate(-512 -512) translate(0 9)" : "translate(512 512) scale(1.06) translate(-512 -512) translate(-10 -14)";
    const rim = s.top ? "url(#rim-top)" : "rgba(255,255,255,0.40)";
    return `<g id="s-${s.id}">` +
      `<g opacity="0.5" filter="url(#shadow)" transform="translate(0 12)">${strokedW(s, s.w, "#000000")}</g>` +
      strokedW(s, s.w + 6, rim) +
      `<g mask="url(#m-${s.id})"><g filter="url(#refract)"><use href="#field" transform="${t}"/></g></g>` +
      strokedW(s, s.w, FROST, ` opacity="${s.film}"`) + `</g>`;
  }).join("");
  return { defs, layers };
}
export function iconSvg() {
  const { defs, layers } = glassSlabsBody();
  return svg("0 0 1024 1024", `<defs>${defs}</defs><use href="#field"/>${layers}`, ` width="1024" height="1024"`);
}
const SCALE = 0.69718;
const FG = `translate(512 512) scale(${SCALE}) translate(-512 -512)`;
export const FG_SCALE = SCALE;
export function iconForegroundSvg() {
  const { defs, layers } = glassSlabsBody();
  // the field is a def only (refraction source): the Android background layer carries it
  return svg("0 0 1024 1024", `<defs>${defs}</defs><g transform="${FG}">${layers}</g>`, ` width="1024" height="1024"`);
}
const railed = (fill, op = 1) => SLABS.map((s) => strokedW(s, s.w, fill, op === 1 ? "" : ` opacity="${op}"`)).join("");
export function iconDarkSvg() {
  const rim = (s) => strokedW(s, s.w + 6, "rgba(255,255,255,0.40)");
  return svg("0 0 1024 1024", SLABS.map((s) => `<g opacity="0.85">${rim(s)}${strokedW(s, s.w, FROST)}</g>`).join(""), ` width="1024" height="1024"`);
}
export function iconTintedSvg() {
  const op = { "bottom-m": 0.8, "gutter-bar": 0.55, "top-m": 1 };
  return svg("0 0 1024 1024", `<rect width="1024" height="1024" fill="#000000"/>` + SLABS.map((s) => strokedW(s, s.w, "#FFFFFF", op[s.id] === 1 ? "" : ` opacity="${op[s.id]}"`)).join(""), ` width="1024" height="1024"`);
}
export const iconMonochromeSvg = () => svg("0 0 1024 1024", `<g transform="${FG}">${railed("#FFFFFF")}</g>`, ` width="1024" height="1024"`);
export const neutralMarkSvg = () => svg(G.viewBox, railed(FROST), ` width="544" height="640"`);
export const columnSmallSvg = () => svg(G.viewBox, railed(FROST).split("<path").filter((p) => p).filter((p) => !p.includes(G.bar.d)).map((p) => "<path" + p).join(""), ` width="544" height="640"`);

// ---- lowercase settings ----
export const LOWER = { axes: { wght: 620, ROND: 100, opsz: 144, GRAD: 0, wdth: 100, slnt: 0 }, size: 402.23, tracking: -0.02 };
export const LINE = { axes: { wght: 640, ROND: 100, opsz: 20, GRAD: 0, wdth: 100, slnt: 0 }, tracking: -0.02 };

const onlyMs = () => SLABS.filter((s) => !s.bar);
export async function wordmarkStacked() {
  const font = await fontPath("gsf");
  const a = textPath({ font, axes: LOWER.axes, text: "anhwa", size: LOWER.size, x: 920, baseline: 480, tracking: LOWER.tracking });
  const b = textPath({ font, axes: LOWER.axes, text: "aniacs", size: LOWER.size, x: 920, baseline: 832, tracking: LOWER.tracking });
  const c = G.capsule;
  const x1 = Math.max(a.bbox.x1, b.bbox.x1);
  const vb = `${c.x} ${c.y} ${r2(x1 - c.x + 8)} ${c.height}`;
  const defs = `<filter id="eng" ${REGION}><feComponentTransfer in="SourceAlpha"><feFuncA type="table" tableValues="1 0"/></feComponentTransfer><feOffset dx="9" dy="9"/><feGaussianBlur stdDeviation="9"/><feComposite operator="in" in2="SourceAlpha" result="sh"/><feFlood flood-color="#000000" flood-opacity="0.45"/><feComposite operator="in" in2="sh" result="ish"/><feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="ish"/></feMerge></filter>` +
    `<linearGradient id="spec-t" gradientUnits="userSpaceOnUse" x1="240" y1="192" x2="512" y2="336"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>` +
    `<linearGradient id="spec-b" gradientUnits="userSpaceOnUse" x1="240" y1="544" x2="512" y2="688"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>` +
    onlyMs().map((s) => `<mask id="e-${s.id}" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">${strokedW(s, s.w, "#FFFFFF")}<g transform="translate(4.5 4.5)">${strokedW(s, s.w, "#000000")}</g></mask>`).join("");
  const engr = onlyMs().map((s) => `<g filter="url(#eng)">${strokedW(s, s.w, FROST)}</g>` +
    `<g mask="url(#e-${s.id})">${strokedW(s, s.w, `url(#spec-${s.top ? "t" : "b"})`)}</g>`).join("");
  const bar = `<path d="${G.bar.d}" fill="none" stroke="rgba(245,247,250,0.18)" stroke-width="${G.bar.stroke}" stroke-linecap="round"/>` +
    `<path d="M 272 480 Q 512 498 752 480" fill="none" stroke="rgba(255,255,255,0.55)" stroke-width="2.25"/>`;
  const body = `<defs>${defs}</defs><rect x="${c.x}" y="${c.y}" width="${c.width}" height="${c.height}" rx="${c.radius}" fill="rgba(245,247,250,0.08)" stroke="rgba(255,255,255,0.30)" stroke-width="4.5"/>` + engr + bar +
    `<path d="${a.d}" fill="${FROST}"/><path d="${b.d}" fill="${FROST}"/>`;
  return { svg: svg(vb, body), a, b };
}
export async function wordmarkStackedFlat() {
  const { a, b } = await wordmarkStacked();
  const x1 = Math.max(a.bbox.x1, b.bbox.x1);
  const m = onlyMs().map((s) => strokedW(s, s.w, FROST)).join("");
  return svg(`240 192 ${r2(x1 - 240 + 8)} 640`, m + `<path d="${a.d}" fill="${FROST}"/><path d="${b.d}" fill="${FROST}"/>`);
}
export async function wordmarkLine() {
  const font = await fontPath("gsf");
  const size = 100, seg = [["M", IRIS400], ["anhwa", FROST], ["M", IRIS400], ["aniacs", FROST]];
  let x = 0, out = "", y0 = Infinity, y1 = -Infinity;
  for (const [text, fill] of seg) {
    const t = textPath({ font, axes: LINE.axes, text, size, x, baseline: 100, tracking: LINE.tracking });
    out += `<path d="${t.d}" fill="${fill}"/>`; x += t.advance; y0 = Math.min(y0, t.bbox.y0); y1 = Math.max(y1, t.bbox.y1);
  }
  return svg(`0 ${r2(y0 - 4)} ${r2(x + 4)} ${r2(y1 - y0 + 8)}`, out);
}
export function faviconSvg() {
  const f = G.field;
  const s = 0.0375, s2 = 26 / 544;
  const inner = railed(FROST);
  const small = strokedW(slab("top-m"), 88, FROST) + strokedW(slab("gutter-bar"), 64, FROST);
  return svg("0 0 32 32",
    `<defs><linearGradient id="f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${f.top}"/><stop offset="1" stop-color="${f.bottom}"/></linearGradient></defs>` +
    `<style>.small{display:none}@media (max-width: 31px){.full{display:none}.small{display:inline}}</style>` +
    `<rect width="32" height="32" rx="7.2" fill="url(#f)"/>` +
    `<g class="full" transform="translate(5.8 4) scale(${s}) translate(-240 -192)">${inner}</g>` +
    `<g class="small" transform="translate(3 7.6) scale(${r2(s2 * 1e5) / 1e5}) translate(-240 -192)">${small}</g>`,
    ` width="32" height="32"`);
}
const DROPS = [[72, 96, 15], [208, 60, 9], [356, 132, 18], [120, 280, 12], [300, 330, 10.5], [410, 420, 13.5]];
export const DROP_COUNT = DROPS.length;
export function dropletsSvg() {
  const defs = `<radialGradient id="d"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.06"/><stop offset="0.7" stop-color="#FFFFFF" stop-opacity="0.02"/><stop offset="1" stop-color="#000000" stop-opacity="0.22"/></radialGradient>`;
  const drops = DROPS.map(([x, y, r]) => `<circle class="drop" cx="${x}" cy="${y}" r="${r}" fill="url(#d)"/><circle cx="${r2(x - 0.35 * r)}" cy="${r2(y - 0.35 * r)}" r="3" fill="#FFFFFF" fill-opacity="0.35"/>`).join("");
  return svg("0 0 480 480", `<defs>${defs}</defs>${drops}`, ` width="480" height="480"`);
}

// stroked extents (round caps and joins: every point +- w/2; the bar is measured on its curve)
export function extents() {
  const ext = (pts, w) => ({ x0: Math.min(...pts.map((p) => p[0])) - w / 2, x1: Math.max(...pts.map((p) => p[0])) + w / 2, y0: Math.min(...pts.map((p) => p[1])) - w / 2, y1: Math.max(...pts.map((p) => p[1])) + w / 2 });
  const t = ext(G.topM, G.stroke), b = ext(G.bottomM, G.stroke);
  const bar = { x0: G.bar.p0[0] - G.bar.stroke / 2, x1: G.bar.p1[0] + G.bar.stroke / 2 };
  const midY = 0.25 * G.bar.p0[1] + 0.5 * G.bar.c[1] + 0.25 * G.bar.p1[1];
  return { column: { x0: Math.min(t.x0, b.x0, bar.x0), x1: Math.max(t.x1, b.x1, bar.x1), y0: t.y0, y1: b.y1 }, bow: midY - G.bar.p0[1], capsule: G.capsule };
}
