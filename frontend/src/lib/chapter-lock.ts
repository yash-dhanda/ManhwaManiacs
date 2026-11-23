import { parseUtcTimestamp } from "@/lib/utc-time";
import { ApiError } from "@/types/api";

/**
 * Early access: a source (AsuraScans) lists a chapter for everyone hours before
 * it opens to everyone, and the backend answers an attempt to read it with
 * HTTP 423 `chapter_locked`. Every chapter list and every update notification
 * carries the instant it opens as `locked_until`.
 *
 * The INSTANT decides, never a flag: a cached row that said "locked" last night
 * stops saying so by itself once the clock passes it, with no refetch. Anything
 * the backend sends that is not a readable future instant (null, absent, junk,
 * past) means "open" — a data problem must never lock a chapter out of reach.
 */

/** The error code the reader endpoints answer a locked chapter with. */
export const CHAPTER_LOCKED_CODE = "chapter_locked";

/**
 * A lock the reader hit: the server's own sentence, and when it opens if the
 * source said (`null` when it did not).
 */
export interface ChapterLock {
  lockedUntil: string | null;
  message: string;
}

/** The instant a chapter opens, in epoch ms, or `null` when there is none. */
export function lockedUntilMs(value: string | null | undefined): number | null {
  return parseUtcTimestamp(value);
}

/** Whether a chapter is still closed at `nowMs`. Past, absent and malformed are open. */
export function isLocked(value: string | null | undefined, nowMs: number): boolean {
  const at = lockedUntilMs(value);
  return at !== null && at > nowMs;
}

/** Milliseconds until the chapter opens; 0 once it has, or when there is no lock. */
export function lockRemainingMs(value: string | null | undefined, nowMs: number): number {
  const at = lockedUntilMs(value);
  return at === null ? 0 : Math.max(0, at - nowMs);
}

/** Whole seconds, rounded UP so the readout never shows 0:00 while still locked. */
function wholeSeconds(remainingMs: number): number {
  return Math.max(0, Math.ceil(remainingMs / 1000));
}

/** `3:27:14` from an hour up, `27:14` under one. */
export function formatCountdown(remainingMs: number): string {
  const total = wholeSeconds(remainingMs);
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  const ss = String(seconds).padStart(2, "0");
  if (hours > 0) return `${hours}:${String(minutes).padStart(2, "0")}:${ss}`;
  return `${minutes}:${ss}`;
}

function plural(count: number, unit: string): string {
  return `${count} ${unit}${count === 1 ? "" : "s"}`;
}

/** The same remaining time in words, for a screen reader: `3 hours 27 minutes 14 seconds`. */
export function formatCountdownWords(remainingMs: number): string {
  const total = wholeSeconds(remainingMs);
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  const parts: string[] = [];
  if (hours > 0) parts.push(plural(hours, "hour"));
  if (hours > 0 || minutes > 0) parts.push(plural(minutes, "minute"));
  parts.push(plural(seconds, "second"));
  return parts.join(" ");
}

/**
 * Compact minute-granularity remaining time for a list row: `3 h 27 min`,
 * `45 min`, `2 d 3 h`. Rounded up, so a chapter opening in 20 seconds says
 * `1 min` rather than a "0 min" that reads as already open.
 */
export function formatOpensInCompact(remainingMs: number): string {
  const totalMinutes = Math.max(1, Math.ceil(remainingMs / 60_000));
  const days = Math.floor(totalMinutes / 1440);
  const hours = Math.floor((totalMinutes % 1440) / 60);
  const minutes = totalMinutes % 60;
  if (days > 0) return hours > 0 ? `${days} d ${hours} h` : `${days} d`;
  if (hours > 0) return minutes > 0 ? `${hours} h ${minutes} min` : `${hours} h`;
  return `${minutes} min`;
}

/**
 * When the chapter opens, on the viewer's own clock: `7:45 PM`, or with the day
 * (`Mon, Nov 24, 7:45 PM`) when that is not today. `null` when there is no
 * readable instant.
 */
export function formatOpensAt(
  value: string | null | undefined,
  nowMs: number,
): string | null {
  const at = lockedUntilMs(value);
  if (at === null) return null;
  const date = new Date(at);
  const today = new Date(nowMs);
  const sameDay =
    date.getFullYear() === today.getFullYear() &&
    date.getMonth() === today.getMonth() &&
    date.getDate() === today.getDate();
  const time = date.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
  if (sameDay) return time;
  return `${date.toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
  })}, ${time}`;
}

/**
 * The lock behind a failed reader request, or `null` when it failed for any
 * other reason. `details.locked_until` may be null (the source did not say).
 */
export function chapterLockFromError(cause: unknown): ChapterLock | null {
  if (!(cause instanceof ApiError) || cause.code !== CHAPTER_LOCKED_CODE) return null;
  const details = cause.details;
  const raw =
    details !== null && typeof details === "object"
      ? (details as { locked_until?: unknown }).locked_until
      : null;
  return {
    lockedUntil: typeof raw === "string" && raw !== "" ? raw : null,
    message: cause.message,
  };
}

/** The lock in one bulk-manifest error item, or `null` for any other failure. */
export function chapterLockFromBatchError(
  error: { code: string; message: string; locked_until?: string | null } | null | undefined,
): ChapterLock | null {
  if (!error || error.code !== CHAPTER_LOCKED_CODE) return null;
  return { lockedUntil: error.locked_until || null, message: error.message };
}

/**
 * What a chapter row says where its date goes while the chapter is in early
 * access: `Opens in 3 h 27 min`. `null` when the chapter is open, and while the
 * clock is not known yet (first paint), so the row renders as it did before.
 */
export function opensInLabel(
  lockedUntil: string | null | undefined,
  nowMs: number | null,
): string | null {
  if (nowMs === null || !isLocked(lockedUntil, nowMs)) return null;
  return `Opens in ${formatOpensInCompact(lockRemainingMs(lockedUntil, nowMs))}`;
}
