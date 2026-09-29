// Proof screenshots for web/25 (Glass foundation). Usage:
//   E2E_BASE_URL=http://127.0.0.1:3033 node scripts/proof-web25.mjs [outDir]
import { chromium } from "@playwright/test";
import { mkdirSync } from "node:fs";

const base = process.env.E2E_BASE_URL ?? "http://127.0.0.1:3033";
const out = process.argv[2] ?? "../docs/redesign/proof/web-25";
mkdirSync(out, { recursive: true });
const PAGE = `${base}/dev/glass-calibration`;
const sizes = { desktop: { viewport: { width: 1440, height: 900 } }, phone: { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 } };

const browser = await chromium.launch();
async function shot(name, size, { url = PAGE, media, prep } = {}) {
  const ctx = await browser.newContext(sizes[size]);
  const page = await ctx.newPage();
  if (media) await page.emulateMedia(media);
  await page.goto(url, { waitUntil: "networkidle" });
  await page.waitForTimeout(1800);
  if (prep) await prep(page);
  await page.waitForTimeout(700);
  await page.screenshot({ path: `${out}/${name}-${size}.png` });
  await ctx.close();
}

for (const size of ["desktop", "phone"]) {
  await shot("calibration-liquid", size, { url: `${PAGE}?renderer=liquid` });
  await shot("calibration-frosted", size, { url: `${PAGE}?renderer=frosted` });
  await shot("calibration-solid", size, { url: `${PAGE}?renderer=solid` });
}
await shot("calibration-contrast", "desktop", { prep: (p) => p.getByRole("button", { name: "Increase contrast" }).click() });
await shot("calibration-forced-colors", "desktop", { media: { forcedColors: "active" } });
await shot("calibration-reduced", "desktop", { media: { reducedMotion: "reduce" } });

// legibility: the bar over the darkest and the palest cover
const sectionLb = `${PAGE}?section=3`;
async function lbShot(name, pick) {
  await shot(name, "desktop", {
    url: sectionLb,
    prep: async (p) => {
      const idx = await p.evaluate((mode) => {
        const imgs = [...document.querySelectorAll("[data-testid=cover-column] img")];
        const vals = imgs.map((i) => Number(i.dataset.lmax));
        const target = mode === "dark" ? Math.min(...vals) : Math.max(...vals);
        return vals.indexOf(target);
      }, pick);
      await p.evaluate((i) => {
        const col = document.querySelector("[data-testid=cover-column]");
        const img = col.querySelectorAll("img")[i];
        col.scrollTop = img.offsetTop - 12;
      }, idx);
      await p.waitForTimeout(900);
    },
  });
}
await lbShot("legibility-dark", "dark");
await lbShot("legibility-pale", "pale");

await shot("caustic-rest", "desktop", { url: `${PAGE}?section=4` });
await shot("caustic-pressed", "desktop", {
  url: `${PAGE}?section=4`,
  prep: async (p) => {
    const b = await p.locator("[data-testid=tinted-button]").boundingBox();
    await p.mouse.move(b.x + b.width / 2, b.y + b.height / 2);
    await p.mouse.down();
  },
});
await shot("focus-ring-t2", "desktop", {
  prep: async (p) => {
    await p.locator("[data-testid=t2-button]").focus();
    await p.keyboard.press("Shift+Tab");
    await p.keyboard.press("Tab");
  },
});
await shot("ambient-mood", "phone", { url: `${PAGE}?section=5`, prep: (p) => p.getByRole("button", { name: "romantic" }).click() });
await shot("ambient-palette", "phone", { url: `${PAGE}?section=5`, prep: (p) => p.getByRole("button", { name: "Next cover palette" }).click() });
await browser.close();
