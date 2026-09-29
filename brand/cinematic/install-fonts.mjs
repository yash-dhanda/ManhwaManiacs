// Self-hosted install-page fonts: latin + latin-ext subsets from Google Fonts CSS2 into backend/media/fonts/.
import { createHash } from "node:crypto";
import { copyFileSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { fontPath } from "../lib/fonts.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");
const dir = join(root, "backend/media/fonts");
const CSS = "https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..100,400..800&family=Bodoni+Moda:ital,opsz,wght@0,6..96,400..900;1,6..96,400..900&display=swap";
const UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";
const AXES = { "Bodoni Moda": { opsz: [6, 96], wght: [400, 900] }, Archivo: { wdth: [62, 100], wght: [400, 800] } };

mkdirSync(dir, { recursive: true });
const css = await (await fetch(CSS, { headers: { "User-Agent": UA } })).text();
const entries = [];
for (const m of css.matchAll(/\/\*\s*([\w-]+)\s*\*\/\s*@font-face\s*\{([^}]*)\}/g)) {
  const [, subset, body] = m;
  if (subset !== "latin" && subset !== "latin-ext") continue;
  const family = body.match(/font-family:\s*'([^']+)'/)[1];
  const style = body.match(/font-style:\s*(\w+)/)[1];
  const src = body.match(/url\(([^)]+)\)/)[1];
  const unicodeRange = body.match(/unicode-range:\s*([^;]+);/)[1];
  const file = `${family === "Archivo" ? "archivo" : "bodoni-moda"}${style === "italic" ? "-italic" : ""}-${subset}.woff2`;
  const buf = Buffer.from(await (await fetch(src)).arrayBuffer());
  writeFileSync(join(dir, file), buf);
  entries.push({ file, family, style, subset, unicodeRange, axes: AXES[family], src, css: CSS, sha256: createHash("sha256").update(buf).digest("hex") });
}
entries.sort((a, b) => (a.file < b.file ? -1 : 1));
if (entries.length !== 6) throw new Error(`expected 6 font files, got ${entries.length}`);
writeFileSync(join(dir, "fonts.json"), JSON.stringify(entries, null, 1) + "\n");
copyFileSync(await fontPath("bodoni-ofl"), join(dir, "OFL-BodoniModa.txt"));
copyFileSync(await fontPath("archivo-ofl"), join(dir, "OFL-Archivo.txt"));
console.log(entries.map((e) => e.file).join("\n"));
