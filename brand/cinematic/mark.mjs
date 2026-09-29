// One construction module for every Cinematic master. Geometry comes from monogram.json (shared/02); never recomputed.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { token } from "../lib/tokens.mjs";
import { fontPath } from "../lib/fonts.mjs";
import { textPath } from "../lib/text.mjs";

const here = dirname(fileURLToPath(import.meta.url));
export const MONO = JSON.parse(readFileSync(join(here, "monogram.json"), "utf8"));
export const C = {
  bone: token("cinematic", "color.ink.100"),
  spot: token("cinematic", "color.spot"),
  glow: token("cinematic", "color.spot.glow"),
  page: token("cinematic", "color.paper.0"),
  duo: token("cinematic", "color.ambient.fallback.duo"),
};
export const WHITE = "#FFFFFF";
const r2 = (n) => Math.round(n * 100) / 100;
export const svg = (vb, body, extra = "") =>
  `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="${vb}"${extra}>${body}</svg>\n`;

const U = MONO.upright, I = MONO.italic;
const BOX = { x0: MONO.bbox.x[0], x1: MONO.bbox.x[1], y0: MONO.bbox.y[0], y1: MONO.bbox.y[1] };
export const MARK_W = BOX.x1 - BOX.x0; // 560
export const MARK_H = BOX.y1 - BOX.y0;

// mask carrying the upright as a white shape (masks, not clipPath: strokes must count)
const mask = (id, d, stroke = 0) =>
  `<mask id="${id}" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024"><path d="${d}" fill="#FFFFFF"${stroke ? ` stroke="#FFFFFF" stroke-width="${stroke}" stroke-linejoin="round"` : ""}/></mask>`;
const sk = (c, w) => (w ? ` stroke="${c}" stroke-width="${w}" stroke-linejoin="round"` : "");

// colour monogram in 1024 space; stroke widens hairlines for small sizes
export function monogramBody({ stroke = 0, bloom = false } = {}) {
  return `<defs>${mask("mU", U, stroke)}</defs>` +
    `<path d="${U}" fill="${C.bone}"${sk(C.bone, stroke)}/>` +
    `<path d="${I}" fill="${C.bone}"${sk(C.bone, stroke)}/>` +
    (bloom ? `<g filter="url(#bloom)" opacity="0.30"><g mask="url(#mU)"><path d="${I}" fill="${C.spot}"/></g></g>` : "") +
    `<g mask="url(#mU)"><path d="${I}" fill="${C.spot}"${sk(C.spot, stroke)}/></g>`;
}
export const BLOOM_FILTER = `<filter id="bloom" filterUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024"><feGaussianBlur stdDeviation="12"/></filter>`;

export function monogramMono(fill = WHITE, stroke = 0) {
  return `<path d="${U}" fill="${fill}"${sk(fill, stroke)}/><path d="${I}" fill="${fill}"${sk(fill, stroke)}/>`;
}

// bone/black variants: union in `m`, intersection in `f` with a 14 unit rim in `m`
export function monogramTwoTone(field, m) {
  return `<rect width="1024" height="1024" fill="${field}"/><defs>${mask("mU", U)}<mask id="mI" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024"><path d="${I}" fill="#FFFFFF"/></mask></defs>` +
    `<path d="${U}" fill="${m}"/><path d="${I}" fill="${m}"/>` +
    `<g mask="url(#mU)"><path d="${I}" fill="${field}"/></g>` +
    `<g mask="url(#mI)"><path d="${U}" fill="none" stroke="${m}" stroke-width="28"/></g>` +
    `<g mask="url(#mU)"><path d="${I}" fill="none" stroke="${m}" stroke-width="28"/></g>`;
}

// ---- icon composition (Decisions 2, 3) ----
export const ICON = (() => {
  const s = 655.36 / MARK_W;
  const mh = MARK_H * s, gap = 184.32, rule = 48;
  const top = (1024 - (mh + gap + rule)) / 2;
  return { s, top, mh, ruleTop: top + mh + gap, box: { x0: 184.32, x1: 839.68, y0: top, y1: top + mh + gap + rule } };
})();

