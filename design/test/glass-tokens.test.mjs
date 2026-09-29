import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const read = (p) => readFileSync(new URL(p, import.meta.url), "utf8");
const t = JSON.parse(read("../tokens/glass.json"));
const contract = JSON.parse(read("../contract.json"));
const leaves = (o) => Object.values(o).flatMap((v) => (typeof v === "string" ? [v] : leaves(v)));

test("colour: 134 rows of §2.8.1 plus 12 avatar glyph colours", () => {
  assert.equal(leaves(t.color).length, 146);
  assert.equal(Object.keys(t.color.avatar).length, 12);
  for (const [p, a] of Object.entries(t.color.avatar)) assert.deepEqual(Object.keys(a), ["from", "to", "glyph"], p);
  assert.equal(Object.keys(t.color.paper).length, 7);
  assert.equal(Object.keys(t.color.mood).length, 7);
});

test("group sizes of §2.8.2 to §2.8.5 and §3.7", () => {
  const n = (o) => Object.keys(o).length;
  assert.equal(n(t.space), 15);
  assert.equal(n(t.layout), 23);
  assert.equal(n(t.radius), 9);
  assert.equal(n(t.blur), 12);
  assert.equal(n(t.border), 6);
  assert.equal(n(t.z), 10);
  assert.equal(n(t.spring) - 1, 20);
  assert.equal(n(t.curve), 17);
  assert.equal(n(t.physics), 21);
  assert.equal(n(t.threshold), 33);
  assert.equal(n(t.type), 18);
  assert.equal(n(t.ahap), 15);
  assert.equal(n(t.sounds), 28);
  assert.equal(t.motionNames.length, 116);
});

test("spot checks against glass/DESIGN.md", () => {
  assert.equal(t.color.twinDense, "rgba(19,19,23,0.82)");
  assert.equal(t.color.paper.glass.muted, "#8F8F99");
  assert.equal(t.color.avatar.steelBlade.glyph, "rgba(0,0,0,0.85)");
  assert.equal(t.color.avatar.roseHeart.glyph, "#FFFFFF");
  assert.equal(t.color.backingDisc, "rgba(0,0,0,0.60)");
  assert.deepEqual(t.layout.readerStripMax, { min: 480, fraction: 0.5, max: 900 });
  assert.deepEqual(t.layout.touchMin, { value: 44, android: 48 });
  assert.equal(t.radius.iconTile, 12);
  assert.equal(t.blur.fieldDesktop, 180);
  assert.equal(t.border.focusRing.color, "color.iris300");
  assert.equal(t.glass.t4.dispersion, 0.6);
  assert.equal(t.glass.tinted.fillPressed, "rgba(91,74,209,0.86)");
  assert.deepEqual(t.glass.snap, [36, 57, 97]);
  assert.equal(t.dim.legibility.maxHc, 0.72);
  assert.deepEqual(t.spring.splashLens, { ms: 468, bounce: 0.18 });
  assert.deepEqual(t.curve.caretBlink, { ms: 530, curve: "step" });
  assert.equal(t.physics.gravitySplash, 9000);
  assert.equal(t.physics.magnetPull, 0.35);
  assert.equal(t.threshold.topCapsule, 400);
  assert.equal(t.threshold.doubleTapWindow, 280);
  assert.equal(t.threshold.imageDismissVelocity, 800);
  assert.deepEqual(t.type.wrappedNumeral.phone, [88, 88]);
  assert.equal(t.type.footnote.floor, 11);
  assert.equal(t.type.sidebarItem.phone, null);
  assert.equal(t.type.mono.rond, null);
});

test("every contract event is mapped: 90 haptic, 52 sound", () => {
  assert.deepEqual(Object.keys(t.haptics).sort(), [...contract.hapticEvents].sort());
  assert.deepEqual(Object.keys(t.soundEvents).sort(), [...contract.soundEvents].sort());
  assert.equal(t.soundEvents["nav.push"].length, 4);
  assert.equal(Object.keys(t.hapticsWeb).length, 7);
});
