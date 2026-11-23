import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ChapterLockedNotice, ChapterLockedTail } from "./ChapterLockedNotice";

const MESSAGE = "Early access on AsuraScans. This chapter opens to everyone at 14:15 UTC on 23 Nov.";

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(Date.parse("2026-11-23T10:48:00Z"));
});
afterEach(() => vi.useRealTimers());

const fallback = createElement("p", null, "FALLBACK");
const notice = (lockedUntil: string | null) =>
  renderToStaticMarkup(
    createElement(ChapterLockedNotice, {
      lock: { lockedUntil, message: MESSAGE },
      retry: () => {},
      seriesHref: "/sources/asurascans/series/nano",
      fallback,
    }),
  );

describe("ChapterLockedNotice", () => {
  it("shows the label, countdown, local time line and series link, with no retry", () => {
    const html = notice("2026-11-23T14:15:24Z");
    expect(html).toContain("Early access");
    expect(html).toContain("Opens in");
    expect(html).toContain("Opens to everyone at");
    expect(html).toContain('href="/sources/asurascans/series/nano"');
    expect(html).not.toContain("FALLBACK");
    expect(html).not.toMatch(/retry|try again/i);
  });

  it("falls back to the server message and retry when no time is known", () => {
    expect(notice(null)).toContain("FALLBACK");
  });

  it("falls back once the instant has passed", () => {
    expect(notice("2026-11-23T10:47:00Z")).toContain("FALLBACK");
  });

  it("falls back when there is no lock at all", () => {
    const html = renderToStaticMarkup(
      createElement(ChapterLockedNotice, {
        lock: null,
        retry: () => {},
        seriesHref: "/s",
        fallback,
      }),
    );
    expect(html).toContain("FALLBACK");
  });
});

describe("ChapterLockedTail", () => {
  const tail = (lockedUntil: string | null) =>
    renderToStaticMarkup(
      createElement(ChapterLockedTail, {
        lock: { lockedUntil, message: MESSAGE },
        label: "Ch 332",
        retry: () => {},
        fallback,
      }),
    );

  it("says when the next chapter opens", () => {
    const html = tail("2026-11-23T14:15:24Z");
    expect(html).toContain("Ch 332");
    expect(html).toContain("Opens in");
    expect(html).not.toContain("on its way");
    expect(html).not.toContain("FALLBACK");
  });

  it("shows the ordinary failure when the lock has no usable time", () => {
    expect(tail(null)).toContain("FALLBACK");
  });
});
