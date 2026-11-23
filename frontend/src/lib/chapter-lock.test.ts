import { describe, expect, it } from "vitest";
import { ApiError } from "@/types/api";
import {
  chapterLockFromBatchError,
  chapterLockFromError,
  formatCountdown,
  formatCountdownWords,
  formatOpensAt,
  formatOpensInCompact,
  isLocked,
  lockRemainingMs,
  opensInLabel,
} from "./chapter-lock";

const NOW = Date.parse("2026-11-23T10:48:00Z");
const H = 3_600_000;

describe("isLocked", () => {
  it("is locked while the instant is in the future", () => {
    expect(isLocked("2026-11-23T14:15:24Z", NOW)).toBe(true);
  });
  it("is open for null, absent, malformed and past values", () => {
    expect(isLocked(null, NOW)).toBe(false);
    expect(isLocked(undefined, NOW)).toBe(false);
    expect(isLocked("", NOW)).toBe(false);
    expect(isLocked("soon", NOW)).toBe(false);
    expect(isLocked("2026-11-23T10:00:00Z", NOW)).toBe(false);
  });
  it("is open exactly at the instant", () => {
    expect(isLocked("2026-11-23T10:48:00Z", NOW)).toBe(false);
  });
  it("reads an offset-less value as UTC", () => {
    expect(isLocked("2026-11-23T10:48:01", NOW)).toBe(true);
  });
});

describe("lockRemainingMs", () => {
  it("never goes negative and is 0 without a lock", () => {
    expect(lockRemainingMs("2026-11-23T14:15:24Z", NOW)).toBe(3 * H + 27 * 60_000 + 24_000);
    expect(lockRemainingMs("2026-11-23T09:00:00Z", NOW)).toBe(0);
    expect(lockRemainingMs(null, NOW)).toBe(0);
  });
});

describe("formatCountdown", () => {
  it("shows h:mm:ss from an hour up", () => {
    expect(formatCountdown(3 * H + 27 * 60_000 + 14_000)).toBe("3:27:14");
    expect(formatCountdown(H)).toBe("1:00:00");
  });
  it("shows m:ss under an hour", () => {
    expect(formatCountdown(27 * 60_000 + 14_000)).toBe("27:14");
    expect(formatCountdown(5_000)).toBe("0:05");
  });
  it("rounds up so a locked chapter never reads 0:00", () => {
    expect(formatCountdown(400)).toBe("0:01");
    expect(formatCountdown(0)).toBe("0:00");
    expect(formatCountdown(-5)).toBe("0:00");
  });
});

describe("formatCountdownWords", () => {
  it("spells it out", () => {
    expect(formatCountdownWords(3 * H + 27 * 60_000 + 14_000)).toBe(
      "3 hours 27 minutes 14 seconds",
    );
    expect(formatCountdownWords(H + 60_000 + 1_000)).toBe("1 hour 1 minute 1 second");
    expect(formatCountdownWords(45_000)).toBe("45 seconds");
    expect(formatCountdownWords(H + 5_000)).toBe("1 hour 0 minutes 5 seconds");
  });
});

describe("formatOpensInCompact", () => {
  it("is minute-granular and rounds up", () => {
    expect(formatOpensInCompact(3 * H + 27 * 60_000 + 1_000)).toBe("3 h 28 min");
    expect(formatOpensInCompact(3 * H + 27 * 60_000)).toBe("3 h 27 min");
    expect(formatOpensInCompact(45 * 60_000)).toBe("45 min");
    expect(formatOpensInCompact(20_000)).toBe("1 min");
    expect(formatOpensInCompact(2 * H)).toBe("2 h");
    expect(formatOpensInCompact(27 * H)).toBe("1 d 3 h");
    expect(formatOpensInCompact(48 * H)).toBe("2 d");
  });
});

describe("formatOpensAt", () => {
  it("is null without a readable instant", () => {
    expect(formatOpensAt(null, NOW)).toBeNull();
    expect(formatOpensAt("nope", NOW)).toBeNull();
  });
  it("omits the day when it is today and adds it otherwise", () => {
    const at = new Date(NOW + 2 * H).toISOString();
    const sameDay = new Date(NOW).toDateString() === new Date(NOW + 2 * H).toDateString();
    const text = formatOpensAt(at, NOW) ?? "";
    expect(text).toMatch(/\d/);
    if (sameDay) expect(text).not.toContain(",");
    const nextWeek = formatOpensAt(new Date(NOW + 7 * 24 * H).toISOString(), NOW) ?? "";
    expect(nextWeek).toContain(",");
  });
});

describe("chapterLockFromError", () => {
  it("reads locked_until from the 423 envelope", () => {
    const error = new ApiError(423, {
      code: "chapter_locked",
      message: "Early access on AsuraScans.",
      details: { locked_until: "2026-11-23T14:15:24Z" },
    });
    expect(chapterLockFromError(error)).toEqual({
      lockedUntil: "2026-11-23T14:15:24Z",
      message: "Early access on AsuraScans.",
    });
  });
  it("keeps a null instant as a lock with no time", () => {
    const error = new ApiError(423, {
      code: "chapter_locked",
      message: "m",
      details: { locked_until: null },
    });
    expect(chapterLockFromError(error)?.lockedUntil).toBeNull();
    expect(
      chapterLockFromError(new ApiError(423, { code: "chapter_locked", message: "m" }))
        ?.lockedUntil,
    ).toBeNull();
  });
  it("ignores every other failure", () => {
    expect(chapterLockFromError(new ApiError(500, { code: "boom", message: "x" }))).toBeNull();
    expect(chapterLockFromError(new Error("x"))).toBeNull();
  });
});

describe("chapterLockFromBatchError", () => {
  it("maps a bulk item error", () => {
    expect(
      chapterLockFromBatchError({
        code: "chapter_locked",
        message: "m",
        locked_until: "2026-11-23T14:15:24Z",
      }),
    ).toEqual({ lockedUntil: "2026-11-23T14:15:24Z", message: "m" });
    expect(chapterLockFromBatchError({ code: "chapter_locked", message: "m" })?.lockedUntil).toBeNull();
    expect(chapterLockFromBatchError({ code: "other", message: "m" })).toBeNull();
    expect(chapterLockFromBatchError(null)).toBeNull();
  });
});

describe("opensInLabel", () => {
  it("says when a locked chapter opens, and nothing otherwise", () => {
    expect(opensInLabel("2026-11-23T14:15:24Z", NOW)).toBe("Opens in 3 h 28 min");
    expect(opensInLabel("2026-11-23T14:15:24Z", null)).toBeNull();
    expect(opensInLabel(null, NOW)).toBeNull();
    expect(opensInLabel(undefined, NOW)).toBeNull();
    expect(opensInLabel("2026-11-23T09:00:00Z", NOW)).toBeNull();
    expect(opensInLabel("garbage", NOW)).toBeNull();
  });
});
