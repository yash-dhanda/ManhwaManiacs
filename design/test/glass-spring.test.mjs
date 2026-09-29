import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { physical, physicalSpringCss, motionPhysical } from "../lib/spring.mjs";

const t = JSON.parse(readFileSync(new URL("../tokens/glass.json", import.meta.url), "utf8"));
// glass/DESIGN.md §4.2: [k, c, settle ms].
const TABLE = {
  track: [1754.6, 72.05, 149], press: [815.7, 45.7, 253], tick: [584.0, 33.83, 289], snappy: [246.7, 26.7, 431], morph: [273.4, 24.8, 434],
  tab: [195.0, 21.78, 518], lens: [223.8, 20.94, 467], sheet: [171.3, 24.09, 447], sheetSnap: [223.8, 26.33, 342], page: [146.0, 24.17, 615],
  zoom: [125.9, 21.09, 558], settle: [322.3, 35.9, 414], minimize: [246.7, 31.42, 473], dismiss: [385.5, 39.27, 378], camera: [195.0, 25.13, 392],
  celebrate: [109.7, 13.61, 643], drift: [48.7, 13.96, 1064], letter: [219.6, 26.08, 345], smooth: [157.9, 22.62, 436], splashLens: [180.0, 22.0, 532],
};

test("glass.json declares the physical format and the 20 springs of §4.2", () => {
  assert.equal(t.spring.format, "physical");
  assert.deepEqual(Object.keys(t.spring).filter((k) => k !== "format").sort(), Object.keys(TABLE).sort());
});

for (const [name, [k, c, settle]] of Object.entries(TABLE)) {
  test(`${name}: k ${k} ±0.3, c ${c} ±0.03, settle ${settle} ms`, () => {
    const s = t.spring[name];
    const p = physical(s.ms, s.bounce);
    assert.ok(Math.abs(p.k - k) <= 0.3, `k ${p.k}`);
    assert.ok(Math.abs(p.c - c) <= 0.03, `c ${p.c}`);
    assert.equal(physicalSpringCss(s.ms, s.bounce).ms, settle);
  });
}

test("§15.8 physics values: {520, 0} → k 146.0, c 24.17; {150, 0.14} → k 1754.6, c 72.05", () => {
  assert.deepEqual(motionPhysical(520, 0), { type: "spring", stiffness: 146, damping: 24.17, mass: 1 });
  assert.deepEqual(motionPhysical(150, 0.14), { type: "spring", stiffness: 1754.6, damping: 72.05, mass: 1 });
});

test("page linear(): 60 samples over 615 ms, samples 2 and 3 are 0.0073 and 0.0269", () => {
  const { ms, easing } = physicalSpringCss(520, 0);
  assert.equal(ms, 615);
  const xs = easing.slice(7, -1).split(", ");
  assert.equal(xs.length, 60);
  assert.equal(xs[0], "0");
  assert.equal(xs[1], "0.0073");
  assert.equal(xs[2], "0.0269");
  assert.ok(easing.endsWith(", 1)"));
});
