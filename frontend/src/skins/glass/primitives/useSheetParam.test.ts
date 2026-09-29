import { describe, expect, it } from "vitest";
import { pushStack, reconcileStack } from "./useSheetParam";

describe("sheet stack", () => {
  it("keeps at most two sheets; a third replaces the top one", () => {
    expect(pushStack([], "a")).toEqual(["a"]);
    expect(pushStack(["a"], "b")).toEqual(["a", "b"]);
    expect(pushStack(["a", "b"], "c")).toEqual(["a", "c"]);
  });
  it("follows the URL: back pops, a hard load starts a fresh stack, no parameter clears", () => {
    expect(reconcileStack(["a", "b"], "a")).toEqual(["a"]);
    expect(reconcileStack([], "filters")).toEqual(["filters"]);
    expect(reconcileStack(["a", "b"], null)).toEqual([]);
    expect(reconcileStack(["a", "b"], "b")).toEqual(["a", "b"]);
  });
});
