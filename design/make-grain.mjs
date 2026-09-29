#!/usr/bin/env node
// Writes frontend/src/skins/cinematic/assets/grain.png: 256x256 8-bit greyscale Gaussian noise
// (mean 128, sigma 64, clipped), mulberry32 seed 0x6D6D + Box-Muller. Deterministic; Node 22 stdlib only.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { crc32, deflateSync } from "node:zlib";

const N = 256;
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const out = join(root, "frontend/src/skins/cinematic/assets/grain.png");

function mulberry32(a) {
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rnd = mulberry32(0x6d6d);
const gauss = () => Math.sqrt(-2 * Math.log(1 - rnd())) * Math.cos(2 * Math.PI * rnd());

const raw = Buffer.alloc((N + 1) * N); // filter byte 0 per scanline
for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
  raw[y * (N + 1) + 1 + x] = Math.max(0, Math.min(255, Math.round(128 + 64 * gauss())));
}
const chunk = (type, data) => {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body) >>> 0);
  return Buffer.concat([len, body, crc]);
};
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(N, 0); ihdr.writeUInt32BE(N, 4); ihdr[8] = 8; ihdr[9] = 0; // 8-bit greyscale
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0)),
]);
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, png);
console.log(`wrote ${out} (${png.length} bytes)`);
