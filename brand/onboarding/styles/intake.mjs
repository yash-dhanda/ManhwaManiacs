#!/usr/bin/env node
// Turns delivered masters into the sized WebP files. `--check` names everything still missing (exit 1) and needs only stdlib.
//   node brand/onboarding/styles/intake.mjs [--check]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readWebpSize } from "../../lib/img.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../../..");
const IDS = ["painted", "cel", "screentone", "manhua-3d", "watercolour", "sketch", "retro", "pastel", "noir", "chibi", "dark-realism"];
const GLASS = ["painted", "cel", "screentone", "manhua-3d", "watercolour", "sketch", "retro", "chibi", "dark-realism"];
const CINE = ["painted", "cel", "screentone", "manhua-3d", "sketch", "retro", "pastel", "noir", "chibi"];
const nn = (list, id) => String(list.indexOf(id) + 1).padStart(2, "0");
const GLASS_DIRS = ["brand/onboarding/styles", "frontend/public/onboarding/styles/glass", "mobile/assets/onboarding/styles/glass"];
const CINE_DIRS = ["frontend/public/onboarding/styles", "mobile/assets/onboarding/styles"];
const master = (id) => path.join(HERE, "masters", `${id}.png`);
const abs = (...p) => path.join(ROOT, ...p);

function licenceRows() {
  const rows = {};
  const f = path.join(HERE, "LICENSE.md");
  if (!fs.existsSync(f)) return rows;
  for (const line of fs.readFileSync(f, "utf8").split("\n")) {
    const c = line.split("|").slice(1, -1).map((s) => s.trim());
    if (c.length === 6 && IDS.includes(c[0])) rows[c[0]] = { artist: c[1], date: c[2], licence: c[3], source: c[4], notes: c[5] };
  }
  return rows;
}
const complete = (r) => !!r && !!r.artist && /^\d{4}-\d{2}-\d{2}$/.test(r.date) && r.licence === "CC0-1.0" && !!r.source;
const drawn = (r) => r && (r.source === "own work" || r.source === "commission");

// [dir, file, px, budget, id, skin]
function outputs(rows) {
  const out = [];
  for (const id of GLASS) for (const d of GLASS_DIRS) out.push([d, `${nn(GLASS, id)}-${id}.webp`, 320, 40000, id, "Glass"]);
  for (const id of CINE) if (drawn(rows[id])) for (const d of CINE_DIRS) out.push([d, `${nn(CINE, id)}-${id}.webp`, 600, 60000, id, "Cinematic"]);
  return out;
}
const skins = (id) => [GLASS.includes(id) && `Glass ${nn(GLASS, id)}`, CINE.includes(id) && `Cinematic ${nn(CINE, id)}`].filter(Boolean).join(", ");

function check() {
  const rows = licenceRows();
  const problems = [];
  let missing = 0;
  for (const id of IDS) {
    if (!fs.existsSync(master(id))) { missing++; problems.push(`missing brand/onboarding/styles/masters/${id}.png (${skins(id)})`); continue; }
    if (!complete(rows[id])) problems.push(`LICENSE.md row incomplete for ${id}`);
    else if (!drawn(rows[id]) && CINE.includes(id)) problems.push(`Cinematic needs drawn art for ${id}`);
  }
  for (const [d, f, px, budget, id, skin] of outputs(rows)) {
    if (!fs.existsSync(master(id))) continue;
    const p = abs(d, f);
    if (!fs.existsSync(p)) { problems.push(`missing output ${d}/${f}`); continue; }
    const b = fs.readFileSync(p), s = readWebpSize(b);
    if (s.width !== px || s.height !== px) problems.push(`${d}/${f} is ${s.width}x${s.height}, want ${px}`);
    if (b.length > budget) problems.push(`${d}/${f} is ${b.length} bytes, over ${budget} (${skin})`);
  }
  for (const p of problems) console.log(p);
  console.log(`art intake: ${missing} of ${IDS.length} masters missing`);
  process.exit(problems.length ? 1 : 0);
}

async function run() {
  const { default: sharp } = await import(path.join(ROOT, "brand/node_modules/sharp/lib/index.js"));
  const rows = licenceRows();
  const licence = fs.readFileSync(path.join(HERE, "LICENSE.md"), "utf8");
  const dirs = new Set();
  for (const id of IDS) {
    if (!fs.existsSync(master(id))) continue;
    if (!complete(rows[id])) { console.log(`skip ${id}: LICENSE.md row incomplete`); continue; }
    const src = await sharp(master(id)).rotate().toColourspace("srgb").toBuffer();
    const meta = await sharp(src).metadata();
    const side = Math.min(meta.width, meta.height);
    if (side < 600) { console.log(`skip ${id}: master is ${meta.width}x${meta.height}, minimum 600`); continue; }
    const crop = await sharp(src).extract({ left: Math.floor((meta.width - side) / 2), top: Math.floor((meta.height - side) / 2), width: side, height: side }).toBuffer();
    for (const [d, f, px, budget] of outputs({ [id]: rows[id] }).filter((o) => o[4] === id)) {
      let q = 80, buf;
      for (;;) {
        buf = await sharp(crop).resize(px, px, { kernel: "lanczos3" }).webp({ quality: q, effort: 6 }).toBuffer();
        if (buf.length <= budget) break;
        if (q <= 50) { console.error(`${d}/${f} does not fit ${budget} bytes at quality 50`); process.exit(1); }
        q -= 5;
      }
      fs.mkdirSync(abs(d), { recursive: true });
      fs.writeFileSync(abs(d, f), buf);
      dirs.add(d);
      console.log(`wrote ${d}/${f} (${buf.length} bytes, q${q})`);
    }
    if (!drawn(rows[id]) && CINE.includes(id)) // Decision 12: generated drafts never reach Cinematic
      for (const d of CINE_DIRS) fs.rmSync(abs(d, `${nn(CINE, id)}-${id}.webp`), { force: true });
  }
  for (const d of dirs) if (d !== "brand/onboarding/styles") fs.writeFileSync(abs(d, "LICENSE.md"), licence);
}

if (process.argv.includes("--check")) check();
else await run();
