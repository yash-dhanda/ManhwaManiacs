/** One segmenter for the whole skin (cinematic §10.1.5). */
const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });

export const graphemes = (s: string): string[] => Array.from(seg.segment(s), (x) => x.segment);

/** Graphemes excluding spaces: the `n` of the letter stagger, the same count as Flutter. */
export const graphemeCount = (s: string): number => graphemes(s.replaceAll(" ", "")).length;
