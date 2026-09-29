import { glass } from "../tokens.generated";
import type { Tier } from "./material";

/** Refractive index of the glass (DESIGN 2.4.3). */
export const N = 1.5;
export const SAMPLES = 128;

export interface MapShape {
  x: number;
  y: number;
  w: number;
  h: number;
  r: number;
  tier: Tier;
}

export interface LiquidMap {
  key: string;
  /** PNG data URL, CSS-pixel resolution, group-sized */
  href: string;
  /** feDisplacementMap scale = 2 x the group's largest max displacement */
  scale: number;
  /** channel scale multipliers for T4/T5 dispersion, or null */
  dispersion: [number, number, number] | null;
}

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

const profileCache = new Map<Tier, number[]>();

/**
 * Lateral travel of a vertical ray refracted (Snell, n = 1.5) at the convex squircle surface
 * y(x) = (1 - (1 - x)^4)^(1/4) of the bezel, x = 0 at the rim and 1 at the inner edge of the band,
 * over the tier's virtual thickness; 128 samples, normalised so the largest equals the tier's max displacement.
 */
export function profileFor(tier: Tier): number[] {
  const hit = profileCache.get(tier);
  if (hit) return hit;
  const { thickness, displacement } = glass[tier];
  const raw = Array.from({ length: SAMPLES }, (_, i) => {
    const x = Math.min(i / (SAMPLES - 1), 1);
    const u = 1 - x;
    const inner = 1 - u ** 4;
    // slope of the surface: infinite at the rim (vertical wall), 0 at the inner edge
    const slope = inner <= 0 ? Infinity : (u ** 3) / inner ** 0.75;
    const t1 = Math.atan(slope); // incidence angle of the vertical ray
    const t2 = Math.asin(Math.sin(t1) / N);
    return thickness * Math.tan(t1 - t2);
  });
  const max = Math.max(...raw);
  const out = raw.map((v) => (v / max) * displacement);
  profileCache.set(tier, out);
  return out;
}

/** Signed distance to a rounded rectangle at p (negative inside) and the gradient of it (outward unit normal). */
export function rrSdf(px: number, py: number, s: MapShape) {
  const cx = s.x + s.w / 2, cy = s.y + s.h / 2;
  const hx = s.w / 2 - s.r, hy = s.h / 2 - s.r;
  const dx = px - cx, dy = py - cy;
  const qx = Math.abs(dx) - hx, qy = Math.abs(dy) - hy;
  const sx = dx < 0 ? -1 : 1, sy = dy < 0 ? -1 : 1;
  const ox = Math.max(qx, 0), oy = Math.max(qy, 0);
  const outside = Math.hypot(ox, oy);
  const sd = outside + Math.min(Math.max(qx, qy), 0) - s.r;
  let nx: number, ny: number;
  if (outside > 0) { nx = (ox / outside) * sx; ny = (oy / outside) * sy; }
  else if (qx > qy) { nx = sx; ny = 0; }
  else { nx = 0; ny = sy; }
  return { sd, nx, ny };
}

/** R/G encoding of a displacement component in [-D, D]: 128 + 127 x d / D. */
export const encode = (d: number, D: number) => Math.round(128 + (127 * d) / D);

/** The RGBA buffer of a shape list over a groupW x groupH canvas. Direction: the inward normal, so the rim bends the backdrop toward the centre. */
export function renderMapData(shapes: readonly MapShape[], groupW: number, groupH: number) {
  const data = new Uint8ClampedArray(groupW * groupH * 4);
  for (let i = 0; i < data.length; i += 4) { data[i] = 128; data[i + 1] = 128; data[i + 2] = 128; data[i + 3] = 255; }
  const D = Math.max(...shapes.map((s) => glass[s.tier].displacement));
  for (const s of shapes) {
    const bezel = glass[s.tier].bezel;
    const profile = profileFor(s.tier);
    const x0 = Math.max(0, Math.floor(s.x)), x1 = Math.min(groupW, Math.ceil(s.x + s.w));
    const y0 = Math.max(0, Math.floor(s.y)), y1 = Math.min(groupH, Math.ceil(s.y + s.h));
    for (let y = y0; y < y1; y++) {
      for (let x = x0; x < x1; x++) {
        const { sd, nx, ny } = rrSdf(x + 0.5, y + 0.5, s);
        const depth = Math.max(0, -sd - 0.5); // the outermost pixel row sits on the rim
        if (sd > 0 || depth >= bezel) continue;
        const mag = profile[Math.min(SAMPLES - 1, Math.round(clamp01(depth / bezel) * (SAMPLES - 1)))];
        const o = (y * groupW + x) * 4;
        data[o] = encode(-nx * mag, D);
        data[o + 1] = encode(-ny * mag, D);
      }
    }
  }
  return { data, D };
}

const DISPERSION: Partial<Record<Tier, [number, number, number]>> = { t4: [1, 1.033, 1.067], t5: [1, 1.055, 1.109] };

/** Stable cache key: the shape list rounded to whole px, the tiers and the caller's variant. */
export const mapKey = (shapes: readonly MapShape[], w: number, h: number, variant = "") =>
  `${variant}|${Math.round(w)}x${Math.round(h)}|` +
  shapes.map((s) => [s.x, s.y, s.w, s.h, s.r].map(Math.round).join(",") + s.tier).join(";");

const cache = new Map<string, LiquidMap>();
const CACHE_MAX = 32;
export const mapCacheSize = () => cache.size;

/** One displacement map per surface or bar group (LRU of 32). Browser only (canvas). */
export function liquidMap(shapes: readonly MapShape[], groupW: number, groupH: number, variant = ""): LiquidMap {
  const key = mapKey(shapes, groupW, groupH, variant);
  const hit = cache.get(key);
  if (hit) { cache.delete(key); cache.set(key, hit); return hit; }
  const w = Math.max(1, Math.round(groupW)), h = Math.max(1, Math.round(groupH));
  const { data, D } = renderMapData(shapes, w, h);
  const canvas = document.createElement("canvas");
  canvas.width = w; canvas.height = h;
  canvas.getContext("2d")!.putImageData(new ImageData(data, w, h), 0, 0);
  const tiers = shapes.map((s) => s.tier);
  const top = (["t5", "t4"] as const).find((t) => tiers.includes(t));
  const map: LiquidMap = { key, href: canvas.toDataURL("image/png"), scale: 2 * D, dispersion: top ? DISPERSION[top]! : null };
  cache.set(key, map);
  if (cache.size > CACHE_MAX) cache.delete(cache.keys().next().value!);
  return map;
}

/** mask-image for a bar group: the same rounded rectangles as an SVG data URL. */
export function maskHref(shapes: readonly MapShape[], w: number, h: number) {
  const rects = shapes.map((s) => `<rect x="${s.x}" y="${s.y}" width="${s.w}" height="${s.h}" rx="${s.r}" ry="${s.r}"/>`).join("");
  return `url("data:image/svg+xml,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' width='${w}' height='${h}'><g fill='#000'>${rects}</g></svg>`)}")`;
}
