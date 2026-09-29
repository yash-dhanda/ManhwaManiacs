export interface PageBox {
  x: number;
  y: number;
  w: number;
  h: number;
}

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/**
 * CSS for a 16:9 still cut from a page (`object-fit: cover`, width 100%).
 * `pageAspect` = page width / height. The box fills 60% of the still's width,
 * centred on the box, never leaving the page. Null box = top 16:9 of the page.
 * `objectPosition` is a percentage pair; `scale` is >= 1 (transform-origin = objectPosition).
 */
export function stillCrop(box: PageBox | null, pageAspect: number): { objectPosition: string; scale: number } {
  if (!box || !(box.w > 0) || !(pageAspect > 0)) return { objectPosition: "50% 0%", scale: 1 };
  // With cover at width 100%, the still shows the page's full width, so box.w of the page = box.w of the still.
  const scale = Math.max(1, 0.6 / box.w);
  const cx = box.x + box.w / 2;
  const cy = box.y + box.h / 2;
  // Visible window (page fractions) at this scale: 1/scale wide, and (16/9 / pageAspect)/scale tall.
  const winW = 1 / scale;
  const winH = Math.min(1, 16 / 9 / pageAspect) / scale;
  const left = clamp(cx - winW / 2, 0, 1 - winW);
  const top = clamp(cy - winH / 2, 0, 1 - winH);
  const px = winW >= 1 ? 50 : (left / (1 - winW)) * 100;
  const py = winH >= 1 ? 0 : (top / (1 - winH)) * 100;
  return { objectPosition: `${round(px)}% ${round(py)}%`, scale: round(scale) };
}

const round = (n: number) => Math.round(n * 100) / 100;
