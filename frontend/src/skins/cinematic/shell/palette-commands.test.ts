import { describe, expect, it } from "vitest";
import { groupCommands, rankCommands } from "@/lib/command-palette";
import { buildPaletteCommands, continueTitle, type PaletteInput } from "./palette-commands";

const base: PaletteInput = { series: [{ id: 1, title: "Solo Leveling", chapterCount: 200, sourceId: "x" }], sources: [{ id: "bato", name: "Bato" }], isAdmin: false, novelsEnabled: false, novelMode: false, glassAvailable: false };

describe("palette commands", () => {
  const groups = (i: PaletteInput, q = "") => groupCommands(rankCommands(buildPaletteCommands(i).commands, q)).map((g) => g.group);
  it("orders groups Library, Sources, Go to, Actions, Settings and has no Edition while Glass is unavailable", () => {
    expect(groups(base)).toEqual(["Library", "Sources", "Go to", "Actions", "Settings"]);
  });
  it("admins get Status and Admin; others do not", () => {
    const titles = (i: PaletteInput) => buildPaletteCommands(i).commands.map((c) => c.title);
    expect(titles(base)).not.toContain("Status");
    expect(titles({ ...base, isAdmin: true })).toEqual(expect.arrayContaining(["Status", "Admin"]));
  });
  it("hides Dialogue in novels mode and the reading-mode action without novels", () => {
    const t = (i: PaletteInput) => buildPaletteCommands(i).commands.map((c) => c.title);
    expect(t(base)).toContain("Dialogue");
    expect(t({ ...base, novelsEnabled: true, novelMode: true })).not.toContain("Dialogue");
    expect(t(base)).not.toContain("Switch to novels");
    expect(t({ ...base, novelsEnabled: true })).toContain("Switch to novels");
  });
  it("caps at 40 results and numbers the routes", () => {
    expect(rankCommands(buildPaletteCommands({ ...base, isAdmin: true, novelsEnabled: true }).commands, "").length).toBeLessThanOrEqual(40);
    expect(buildPaletteCommands(base).folios["route:/library/recommendations"]).toBe("12");
  });
  it("offers Continue only with a continue-reading row", () => {
    expect(buildPaletteCommands(base).commands.some((c) => c.id === "action:continue")).toBe(false);
    expect(buildPaletteCommands({ ...base, continue: { title: "Tower", href: "/reader/a/b/c" } }).commands.some((c) => c.title === "Continue Tower")).toBe(true);
  });
  it("names Continue by series title, not the key", () => {
    const c = { source_id: "s", series_key: "series/x" };
    expect(continueTitle({ ...c, title: "Tower" }, new Map())).toBe("Tower");
    expect(continueTitle(c, new Map([["s:series/x", "Joined"]]))).toBe("Joined");
    expect(continueTitle(c, new Map())).toBe("series/x");
  });
});
