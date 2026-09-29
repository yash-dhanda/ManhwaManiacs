import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { measure, forbidden, run } from "../check-contrast.mjs";
import { parseColor, ratio } from "../lib/composite.mjs";

const read = (s) => JSON.parse(readFileSync(new URL(`../tokens/${s}.json`, import.meta.url), "utf8"));
const glass = read("glass"), cine = read("cinematic");
const W = "#FFFFFF", bk = (a) => ({ black: a });
const near = (x, want, tol = 0.02) => assert.ok(Math.abs(x - want) <= tol, `${x.toFixed(3)} vs ${want}`);
const g = (fg, over) => measure(glass, { id: "t", fg, over, kind: "text" });

test("WCAG basics: white on black is 21, rgba parses with alpha", () => {
  near(ratio([1, 1, 1], [0, 0, 0]), 21, 1e-9);
  assert.deepEqual(parseColor("rgba(0,0,0,0.60)"), [0, 0, 0, 0.6]);
});

test("compositing vectors (glass §15.8, verified on this box)", () => {
  near(g("color.onGlass", [W, bk(0.64), "glass.t3.fill"]), 5.18);
  near(g("color.onGlass", [W, bk(0.72), bk(0.22), "glass.t3.fill"]), 8.78);
  near(g("color.onTint", [W, bk(0.64), "glass.tinted.fill"]), 4.67);
  near(g("color.onGlass", [W, bk(0.64), "glass.clear.fill"]), 5.72);
  near(g("color.onGlass", [W, bk(0.64), "glass.t2.fill"]), 5.05);
  near(g("color.onGlass", [W, bk(0.22), "glass.t4.fill"]), 4.55);
  near(g("color.iris500", [W, bk(0.64), "glass.t2.fill", "color.backingDisc"]), 4.55);
  near(g("color.label2", [W, "color.dimSheet", bk(0.22), "glass.t4.fill", "color.wellOnGlass"]), 5.2);
  near(g("color.onGlass", [W, "color.dimModal", bk(0.22), "glass.t4.fill"]), 9.23);
  near(g("color.onGlass", [W, "color.dimSheet", bk(0.22), "glass.t5.fill"]), 8.36);
  near(g("color.iris500", [W, bk(0.22), "glass.t4.fill", "color.backingDisc"]), 4.38);
  near(g("color.onGlass", ["#BCBCBC", bk(0.43), "glass.clear.fill"]), 4.56);
  const c = (fg, over) => measure(cine, { id: "t", fg, over, kind: "text" });
  near(c("color.ink.60", [W, bk(0.88)]), 5.68);
  near(c("color.spot", [W, bk(0.88)]), 10.99);
  near(c("color.ink.100", [W, bk(0.88)]), 14.54);
  near(c("color.ink.80", ["#000000", "color.spot.wash"]), 9.38);
});

test("negative: bare danger inside T4 measures 1.68 and the state-colour rule rejects it", () => {
  const k = { id: "glass.neg.danger", fg: "color.danger", over: [W, bk(0.22), "glass.t4.fill"], kind: "nontext" };
  near(measure(glass, k), 1.68);
  assert.equal(forbidden("glass", k).length, 1);
  assert.equal(forbidden("glass", { ...k, over: [...k.over, "color.backingDisc"] }).length, 0);
});

test("negative: label3 on T4 under dimModal measures 3.64 and the label rule rejects it", () => {
  const k = { id: "glass.neg.label3", fg: "color.label3", over: [W, "color.dimModal", bk(0.22), "glass.t4.fill"], kind: "text" };
  near(measure(glass, k), 3.64);
  assert.equal(forbidden("glass", k).length, 1);
  assert.equal(forbidden("glass", { ...k, id: "glass.wrapped.x" }).length, 0);
});

test("negative: label2 on T5 under dimSheet measures 4.32 and is rejected", () => {
  const k = { id: "glass.neg.label2", fg: "color.label2", over: [W, "color.dimSheet", bk(0.22), "glass.t5.fill"], kind: "text" };
  near(measure(glass, k), 4.32);
  assert.equal(forbidden("glass", k).length, 1);
});

test("negative: ink.45 on paper.2 measures 4.20 and the Cinematic rule rejects it", () => {
  const k = { id: "cine.neg.ink45", fg: "color.ink.45", over: ["color.paper.2"], kind: "text" };
  near(measure(cine, k), 4.2);
  assert.equal(forbidden("cinematic", k).length, 1);
  assert.equal(forbidden("cinematic", { ...k, over: ["#000000"] }).length, 0);
});

test("every declared case of both skins passes", () => {
  const r = run(join(fileURLToPath(new URL(".", import.meta.url)), "../.."));
  assert.equal(r.failures, 0, r.lines.filter((l) => l.endsWith("FAIL")).join("\n"));
  assert.ok(r.counts.glass.pass > 0 && r.counts.cinematic.pass > 0);
});
