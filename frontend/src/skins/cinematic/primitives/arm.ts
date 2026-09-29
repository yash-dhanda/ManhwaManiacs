/** The destructive arm (§7.10): a committing action is disabled for `ms` from `startedAt`; heavy confirms also need their condition. */
export const ARM_MS = 1000;

export type ArmState = { startedAt: number | null; ms: number };
export const armStart = (now: number, ms = ARM_MS): ArmState => ({ startedAt: now, ms });
export const armIdle = (ms = ARM_MS): ArmState => ({ startedAt: null, ms });
/** True once the arm has fully elapsed (>= ms). At 999 ms it is still arming. */
export const isArmed = (s: ArmState, now: number): boolean => s.startedAt !== null && now - s.startedAt >= s.ms;
export const armElapsed = (s: ArmState, now: number): number => (s.startedAt === null ? 0 : Math.min(s.ms, Math.max(0, now - s.startedAt)));
/** Can the committing action fire? Needs the arm and, for heavy confirms, the extra condition. */
export const canCommit = (s: ArmState, now: number, conditionMet = true): boolean => isArmed(s, now) && conditionMet;
/** Typed-phrase check: case-insensitive, trimmed. */
export const phraseMatches = (typed: string, phrase: string): boolean => typed.trim().toLowerCase() === phrase.trim().toLowerCase();
