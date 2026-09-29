import { describe, expect, it } from "vitest";
import { describeHealth, sortWorstFirst } from "./health";
import type { SourceHealth } from "./types";

const base: SourceHealth = { status: "ok", consecutive_failures: 0, demoted: false, last_ok_at: null, last_error_at: null, last_error: null, last_checked_at: "2026-09-29T10:00:00" };
const now = Date.parse("2026-09-29T10:04:00Z");

describe("describeHealth", () => {
  it("labels ok with age", () => {
    expect(describeHealth(base, now)).toEqual({ state: "ok", label: "OK · last checked 4 min ago" });
  });
  it("labels failing", () => {
    expect(describeHealth({ ...base, status: "failing", consecutive_failures: 3 }, now).label).toBe("FAILING · 3 errors");
  });
  it("labels dead with a date", () => {
    expect(describeHealth({ ...base, status: "dead", last_ok_at: "2026-09-12T08:00:00" }, now).label).toBe("DEAD since 12 Sep");
  });
  it("demoted wins over status", () => {
    expect(describeHealth({ ...base, status: "dead", demoted: true }, now)).toEqual({ state: "demoted", label: "DEMOTED" });
  });
  it("is unknown when null or never checked", () => {
    expect(describeHealth(null, now).state).toBe("unknown");
    expect(describeHealth({ ...base, last_checked_at: null }, now).state).toBe("unknown");
  });
});

describe("sortWorstFirst", () => {
  it("orders dead, failing, demoted, unknown, ok then name", () => {
    const rows = [
      { name: "b", health: base },
      { name: "a", health: base },
      { name: "u", health: null },
      { name: "d", health: { ...base, demoted: true } },
      { name: "f", health: { ...base, status: "failing", consecutive_failures: 1 } },
      { name: "x", health: { ...base, status: "dead" } },
    ];
    expect(sortWorstFirst(rows, now).map((r) => r.name)).toEqual(["x", "f", "d", "u", "a", "b"]);
  });
});
