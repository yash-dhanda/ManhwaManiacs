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
<style>body{background:#000;color:#F3F0E8;font:14px system-ui;margin:0;padding:24px}h2{font-size:15px;margin:32px 0 8px;color:#9A978F}.row{display:flex;flex-wrap:wrap;gap:16px;align-items:flex-end}figure{margin:0}figcaption{font-size:11px;color:#7A7770}img{display:block;max-width:100%}.g{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}.g img{width:100%}img.mask{border-radius:22.37%}</style>
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
const GL = "brand/glass/";
const rnd = (x, w) => `<div style="width:${w}px">${x.replace("<img", `<img class=\"mask\"`)}</div>`;
const strip = (src, w) => [["#fff", 0], ["#202124", 0]].map(([b]) => `<div style="background:${b};padding:8px">${im(src, w)}</div>`).join("");
const glassHtml = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>shared-05 brand proof</title>
<style>body{background:#000;color:#F5F7FA;font:14px system-ui;margin:0;padding:24px}h2{font-size:15px;margin:32px 0 8px;color:#8B93A7}.row{display:flex;flex-wrap:wrap;gap:16px;align-items:flex-end}figure{margin:0}figcaption{font-size:11px;color:#6E7688}img{display:block;max-width:100%}img.mask{border-radius:22.37%}</style>
<h1>Glass brand proof (${name})</h1>
${sec("Field alone", im(GL + "field.svg", 320))}
${sec("Slab layers (bottom M, gutter bar, top M) on grey", ["bottom-m", "gutter-bar", "top-m"].map((n) => im(GL + n + ".svg", 200, "background:#555")).join(""))}
${sec("iOS icon under a 22.37 % mask at 1024 (shown 320), 180 and 60; dark and tinted", [320, 180, 60].map((w) => rnd(im(GL + "export/icon-ios-1024.png", w), w)).join("") + [180, 60].map((w) => rnd(im(GL + "export/icon-ios-dark-1024.png", w, "background:#333"), w)).join("") + [180, 60].map((w) => rnd(im(GL + "export/icon-ios-tinted-1024.png", w), w)).join(""))}
${sec("Android foreground over the field with the 66 dp circle; monochrome themed", `<div style="position:relative;width:216px;height:216px">${im(GL + "export/field-1024.png", 216, "position:absolute")}${im(GL + "export/android-foreground-1024.png", 216, "position:absolute")}<div style="position:absolute;left:37.5px;top:37.5px;width:141px;height:141px;border:1px solid #f0f;border-radius:50%"></div></div><div style="background:#1F1F1F;padding:8px;width:216px;height:216px">${im(GL + "export/android-monochrome-1024.png", 216, "filter:sepia(1) hue-rotate(180deg) saturate(2)")}</div></div>`)}
${sec("Neutral mark at 96 px and 44 px", im(GL + "neutral-mark.svg", 96 * 544 / 640) + im(GL + "neutral-mark.svg", 44 * 544 / 640))}
${sec("Column at 32, 24 and 16 px tall", [32, 24, 16].map((h) => im(GL + "column-small.svg", h * 544 / 640)).join(""))}
${sec("Stacked wordmark at 1x and at its 28 px minimum height", im(GL + "wordmark-stacked.svg", 480) + im(GL + "wordmark-stacked.svg", 28 * 1067 / 462) + im(GL + "wordmark-stacked-flat.svg", 320))}
${sec("Single-line wordmark at 12 px cap height", im(GL + "wordmark-line.svg", 12 * 6.2 * 100 / 72))}
${sec("Favicons at 16 and 32 on white and #202124: Glass then Cinematic", [16, 32].map((w) => strip("frontend/public/favicon-glass.svg", w)).join("") + [16, 32].map((w) => strip("frontend/public/favicon.svg", w)).join(""))}
${sec("Droplet texture at 60 % over white and black 160 px tiles", ["#fff", "#000"].map((b) => `<div style="width:160px;height:160px;background:${b} url(${R("frontend/public/glass/droplets.webp")}) 0 0/160px 160px;background-blend-mode:normal"></div>`).join("") + im("frontend/public/glass/droplets.webp", 240, "background:#777"))}
${sec("Cinematic and Glass iOS icons at 60 px", rnd(im(C + "export/icon-ios-1024.png", 60), 60) + rnd(im(GL + "export/icon-ios-1024.png", 60), 60))}
<p style="color:#6E7688">${man.length} exported files in manifest.</p>`;
writeFileSync(join(outDir, "sheet.html"), name.includes("05") ? glassHtml : html);

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
