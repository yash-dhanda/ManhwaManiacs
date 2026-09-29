// TODO(web/03): stand-in for features/sources/cover-transition-name.ts (fnv1a32). Delete when web/03 lands and re-point source-wash.ts.
export function fnv1a32(text: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return hash >>> 0;
}
