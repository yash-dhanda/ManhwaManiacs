import { expect, it } from "vitest";
import { chaptersUpTo, manualRow, undoMarkRead, type MarkableChapter } from "./mark-read";

const c = (n: number | null, completed = false, pageCount = 10): MarkableChapter => ({
  chapterKey: `k${n}`,
  number: n,
  pageCount,
  completed,
});

it("chaptersUpTo takes numbered, not-yet-completed chapters at or below", () => {
  const rows = [c(1), c(2, true), c(3), c(null), c(4)];
  expect(chaptersUpTo(rows, 3).map((r) => r.chapterKey)).toEqual(["k1", "k3"]);
});

it("undoMarkRead keeps only keys that were not completed before", () => {
  expect(undoMarkRead(new Set(["a"]), ["a", "b", "c"])).toEqual(["b", "c"]);
});

it("manualRow is a manual completed row with at least one page", () => {
  const r = manualRow({ sourceId: "s", seriesKey: "x" }, c(5, false, 0));
  expect(r).toMatchObject({ last_page: 1, page_count: 1, is_completed: true, manual: true, chapter_number: 5 });
});