export function oxford(x, y, w, [t, g, h], { bone = C.bone, spot = null, spotFrac = 0.12 } = {}) {
  const line = (yy, hh) => {
    if (!spot) return `<rect x="${r2(x)}" y="${r2(yy)}" width="${r2(w)}" height="${hh}" fill="${bone}"/>`;
    const sw = r2(w * spotFrac);
    return `<rect x="${r2(x)}" y="${r2(yy)}" width="${sw}" height="${hh}" fill="${spot}"/><rect x="${r2(x + sw)}" y="${r2(yy)}" width="${r2(w - sw)}" height="${hh}" fill="${bone}"/>`;
  };
  return line(y, t) + line(y + t + g, h);
}

// mark + bloom + rule in icon space. mode: color | mono
export function iconGroup(mode = "color") {
  const { s, top, ruleTop } = ICON;
  const T = `translate(512 ${r2(top)}) scale(${r2(s * 1e4) / 1e4}) translate(-512 ${-BOX.y0})`;
  const mark = mode === "color" ? `<g transform="${T}">${monogramBody({ bloom: true })}</g>` : `<g transform="${T}">${monogramMono()}</g>`;
  const ruleFill = mode === "color" ? C.bone : WHITE;
  return mark + oxford(512 - 204.8, ruleTop, 409.6, [24, 16, 8], { bone: ruleFill });
}
const iconDefs = `<defs>${BLOOM_FILTER}</defs>`;

const GRAIN = `<filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="2" seed="11" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter>` ;
export const iconSvg = () => svg("0 0 1024 1024", `<defs>${GRAIN}${BLOOM_FILTER}</defs><rect width="1024" height="1024" fill="${C.page}"/><rect width="1024" height="1024" filter="url(#grain)" opacity="0.02"/>${iconGroup()}`);
export const iconDarkSvg = () => svg("0 0 1024 1024", iconDefs + iconGroup());
export const iconTintedSvg = () => svg("0 0 1024 1024", `<rect width="1024" height="1024" fill="${C.page}"/>${iconGroup("mono")}`);
function fitted(mode, side) {
  const k = side / (ICON.box.x1 - ICON.box.x0), cy = (ICON.box.y0 + ICON.box.y1) / 2;
  return `<g transform="translate(512 512) scale(${r2(k * 1e4) / 1e4}) translate(-512 ${r2(-cy)})">${iconGroup(mode)}</g>`;
}
export const iconForegroundSvg = () => svg("0 0 1024 1024", iconDefs + fitted("color", 379.26));
export const iconMonochromeSvg = () => svg("0 0 1024 1024", fitted("mono", 379.26));
export const maskableSvg = () => {
  const k = 302 / (ICON.box.x1 - ICON.box.x0), cy = (ICON.box.y0 + ICON.box.y1) / 2;
  return svg("0 0 512 512", `${iconDefs}<rect width="512" height="512" fill="${C.page}"/><g transform="translate(256 256) scale(${r2(k * 1e4) / 1e4}) translate(-512 ${r2(-cy)})">${iconGroup()}</g>`);
};

export const monogramSvg = () => svg("0 0 1024 1024", monogramBody());
export const monogramSmallSvg = () => svg("0 0 1024 1024", monogramBody({ stroke: 16 }));
export const monogramBoneOnBlack = () => svg("0 0 1024 1024", monogramTwoTone(C.page, C.bone));
export const monogramBlackOnBone = () => svg("0 0 1024 1024", monogramTwoTone(C.bone, C.page));
export const monogramMonoSvg = () => svg("0 0 1024 1024", monogramMono());
export const icStatSvg = () => {
  const s = (20 - 1.7) / MARK_W;
  return svg("0 0 24 24", `<g transform="translate(12 12) scale(${s.toFixed(6)}) translate(-512 -512)">${monogramMono(WHITE, 1.7 / s)}</g>`);
};

