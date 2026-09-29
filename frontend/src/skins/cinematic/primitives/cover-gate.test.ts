import { describe, expect, it, vi } from "vitest";
import type { Ticket } from "@/features/sources/request-limiter";
import { acquireCover, isLocalImage, needsGrant, refundIfCached, snapCoverWidth, timingKey } from "./cover-gate";

const ticket: Ticket = { id: 1, priority: "P2" };

describe("cover gate", () => {
  it("asks the limiter for a P2 grant before a remote src is assigned", async () => {
    const acquire = vi.fn().mockResolvedValue(ticket);
    await expect(acquireCover({ acquire })).resolves.toBe(ticket);
    expect(acquire).toHaveBeenCalledWith("P2", undefined);
  });
  it("propagates an abort while waiting", async () => {
    const ac = new AbortController();
    const acquire = vi.fn((_p, signal?: AbortSignal) => new Promise<Ticket>((_, rej) => signal?.addEventListener("abort", () => rej(new Error("aborted")))));
    const p = acquireCover({ acquire }, ac.signal);
    ac.abort();
    await expect(p).rejects.toThrow("aborted");
  });
  it("refunds a cache hit (transferSize 0) and only a cache hit", () => {
    const refund = vi.fn();
    expect(refundIfCached({ refund }, ticket, "u", () => [{ transferSize: 0 } as PerformanceResourceTiming])).toBe(true);
    expect(refund).toHaveBeenCalledWith(ticket);
    refund.mockClear();
    expect(refundIfCached({ refund }, ticket, "u", () => [{ transferSize: 4096 } as PerformanceResourceTiming])).toBe(false);
    expect(refundIfCached({ refund }, ticket, "u", () => [])).toBe(false);
    expect(refund).not.toHaveBeenCalled();
  });
  it("local images skip the limiter", () => {
    for (const s of ["/gallery/covers/01.webp", "/skin-preview/x.png", "data:image/png;base64,AA", "blob:http://x/1"]) expect(isLocalImage(s)).toBe(true);
    expect(isLocalImage("/api/sources/a/series/b/cover")).toBe(false);
  });
  it("snaps to the nearest rung at or above the device width", () => {
    expect(snapCoverWidth(100, 1)).toBe(160);
    expect(snapCoverWidth(120, 2)).toBe(240);
    expect(snapCoverWidth(300, 3)).toBe(720);
    expect(snapCoverWidth(1000, 3)).toBe(720);
    expect(snapCoverWidth(40, 1)).toBe(96);
  });
  it("looks resource timing up by the absolute URL", () => {
    const keys: string[] = [];
    refundIfCached({ refund: vi.fn() }, ticket, "/api/x/cover?w=160", (n) => { keys.push(n); return []; }, "http://h.test/lib");
    expect(keys).toEqual(["http://h.test/api/x/cover?w=160"]);
    expect(timingKey("http://a.test/b.webp", "http://h.test/")).toBe("http://a.test/b.webp");
  });
  it("takes one P2 grant per src: a landed grant never re-arms the effect", () => {
    expect(needsGrant(null, "a")).toBe(true);
    expect(needsGrant({ src: "a" }, "a")).toBe(false);
    expect(needsGrant({ src: "a" }, "b")).toBe(true);
  });
});
