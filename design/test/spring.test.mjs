import { test } from "node:test";
import assert from "node:assert/strict";
import { motionSpring, springCss } from "../lib/spring.mjs";

// Reference vectors from motion-dom 12.42.2's spring(ms / 1000, bounce).toString() (shared/00).
const vectors = [
  ["release", 420, 0, 800, 27, "linear(0, 0.0572, 0.1795, 0.3195, 0.4536,", ", 0.999, 1, 1)"],
  ["sheet", 480, 0, 850, 28, "linear(0, 0.0471, 0.1512, 0.2754, 0.399,", ", 0.9982, 0.9987, 1)"],
  ["scrub", 240, 0, 500, 17, "linear(0, 0.1495, 0.3955, 0.6061, 0.7562,", ", 0.9992, 1, 1)"],
  ["underdamped", 400, 0.3, 650, 22, "linear(0, 0.0676, 0.2212, 0.4046, 0.5821,", ", 0.9999, 0.9986, 1)"],
  ["bouncy", 300, 0.5, 800, 27, "linear(0, 0.1187, 0.3801, 0.6679, 0.9085,", ", 1.0006, 0.9998, 1)"],
];

for (const [name, ms, bounce, T, n, head, tail] of vectors) {
  test(`${name} {${ms}, ${bounce}}: settle ${T} ms, ${n} samples`, () => {
    const { ms: settle, easing } = springCss(ms, bounce);
    assert.equal(settle, T);
    assert.equal(easing.slice(7, -1).split(", ").length, n);
    assert.ok(easing.startsWith(head), easing);
    assert.ok(easing.endsWith(tail), easing);
    assert.equal(motionSpring(ms, bounce), `${T}ms ${easing}`);
  });
}

test("Flutter description of release: stiffness 155.42, damping 24.93 (ms × 1.2)", () => {
  // SpringDescription.withDurationAndBounce(duration: d, bounce: 0): k = (2π / d)², c = 2√k.
  const d = Math.round(420 * 1.2) / 1000;
  const k = (2 * Math.PI / d) ** 2;
  assert.ok(Math.abs(k - 155.42) <= 0.01, String(k));
  assert.ok(Math.abs(2 * Math.sqrt(k) - 24.93) <= 0.01);
});
