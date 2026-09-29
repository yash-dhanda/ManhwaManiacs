// 16-bit PCM WAV read/write, peak and RMS, and the equal-power loop cross-fade (stdlib only).
// Used by synth.mjs, render.mjs, trim-loop.mjs and check.mjs.

/** Parse a 16-bit PCM WAV (plain or WAVE_FORMAT_EXTENSIBLE). Samples are floats in [-1, 1). */
export function readWav(buf) {
  if (buf.toString("ascii", 0, 4) !== "RIFF" || buf.toString("ascii", 8, 12) !== "WAVE") throw new Error("not a RIFF/WAVE file");
  let fmt = null, data = null;
  for (let p = 12; p + 8 <= buf.length; ) {
    const id = buf.toString("ascii", p, p + 4), len = buf.readUInt32LE(p + 4);
    if (id === "fmt ") fmt = { tag: buf.readUInt16LE(p + 8), channels: buf.readUInt16LE(p + 10), rate: buf.readUInt32LE(p + 12), bits: buf.readUInt16LE(p + 22) };
    if (id === "data") data = { off: p + 8, len: Math.min(len, buf.length - p - 8) };
    p += 8 + len + (len & 1);
  }
  if (!fmt || !data) throw new Error("WAV without fmt or data chunk");
  if ((fmt.tag !== 1 && fmt.tag !== 0xfffe) || fmt.bits !== 16) throw new Error(`only 16-bit PCM is supported (tag ${fmt.tag}, ${fmt.bits} bits)`);
  const { channels, rate, bits } = fmt;
  const frames = Math.floor(data.len / (2 * channels));
  const samples = Array.from({ length: channels }, () => new Float32Array(frames));
  for (let i = 0, o = data.off; i < frames; i++) for (let c = 0; c < channels; c++, o += 2) samples[c][i] = buf.readInt16LE(o) / 32768;
  return { rate, channels, bits, frames, samples };
}

/** 16-bit PCM WAV, no dither: round to nearest, clamp. `channels` defaults to samples.length. */
export function writeWav({ rate, channels = undefined, samples }) {
  const ch = channels ?? samples.length, frames = samples[0].length;
  const buf = Buffer.alloc(44 + frames * ch * 2);
  buf.write("RIFF", 0, "ascii"); buf.writeUInt32LE(36 + frames * ch * 2, 4); buf.write("WAVE", 8, "ascii");
  buf.write("fmt ", 12, "ascii"); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(ch, 22);
  buf.writeUInt32LE(rate, 24); buf.writeUInt32LE(rate * ch * 2, 28); buf.writeUInt16LE(ch * 2, 32); buf.writeUInt16LE(16, 34);
  buf.write("data", 36, "ascii"); buf.writeUInt32LE(frames * ch * 2, 40);
  for (let i = 0, o = 44; i < frames; i++) for (let c = 0; c < ch; c++, o += 2) {
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(samples[c][i] * 32768))), o);
  }
  return buf;
}

const asChannels = (s) => (ArrayBuffer.isView(s) ? [s] : s);

/** Sample peak in dBFS over all channels (-Infinity for silence). */
export function peakDbfs(samples) {
  let m = 0;
  for (const ch of asChannels(samples)) for (const v of ch) if (Math.abs(v) > m) m = Math.abs(v);
  return 20 * Math.log10(m);
}

/** RMS in dB over frames [from, to) of all channels together. */
export function rmsDb(samples, from = 0, to = undefined) {
  const chs = asChannels(samples), end = to ?? chs[0].length;
  let sum = 0, n = 0;
  for (const ch of chs) for (let i = from; i < end; i++) { sum += ch[i] * ch[i]; n++; }
  return n ? 10 * Math.log10(sum / n) : -Infinity;
}

/**
 * The seamless loop: keep `loopSec` of a longer render and cross-fade the render's
 * frames [loop, loop + fade) into the first `fadeSec` with an equal-power (sin/cos) curve.
 * The loop's first frame is then the render's frame `loop`, which follows its last frame.
 */
export function makeLoop(channels, rate, loopSec = 90, fadeSec = 6) {
  const n = Math.round(loopSec * rate), f = Math.round(fadeSec * rate);
  return channels.map((x) => {
    if (x.length < n + f) throw new Error(`loop needs ${n + f} frames, got ${x.length}`);
    const y = Float64Array.from(x.subarray(0, n));
    for (let i = 0; i < f; i++) {
      const t = (Math.PI / 2) * (i / f);
      y[i] = x[i] * Math.sin(t) + x[n + i] * Math.cos(t);
    }
    return y;
  });
}
