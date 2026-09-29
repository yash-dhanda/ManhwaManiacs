import { describe, expect, it } from "vitest";
import { parseDiscoverScope } from "./search-scope";

const on = { aiAvailable: true, dialogueAvailable: true };
const off = { aiAvailable: false, dialogueAvailable: false };

describe("parseDiscoverScope", () => {
  it("keeps the always-available scopes", () => {
    expect(parseDiscoverScope("library", off)).toBe("library");
    expect(parseDiscoverScope("sources", off)).toBe("sources");
    expect(parseDiscoverScope("all", off)).toBe("all");
  });
  it("gates ask and dialogue", () => {
    expect(parseDiscoverScope("ask", on)).toBe("ask");
    expect(parseDiscoverScope("ask", off)).toBe("all");
    expect(parseDiscoverScope("dialogue", on)).toBe("dialogue");
    expect(parseDiscoverScope("dialogue", off)).toBe("all");
  });
  it("maps text, unknown and missing to all", () => {
    expect(parseDiscoverScope("text", on)).toBe("all");
    expect(parseDiscoverScope("zzz", on)).toBe("all");
    expect(parseDiscoverScope(null, on)).toBe("all");
    expect(parseDiscoverScope(undefined, on)).toBe("all");
  });
});
