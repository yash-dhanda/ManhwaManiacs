import { describe, expect, it } from "vitest";
import { parseRetryAfter } from "./http";

describe("parseRetryAfter", () => {
  it("parses delta seconds, dates and junk", () => {
    expect(parseRetryAfter("5")).toBe(5000);
    expect(parseRetryAfter(null)).toBeNull();
    expect(parseRetryAfter("soon")).toBeNull();
    const ms = parseRetryAfter(new Date(Date.now() + 10_000).toUTCString());
    expect(ms).toBeGreaterThan(8000);
    expect(ms).toBeLessThanOrEqual(10_000);
  });
});
