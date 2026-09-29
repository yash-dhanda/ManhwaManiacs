import { contrastBetween, over, parseColor, type Rgb } from "@/lib/contrast";

/** Pure HLS colour maths for the page tint, page light and Issue stock (cinematic §2.1.5, §2.1.6). h in degrees, l and s in 0..1. */
const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));
const hex2 = (v: number) => Math.round(clamp(v, 0, 1) * 255).toString(16).padStart(2, "0");

export function hlsToHex(h: number, l: number, s: number): string {
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const hp = (((h % 360) + 360) % 360) / 60;
  const x = c * (1 - Math.abs((hp % 2) - 1));
  const [r1, g1, b1] = hp < 1 ? [c, x, 0] : hp < 2 ? [x, c, 0] : hp < 3 ? [0, c, x] : hp < 4 ? [0, x, c] : hp < 5 ? [x, 0, c] : [c, 0, x];
  const m = l - c / 2;
  return `#${hex2(r1 + m)}${hex2(g1 + m)}${hex2(b1 + m)}`.toUpperCase();
}

export function hexToHls(hex: string): { h: number; l: number; s: number } {
  const c = parseColor(hex) as Rgb;
  const [r, g, b] = [c.r / 255, c.g / 255, c.b / 255];
  const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
  const l = (max + min) / 2;
  const s = d === 0 ? 0 : d / (1 - Math.abs(2 * l - 1));
  let h = 0;
  if (d !== 0) h = max === r ? ((g - b) / d) % 6 : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
  return { h: (h * 60 + 360) % 360, l, s };
}

const BLACK = "#000000";
/** Raise L by `step` until the colour reaches `min` on `bg`. */
function lighten(h: number, l: number, s: number, bg: string, min: number, step: number): string {
  let out = hlsToHex(h, l, s);
  while (contrastBetween(out, bg) < min && l < 1) { l = Math.min(1, l + step); out = hlsToHex(h, l, s); }
  return out;
}

export const pageTint = (h: number, s: number) => hlsToHex(h, 0.06, Math.min(s, 0.35));
export const pageLight = (h: number, s: number) => lighten(h, 0.75, clamp(s, 0.35, 0.7), BLACK, 4.5, 0.02);

export type Ambient = { duo: string; tint: string; ink: string };
export function ambientRoles(h: number, s: number): Ambient {
  return {
    duo: hlsToHex(h, 0.62, clamp(s, 0.45, 0.9)),
    tint: hlsToHex(h, 0.06, Math.min(s, 0.35)),
    ink: lighten(h, 0.78, clamp(s, 0.35, 0.7), BLACK, 7, 0.03),
  };
}

// OKLab mix (Ottosson): only used for the 10 % Issue-ink nudge.
const lin = (v: number) => (v /= 255) <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
const gam = (v: number) => 255 * (v <= 0.0031308 ? 12.92 * v : 1.055 * v ** (1 / 2.4) - 0.055);
function toLab(hex: string) {
  const { r, g, b } = parseColor(hex) as Rgb;
  const [R, G, B] = [lin(r), lin(g), lin(b)];
  const l = Math.cbrt(0.4122214708 * R + 0.5363325363 * G + 0.0514459929 * B);
  const m = Math.cbrt(0.2119034982 * R + 0.6806995451 * G + 0.1073969566 * B);
  const s = Math.cbrt(0.0883024619 * R + 0.2817188376 * G + 0.6299787005 * B);
  return [0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s, 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s];
}
function fromLab([L, a, b]: number[]): string {
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3, m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3, s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
  const rgb = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s];
  return `#${rgb.map((v) => Math.round(clamp(gam(clamp(v, 0, 1)), 0, 255)).toString(16).padStart(2, "0")).join("")}`.toUpperCase();
}
export const mixOklab = (a: string, b: string, t: number) => { const A = toLab(a), B = toLab(b); return fromLab(A.map((v, i) => v + (B[i] - v) * t)); };

export const NITRATE = { page: "#000000", ink: "#D9D6D0", muted: "#8A877F" };
export const INK_100 = "#F3F0E8";

/** The Issue stock for a series' ambient: page = tint, ink >= 13:1, muted >= 5.5:1 on the page. No ambient -> Nitrate. */
export function issueStock(ambient?: Pick<Ambient, "tint" | "ink"> | null) {
  if (!ambient) return NITRATE;
  const page = ambient.tint;
  const mixed = mixOklab(INK_100, ambient.ink, 0.1);
  const mh = hexToHls(mixed);
  let ink = mixed;
  for (let l = mh.l; contrastBetween(ink, page) < 13 && l < 1; ) { l = Math.min(1, l + 0.01); ink = hlsToHex(mh.h, l, mh.s); }
  const ah = hexToHls(ambient.ink);
  let muted = ambient.ink;
  let l = ah.l;
  while (l > 0.01) {
    const next = hlsToHex(ah.h, l - 0.01, ah.s);
    if (contrastBetween(next, page) < 5.5) break;
    muted = next; l -= 0.01;
  }
  return { page, ink, muted };
}

export { over, parseColor };
