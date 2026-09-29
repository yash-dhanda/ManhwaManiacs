import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { motionId, dartMotionId, motionDart, motionTs } from "../build-haptics.mjs";

const read = (s) => JSON.parse(readFileSync(new URL(`../tokens/${s}.json`, import.meta.url), "utf8"));
const unique = (xs) => new Set(xs).size === xs.length;

test("38 Cinematic and 116 Glass ids, unique per skin", () => {
  for (const [s, n] of [["cinematic", 38], ["glass", 116]]) {
    const names = read(s).motionNames;
    assert.equal(names.length, n);
    assert.ok(unique(names.map(motionId)), s);
    assert.ok(unique(names.map(dartMotionId)), s);
  }
});

test("id conversion", () => {
  assert.equal(motionId("Column wipe"), "columnWipe");
  assert.equal(motionId("Count-up"), "countUp");
  assert.equal(motionId("Deck lift-off"), "deckLiftOff");
  assert.equal(motionId("Reaction bloom and arc"), "reactionBloomAndArc");
  assert.equal(dartMotionId("Throw"), "throwMove");
  assert.equal(dartMotionId("Catch"), "catchMove");
  assert.equal(dartMotionId("Count-up"), "countUp");
});

test("Dart enum and TS union carry the upper-cased labels", () => {
  const d = motionDart(["Throw", "Column wipe"], "h");
  assert.match(d, /throwMove\('THROW'\),\n  columnWipe\('COLUMN WIPE'\);/);
  const ts = motionTs(["Column wipe"], "h");
  assert.match(ts, /"columnWipe",/);
  assert.match(ts, /columnWipe: "COLUMN WIPE",/);
});
