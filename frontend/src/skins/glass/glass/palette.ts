import { FastAverageColor } from "fast-average-color";
import { hexToOklch, oklchToHex, rgbToHex } from "@/lib/color/oklch";

export interface CoverPalette {
  /** three colours, dominant first */
  a: readonly string[];
  /** mean relative luminance 0 to 1 */
  l: number;
  /** 95th percentile relative luminance */
  lMax: number;
}

export type Mood = "default" | "romantic" | "action" | "comedy" | "horror" | "sliceOfLife" | "fantasy";

/** DESIGN 2.1.6: the seven moods, colour and field opacity. Default is #4336A3 over #2B2370 at 30 %. */
export const MOODS: Record<Mood, { colour: string; colour2?: string; opacity: number }> = {
  default: { colour: "#4336A3", colour2: "#2B2370", opacity: 0.3 },
  romantic: { colour: "#FF7AA8", opacity: 0.2 },
  action: { colour: "#FF6B4A", opacity: 0.2 },
  comedy: { colour: "#FFC94D", opacity: 0.16 },
  horror: { colour: "#C0506F", opacity: 0.26 },
  sliceOfLife: { colour: "#9FD98A", opacity: 0.16 },
  fantasy: { colour: "#9B8CFF", opacity: 0.22 },
};

/** Brand aurora for auth and onboarding (2.1.8), at 20 %. */
export const AURORA = ["#8FD8FF", "#A99BFF", "#FF9ED8"] as const;

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/** Relative luminance of an sRGB pixel (0 to 1). */
const lum = (r: number, g: number, b: number) => {
  const f = (v: number) => { const x = v / 255; return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4; };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
};

/** Mean and 95th-percentile relative luminance of RGBA pixel data. */
export function luminanceStats(data: ArrayLike<number>): { l: number; lMax: number } {
  const n = Math.floor(data.length / 4);
  if (!n) return { l: 0, lMax: 0 };
  const ls = new Float32Array(n);
  let sum = 0;
  for (let i = 0; i < n; i++) { ls[i] = lum(data[i * 4], data[i * 4 + 1], data[i * 4 + 2]); sum += ls[i]; }
  ls.sort();
  return { l: sum / n, lMax: ls[Math.min(n - 1, Math.floor(0.95 * n))] };
}

/** a[1] and a[2]: the dominant colour with the hue rotated by +-30 degrees at the same OKLCH L and C. */
export function deriveAccents(hex: string): [string, string, string] {
  const o = hexToOklch(hex);
  return [hex.toUpperCase(), oklchToHex({ ...o, h: (o.h + 30) % 360 }), oklchToHex({ ...o, h: (o.h + 330) % 360 })];
}

/** OKLCH clamping for the field (2.1.8): L 0.55 to 0.78, C 0.06 to 0.16, hue kept; a near-grey colour becomes the mood colour. */
export function fieldColours(palette: Pick<CoverPalette, "a">, mood: Mood): { colours: [string, string, string]; smallThird: boolean } {
  const moodHex = MOODS[mood].colour;
  const clampOne = (hex: string) => {
    const o = hexToOklch(hex);
    if (o.c < 0.03) return moodHex; // near-grey: the mood colour carries the field
    return oklchToHex({ l: clamp(o.l, 0.55, 0.78), c: clamp(o.c, 0.06, 0.16), h: o.h });
  };
  const src = palette.a.length ? palette.a.slice(0, 3) : [moodHex];
  const out = src.map(clampOne);
  const smallThird = out.length < 3;
  while (out.length < 3) out.push(out[0]);
  return { colours: out as [string, string, string], smallThird };
}

/** The rim tint: a[0] at OKLCH L 0.86 with C capped at 0.08. */
export function rimTint(palette: Pick<CoverPalette, "a">): string {
  const o = hexToOklch(palette.a[0] ?? MOODS.default.colour);
  return oklchToHex({ l: 0.86, c: Math.min(o.c, 0.08), h: o.h });
}

const cache = new Map<string, Promise<CoverPalette>>();

function decode(url: string): Promise<CoverPalette> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      try {
        const canvas = document.createElement("canvas");
        canvas.width = 32; canvas.height = 32;
        const ctx = canvas.getContext("2d", { willReadFrequently: true })!;
        ctx.drawImage(img, 0, 0, 32, 32);
        const px = ctx.getImageData(0, 0, 32, 32).data;
        const fac = new FastAverageColor();
        const dom = fac.getColorFromArray4(px, { algorithm: "dominant" });
        fac.destroy();
        resolve({ a: deriveAccents(rgbToHex(dom[0], dom[1], dom[2])), ...luminanceStats(px) });
      } catch (e) { reject(e); }
    };
    img.onerror = () => reject(new Error(`cover failed to load: ${url}`));
    img.src = url;
  });
}

/** The server palette when present, else (the offline fallback) a 32 x 32 decode of the cover; cached per URL for the session. */
export function coverPalette(item: { palette?: CoverPalette | null; coverUrl?: string | null }): Promise<CoverPalette> {
  if (item.palette) return Promise.resolve(item.palette);
  const url = item.coverUrl;
  if (!url) return Promise.reject(new Error("coverPalette: no palette and no cover"));
  let p = cache.get(url);
  if (!p) { p = decode(url); cache.set(url, p); p.catch(() => cache.delete(url)); }
  return p;
}
