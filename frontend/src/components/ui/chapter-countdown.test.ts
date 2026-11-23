import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { ChapterCountdown } from "./chapter-countdown";

describe("ChapterCountdown first paint", () => {
  it("renders no clock-dependent text on the server", () => {
    const html = renderToStaticMarkup(
      createElement(ChapterCountdown, { lockedUntil: "2099-01-01T00:00:00Z" }),
    );
    expect(html).toContain("Opens in");
    expect(html).toContain('data-countdown="pending"');
    expect(html).not.toMatch(/\d:\d\d/);
  });

  it("is identical for any two instants, so it cannot mismatch on hydration", () => {
    const a = renderToStaticMarkup(
      createElement(ChapterCountdown, { lockedUntil: "2099-01-01T00:00:00Z" }),
    );
    const b = renderToStaticMarkup(
      createElement(ChapterCountdown, { lockedUntil: "2099-06-01T00:00:00Z" }),
    );
    expect(a).toBe(b);
  });
});
