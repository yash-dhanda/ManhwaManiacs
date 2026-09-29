import { afterEach, describe, expect, it, vi } from "vitest";
import { PausableTimer, _resetQueue, computeAllowed, getAllowed, registerBlocker, requestSlot, setQueueFrame } from "./overlay-queue";

const W = (o: Partial<Record<"toast" | "chapters" | "update", boolean>>) => ({ toast: false, chapters: false, update: false, ...o });
const NB = { menu: 0, alert: 0 };

describe("computeAllowed", () => {
  it("a menu blocks every item, on every platform", () => {
    for (const phone of [true, false])
      expect(computeAllowed({ wanted: W({ toast: true, chapters: true, update: true }), blockers: { menu: 1, alert: 0 }, phone, bottomBar: false })).toEqual(W({}));
  });
  it("an alert blocks on phones only", () => {
    const wanted = W({ toast: true });
    expect(computeAllowed({ wanted, blockers: { menu: 0, alert: 1 }, phone: true, bottomBar: false }).toast).toBe(false);
    expect(computeAllowed({ wanted, blockers: { menu: 0, alert: 1 }, phone: false, bottomBar: false }).toast).toBe(true);
  });
  it("phone top band: toast > new-chapters > app-update, one at a time", () => {
    const at = (w: ReturnType<typeof W>) => computeAllowed({ wanted: w, blockers: NB, phone: true, bottomBar: false });
    expect(at(W({ toast: true, chapters: true, update: true }))).toEqual(W({ toast: true }));
    expect(at(W({ chapters: true, update: true }))).toEqual(W({ chapters: true }));
    expect(at(W({ update: true }))).toEqual(W({ update: true }));
  });
  it("desktop: a toast waits while the capsule shows; the update capsule waits for a bottom bar", () => {
    const at = (w: ReturnType<typeof W>, bottomBar = false) => computeAllowed({ wanted: w, blockers: NB, phone: false, bottomBar });
    expect(at(W({ toast: true, chapters: true }))).toEqual(W({ chapters: true }));
    expect(at(W({ toast: true, update: true }))).toEqual(W({ toast: true, update: true }));
    expect(at(W({ update: true }), true).update).toBe(false);
  });
});

describe("the store", () => {
  afterEach(_resetQueue);
  it("holds a toast while a menu is open and lets it back when the menu closes", () => {
    const release = requestSlot("toast");
    expect(getAllowed().toast).toBe(true);
    const unblock = registerBlocker("menu");
    expect(getAllowed().toast).toBe(false);
    unblock();
    expect(getAllowed().toast).toBe(true);
    release();
    expect(getAllowed().toast).toBe(false);
  });
  it("the capsule reappears when a higher phone item leaves", () => {
    setQueueFrame({ phone: true });
    const c = requestSlot("chapters");
    const t = requestSlot("toast");
    expect(getAllowed()).toEqual(W({ toast: true }));
    t();
    expect(getAllowed()).toEqual(W({ chapters: true }));
    c();
  });
});

describe("PausableTimer", () => {
  it("keeps its remaining time across a pause and fires when it runs out", () => {
    vi.useFakeTimers();
    let t = 0;
    const done = vi.fn();
    const timer = new PausableTimer(4000, done, () => t);
    timer.start();
    t = 1500; vi.advanceTimersByTime(1500);
    timer.pause();
    expect(timer.remaining).toBe(2500);
    vi.advanceTimersByTime(10_000);
    expect(done).not.toHaveBeenCalled();
    timer.start();
    t = 4000; vi.advanceTimersByTime(2500);
    expect(done).toHaveBeenCalledOnce();
    vi.useRealTimers();
  });
});
