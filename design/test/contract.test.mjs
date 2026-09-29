import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";

const read = (p) => JSON.parse(readFileSync(new URL(p, import.meta.url), "utf8"));
const contract = read("../contract.json");
const skins = readdirSync(new URL("../tokens/", import.meta.url)).filter((f) => f.endsWith(".json"));
const unique = (xs) => new Set(xs).size === xs.length;

test("35 screens with unique ids and paths", () => {
  assert.equal(contract.screens.length, 35);
  assert.ok(unique(contract.screens.map((s) => s.id)));
  assert.ok(unique(contract.screens.map((s) => s.path)));
});

test("static /library/* screens precede /library/:followedId", () => {
  const paths = contract.screens.map((s) => s.path);
  const dynamic = paths.indexOf("/library/:followedId");
  assert.ok(dynamic > 0);
  for (const [i, p] of paths.entries())
    if (/^\/library\/[^:]/.test(p)) assert.ok(i < dynamic, `${p} declared after /library/:followedId`);
});

test("params match the path's :segments", () => {
  for (const s of contract.screens)
    assert.deepEqual(s.params, [...s.path.matchAll(/:(\w+)/g)].map((m) => m[1]), s.id);
});

test("29 sheets, 20 settings sections, glass flag off", () => {
  assert.equal(contract.sheets.length, 29);
  assert.ok(unique(contract.sheets));
  assert.equal(contract.settingsSections.length, 20);
  assert.ok(unique(contract.settingsSections.map((s) => s.slug)));
  assert.equal(contract.flags.glass_available, false);
});

test("90 haptic events and 52 sound events, no duplicates", () => {
  assert.equal(contract.hapticEvents.length, 90);
  assert.ok(unique(contract.hapticEvents));
  assert.equal(contract.soundEvents.length, 52);
  assert.ok(unique(contract.soundEvents));
});

for (const f of skins) {
  test(`${f}: haptics and soundEvents cover every contract event`, () => {
    const t = read(`../tokens/${f}`);
    assert.deepEqual(Object.keys(t.haptics).sort(), [...contract.hapticEvents].sort());
    assert.deepEqual(Object.keys(t.soundEvents).sort(), [...contract.soundEvents].sort());
  });
}
