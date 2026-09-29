import { test } from "node:test";
import assert from "node:assert/strict";
import { readWav, writeWav, peakDbfs, rmsDb, makeLoop } from "../wav.mjs";

test("a written-then-read 1 kHz sine keeps its peak within 0.01 dB", () => {
  const rate = 48000, amp = 10 ** (-12 / 20);
  const s = new Float32Array(rate / 10).map((_, i) => amp * Math.sin((2 * Math.PI * 1000 * i) / rate + 0.3));
  const back = readWav(writeWav({ rate, channels: 1, samples: [s] }));
  assert.equal(back.rate, rate);
  assert.equal(back.channels, 1);
  assert.equal(back.bits, 16);
  assert.ok(Math.abs(peakDbfs(back.samples) - peakDbfs([s])) < 0.01);
  assert.ok(Math.abs(peakDbfs(back.samples) + 12) < 0.01);
});

test("a 441-sample file reads 441 frames", () => {
  const buf = writeWav({ rate: 44100, channels: 2, samples: [new Float32Array(441), new Float32Array(441)] });
  assert.equal(buf.length, 44 + 441 * 4);
  const w = readWav(buf);
  assert.equal(w.frames, 441);
  assert.equal(w.samples.length, 2);
  assert.equal(w.samples[1].length, 441);
});

test("rmsDb of a full-scale square is 0 dB and of silence is -Infinity", () => {
  const sq = Float32Array.from({ length: 100 }, (_, i) => (i % 2 ? 1 : -1));
  assert.ok(Math.abs(rmsDb([sq], 0, 100)) < 1e-9);
  assert.equal(rmsDb([new Float32Array(10)], 0, 10), -Infinity);
});

test("makeLoop keeps exactly loop frames and joins end to start without a jump", () => {
  const rate = 100, n = 9600; // 96 "seconds" at 100 Hz
  const ramp = Float64Array.from({ length: n }, (_, i) => i);
  const [y] = makeLoop([ramp], rate, 90, 6);
  assert.equal(y.length, 9000);
  assert.equal(y[0], ramp[9000]); // the start is the render's frame 90 s: the frame after the loop's last
  assert.equal(y[8999], ramp[8999]);
  assert.equal(y[600], ramp[600]); // past the cross-fade the render is untouched
});

test("makeLoop cross-fade is equal-power (sin/cos)", () => {
  const rate = 100;
  const a = new Float64Array(9600).fill(0);
  a.fill(1, 9000); // the tail that fades out is 1, the head that fades in is 0
  const [y] = makeLoop([a], rate, 90, 6);
  const i = 300; // half-way through the 600-frame fade
  assert.ok(Math.abs(y[i] - Math.cos((Math.PI / 2) * (i / 600))) < 1e-12);
});
