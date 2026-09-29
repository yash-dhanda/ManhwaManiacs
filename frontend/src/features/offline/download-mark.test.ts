import { expect, it } from "vitest";
import { downloadMarkLabel, downloadMarkState } from "./download-mark";
import type { SavedChapterEntry } from "./types";

const e = (o: Partial<SavedChapterEntry>) =>
  ({ status: "ready", pageCount: 10, savedPages: 10, failed: 0, stale: false, ...o }) as SavedChapterEntry;

it("maps every state", () => {
  expect(downloadMarkState(null).kind).toBe("none");
  expect(downloadMarkState(null, true).kind).toBe("queued");
  expect(downloadMarkState(e({ status: "saving", savedPages: 3 }))).toEqual({ kind: "downloading", progress: 0.3 });
  expect(downloadMarkState(e({})).kind).toBe("saved");
  expect(downloadMarkState(e({ status: "partial", savedPages: 5, failed: 5 })).kind).toBe("failed");
  expect(downloadMarkState(e({ status: "paused" })).kind).toBe("paused");
  expect(downloadMarkState(e({ stale: true })).kind).toBe("stale");
});

it("words the marks", () => {
  expect(downloadMarkLabel({ kind: "downloading", progress: 0.3 })).toBe("Downloading, 30 percent");
  expect(downloadMarkLabel({ kind: "failed" })).toBe("Failed, tap to retry");
  expect(downloadMarkLabel({ kind: "none" })).toBe("Download");
});
