// Text as outlines via fontkit. Coordinates rounded to 2 dp.
import * as fontkit from "fontkit";

const r2 = (n) => Math.round(n * 100) / 100;
const cache = new Map();
function load(path, axes) {
  const key = path + JSON.stringify(axes);
  if (!cache.has(key)) cache.set(key, fontkit.openSync(path).getVariation(axes));
  return cache.get(key);
}
const fmt = (p) => p.toSVG().replace(/-?\d+\.\d+/g, (m) => String(r2(+m)));

export function textPath({ font, axes, text, size, x = 0, baseline = 0, tracking = 0 }) {
  const f = load(font, axes);
  const k = size / f.unitsPerEm;
  const run = f.layout(text);
  let pen = x;
  const glyphs = [];
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  run.glyphs.forEach((g, i) => {
    const pos = run.positions[i];
    const gx = pen + pos.xOffset * k;
    const gy = baseline - pos.yOffset * k;
    const path = g.path.scale(k, -k).translate(gx, gy);
    const bb = path.bbox;
    const d = fmt(path);
    if (d && isFinite(bb.minX)) {
      glyphs.push({ d, bbox: { x0: r2(bb.minX), y0: r2(bb.minY), x1: r2(bb.maxX), y1: r2(bb.maxY) } });
      minX = Math.min(minX, bb.minX); minY = Math.min(minY, bb.minY);
      maxX = Math.max(maxX, bb.maxX); maxY = Math.max(maxY, bb.maxY);
    }
    pen += pos.xAdvance * k + tracking * size;
  });
  return {
    d: glyphs.map((g) => g.d).join(""),
    advance: r2(pen - x),
    bbox: { x0: r2(minX), y0: r2(minY), x1: r2(maxX), y1: r2(maxY) },
    glyphs,
  };
}
