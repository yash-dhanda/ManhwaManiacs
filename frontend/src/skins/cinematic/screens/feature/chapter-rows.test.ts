import { expect, it } from "vitest";
import { buildRows, sortChapters } from "./chapter-rows";
import type { SourceChapterSummary } from "@/features/sources/types";

const ch = (id: string, number: number | null, title = ""): SourceChapterSummary => ({
  id,
  source_id: "s",
  series_id: "x",
  title,
  number,
  page_count: 10,
  release_date: null,
});

it("sorts with unnumbered chapters last in both directions", () => {
  const rows = [ch("a", 2), ch("n", null), ch("b", 1), ch("c", 3)];
  expect(sortChapters(rows, "newest").map((r) => r.id)).toEqual(["c", "a", "b", "n"]);
  expect(sortChapters(rows, "oldest").map((r) => r.id)).toEqual(["b", "a", "c", "n"]);
});

it("de-duplicates the title and carries progress", () => {
  const [r] = buildRows([ch("a", 12, "Chapter 12")], { a: { page: 4, pageCount: 10, completed: false, updatedAt: "" } });
  expect(r.ordinal).toBe("12");
  expect(r.title).toBeNull();
  expect(r.inProgress).toBe(true);
});
