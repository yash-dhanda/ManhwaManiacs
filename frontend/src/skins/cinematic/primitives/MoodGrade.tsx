import { color } from "../tokens.generated";

export const MOOD_GRADES = { romantic: color.moodRomantic, action: color.moodAction, comedy: color.moodComedy, horror: color.moodHorror, slice_of_life: color.moodSliceOfLife, fantasy: color.moodFantasy } as const;
export type Mood = keyof typeof MOOD_GRADES;

/** §2.1.6: a 30 vh gradient from the profile's grade colour to #000000 behind the top of the page. Default: none. */
export function MoodGrade({ mood }: { mood?: Mood | null }) {
  if (!mood || !(mood in MOOD_GRADES)) return null;
  return <div aria-hidden className="pointer-events-none absolute inset-x-0 top-0" style={{ height: "30vh", background: `linear-gradient(to bottom, ${MOOD_GRADES[mood]}, #000000)` }} />;
}

/** `data-stock="raised"` applies while a grade is present (ink.45 remaps to ink.60). */
export const gradeStock = (mood?: Mood | null) => (mood && mood in MOOD_GRADES ? "raised" : undefined);
