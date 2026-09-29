import { describe, expect, it } from "vitest";
import { ApiError } from "@/types/api";
import { createRequestLimiter } from "./request-limiter";

function setup() {
  let t = 0;
  const timers: { at: number; fn: () => void }[] = [];
  const limiter = createRequestLimiter({
    now: () => t,
    setTimer: (fn, ms) => timers.push({ at: t + ms, fn }),
  });
  const advance = async (ms: number) => {
    const target = t + ms;
    for (;;) {
      const due = timers.filter((x) => x.at <= target).sort((a, b) => a.at - b.at)[0];
      if (!due) break;
      timers.splice(timers.indexOf(due), 1);
      t = Math.max(t, due.at);
      due.fn();
      await Promise.resolve();
    }
    t = target;
    await Promise.resolve();
    await Promise.resolve();
  };
  return { limiter, advance, now: () => t };
}
const flush = async () => { for (let i = 0; i < 5; i++) await Promise.resolve(); };
const track = (p: Promise<unknown>) => {
  const s = { done: false };
  p.then(() => (s.done = true), () => {});
  return s;
};

describe("request limiter", () => {
  it("50 starts leave free()=0 and the 51st P2 waits for the first to age 60 s", async () => {
    const { limiter, advance } = setup();
    for (let i = 0; i < 50; i++) await limiter.acquire("P2");
    expect(limiter.free()).toBe(0);
    const w = track(limiter.acquire("P2"));
    await advance(59_999);
    expect(w.done).toBe(false);
    await advance(2);
    expect(w.done).toBe(true);
  });

  it("P0 and P1 never wait", async () => {
    const { limiter } = setup();
    for (let i = 0; i < 50; i++) await limiter.acquire("P2");
    const a = track(limiter.acquire("P0"));
    const b = track(limiter.acquire("P1"));
    await flush();
    expect(a.done && b.done).toBe(true);
  });

  it("P3 waits while free < 20 and while 2 P3 are in flight", async () => {
    const { limiter, advance } = setup();
    for (let i = 0; i < 31; i++) await limiter.acquire("P2"); // free 19
    const w = track(limiter.acquire("P3"));
    await flush();
    expect(w.done).toBe(false);
    await advance(60_001);
    expect(w.done).toBe(true);

    const s = setup();
    const t1 = await s.limiter.acquire("P3");
    await s.limiter.acquire("P3");
    const third = track(s.limiter.acquire("P3"));
    await flush();
    expect(third.done).toBe(false);
    s.limiter.release(t1);
    await flush();
    expect(third.done).toBe(true);
  });

  it("a 12 s pause holds P2 and P3 but not P0 or P1", async () => {
    const { limiter, advance } = setup();
    limiter.pause(12_000);
    const p2 = track(limiter.acquire("P2"));
    const p3 = track(limiter.acquire("P3"));
    const p0 = track(limiter.acquire("P0"));
    const p1 = track(limiter.acquire("P1"));
    await flush();
    expect([p2.done, p3.done, p0.done, p1.done]).toEqual([false, false, true, true]);
    await advance(12_001);
    expect(p2.done && p3.done).toBe(true);
  });

  it("a P0 that hits 429 retries once after Retry-After", async () => {
    const { limiter, advance } = setup();
    let calls = 0;
    const r = limiter.run("P0", async () => {
      calls++;
      if (calls === 1) throw Object.assign(new ApiError(429, {}), { retryAfterMs: 5000 });
      return "ok";
    });
    const s = track(r);
    await flush();
    expect(calls).toBe(1);
    await advance(4_999);
    expect(calls).toBe(1);
    await advance(2);
    await flush();
    expect(calls).toBe(2);
    expect(await r).toBe("ok");
    expect(s.done).toBe(true);
  });

  it("refund frees the slot", async () => {
    const { limiter } = setup();
    const t = await limiter.acquire("P2");
    expect(limiter.free()).toBe(49);
    limiter.refund(t);
    expect(limiter.free()).toBe(50);
  });

  it("an aborted waiter never starts", async () => {
    const { limiter, advance } = setup();
    for (let i = 0; i < 50; i++) await limiter.acquire("P2");
    const ac = new AbortController();
    const w = limiter.acquire("P2", ac.signal);
    const rejected = w.catch((e) => e.name);
    ac.abort();
    expect(await rejected).toBe("AbortError");
    await advance(61_000);
    expect(limiter.free()).toBe(50);
  });

  it("never admits 99 P2 starts in any 60 s window (not a refilling bucket)", async () => {
    const { limiter, advance, now } = setup();
    const starts: number[] = [];
    for (let i = 0; i < 99; i++) limiter.acquire("P2").then(() => starts.push(now()));
    await flush();
    await advance(180_000);
    expect(starts.length).toBe(99);
    for (const s of starts) {
      expect(starts.filter((x) => x >= s && x < s + 60_000).length).toBeLessThanOrEqual(50);
    }
  });
});
