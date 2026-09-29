import { beforeEach, describe, expect, it, vi } from "vitest";

const run = vi.fn(async (_p: string, task: () => Promise<unknown>) => task());
vi.mock("./standins/request-limiter", () => ({ sourcesLimiter: { run: (p: string, t: () => Promise<unknown>) => run(p, t) } }));
vi.mock("./api", () => ({
  sourcesApi: {
    genres: vi.fn(async () => []),
    browseModes: vi.fn(async () => [{ id: "popular", label: "Popular" }]),
    listSeries: vi.fn(async () => ({ items: [{ id: "x" }] })),
  },
}));

import { fetchGenreCover, fetchPopularPage, fetchSourceGenres, PRIORITY } from "./discover-requests";

beforeEach(() => {
  run.mockClear();
});

describe("limiter priorities", () => {
  it("issues genre cover lookups as P3", async () => {
    await fetchGenreCover("a", "Action");
    expect(run.mock.calls[0][0]).toBe("P3");
  });
  it("issues genre lists and popular pages as P3", async () => {
    await fetchSourceGenres("a");
    await fetchPopularPage("a");
    expect(run.mock.calls.map((c) => c[0])).toEqual(["P3", "P3"]);
  });
  it("assigns dialogue stills P3 and search P1", () => {
    expect(PRIORITY.dialogueStill).toBe("P3");
    expect(PRIORITY.search).toBe("P1");
    expect(PRIORITY.cover).toBe("P2");
  });
});
