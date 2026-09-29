import { beforeEach, describe, expect, it } from "vitest";
import { findMatchPage, takeDialogueJump, writeDialogueJump } from "./dialogue-jump";

const store = new Map<string, string>();
beforeEach(() => {
  store.clear();
  (globalThis as unknown as { sessionStorage: Storage }).sessionStorage = {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
    removeItem: (k: string) => void store.delete(k),
  } as unknown as Storage;
});

const jump = { sourceId: "s", seriesKey: "k", chapterKey: "c", q: "hi", page: 3, box: null };

describe("dialogue jump", () => {
  it("is read once", () => {
    writeDialogueJump(jump);
    expect(takeDialogueJump("s", "k", "c")).toEqual(jump);
    expect(takeDialogueJump("s", "k", "c")).toBeNull();
  });
  it("ignores another chapter and keeps the entry", () => {
    writeDialogueJump(jump);
    expect(takeDialogueJump("s", "k", "other")).toBeNull();
    expect(takeDialogueJump("s", "k", "c")).toEqual(jump);
  });
});

describe("findMatchPage", () => {
  const pages = [{ page: 1, text: "Nothing here" }, { page: 2, text: "Él dijo: HÉROE llegó" }];
  it("needs every term, folds case and diacritics", () => {
    expect(findMatchPage(pages, "heroe el")).toBe(2);
    expect(findMatchPage(pages, "heroe nothing")).toBeNull();
  });
  it("is null for an empty query", () => {
    expect(findMatchPage(pages, "  ")).toBeNull();
  });
});
