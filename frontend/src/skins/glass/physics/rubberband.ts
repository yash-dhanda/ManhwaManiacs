import { physics } from "../tokens.generated";

/** d x (1 - 1 / (x x c / d + 1)) (DESIGN 4.5): x raw overscroll, d the dimension. Reader chapter end uses physics.rubberBandChapterC. */
export const rubberband = (x: number, d: number, c: number = physics.rubberBandC) => d * (1 - 1 / ((x * c) / d + 1));
