/** 32-bit FNV-1a over the UTF-8 bytes of `text`. Synchronous (render-safe). */
export function fnv1a32(text: string): number {
  let h = 0x811c9dc5;
  for (const b of new TextEncoder().encode(text)) {
    h = Math.imul(h ^ b, 0x01000193) >>> 0;
  }
  return h >>> 0;
}

/** A valid `view-transition-name` shared by a cover and its detail hero. */
export function coverTransitionName(sourceId: string, seriesKey: string): string {
  return "cover-" + fnv1a32(sourceId + "\u0000" + seriesKey).toString(16).padStart(8, "0");
}
