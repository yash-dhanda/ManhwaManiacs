/** The Press start timeline of §12.4 as data. Times in ms from the hydration origin. */
export type SplashElement = "monogram" | "intersection" | "bloom" | "monogramOut" | "letters" | "rule" | "impression" | "handoff";
export type SplashStep = { element: SplashElement; startMs: number; endMs: number; easing: "settle" | "lift" | "turn" | "linear" };

const GRAPHEMES = 13, STAGGER = 24, LETTER_MS = 640, LETTERS_START = 252;
/** Last letter starts at 540 and lands at 1180. */
export const LAST_LETTER_START = LETTERS_START + (GRAPHEMES - 1) * STAGGER;
export const REVEAL_END = LAST_LETTER_START + LETTER_MS;
export const IMPRESSION_MS = 80;
export const HANDOFF_MS = 220;
export const CONNECTING_MS = 2400;

export const SPLASH_TIMELINE: readonly SplashStep[] = [
  { element: "monogram", startMs: 0, endMs: 100, easing: "linear" },
  { element: "intersection", startMs: 100, endMs: 420, easing: "settle" },
  { element: "bloom", startMs: 100, endMs: 420, easing: "settle" },
  { element: "monogramOut", startMs: 252, endMs: 572, easing: "lift" },
  { element: "letters", startMs: LETTERS_START, endMs: REVEAL_END, easing: "settle" },
  { element: "rule", startMs: 700, endMs: 1180, easing: "settle" },
  { element: "impression", startMs: REVEAL_END, endMs: REVEAL_END + IMPRESSION_MS, easing: "settle" },
  { element: "handoff", startMs: REVEAL_END, endMs: REVEAL_END + HANDOFF_MS, easing: "turn" },
];

/** The choreography always runs 0-1180; the hand-off starts at max(probeDone, 1180). Never stretched. */
export const handoffStart = (probeDoneMs: number | null) => (probeDoneMs === null ? null : Math.max(probeDoneMs, REVEAL_END));
/** The dial and `CONNECTING` caption appear at 2400 ms while the probe is still pending. */
export const showConnecting = (nowMs: number, probeDoneMs: number | null) => probeDoneMs === null && nowMs >= CONNECTING_MS;
export const stepFor = (el: SplashElement) => SPLASH_TIMELINE.find((s) => s.element === el)!;
