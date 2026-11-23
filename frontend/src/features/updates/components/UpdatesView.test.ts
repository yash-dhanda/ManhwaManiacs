import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { UpdateNotification } from "../types";
import { NotificationRow } from "./UpdatesView";

const base: UpdateNotification = {
  id: 1,
  followed_series_id: 3,
  source_id: "asurascans",
  series_key: "nano-machine",
  chapter_key: "nano-machine:331",
  chapter_title: "Chapter 331",
  chapter_number: 331,
  is_read: false,
  created_at: "2026-11-23T10:00:00Z",
};

function render(item: UpdateNotification): string {
  return renderToStaticMarkup(
    createElement(NotificationRow, {
      item,
      seriesTitle: "Nano Machine",
      onRead: () => {},
      busy: false,
      chapterHref: () => "/reader/asurascans/nano-machine/331",
    }),
  );
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(Date.parse("2026-11-23T10:48:00Z"));
});
afterEach(() => vi.useRealTimers());

describe("NotificationRow early access", () => {
  it("shows a status instead of the read link while locked", () => {
    const html = render({ ...base, locked_until: "2026-11-23T14:15:24Z" });
    expect(html).toContain("Opens in");
    expect(html).not.toContain("/reader/asurascans");
    expect(html).not.toContain(">Read<");
  });

  it("keeps Mark read available while locked", () => {
    expect(render({ ...base, locked_until: "2026-11-23T14:15:24Z" })).toContain("Mark read");
  });

  it.each([
    ["null", { locked_until: null }],
    ["absent", {}],
    ["past", { locked_until: "2026-11-23T09:00:00Z" }],
    ["malformed", { locked_until: "tomorrow-ish" }],
  ])("offers the read link when locked_until is %s", (_name, extra) => {
    const html = render({ ...base, ...extra });
    expect(html).toContain("/reader/asurascans/nano-machine/331");
    expect(html).toContain(">Read<");
    expect(html).not.toContain("Opens in");
  });
});
