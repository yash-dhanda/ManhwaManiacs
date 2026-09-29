import { dim as dimTokens, glass } from "../tokens.generated";

export type Tier = "t1" | "t2" | "t3" | "t4" | "t5";
export const TIERS: readonly Tier[] = ["t1", "t2", "t3", "t4", "t5"];

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/**
 * Tier for a free-size surface by its shorter side (glass.snap [36, 57, 97], DESIGN 2.4.3).
 * T5 is never reached by size: only the Massive objects (2.4.1) declare it, via an explicit tier.
 */
export function tierFor(shorterSide: number): Exclude<Tier, "t5"> {
  const [s2, s3, s4] = glass.snap;
  if (shorterSide < s2) return "t1";
  if (shorterSide < s3) return "t2";
  if (shorterSide < s4) return "t3";
  return "t4";
}

/** The adaptive legibility dim (DESIGN 2.1.7, 4.11): clamp(0.22 + 0.42 x Lb, 0.22, 0.64); Increase Contrast 0.40 to 0.72. */
export function dimFor(lb: number, highContrast = false): number {
  const { min, slope, max, minHc, maxHc } = dimTokens.legibility;
  const lo = highContrast ? minHc : min;
  const hi = highContrast ? maxHc : max;
  return clamp(min + slope * lb, lo, hi);
}

/** Label GRAD follows Lb (3.5); the web has no Bold Text signal. */
export const gradFor = (lb: number) => Math.round(dimTokens.grad.slope * lb);

/** ROND follows the tier: 20 x n (3.5). */
export const rondFor = (tier: Tier) => glass[tier].rond;

/** Every numeric parameter of a tier, so growing glass can interpolate them (2.4.2 rule 2). */
export interface TierParams {
  thickness: number;
  bezel: number;
  displacement: number;
  blur: number;
  saturate: number;
  fillR: number;
  fillG: number;
  fillB: number;
  fillA: number;
  specular: number;
  shadowY: number;
  shadowBlur: number;
  shadowA: number;
  dispersion: number;
  rond: number;
}

const NUM = /-?\d*\.?\d+/g;

function parseTier(t: Tier): TierParams {
  const g = glass[t];
  const [r, gg, b, a] = g.fill.match(NUM)!.map(Number);
  // shadow: "0 6px 20px rgba(0,0,0,0.45)": [x, y, blur, r, g, b, a]
  const sh = g.shadow.match(NUM)!.map(Number);
  return {
    thickness: g.thickness,
    bezel: g.bezel,
    displacement: g.displacement,
    blur: g.blur,
    saturate: g.saturate,
    fillR: r,
    fillG: gg,
    fillB: b,
    fillA: a,
    specular: g.specular,
    shadowY: sh[1],
    shadowBlur: sh[2],
    shadowA: sh[6],
    dispersion: g.dispersion,
    rond: g.rond,
  };
}

const PARAMS = Object.fromEntries(TIERS.map((t) => [t, parseTier(t)])) as Record<Tier, TierParams>;

export const tierParams = (t: Tier): TierParams => PARAMS[t];

/** Linear interpolation of every numeric tier parameter. */
export function lerpTier(a: TierParams, b: TierParams, t: number): TierParams {
  const out = {} as Record<string, number>;
  for (const k of Object.keys(a) as (keyof TierParams)[]) out[k] = a[k] + (b[k] - a[k]) * t;
  return out as unknown as TierParams;
}

/** Parameters at a continuous tier value 1..5 (the `tierValue` of a growing surface). */
export function tierAt(value: number): TierParams {
  const v = clamp(value, 1, 5);
  const lo = Math.min(4, Math.floor(v));
  return lerpTier(PARAMS[TIERS[lo - 1]], PARAMS[TIERS[lo]], v - lo);
}
