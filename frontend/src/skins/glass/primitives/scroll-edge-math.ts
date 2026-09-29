/** Scroll edge opacity (glass 7.32): top clamp(scrollTop / 24), bottom clamp(remaining / 24). */
const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
export const topEdgeOpacity = (scrollTop: number) => clamp01(scrollTop / 24);
export const bottomEdgeOpacity = (scrollHeight: number, scrollTop: number, clientHeight: number) => clamp01((scrollHeight - scrollTop - clientHeight) / 24);
/** Fast scroll: the strip's fraction to a row index, and a `select` tick per 10 rows. */
export const indexAt = (frac: number, count: number) => Math.min(count - 1, Math.max(0, Math.round(frac * (count - 1))));
export const tickBetween = (a: number, b: number) => Math.floor(a / 10) !== Math.floor(b / 10);
export const FAST_SCROLL_MIN_ROWS = 200;
