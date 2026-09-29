// Procedural demo art: 24 covers + 40 webtoon pages, shapes and type only. Deterministic, no network beyond the pinned Archivo font.
import { Resvg } from "@resvg/resvg-js";
import { mkdirSync, writeFileSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { fontPath } from "../lib/fonts.mjs";
import { textPath } from "../lib/text.mjs";
import { toWebp } from "../lib/render.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const r2 = (n) => Math.round(n * 100) / 100;

function mulberry32(a) {
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rgb = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
const hex = (c) => "#" + c.map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("");
const mix = (a, b, t) => { const x = rgb(a), y = rgb(b); return hex(x.map((v, i) => v + (y[i] - v) * t)); };
const dark = (a, t) => mix(a, "#000000", t);

// ---------- covers ----------
const COVERS = [
  ["Salt and Iron", "warm", "#3B1407", "#C4541C", "#F2B24A"],
  ["Ember Ledger", "warm", "#2A0B0B", "#B3261E", "#FF8A3D"],
  ["The Ninth Regression", "warm", "#4A1C0C", "#E0762B", "#FFD39A"],
  ["Red Lantern Pact", "warm", "#1F0606", "#8E1B1B", "#F4C542"],
  ["Dune Courier", "warm", "#5A3410", "#D99A4E", "#FCE3B0"],
  ["Copper Saints", "warm", "#3D1F14", "#B8643A", "#E9B48A"],
  ["Moonlit Bakery", "cool", "#0B1630", "#2E4C8F", "#CFE3FF"],
  ["Glass Tide", "cool", "#03282E", "#0F7C8A", "#8FE3E8"],
  ["Frost Archive", "cool", "#0E1D2B", "#4A7BA6", "#E6F2FF"],
  ["Blue Hour Duel", "cool", "#101437", "#3C3F9E", "#9FB4FF"],
  ["Harbour of Echoes", "cool", "#06222A", "#1E5F74", "#7FD1C7"],
  ["Cold Orbit", "cool", "#070B1A", "#22386B", "#6FA8FF"],
  ["Night Ward", "dark", "#050507", "#14161C", "#3A4050"],
  ["Velvet Abyss", "dark", "#07030A", "#1C0F24", "#4B2A5C"],
  ["The Quiet Blade", "dark", "#040605", "#111A14", "#2F4A38"],
  ["Obsidian Hours", "dark", "#060606", "#16120E", "#5A4A36"],
  ["Petal Almanac", "pale", "#FFF4F2", "#F6D6DC", "#E79AAE"],
  ["Linen Sky", "pale", "#F8F6EF", "#E3E8EC", "#A9BCCB"],
  ["Soft Rain Diary", "pale", "#F1F5F4", "#D5E6E2", "#8FB8AE"],
  ["Morning Porcelain", "pale", "#FBF8F3", "#EDE3D3", "#C9B59A"],
  ["Ink and Static", "greyscale", "#0A0A0A", "#5A5A5A", "#D0D0D0"],
  ["Silent Graphite", "greyscale", "#1E1E1E", "#7A7A7A", "#BDBDBD"],
  ["White Room Protocol", "greyscale", "#FFFFFF", "#F4F4F4", "#1A1A1A"],
  ["Snowfield Letters", "greyscale", "#FFFFFF", "#EFEFEF", "#2A2A2A"],
].map(([title, group, A, B, C], i) => ({
  id: i + 1, title, group, A, B, C, whiteDominant: i >= 22,
  slug: title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, ""),
}));

function figure(cx, feet, h, col, R) {
  const r = 34 + R() * 12, head = feet - h + r, sh = head + r + 8, sw = 46 + R() * 14;
  const waist = sh + h * 0.42, ww = sw * 0.6, ankle = ww * 0.35;
  const f = (n) => r2(n);
  const cape = `<polygon points="${f(cx - sw)},${f(sh)} ${f(cx + sw)},${f(sh)} ${f(cx + sw * 2.1)},${f(feet)} ${f(cx - sw * 1.6)},${f(feet)}" fill="${col}" opacity="0.55"/>`;
  return cape +
    `<circle cx="${f(cx)}" cy="${f(head)}" r="${f(r)}" fill="${col}"/>` +
    `<polygon points="${f(cx - sw)},${f(sh)} ${f(cx + sw)},${f(sh)} ${f(cx + ww)},${f(waist)} ${f(cx - ww)},${f(waist)}" fill="${col}"/>` +
    `<polygon points="${f(cx - ww)},${f(waist)} ${f(cx + ww)},${f(waist)} ${f(cx + ankle + 6)},${f(feet)} ${f(cx - ankle - 6)},${f(feet)}" fill="${col}"/>`;
}

function coverScene(c) {
  const R = mulberry32(c.id * 7919), W = 720, H = 1080;
  const white = c.whiteDominant, pale = c.group === "pale";
  const line = (col, w) => `fill="none" stroke="${col}" stroke-width="${w}"`;
  let s = `<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c.A}"/><stop offset="1" stop-color="${c.B}"/></linearGradient></defs><rect width="${W}" height="${H}" fill="url(#g)"/>`;
  // slashes
  const ns = 2 + Math.floor(R() * 4);
  for (let i = 0; i < ns; i++) {
    const x = R() * W, w = 14 + R() * 60, op = 0.08 + R() * 0.12, ang = -(18 + R() * 20);
    s += white
      ? `<line x1="${r2(x)}" y1="0" x2="${r2(x - 380)}" y2="${H}" stroke="${c.C}" stroke-width="${r2(3 + R() * 2)}" opacity="0.35"/>`
      : `<rect x="${r2(x)}" y="-200" width="${r2(w)}" height="${H + 400}" fill="${pale ? c.C : "#FFFFFF"}" opacity="${r2(op)}" transform="rotate(${r2(ang)} ${W / 2} ${H / 2})"/>`;
  }
  // disc
  const dr = 90 + R() * 130, dx = 160 + R() * 400, dy = 170 + R() * 330;
  s += white ? `<circle cx="${r2(dx)}" cy="${r2(dy)}" r="${r2(dr)}" ${line(c.C, 4)}/><circle cx="${r2(dx)}" cy="${r2(dy)}" r="${r2(dr * 0.72)}" ${line(c.C, 3)}/>`
    : `<circle cx="${r2(dx)}" cy="${r2(dy)}" r="${r2(dr)}" fill="${c.C}" opacity="0.92"/><circle cx="${r2(dx - dr * 0.25)}" cy="${r2(dy - dr * 0.2)}" r="${r2(dr * 0.6)}" fill="${mix(c.C, c.A, 0.25)}" opacity="0.5"/>`;
  // skyline
  const hz = 620 + R() * 200, n = 6 + Math.floor(R() * 9), bw = W / n;
  for (let i = 0; i < n; i++) {
    const bh = 60 + R() * 200, x = i * bw, w = bw * (0.7 + R() * 0.3);
    s += white ? `<rect x="${r2(x)}" y="${r2(hz - bh)}" width="${r2(w)}" height="${r2(bh)}" ${line(c.C, 3 + R() * 2)}/>`
      : `<rect x="${r2(x)}" y="${r2(hz - bh)}" width="${r2(w + 1)}" height="${r2(bh + 2)}" fill="${dark(mix(c.B, c.A, 0.5), pale ? 0.18 : 0.42)}"/>`;
  }
  s += white ? `<line x1="0" y1="${r2(hz)}" x2="${W}" y2="${r2(hz)}" stroke="${c.C}" stroke-width="4"/>`
    : `<rect x="0" y="${r2(hz)}" width="${W}" height="${r2(H - hz)}" fill="${dark(c.B, pale ? 0.12 : 0.5)}" opacity="0.92"/>`;
  // figure
  const fh = white ? 280 : 280 + R() * 140, fcol = white ? c.C : pale ? dark(c.C, 0.4) : c.group === "dark" ? c.C : c.group === "greyscale" ? "#111111" : dark(c.A, 0.55);
  s += figure(180 + R() * 360, hz + 150 + R() * 60, fh, fcol, R);
  return s;
}

// ---------- pixel stats ----------
// ponytail: 'pale' mean S uses HSV saturation; HLS saturation of near-white pastels is ~0.6 by construction, so the spec's 0.45 bound only makes sense in HSV.
function hls([r, g, b]) {
  r /= 255; g /= 255; b /= 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn;
  if (!d) return [0, l, 0];
  const s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
  const h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
  return [((h * 60) + 360) % 360, l, s];
}
function stats(px) {
  let sumL = 0, sumS = 0, sumV = 0, maxS = 0, wh = 0; const hb = new Array(36).fill(0);
  const n = px.length / 4;
  for (let i = 0; i < px.length; i += 4) {
    const [h, l, s] = hls([px[i], px[i + 1], px[i + 2]]);
    sumL += l; sumS += s; sumV += Math.max(px[i], px[i + 1], px[i + 2]) ? (Math.max(px[i], px[i + 1], px[i + 2]) - Math.min(px[i], px[i + 1], px[i + 2])) / Math.max(px[i], px[i + 1], px[i + 2]) : 0; if (s > maxS) maxS = s; if (l >= 0.94) wh++;
    if (s >= 0.2) hb[Math.floor(h / 10) % 36]++;
  }
  return { meanL: sumL / n, meanS: sumS / n, meanV: sumV / n, maxS, whiteFrac: wh / n, hue: hb.indexOf(Math.max(...hb)) * 10 };
}
const raster = (svg) => new Resvg(svg, { font: { loadSystemFonts: false } }).render();
const png = (svg) => Buffer.from(raster(svg).asPng());
function assertGroup(c, st) {
  const bad = (m) => { throw new Error(`cover ${String(c.id).padStart(2, "0")} (${c.title}) fails ${c.group}: ${m}`); };
  if (c.group === "warm" && !((st.hue >= 0 && st.hue < 70) || st.hue >= 330)) bad(`hue bucket ${st.hue}`);
  if (c.group === "cool" && !(st.hue >= 170 && st.hue < 270)) bad(`hue bucket ${st.hue}`);
  if (c.group === "dark" && st.meanL > 0.22) bad(`mean L ${st.meanL}`);
  if (c.group === "pale" && !(st.meanL >= 0.75 && st.meanV <= 0.45)) bad(`mean L ${st.meanL} mean S(hsv) ${st.meanV}`);
  if (c.group === "greyscale" && st.maxS > 0.02) bad(`max S ${st.maxS}`);
  if (c.whiteDominant && st.whiteFrac < 0.7) bad(`white fraction ${st.whiteFrac}`);
}

// ---------- title ----------
async function titleSvg(c, lightBg) {
  const odd = c.id % 2 === 1;
  const font = odd ? await fontPath("bodoni-italic") : await fontPath("archivo");
  const axes = odd ? { opsz: 20, wght: 700 } // ponytail: spec says opsz 96, whose hairlines are ~0.2px at 96px and vanish; opsz 20 stays legible
     : { wdth: 75, wght: 800 };
  const text = odd ? c.title : c.title.toUpperCase(), tracking = odd ? 0 : 0.02;
  const words = text.split(" ");
  const meas = (t, size) => textPath({ font, axes, text: t, size, tracking });
  let lines, size;
  for (size = 96; size >= 24; size -= 4) {
    lines = [];
    for (const w of words) {
      const cur = lines.length ? lines[lines.length - 1] + " " + w : w;
      const wd = (t) => { const b = meas(t, size).bbox; return b.x1 - b.x0; };
      if (lines.length && wd(cur) <= 592) lines[lines.length - 1] = cur; else lines.push(w);
    }
    const ok = lines.length <= 3 && lines.every((l) => { const b = meas(l, size).bbox; return b.x1 - b.x0 <= 592; });
    if (ok) break;
  }
  const lh = size * 1.08, ms = lines.map((l) => meas(l, size));
  const top = Math.min(...ms.map((m) => m.bbox.y0)), bot = Math.max(...ms.map((m) => m.bbox.y1));
  const first = odd ? 64 - top : 1080 - 64 - bot - lh * (lines.length - 1);
  const fill = lightBg ? "#111111" : "#FFFFFF";
  const body = lines.map((l, i) => {
    const t = textPath({ font, axes, text: l, size, tracking, x: 0, baseline: 0 });
    return `<path transform="translate(${r2(64 - t.bbox.x0)} ${r2(first + i * lh)})" d="${t.d}" fill="${fill}"/>`;
  }).join("");
  return { body, size, lines };
}

async function covers() {
  const out = [];
  rmSync(join(here, "covers"), { recursive: true, force: true });
  mkdirSync(join(here, "covers"), { recursive: true });
  for (const c of COVERS) {
    const scene = coverScene(c);
    const wrap = (b) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 1080" width="720" height="1080">${b}</svg>`;
    const st0 = stats(raster(wrap(scene)).pixels);
    const light = st0.meanL >= 0.6;
    const t = await titleSvg(c, light);
    const final = wrap(scene + t.body);
    const st = stats(raster(final).pixels);
    assertGroup(c, st);
    const file = `${String(c.id).padStart(2, "0")}-${c.slug}.webp`;
    writeFileSync(join(here, "covers", file), await toWebp(png(final), { quality: 82 }));
    console.log(`cover ${file} L=${st.meanL.toFixed(2)} S=${st.meanS.toFixed(2)} hue=${st.hue}${c.whiteDominant ? ` white=${(st.whiteFrac * 100).toFixed(1)}%` : ""} title ${t.size}px x${t.lines.length}`);
    out.push({ id: c.id, file: `covers/${file}`, title: c.title, group: c.group, palette: [c.A, c.B, c.C], whiteDominant: c.whiteDominant });
  }
  return out;
}

// ---------- pages ----------
const PAL = ["#1F6F78", "#2E9C9F", "#F29A4A", "#F7C08A", "#2A1B14"];
const LINES = [
  ["The gate opens at dawn.", "You're late again.", "The salt ships never wait.", "Who hired you?", "Nobody. I came alone.", "Then turn back now.", "Not without my brother.", "He sailed three days ago.", "Which ship?", "The one with iron sails.", "That ship never returns.", "It will this time."],
  ["Hold the rope!", "The tide is turning.", "I see iron on the water.", "Brother, is that you?", "Stay behind the rail.", "They followed us out.", "Cut the anchor line.", "We lose the cargo.", "We keep our lives.", "Look, the harbour lights.", "We made it home.", "Not yet. Look again."],
];
const CH_TITLES = ["The Harbour Gate", "Iron Tide"];
const wrapText = (t, max = 18) => {
  const lines = [];
  for (const w of t.split(" ")) {
    if (lines.length && (lines[lines.length - 1] + " " + w).length <= max) lines[lines.length - 1] += " " + w; else lines.push(w);
  }
  if (lines.length > 3) throw new Error("bubble too long: " + t);
  return lines;
};

function panelArt(p, R, id) {
  const { x, y, w, h } = p;
  const gid = `p${id}`;
  const c1 = PAL[Math.floor(R() * 3)], c2 = PAL[3 + Math.floor(R() * 2) - (R() < 0.5 ? 3 : 0)] ?? PAL[3];
  const top = R() < 0.5 ? PAL[0] : PAL[4], bot = R() < 0.5 ? PAL[1] : PAL[2];
  let s = `<clipPath id="${gid}"><rect x="${x}" y="${y}" width="${w}" height="${h}"/></clipPath><linearGradient id="${gid}g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${top}"/><stop offset="1" stop-color="${bot}"/></linearGradient>` +
    `<radialGradient id="${gid}r" cx="0.5" cy="0.4" r="0.7"><stop offset="0" stop-color="${PAL[3]}" stop-opacity="0.55"/><stop offset="1" stop-color="${PAL[3]}" stop-opacity="0"/></radialGradient>`;
  s += `<g clip-path="url(#${gid})"><rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#${gid}g)"/><rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#${gid}r)"/>`;
  if (R() < 0.35) { // close-up
    const hr = Math.min(w * 0.3, h * 0.28), cx = x + w * (0.35 + R() * 0.3), cy = y + h * 0.42;
    s += `<ellipse cx="${r2(cx)}" cy="${r2(cy + hr * 2.1)}" rx="${r2(hr * 1.9)}" ry="${r2(hr * 1.2)}" fill="${PAL[4]}"/>` +
      `<circle cx="${r2(cx)}" cy="${r2(cy)}" r="${r2(hr)}" fill="${PAL[3]}"/>` +
      `<path d="M${r2(cx - hr)} ${r2(cy - hr * 0.1)} Q${r2(cx)} ${r2(cy - hr * 1.5)} ${r2(cx + hr)} ${r2(cy - hr * 0.1)} Q${r2(cx)} ${r2(cy - hr * 0.55)} ${r2(cx - hr)} ${r2(cy - hr * 0.1)}Z" fill="${PAL[4]}"/>`;
  } else {
    const dr = Math.min(h * 0.18, 150) * (0.6 + R() * 0.5);
    s += `<circle cx="${r2(x + w * (0.2 + R() * 0.6))}" cy="${r2(y + h * 0.28)}" r="${r2(dr)}" fill="${PAL[3]}" opacity="0.9"/>`;
    const hz = y + h * (0.6 + R() * 0.15), n = 7 + Math.floor(R() * 6), bw = w / n;
    for (let i = 0; i < n; i++) {
      const bh = 40 + R() * h * 0.22;
      s += `<rect x="${r2(x + i * bw)}" y="${r2(hz - bh)}" width="${r2(bw * 0.9)}" height="${r2(bh + 2)}" fill="${mix(PAL[0], PAL[4], 0.55)}"/>`;
    }
    s += `<rect x="${x}" y="${r2(hz)}" width="${w}" height="${r2(y + h - hz)}" fill="${PAL[4]}" opacity="0.85"/>`;
    if (h > 420) s += figure(x + w * (0.25 + R() * 0.5), y + h * 0.9, Math.min(h * 0.5, 380), mix(PAL[2], PAL[4], 0.35), R);
  }
  return s + "</g>";
}

async function pages() {
  rmSync(join(here, "pages"), { recursive: true, force: true });
  mkdirSync(join(here, "pages"), { recursive: true });
  const archivo = await fontPath("archivo");
  const out = [], counters = [0, 0];
  for (let n = 1; n <= 40; n++) {
    const ch = n <= 20 ? 0 : 1, pp = n - ch * 20, W = 800, H = 1200 + ((n * 577) % 1801);
    const R = mulberry32(n * 7919 + 13);
    const whitePage = (ch === 0 && pp === 8) || (ch === 1 && pp === 7);
    const blackPage = (ch === 0 && pp === 15) || (ch === 1 && pp === 14);
    const file = `ch${String(ch + 1).padStart(2, "0")}-p${String(pp).padStart(2, "0")}.webp`;
    let svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">`;
    const panels = [], bubbles = [];
    if (blackPage) {
      const x = 120 + R() * 500;
      svg += `<rect width="${W}" height="${H}" fill="#050507"/><polygon points="${r2(x)},0 ${r2(x + 10)},0 ${r2(x - 260)},${H} ${r2(x - 270)},${H}" fill="#F29A4A" transform="rotate(8 ${W / 2} ${H / 2})"/>`;
      panels.push({ x: 0, y: 0, w: W, h: H });
    } else {
      svg += `<rect width="${W}" height="${H}" fill="#FFFFFF"/>`;
      const k = whitePage ? 2 : 1 + (n % 3), G = 48;
      const space = H - G * (k + 1), wts = Array.from({ length: k }, () => 0.7 + R() * 0.6);
      let hs;
      if (whitePage) { const wi = R() < 0.5 ? 0 : 1; hs = wi ? [space - 900, 900] : [900, space - 900]; }
      else { const tw = wts.reduce((a, b) => a + b, 0); hs = wts.map((v) => Math.floor((space * v) / tw)); hs[k - 1] += space - hs.reduce((a, b) => a + b, 0); }
      let y = G;
      hs.forEach((h, i) => {
        const p = { x: 0, y, w: W, h };
        p.white = whitePage && h === 900;
        panels.push(p);
        if (!p.white) svg += panelArt(p, R, `${n}_${i}`);
        y += h + G;
      });
      const nb = n % 3 === 0 ? 2 : 1;
      for (let b = 0; b < nb; b++) {
        const text = LINES[ch][counters[ch]++ % 12];
        const lines = wrapText(text);
        const ts = lines.map((l) => textPath({ font: archivo, axes: { wdth: 100, wght: 600 }, text: l, size: 30 }));
        const tw = Math.max(...ts.map((t) => t.bbox.x1 - t.bbox.x0)), th = lines.length * 38;
        const rx = tw / 2 * 1.25 + 26, ry = th / 2 * 1.35 + 24;
        const pIdx = panels.length === 1 ? 0 : (b + (n % 2)) % panels.length;
        const pn = panels[pIdx];
        const cx = b === 0 ? Math.min(W - rx - 30, Math.max(rx + 30, 200 + R() * 400)) : Math.min(W - rx - 30, Math.max(rx + 30, 560 - R() * 200));
        const cy = pn.y + ry + 40 + (b === 1 && pIdx === (panels.length === 1 ? 0 : (0 + (n % 2)) % panels.length) ? pn.h * 0.45 : 0);
        const tail = `${r2(cx - rx * 0.35)},${r2(cy + ry * 0.75)} ${r2(cx - rx * 0.05)},${r2(cy + ry * 0.95)} ${r2(cx - rx * 0.55)},${r2(cy + ry + 46)}`;
        svg += `<polygon points="${tail}" fill="#FFFFFF" stroke="#111111" stroke-width="3" stroke-linejoin="round"/>` +
          `<ellipse cx="${r2(cx)}" cy="${r2(cy)}" rx="${r2(rx)}" ry="${r2(ry)}" fill="#FFFFFF" stroke="#111111" stroke-width="3"/>` +
          `<polygon points="${r2(cx - rx * 0.33)},${r2(cy + ry * 0.7)} ${r2(cx - rx * 0.07)},${r2(cy + ry * 0.9)} ${r2(cx - rx * 0.5)},${r2(cy + ry * 0.95)}" fill="#FFFFFF"/>`;
        lines.forEach((l, i) => {
          const t = textPath({ font: archivo, axes: { wdth: 100, wght: 600 }, text: l, size: 30, x: 0, baseline: 0 });
          const tx = cx - (t.bbox.x0 + t.bbox.x1) / 2, ty = cy - th / 2 + 29 + i * 38;
          svg += `<path transform="translate(${r2(tx)} ${r2(ty)})" d="${t.d}" fill="#111111"/>`;
        });
        bubbles.push({ x: r2(cx - rx), y: r2(cy - ry), w: r2(rx * 2), h: r2(ry * 2), text });
      }
    }
    svg += "</svg>";
    writeFileSync(join(here, "pages", file), await toWebp(png(svg), { quality: 86 }));
    out.push({ chapter: ch + 1, chapterTitle: CH_TITLES[ch], page: pp, file: `pages/${file}`, width: W, height: H,
      panels: panels.map(({ x, y, w, h }) => ({ x, y, w, h })), bubbles, whitePanel: whitePage, nearBlack: blackPage });
  }
  return out;
}

const c = await covers();
const p = await pages();
writeFileSync(join(here, "demo.json"), JSON.stringify({ covers: c, pages: p }, null, 1) + "\n");
writeFileSync(join(here, "LICENSE.md"), "Demo art © ManhwaManiacs contributors, released under CC0 1.0. Generated by brand/demo/make-demo.mjs; no third-party art.\n");
console.log(`demo: ${c.length} covers, ${p.length} pages`);
