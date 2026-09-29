/** In-page tab strip maths (glass 7.13): the indicator reads the pager's continuous position. */
export interface TabBox { left: number; width: number }

/** The indicator's box at a continuous position `pos` (0 = first panel): its left and width lerp between the two labels, plus a velocity stretch up to 25 %. */
export function indicatorAt(boxes: readonly TabBox[], pos: number, speed = 0): TabBox {
  if (!boxes.length) return { left: 0, width: 0 };
  const p = Math.min(boxes.length - 1, Math.max(0, pos));
  const i = Math.floor(p), f = p - i;
  const a = boxes[i], b = boxes[Math.min(boxes.length - 1, i + 1)];
  const left = a.left + (b.left - a.left) * f;
  const width = a.width + (b.width - a.width) * f;
  const stretch = 1 + Math.min(0.25, Math.max(0, speed));
  return { left: left - (width * (stretch - 1)) / 2, width: width * stretch };
}

/** The next enabled tab from `from` in a direction, or `from` when none is enabled that way. */
export function nextTab(disabled: readonly boolean[], from: number, dir: 1 | -1, wrap = false): number {
  const n = disabled.length;
  for (let k = 1; k <= n; k++) {
    let i = from + dir * k;
    if (i < 0 || i >= n) { if (!wrap) return from; i = (i + n) % n; }
    if (!disabled[i]) return i;
  }
  return from;
}
