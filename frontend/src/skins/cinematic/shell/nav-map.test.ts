import { describe, expect, it } from "vitest";
import { isHeldRoute, resolveNav, thumbFor } from "./nav-map";

describe("resolveNav (§7.15 route table)", () => {
  it.each([
    ["/", "tonight", "No. 01 · TONIGHT"],
    ["/library", "library", "No. 02 · LIBRARY"],
    ["/library/browse", "library", "No. 02 · LIBRARY"],
    ["/updates", "updates", "No. 03 · UPDATES"],
    ["/search", "discover", "No. 04 · DISCOVER"],
    ["/sources", "discover", "No. 04 · DISCOVER"],
    ["/sources/mangadex", "discover", "No. 04 · DISCOVER"],
    ["/downloads", "downloads", "No. 05 · DOWNLOADS"],
    ["/library/collections", "collections", "No. 06 · COLLECTIONS"],
    ["/library/collections/7", "collections", "No. 06 · COLLECTIONS"],
    ["/library/history", "history", "No. 07 · HISTORY"],
    ["/library/bookmarks", "bookmarks", "No. 08 · BOOKMARKS"],
    ["/ocr", "dialogue", "No. 09 · DIALOGUE"],
    ["/library/statistics", "numbers", "No. 10 · THE NUMBERS"],
    ["/circle", "circle", "No. 11 · CIRCLE"],
    ["/circle/5", "circle", "No. 11 · CIRCLE"],
    ["/library/recommendations", "picks", "No. 12 · PICKS"],
    ["/profiles/manage", "profiles", "PROFILES"],
    ["/profiles/new", "profiles", "PROFILES"],
    ["/profiles/3/edit", "profiles", "PROFILES"],
    ["/settings", "settings", "SETTINGS"],
    ["/admin/status", "status", "STATUS"],
  ])("%s lights %s", (p, lit, crumb) => {
    const r = resolveNav(p);
    expect(r.lit).toBe(lit);
    expect(r.crumb).toBe(crumb);
  });
  it("/more lights nothing and reads INDEX", () => expect(resolveNav("/more")).toMatchObject({ lit: null, crumb: "INDEX" }));
  it("names static and dynamic tails", () => {
    expect(resolveNav("/sources").tail).toBe("SOURCES");
    expect(resolveNav("/sources/x").dynamicTail).toBe(true);
    expect(resolveNav("/library/collections/7").dynamicTail).toBe(true);
    expect(resolveNav("/settings/appearance").tail).toBe("APPEARANCE");
    expect(resolveNav("/settings/reading-manga").tail).toBe("READING: MANGA");
  });
  it("exact match only: collections never lights Library", () => expect(resolveNav("/library/collections").lit).not.toBe("library"));
  it("feature pages keep the held item, else cold-load rule", () => {
    expect(isHeldRoute("/sources/a/series/b")).toBe(true);
    expect(isHeldRoute("/library/12")).toBe(true);
    expect(isHeldRoute("/library/history")).toBe(false);
    expect(isHeldRoute("/recap/a/b")).toBe(true);
    expect(resolveNav("/sources/a/series/b", { held: "updates" }).lit).toBe("updates");
    expect(resolveNav("/library/12", { followed: true }).lit).toBe("library");
    expect(resolveNav("/sources/a/series/b", { followed: false }).lit).toBe("discover");
    expect(resolveNav("/sources/a/series/b").crumb).toBe("No. 04 · DISCOVER");
  });
});

describe("thumbFor (§8.0.3 branches)", () => {
  it.each([
    ["/", true, "tonight"], ["/library", true, "library"], ["/updates", true, "library"], ["/library/collections/3", true, "library"], ["/library/history", true, "library"],
    ["/search", true, "discover"], ["/sources", true, "discover"], ["/sources/x", true, "discover"], ["/ocr", true, "discover"], ["/library/recommendations", true, "discover"],
    ["/downloads", true, "downloads"],
    ["/more", true, "index"], ["/settings/appearance", true, "index"], ["/admin/status", true, "index"], ["/library/statistics", true, "index"], ["/circle", true, "index"], ["/profiles/manage", true, "index"],
    ["/sources/x/series/y", false, null], ["/library/9", false, null], ["/reader/a/b/c", false, null], ["/login", false, null], ["/profiles", false, null], ["/welcome", false, null], ["/library/statistics/annual/2026", false, null], ["/recap/a/b", false, null], ["/novels/a/b/c", false, null],
    ["/nope", true, null],
  ])("%s", (p, visible, active) => expect(thumbFor(p)).toEqual({ visible, active }));
});
