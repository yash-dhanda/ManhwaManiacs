import test from "node:test";
import assert from "node:assert/strict";
import { deflateSync, crc32 } from "node:zlib";
import { readPng, writeIco, readIco, insideCircle } from "./img.mjs";

function chunk(type, data) {
  const b = Buffer.concat([Buffer.from(type), data]);
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0); b.copy(out, 4); out.writeUInt32BE(crc32(b), 8 + data.length);
  return out;
}
function png(w, h, px) {
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  const rows = [];
  for (let y = 0; y < h; y++) rows.push(Buffer.from([0, ...px.slice(y * w * 4, (y + 1) * w * 4)]));
  return Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(Buffer.concat(rows))), chunk("IEND", Buffer.alloc(0))]);
}

test("png decode", () => {
  const px = [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  const p = readPng(png(3, 2, px));
  assert.equal(p.width, 3); assert.equal(p.height, 2);
  assert.deepEqual([...p.rgba()], px);
});

test("ico round trip", () => {
  const a = png(16, 16, new Array(16 * 16 * 4).fill(255)), b = png(32, 32, new Array(32 * 32 * 4).fill(0));
  const e = readIco(writeIco([a, b]));
  assert.deepEqual(e.map((x) => x.width), [16, 32]);
  assert.ok(e[0].bytes.equals(a) && e[1].bytes.equals(b));
});

test("insideCircle fails on a corner pixel", () => {
  const w = 20, rgba = Buffer.alloc(w * w * 4); rgba[3] = 255;
  assert.equal(insideCircle(rgba, w, w, 10, 10, 8, (r, g, b, a) => a > 0).ok, false);
});
