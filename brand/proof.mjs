// node brand/proof.mjs <name> <export manifest.json> : writes docs/redesign/proof/<name>/sheet.html and two screenshots.
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const [name, manifestPath] = process.argv.slice(2);
if (!name || !manifestPath) throw new Error("usage: node brand/proof.mjs <name> <manifest.json>");
const outDir = join(root, "docs/redesign/proof", name);
mkdirSync(outDir, { recursive: true });
const man = JSON.parse(readFileSync(join(root, manifestPath), "utf8")).outputs;
const R = (p) => relative(outDir, join(root, p));
const C = "brand/cinematic/";
const sec = (t, body) => `<section><h2>${t}</h2><div class="row">${body}</div></section>`;
const im = (src, w, extra = "") => `<figure><img src="${R(src)}" width="${w}" style="${extra}"><figcaption>${w}px</figcaption></figure>`;
const onBone = (x) => `<div style="background:#F3F0E8;padding:8px">${x}</div>`;
const covers = readdirSync(join(root, "brand/demo/covers")).sort();
const pages = readdirSync(join(root, "brand/demo/pages")).sort();
const demo = JSON.parse(readFileSync(join(root, "brand/demo/demo.json"), "utf8"));
const stat = ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"].map((d) => `mobile/android/app/src/main/res/drawable-${d}/ic_stat_mm.png`);
const html = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>shared-04 brand proof</title>
<style>body{background:#000;color:#F3F0E8;font:14px system-ui;margin:0;padding:24px}h2{font-size:15px;margin:32px 0 8px;color:#9A978F}.row{display:flex;flex-wrap:wrap;gap:16px;align-items:flex-end}figure{margin:0}figcaption{font-size:11px;color:#7A7770}img{display:block;max-width:100%}.g{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}.g img{width:100%}.mask{border-radius:22.37%;overflow:hidden}</style>
<h1>Cinematic brand proof (${name})</h1>
${sec("Monogram on black", [1024, 256, 60, 44, 24, 16].map((w) => im(`${C}monogram.svg`, w > 400 ? 400 : w)).join(""))}
${sec("Monogram-small on bone and black at small sizes", [60, 44, 24, 16].map((w) => onBone(im(`${C}monogram-small.svg`, w))).join("") + [60, 44, 24, 16].map((w) => im(`${C}monogram-small.svg`, w)).join(""))}
${sec("Single-colour versions", ["monogram-bone-on-black", "monogram-black-on-bone", "monogram-mono"].map((n) => im(`${C}${n}.svg`, 160, n.includes("mono") ? "background:#444" : "")).join(""))}
${sec("Wordmark 1x, 96 px minimum, and lockups", im(`${C}wordmark.svg`, 640) + im(`${C}wordmark.svg`, 96) + im(`${C}lockup-stacked.svg`, 320) + onBone(im(`${C}wordmark-black.svg`, 320)) + im(`${C}wordmark-mono.svg`, 320))}
${sec("Wordmark a-M joint at 400 %", `<div style="width:520px;height:240px;overflow:hidden;position:relative"><img src="${R(C + "wordmark.svg")}" style="position:absolute;width:9600px;max-width:none;left:-4800px;top:0px"></div>`)}
${sec("Favicon at 16 and 32 on white and #202124", [["#fff", 16], ["#fff", 32], ["#202124", 16], ["#202124", 32]].map(([b, w]) => `<div style="background:${b};padding:8px">${im("frontend/public/favicon.svg", w)}</div>`).join(""))}
${sec("iOS icon under a 22.37 % mask, 60 and 180", [60, 180].map((w) => `<div class="mask" style="width:${w}px">${im(C + "export/icon-ios-1024.png", w)}</div>`).join("") + [60, 180].map((w) => `<div class="mask" style="width:${w}px;background:#333">${im(C + "export/icon-ios-dark-1024.png", w)}</div>`).join("") + im(C + "export/icon-ios-tinted-1024.png", 180))}
${sec("Android foreground with the 66 dp circle; monochrome themed", `<div style="position:relative;background:#000;width:216px;height:216px">${im(C + "export/android-foreground-1024.png", 216)}<div style="position:absolute;inset:0;margin:auto;width:141px;height:141px;border:1px solid #f0f;border-radius:50%;top:0;bottom:0;left:0;right:0"></div></div><div style="background:#1F1F1F;padding:8px;width:216px;height:216px"><div style="background:#A8C7FA;-webkit-mask:url(${R(C + "export/android-monochrome-1024.png")}) center/216px;mask:url(${R(C + "export/android-monochrome-1024.png")}) center/216px;width:216px;height:216px"></div></div>` + im("frontend/public/icons/maskable-512.png", 216))}
${sec("ic_stat_mm on black and on yellow", stat.map((s) => `<div style="background:#000;padding:6px">${im(s, [24, 36, 48, 72, 96][stat.indexOf(s)])}</div>`).join("") + stat.map((s) => `<div style="background:#F4D03F;padding:6px">${im(s, [24, 36, 48, 72, 96][stat.indexOf(s)])}</div>`).join(""))}
${sec("og.png", im("frontend/public/og.png", 1200))}
${sec("24 covers", `<div class="g" style="width:100%">${covers.map((f, i) => `<figure><img src="${R("brand/demo/covers/" + f)}"><figcaption>${demo.covers[i].title} (${demo.covers[i].group})</figcaption></figure>`).join("")}</div>`)}
${sec("40 pages", pages.map((f) => im("brand/demo/pages/" + f, 160)).join(""))}
<p style="color:#7A7770">${man.length} exported files in manifest.</p>`;
writeFileSync(join(outDir, "sheet.html"), html);

const { chromium } = createRequire(new URL("../frontend/package.json", import.meta.url))("playwright");
const browser = await chromium.launch();
for (const [w, h] of [[1440, 900], [390, 844]]) {
  const page = await browser.newPage({ viewport: { width: w, height: h } });
  await page.goto("file://" + join(outDir, "sheet.html"));
  await page.waitForLoadState("networkidle");
  await page.screenshot({ path: join(outDir, `sheet-${w}.png`), fullPage: true });
  await page.close();
}
await browser.close();
console.log("proof written to", outDir);
