import { readFileSync } from "node:fs";
import path from "node:path";
import { spring } from "motion";
import { describe, expect, it } from "vitest";
import { spring as springTokens } from "./tokens.generated";

const css = readFileSync(path.join(__dirname, "tokens.generated.css"), "utf8");
const SETTLE = { release: 800, sheet: 850, scrub: 500 } as const;

describe("cinematic spring parity (design/lib/spring.mjs vs installed motion)", () => {
  for (const name of Object.keys(springTokens) as (keyof typeof springTokens)[]) {
    it(name, () => {
      const curve = css.match(new RegExp(`--mm-spring-${name}: (linear\\([^)]*\\));`))?.[1];
      const ms = css.match(new RegExp(`--mm-spring-${name}-ms: (\\d+)ms;`))?.[1];
      expect(curve).toBeTruthy();
      const { visualDuration, bounce } = springTokens[name];
      expect(`${ms}ms ${curve}`).toBe(spring(visualDuration, bounce).toString());
      if (name in SETTLE) expect(Number(ms)).toBe(SETTLE[name as keyof typeof SETTLE]);
    });
  }
  it("release starts as the contract states", () => {
    expect(spring(0.42, 0).toString().startsWith("800ms linear(0, 0.0572, 0.1795")).toBe(true);
  });
});
