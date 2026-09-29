import { readFileSync } from "node:fs";
import path from "node:path";
import { spring } from "motion";
import { describe, expect, it } from "vitest";
import { spring as springTokens } from "./tokens.generated";

const css = readFileSync(path.join(__dirname, "tokens.generated.css"), "utf8");
const kebab = (s: string) => s.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase());

describe("glass spring parity (physical springs vs installed motion)", () => {
  for (const name of Object.keys(springTokens) as (keyof typeof springTokens)[]) {
    it(name, () => {
      const k = kebab(name);
      const curve = css.match(new RegExp(`--mm-spring-${k}: linear\\(([^)]*)\\);`))?.[1];
      const T = Number(css.match(new RegExp(`--mm-spring-${k}-ms: (\\d+)ms;`))?.[1]);
      expect(curve).toBeTruthy();
      const { stiffness, damping } = springTokens[name];
      // k = (2π/d)², c = 4π(1-bounce)/d, d = settle-independent visual duration; recover d from stiffness.
      const d = (2 * Math.PI) / Math.sqrt(stiffness);
      expect(stiffness).toBeCloseTo((2 * Math.PI / d) ** 2, 0);
      expect(damping).toBeGreaterThan(0);
      const samples = curve!.split(",").map(Number);
      expect(samples).toHaveLength(60);
      expect(samples[59]).toBe(1);
      const gen = spring({ keyframes: [0, 1], stiffness, damping, mass: 1 });
      for (let i = 1; i < 59; i++) {
        const t = (i * T) / 59;
        expect(Math.abs(gen.next(t).value - samples[i]), `${name}[${i}]`).toBeLessThanOrEqual(0.0005);
      }
    });
  }
});
