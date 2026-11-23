import { afterEach, describe, expect, it, vi } from "vitest";
import { readerApi } from "@/features/reader/api";
import { http } from "./http";

function stubFetch() {
  const fetchMock = vi.fn(async () => new Response("{}", { status: 200 }));
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("keepalive", () => {
  it("is passed through to fetch when a request asks for it", async () => {
    const fetchMock = stubFetch();
    await http.post("/x", { a: 1 }, { keepalive: true });
    const init = (fetchMock.mock.calls[0] as unknown as [string, RequestInit])[1];
    expect(init.keepalive).toBe(true);
    expect(init.credentials).toBe("include");
  });

  it("is not set on an ordinary request", async () => {
    const fetchMock = stubFetch();
    await http.get("/x");
    const init = (fetchMock.mock.calls[0] as unknown as [string, RequestInit])[1];
    expect(init.keepalive).toBeUndefined();
  });

  it("is set on the reader's progress save, which is flushed as the page unloads", async () => {
    const fetchMock = stubFetch();
    await readerApi.saveProgress(
      { sourceId: "s", seriesKey: "k", chapterKey: "c" },
      { page_number: 3 } as never,
    );
    const [url, init] = fetchMock.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toContain("/reader/progress");
    expect(init.keepalive).toBe(true);
    expect(init.credentials).toBe("include");
  });
});
