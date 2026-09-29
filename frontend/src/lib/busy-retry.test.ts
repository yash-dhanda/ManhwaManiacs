import { afterEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "@/types/api";
import { busyRetry, busyRetryDelay, DB_BUSY_EVENT } from "./busy-retry";

const busy = (ms: number | null = null) => { const e = new ApiError(503, { code: "db_busy" }); e.retryAfterMs = ms; return e; };

describe("busyRetry", () => {
  afterEach(() => vi.unstubAllGlobals());
  it("retries db_busy three times then dispatches the event once", () => {
    const dispatch = vi.fn();
    vi.stubGlobal("window", { dispatchEvent: dispatch });
    vi.stubGlobal("CustomEvent", class { constructor(public type: string) {} });
    expect([0, 1, 2].map((n) => busyRetry(n, busy()))).toEqual([true, true, true]);
    expect(dispatch).not.toHaveBeenCalled();
    expect(busyRetry(3, busy())).toBe(false);
    expect(dispatch).toHaveBeenCalledTimes(1);
    expect((dispatch.mock.calls[0][0] as { type: string }).type).toBe(DB_BUSY_EVENT);
  });
  it("uses retryAfterMs, else 2000 ms", () => {
    expect(busyRetryDelay(0, busy(7000))).toBe(7000);
    expect(busyRetryDelay(1, busy(null))).toBe(2000);
  });
  it("retries any other error once, as before", () => {
    const other = new ApiError(500, { code: "boom" });
    expect(busyRetry(0, other)).toBe(true);
    expect(busyRetry(1, other)).toBe(false);
    expect(busyRetry(0, new Error("x"))).toBe(true);
    expect(busyRetry(0, new ApiError(503, { code: "other" }))).toBe(true);
  });
});