// ---- favicon ----
const M_STROKES = (c) =>
  `<g stroke="${c}" fill="none" stroke-linecap="butt"><path d="M3.5 7V25" stroke-width="3"/><path d="M3.5 7L9 25" stroke-width="5"/><path d="M9 25L14.5 7" stroke-width="3"/><path d="M14.5 7V25" stroke-width="5"/></g>`;
export const faviconSvg = () => svg("0 0 32 32",
  `<defs><clipPath id="c"><rect x="0" y="7" width="32" height="18"/></clipPath><mask id="mu" maskUnits="userSpaceOnUse" x="0" y="0" width="32" height="32"><g clip-path="url(#c)">${M_STROKES("#FFFFFF")}</g></mask></defs>` +
  `<rect width="32" height="32" fill="${C.page}"/><g clip-path="url(#c)">${M_STROKES(C.bone)}</g>` +
  `<g transform="translate(15.1 0) skewX(-12)"><g clip-path="url(#c)">${M_STROKES(C.bone)}</g></g>` +
  `<g mask="url(#mu)"><g transform="translate(15.1 0) skewX(-12)"><g clip-path="url(#c)">${M_STROKES(C.spot)}</g></g></g>`);

// ---- wordmark ----
const AX = { opsz: 96, wght: 800 };
export async function words() {
  const roman = await fontPath("bodoni"), ital = await fontPath("bodoni-italic");
  const a = textPath({ font: roman, axes: AX, text: "Manhwa", size: 320, tracking: -0.035 });
  const b0 = textPath({ font: ital, axes: AX, text: "Maniacs", size: 320, tracking: -0.035 });
  return { a, b0 };
}
const move = (t, dx, dy) => ({ ...t, d: t.glyphs.map((g) => g.d).join(""), dx, dy });
const U10 = 10; // u = cap height 240 / 24

// mode: color | bone | black
export async function wordmarkSvg(mode = "color") {
  const { a, b0 } = await words();
  const lastA = a.glyphs[a.glyphs.length - 1].bbox, firstM = b0.glyphs[0].bbox;
  const dx = lastA.x1 - firstM.x0; // italic M's box left edge = last a's box right edge
  const left = a.bbox.x0, right = dx + b0.bbox.x1, w = right - left;
  const top = Math.min(a.bbox.y0, b0.bbox.y0), base = 0, ruleY = base + 6 * U10;
  const fill = mode === "black" ? C.page : C.bone;
  const body = `<path d="${a.d}" fill="${fill}"/><path transform="translate(${r2(dx)} 0)" d="${b0.d}" fill="${fill}"/>` +
    oxford(left, ruleY, w, [3 * U10, 2 * U10, U10], { bone: fill, spot: mode === "color" ? C.spot : null });
  const vb = [r2(left), r2(top), r2(w), r2(ruleY + 6 * U10 - top)].join(" ");
  return { svg: svg(vb, body), w, cap: 240, dx, left, top };
}

export async function lockupSvg(mode = "color", opts = {}) {
  const { a, b0 } = await words();
  const fill = mode === "mono" ? C.bone : C.bone;
  const dy = 0.86 * 320;
  const aL = a.bbox.x0, bL = b0.glyphs[0].bbox.x0, wA = a.bbox.x1 - aL, wB = b0.bbox.x1 - bL;
  const w = Math.max(wA, wB);
  const ruleY = dy + 6 * U10;
  const top = Math.min(a.bbox.y0, b0.bbox.y0 + dy) ;
  const inner = `<path transform="translate(${r2(-aL)} 0)" d="${a.d}" fill="${fill}"/><path transform="translate(${r2(-bL)} ${r2(dy)})" d="${b0.d}" fill="${fill}"/>` +
    oxford(0, ruleY, w, [3 * U10, 2 * U10, U10], { bone: fill, spot: mode === "color" ? C.spot : null });
  const h = ruleY + 6 * U10 - top;
  return { svg: svg([0, r2(top), r2(w), r2(h)].join(" "), inner), inner, w, top, h, cap: 240 };
}
