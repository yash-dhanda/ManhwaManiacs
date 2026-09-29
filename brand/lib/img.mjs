// Stdlib-only image helpers (PNG decode, WebP size, ICO read/write, safe-circle test).
import { inflateSync, deflateSync, crc32 } from "node:zlib";

export function readPng(buf) {
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error("not a png");
  let p = 8, width, height, bitDepth, colorType, interlace;
  const idat = [];
  while (p < buf.length) {
    const len = buf.readUInt32BE(p), type = buf.toString("latin1", p + 4, p + 8);
    const data = buf.subarray(p + 8, p + 8 + len);
    if (type === "IHDR") {
      width = data.readUInt32BE(0); height = data.readUInt32BE(4);
      bitDepth = data[8]; colorType = data[9]; interlace = data[12];
    } else if (type === "IDAT") idat.push(data);
    else if (type === "IEND") break;
    p += 12 + len;
  }
  if (bitDepth !== 8 || interlace !== 0 || ![0, 2, 4, 6].includes(colorType)) throw new Error("unsupported png");
  const ch = { 0: 1, 2: 3, 4: 2, 6: 4 }[colorType];
  return {
    width, height, colorType, bitDepth,
    rgba() {
      const raw = inflateSync(Buffer.concat(idat));
      const stride = width * ch, out = Buffer.alloc(width * height * 4);
      let prev = Buffer.alloc(stride);
      for (let y = 0; y < height; y++) {
        const f = raw[y * (stride + 1)];
        const line = Buffer.from(raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)));
        for (let i = 0; i < stride; i++) {
          const a = i >= ch ? line[i - ch] : 0, b = prev[i], c = i >= ch ? prev[i - ch] : 0;
          let add = 0;
          if (f === 1) add = a; else if (f === 2) add = b; else if (f === 3) add = (a + b) >> 1;
          else if (f === 4) {
            const pp = a + b - c, pa = Math.abs(pp - a), pb = Math.abs(pp - b), pc = Math.abs(pp - c);
            add = pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
          } else if (f !== 0) throw new Error("bad filter");
          line[i] = (line[i] + add) & 255;
        }
        for (let x = 0; x < width; x++) {
          const o = (y * width + x) * 4, s = x * ch;
          if (colorType === 6) { out[o] = line[s]; out[o + 1] = line[s + 1]; out[o + 2] = line[s + 2]; out[o + 3] = line[s + 3]; }
          else if (colorType === 2) { out[o] = line[s]; out[o + 1] = line[s + 1]; out[o + 2] = line[s + 2]; out[o + 3] = 255; }
          else if (colorType === 0) { out[o] = out[o + 1] = out[o + 2] = line[s]; out[o + 3] = 255; }
          else { out[o] = out[o + 1] = out[o + 2] = line[s]; out[o + 3] = line[s + 1]; }
        }
        prev = line;
      }
      return out;
    },
  };
}

export function readWebpSize(buf) {
  if (buf.toString("latin1", 0, 4) !== "RIFF" || buf.toString("latin1", 8, 12) !== "WEBP") throw new Error("not webp");
  const t = buf.toString("latin1", 12, 16);
  if (t === "VP8 ") return { width: buf.readUInt16LE(26) & 0x3fff, height: buf.readUInt16LE(28) & 0x3fff };
  if (t === "VP8L") { const b = buf.readUInt32LE(21); return { width: (b & 0x3fff) + 1, height: ((b >> 14) & 0x3fff) + 1 }; }
  if (t === "VP8X") return { width: buf.readUIntLE(24, 3) + 1, height: buf.readUIntLE(27, 3) + 1 };
  throw new Error("unknown webp chunk " + t);
}

export function readIco(buf) {
  const n = buf.readUInt16LE(4), out = [];
  for (let i = 0; i < n; i++) {
    const o = 6 + i * 16, size = buf.readUInt32LE(o + 8), off = buf.readUInt32LE(o + 12);
    out.push({ width: buf[o] || 256, height: buf[o + 1] || 256, bytes: buf.subarray(off, off + size) });
  }
  return out;
}

export function writeIco(pngs) {
  const head = Buffer.alloc(6 + 16 * pngs.length);
  head.writeUInt16LE(1, 2); head.writeUInt16LE(pngs.length, 4);
  let off = head.length;
  pngs.forEach((p, i) => {
    const o = 6 + i * 16, w = p.readUInt32BE(16), h = p.readUInt32BE(20);
    head[o] = w >= 256 ? 0 : w; head[o + 1] = h >= 256 ? 0 : h;
    head.writeUInt16LE(1, o + 4); head.writeUInt16LE(32, o + 6);
    head.writeUInt32LE(p.length, o + 8); head.writeUInt32LE(off, o + 12);
    off += p.length;
  });
  return Buffer.concat([head, ...pngs]);
}

// isInk(r,g,b,a) marks pixels that must lie inside the circle; worst = largest ink radius.
export function insideCircle(rgba, w, h, cx, cy, r, isInk) {
  let worst = 0;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const o = (y * w + x) * 4;
    if (!isInk(rgba[o], rgba[o + 1], rgba[o + 2], rgba[o + 3])) continue;
    const d = Math.hypot(x + 0.5 - cx, y + 0.5 - cy);
    if (d > worst) worst = d;
  }
  return { ok: worst <= r, worst };
}

export { deflateSync, crc32 };
