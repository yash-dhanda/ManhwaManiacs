import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { WorldTitleCard } from "./components/WorldTitleCard";
import type { WorldItem } from "./types";
import {
  worldAvailabilityLabel,
  worldBadgeLine,
  worldChaptersLabel,
  worldPlatformLink,
  worldRatingLabel,
  worldSearchHref,
  worldSeriesHref,
} from "./world-card";

const asura = {
  source_id: "asurascans",
  source_name: "Asura Scans",
  series_key: "nano-machine-6f7fe6eb",
};
const flame = { source_id: "flamecomics", source_name: "Flame Comics", series_key: "nano/1" };

describe("where the card goes", () => {
  it("opens the first carrying source's series page", () => {
    expect(worldSeriesHref({ available: [asura, flame] })).toBe(
      "/sources/asurascans/series/nano-machine-6f7fe6eb",
    );
  });

  it("encodes the series key as one path segment", () => {
    expect(worldSeriesHref({ available: [flame] })).toBe(
      "/sources/flamecomics/series/nano%2F1",
    );
  });

  it("goes nowhere when no source carries it", () => {
    expect(worldSeriesHref({ available: [] })).toBeNull();
  });

  it("searches for the title, encoded", () => {
    expect(worldSearchHref("Solo Leveling: Ragnarok & more")).toBe(
      "/search?q=Solo%20Leveling%3A%20Ragnarok%20%26%20more",
    );
  });
});

describe("which sources carry it", () => {
  it("names a single source", () => {
    expect(worldAvailabilityLabel({ available: [asura] })).toBe("On: Asura Scans");
  });

  it("counts the rest", () => {
    expect(worldAvailabilityLabel({ available: [asura, flame, flame] })).toBe(
      "On: Asura Scans +2 more",
    );
  });

  it("says plainly when none does", () => {
    expect(worldAvailabilityLabel({ available: [] })).toBe("Not on your sources");
  });
});

describe("the numbers", () => {
  it("formats chapters and hides unknown", () => {
    expect(worldChaptersLabel(181)).toBe("181 ch");
    expect(worldChaptersLabel(null)).toBeNull();
  });

  it("formats rating to one decimal and hides unrated", () => {
    expect(worldRatingLabel(8.1)).toBe("★ 8.1");
    expect(worldRatingLabel(8)).toBe("★ 8.0");
    expect(worldRatingLabel(null)).toBeNull();
  });

  it("joins format and status, skipping the unknown half", () => {
    expect(worldBadgeLine({ format: "Manhwa", status: "Ongoing" })).toBe("Manhwa · Ongoing");
    expect(worldBadgeLine({ format: "Manga", status: null })).toBe("Manga");
    expect(worldBadgeLine({ format: null, status: null })).toBeNull();
  });
});

describe("the official platform", () => {
  it("links the first one", () => {
    expect(
      worldPlatformLink({
        platforms: [
          { site: "Webtoon", url: "https://www.webtoons.com/x" },
          { site: "Tapas", url: "https://tapas.io/x" },
        ],
      }),
    ).toEqual({ label: "Read on Webtoon", url: "https://www.webtoons.com/x" });
  });

  it("is absent when there is none", () => {
    expect(worldPlatformLink({ platforms: [] })).toBeNull();
  });

  it("never links a non-web URL", () => {
    // Third-party data landing in an href: a javascript: URL would run on click.
    expect(
      worldPlatformLink({ platforms: [{ site: "Evil", url: "javascript:alert(1)" }] }),
    ).toBeNull();
  });
});

describe("the card, rendered", () => {
  function item(overrides: Partial<WorldItem> = {}): WorldItem {
    return {
      anilist_id: 105398,
      title: "Nano Machine",
      alt_titles: [],
      format: "Manhwa",
      country: "KR",
      status: "Ongoing",
      chapters: 181,
      rating: 8.1,
      genres: ["Action", "Martial Arts", "Sci-Fi", "Drama"],
      cover_url: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx1.jpg",
      is_adult: false,
      platforms: [{ site: "Webtoon", url: "https://www.webtoons.com/x" }],
      anilist_url: "https://anilist.co/manga/105398",
      available: [asura],
      why: null,
      ...overrides,
    };
  }

  const render = (value: WorldItem) =>
    renderToStaticMarkup(createElement(WorldTitleCard, { item: value }));

  it("opens the series when a source carries it, and offers no search", () => {
    const html = render(item());
    expect(html).toContain('href="/sources/asurascans/series/nano-machine-6f7fe6eb"');
    expect(html).toContain("On: Asura Scans");
    expect(html).not.toContain("/search?q=");
    expect(html).toContain("Manhwa · Ongoing");
    expect(html).toContain("181 ch · ★ 8.1");
    expect(html).not.toContain("Drama"); // three genres at most
  });

  it("offers search and the platform, and no series link, when none does", () => {
    const html = render(item({ available: [], why: "Same murim revenge arc." }));
    expect(html).not.toContain("/sources/");
    expect(html).toContain("Not on your sources");
    expect(html).toContain('href="/search?q=Nano%20Machine"');
    expect(html).toMatch(
      /href="https:\/\/www\.webtoons\.com\/x" target="_blank" rel="noopener noreferrer"/,
    );
    expect(html).toContain("Read on Webtoon");
    expect(html).toContain("Same murim revenge arc.");
  });

  it("loads the external cover lazily with no referrer, and never blurs", () => {
    const html = render(item());
    expect(html).toMatch(/referrerPolicy="no-referrer"/i);
    expect(html).toContain('loading="lazy"');
    expect(html).toContain("glass-flat");
    expect(html).not.toContain("backdrop-blur");
  });
});
