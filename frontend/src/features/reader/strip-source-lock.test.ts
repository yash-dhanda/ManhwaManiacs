import type { QueryClient } from "@tanstack/react-query";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "@/types/api";
import { readerApi } from "./api";
import { bulkChapterSource, linkedChapterSource } from "./strip-source";

vi.mock("./api", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./api")>();
  return {
    ...actual,
    readerApi: { manifest: vi.fn(), manifestBatch: vi.fn() },
  };
});

const store = new Map<string, unknown>();
const queryClient = {
  getQueryData: (key: unknown) => store.get(JSON.stringify(key)),
  setQueryData: (key: unknown, value: unknown) => store.set(JSON.stringify(key), value),
  ensureQueryData: async ({ queryFn }: { queryFn: () => Promise<unknown> }) =>
    queryFn(),
} as unknown as QueryClient;

beforeEach(() => {
  store.clear();
  vi.mocked(readerApi.manifest).mockReset();
  vi.mocked(readerApi.manifestBatch).mockReset();
});

describe("a locked chapter in the strip", () => {
  it("carries the lock from a 423 on the plain reader's fetch", async () => {
    vi.mocked(readerApi.manifest).mockRejectedValue(
      new ApiError(423, {
        code: "chapter_locked",
        message: "Early access.",
        details: { locked_until: "2026-11-23T14:15:24Z" },
      }),
    );
    const result = await linkedChapterSource(queryClient, "asurascans", "nano").fetch(["c1"]);
    expect(result.chapters).toEqual([]);
    expect(result.error).toBe("Early access.");
    expect(result.lock).toEqual({
      lockedUntil: "2026-11-23T14:15:24Z",
      message: "Early access.",
    });
  });

  it("has no lock for an ordinary failure", async () => {
    vi.mocked(readerApi.manifest).mockRejectedValue(new ApiError(500, { code: "x", message: "boom" }));
    const result = await linkedChapterSource(queryClient, "a", "s").fetch(["c1"]);
    expect(result.lock ?? null).toBeNull();
  });

  it("carries the lock from a bulk window item", async () => {
    vi.mocked(readerApi.manifestBatch).mockResolvedValue({
      source_id: "a",
      series_key: "s",
      max_chapters: 20,
      requested: 1,
      ok_count: 0,
      failed_count: 1,
      items: [
        {
          chapter_key: "c1",
          status: "error",
          manifest: null,
          error: {
            code: "chapter_locked",
            status: 423,
            message: "Early access.",
            locked_until: "2026-11-23T14:15:24Z",
          },
        },
      ],
    });
    const source = bulkChapterSource(queryClient, "a", "s", [{ chapterKey: "c1", number: 1 }] as never);
    const result = await source.fetch(["c1"]);
    expect(result.lock).toEqual({ lockedUntil: "2026-11-23T14:15:24Z", message: "Early access." });
  });
});
