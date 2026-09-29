// Cinematic monogram geometry (cinematic §12.2): upright and italic Bodoni Moda `M`
// at opsz 96 / wght 800, the italic overlapping the upright by 22 % of the upright's
// width on the same baseline, the pair scaled to 560 units wide (x 232–792) and centred
// on y 512 of the 1024 canvas. Returns path strings in 1024 coordinates (y down).
// shared/04 reads brand/cinematic/monogram.json, written from this by make-glyph-masters.mjs.
import * as fontkit from 'fontkit';
import { fileURLToPath } from 'node:url';

const font = (file) =>
  fontkit.openSync(fileURLToPath(new URL(`../fonts/${file}`, import.meta.url))).getVariation({ opsz: 96, wght: 800 });

const round = (d) => d.replace(/-?\d+\.?\d*(?:e-?\d+)?/g, (n) => String(Math.round(Number(n) * 100) / 100));

export function monogram() {
  const up = font('BodoniModa[opsz,wght].ttf').glyphsForString('M')[0];
  const it = font('BodoniModa-Italic[opsz,wght].ttf').glyphsForString('M')[0];
  const u = up.path.bbox;
  const i = it.path.bbox;
  const w = u.maxX - u.minX;
  const dx = u.maxX - 0.22 * w - i.minX; // italic minX sits at upright maxX − 22 % width
  const minX = u.minX;
  const maxX = i.maxX + dx;
  const minY = Math.min(u.minY, i.minY);
  const maxY = Math.max(u.maxY, i.maxY);
  const s = 560 / (maxX - minX);
  const cy = (minY + maxY) / 2;
  // font units (y up) → canvas (y down): x' = 232 + (x − minX)·s, y' = 512 − (y − cy)·s
  const place = (p, ox) => round(p.transform(s, 0, 0, -s, 232 + (ox - minX) * s, 512 + cy * s).toSVG());
  return {
    font: 'Bodoni Moda opsz 96 wght 800 (brand/fonts)',
    canvas: 1024,
    box: { x: [232, 792], y: [272, 752] },
    overlap: 0.22,
    scale: Math.round(s * 1e6) / 1e6,
    bbox: {
      x: [232, 792],
      y: [Math.round((512 - (maxY - cy) * s) * 100) / 100, Math.round((512 + (cy - minY) * s) * 100) / 100],
    },
    upright: place(up.path, 0),
    italic: place(it.path, dx),
  };
}
