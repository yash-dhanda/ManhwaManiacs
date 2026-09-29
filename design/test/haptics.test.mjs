import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { ahapJson } from "../build-haptics.mjs";

const read = (p) => JSON.parse(readFileSync(new URL(p, import.meta.url), "utf8"));
const glass = read("../tokens/glass.json"), cine = read("../tokens/cinematic.json"), contract = read("../contract.json");

test("rise3 AHAP byte for byte (shared/01 §3)", () => {
  const want = `{
  "Version": 1.0,
  "Metadata": { "Project": "ManhwaManiacs", "Description": "glass rise3" },
  "Pattern": [
    { "Event": { "Time": 0.0, "EventType": "HapticContinuous", "EventDuration": 0.12,
      "EventParameters": [ { "ParameterID": "HapticIntensity", "ParameterValue": 0.27 },
                           { "ParameterID": "HapticSharpness", "ParameterValue": 0.7 } ] } },
    { "Event": { "Time": 0.12, "EventType": "HapticTransient",
      "EventParameters": [ { "ParameterID": "HapticIntensity", "ParameterValue": 0.54 },
                           { "ParameterID": "HapticSharpness", "ParameterValue": 0.85 } ] } }
  ]
}
`;
  assert.equal(ahapJson("glass", "rise3", glass.ahap.rise3), want);
  assert.deepEqual(JSON.parse(want).Pattern.length, 2);
});

test("every AHAP file is valid JSON with only transient and continuous events", () => {
  for (const [skin, t] of [["glass", glass], ["cinematic", cine]])
    for (const [name, ev] of Object.entries(t.ahap)) {
      const j = JSON.parse(ahapJson(skin, name, ev));
      for (const { Event: e } of j.Pattern) {
        assert.ok(["HapticTransient", "HapticContinuous"].includes(e.EventType));
        assert.equal("EventDuration" in e, e.EventType === "HapticContinuous");
      }
    }
  assert.equal(Object.keys(cine.ahap).length, 6);
  assert.equal(Object.keys(glass.ahap).length, 15);
});

test("swell: 7 transients, the last at 0.9 s with I 0.8 and S 0.9", () => {
  const s = glass.ahap.swell;
  assert.equal(s.length, 7);
  assert.ok(s.every((e) => e.type === "T"));
  assert.deepEqual(s.at(-1), { type: "T", t: 0.9, i: 0.8, s: 0.9 });
});

test("rise1..4 follow I_d = 0.30 + 0.08 × d", () => {
  for (const d of [1, 2, 3, 4]) {
    const I = Math.round((0.3 + 0.08 * d) * 100) / 100;
    assert.deepEqual(glass.ahap[`rise${d}`].map((e) => e.i), [Math.round(I * 50) / 100, I]);
  }
});

test("every contract haptic event is in both skins' haptics", () => {
  for (const t of [glass, cine]) for (const e of contract.hapticEvents) assert.ok(e in t.haptics, e);
});
