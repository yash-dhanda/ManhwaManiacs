// Font paths: Bodoni Moda from brand/fonts (shared/02); Archivo cached from a pinned google/fonts commit.
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const brand = join(dirname(fileURLToPath(import.meta.url)), "..");
const LOCAL = {
  bodoni: "fonts/BodoniModa[opsz,wght].ttf",
  "bodoni-italic": "fonts/BodoniModa-Italic[opsz,wght].ttf",
  "bodoni-ofl": "fonts/OFL-BodoniModa.txt",
};
const BASE = "https://raw.githubusercontent.com/google/fonts/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/";
const REMOTE = {
  archivo: "ofl/archivo/Archivo[wdth,wght].ttf",
  "archivo-ofl": "ofl/archivo/OFL.txt",
  gsf: "ofl/googlesansflex/GoogleSansFlex[GRAD,ROND,opsz,slnt,wdth,wght].ttf",
  "gsf-ofl": "ofl/googlesansflex/OFL.txt",
};
const enc = (p) => p.replace(/\[/g, "%5B").replace(/,/g, "%2C").replace(/\]/g, "%5D");

export async function fontPath(id) {
  if (LOCAL[id]) {
    const p = join(brand, LOCAL[id]);
    if (!existsSync(p)) throw new Error(`missing ${p}: shared/02 is incomplete`);
    return p;
  }
  if (!REMOTE[id]) throw new Error(`unknown font id ${id}`);
  const dest = join(brand, ".cache/fonts", REMOTE[id].split("/").pop());
  if (!existsSync(dest)) {
    const r = await fetch(BASE + enc(REMOTE[id]));
    if (!r.ok) throw new Error(`fetch ${id}: ${r.status}`);
    mkdirSync(dirname(dest), { recursive: true });
    writeFileSync(dest, Buffer.from(await r.arrayBuffer()));
  }
  return dest;
}
