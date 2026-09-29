import { describe, expect, it } from "vitest";
import { ApiError } from "@/types/api";
import { notAvailableKind } from "./not-available";

describe("notAvailableKind", () => {
  it("maps the three codes", () => {
    expect(notAvailableKind(new ApiError(404, { code: "series_not_found" }))).toBe("series");
    expect(notAvailableKind(new ApiError(404, { code: "source_not_found" }))).toBe("source");
    expect(notAvailableKind(new ApiError(400, { code: "source_not_browsable" }))).toBe("not-browsable");
  });
  it("is null for anything else", () => {
    expect(notAvailableKind(new ApiError(500, { code: "boom" }))).toBeNull();
    expect(notAvailableKind(new Error("x"))).toBeNull();
    expect(notAvailableKind(null)).toBeNull();
  });
});
