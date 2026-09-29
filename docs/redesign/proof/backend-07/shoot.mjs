import { chromium } from "/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/node_modules/playwright/index.mjs";

const out = "/srv/manhwamaniacs/dev/wt/backend/docs/redesign/proof/backend-07";
const browser = await chromium.launch();
for (const [width, height, scale] of [[1440, 900, 1], [390, 844, 3]]) {
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: scale });
  await page.goto("http://127.0.0.1:8012/", { waitUntil: "networkidle" });
  await page.screenshot({ path: `${out}/install-${width}x${height}.png`, fullPage: true });
  await page.close();
}
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, reducedMotion: "reduce" });
await page.goto("http://127.0.0.1:8012/", { waitUntil: "networkidle" });
await page.keyboard.press("Tab");
await page.screenshot({ path: `${out}/install-390x844-skiplink-focus.png` });
await page.keyboard.press("Tab");
await page.keyboard.press("Tab");
await page.screenshot({ path: `${out}/install-390x844-focus.png` });
const fonts = await page.evaluate(() => [...document.fonts].filter((f) => f.status === "loaded").map((f) => `${f.family} ${f.style}`));
console.log(JSON.stringify({ fontsLoaded: fonts }));
await browser.close();
