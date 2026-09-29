import { readFileSync } from "node:fs";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { _resetLit, isSuppressed, litCount, registerLit, suppressLit } from "./lit";

const box = (visible = true) => ({ getClientRects: () => (visible ? [{}] : []) }) as unknown as HTMLElement;

beforeEach(() => {
  vi.useFakeTimers();
  vi.stubGlobal("getComputedStyle", () => ({ visibility: "visible" }));
  _resetLit();
});
afterEach(() => { vi.useRealTimers(); vi.unstubAllGlobals(); vi.restoreAllMocks(); });

describe("one lit object per screen", () => {
  it("two visible tinted objects log one console.warn", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    registerLit(() => box());
    registerLit(() => box());
    vi.runAllTimers();
    expect(litCount()).toBe(2);
    expect(warn).toHaveBeenCalledTimes(1);
  });
  it("one object, an overlay object or a hidden object stays quiet", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    registerLit(() => box());
    registerLit(() => box(), true);
    registerLit(() => box(false));
    vi.runAllTimers();
    expect(litCount()).toBe(1);
    expect(warn).not.toHaveBeenCalled();
  });
});

describe("suppressLit", () => {
  it("suppresses until released, once", () => {
    expect(isSuppressed()).toBe(false);
    const a = suppressLit(), b = suppressLit();
    expect(isSuppressed()).toBe(true);
    a(); a();
    expect(isSuppressed()).toBe(true);
    b();
    expect(isSuppressed()).toBe(false);
  });
  it("fades the caustic over 180 ms while suppressed", () => {
    const css = readFileSync(join(__dirname, "../glass.css"), "utf8");
    expect(css).toMatch(/\.caustic\[data-suppressed\][^}]*--caustic-a: 0[^}]*transition: --caustic-a 180ms/);
  });
});
