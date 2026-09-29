// WCAG 2.x relative luminance, contrast ratio and plain alpha-over compositing in sRGB floats
// (glass/DESIGN.md §15.8; no 8-bit rounding anywhere).

// "#RRGGBB" or "rgba(r,g,b,a)" → [r, g, b, a] with channels in 0..1.
export function parseColor(c) {
  const h = /^#([0-9a-f]{6})$/i.exec(c);
  if (h) return [...h[1].match(/../g).map((x) => parseInt(x, 16) / 255), 1];
  const m = /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$/.exec(c);
  if (!m) throw new Error(`not a colour: ${c}`);
  return [Number(m[1]) / 255, Number(m[2]) / 255, Number(m[3]) / 255, m[4] === undefined ? 1 : Number(m[4])];
}

// out = a × src + (1 − a) × dst; dst is opaque [r, g, b].
export const over = ([r, g, b, a], dst) => [r, g, b].map((c, i) => a * c + (1 - a) * dst[i]);

const lin = (c) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
export const luminance = ([r, g, b]) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);

export function ratio(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

// Linear interpolation from one colour to another in sRGB (alpha included).
export const mix = (a, b, t) => a.map((x, i) => x + (b[i] - x) * t);
