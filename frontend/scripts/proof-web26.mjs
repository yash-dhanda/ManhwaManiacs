// Proof screenshots for web/26. Usage: E2E_BASE_URL=http://127.0.0.1:3033 node scripts/proof-web26.mjs [outDir]
import { chromium } from "@playwright/test";
import { mkdirSync } from "node:fs";

const base = process.env.E2E_BASE_URL ?? "http://127.0.0.1:3033";
const out = process.argv[2] ?? "../docs/redesign/proof/web-26";
mkdirSync(out, { recursive: true });
const G = `${base}/dev/glass-primitives`;
const SECTIONS = ["buttons", "hold", "icon-buttons", "inputs", "search", "chips", "segmented", "cards", "posters", "rails", "skeletons", "progress", "badges", "avatars", "tooltips", "reveals", "cursors"];
const sizes = { desktop: { viewport: { width: 1440, height: 900 } }, phone: { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 } };
const browser = await chromium.launch();
async function shot(name, size, url, prep) {
  const ctx = await browser.newContext(sizes[size]);
  const page = await ctx.newPage();
  await page.goto(url, { waitUntil: "networkidle" });
  await page.waitForTimeout(1200);
  if (prep) await prep(page);
  await page.waitForTimeout(500);
  await page.screenshot({ path: `${out}/${name}.png`, fullPage: name.startsWith("reveals-typing") || name.includes("lift") || name.includes("aborted") ? false : true });
  await ctx.close();
}
for (const s of SECTIONS) {
  await shot(`${s}-desktop`, "desktop", `${G}?section=${s}`);
  await shot(`${s}-phone`, "phone", `${G}?section=${s}`);
  await shot(`${s}-solid-desktop`, "desktop", `${G}?section=${s}`, (p) => p.getByRole("button", { name: "Solid glass" }).click());
  await shot(`${s}-contrast-desktop`, "desktop", `${G}?section=${s}`, (p) => p.getByRole("button", { name: "Increase contrast" }).click());
}
{
  const ctx = await browser.newContext(sizes.desktop);
  const page = await ctx.newPage();
  await page.goto(`${G}?section=reveals`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(200);
  await page.screenshot({ path: `${out}/reveals-typing-200ms-desktop.png` });
  const box = await page.getByTestId("three-rails").boundingBox();
  await page.evaluate((y) => window.scrollTo(0, y - 300), box.y);
  await page.waitForTimeout(350);
  await page.screenshot({ path: `${out}/reveals-rails-running-desktop.png` });
  await ctx.close();
}
{
  const ctx = await browser.newContext(sizes.desktop);
  const page = await ctx.newPage();
  await page.goto(`${G}?section=hold`, { waitUntil: "networkidle" });
  const b = await page.getByTestId("hold-standalone").first().boundingBox();
  await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2);
  await page.mouse.down(); await page.waitForTimeout(600); await page.mouse.up(); await page.waitForTimeout(150);
  await page.screenshot({ path: `${out}/hold-aborted-desktop.png` });
  await ctx.close();
}
{
  const ctx = await browser.newContext(sizes.phone);
  const page = await ctx.newPage();
  await page.goto(`${G}?section=posters`, { waitUntil: "networkidle" });
  const el = page.getByTestId("poster-main").first().locator(".g-poster__main");
  await el.scrollIntoViewIfNeeded();
  const b = await el.boundingBox();
  const cdp = await ctx.newCDPSession(page);
  const pt = [{ x: b.x + b.width / 2, y: b.y + b.height / 2 }];
  await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: pt });
  await page.waitForTimeout(470);
  await page.screenshot({ path: `${out}/poster-lift-phone.png` });
  await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
  await ctx.close();
}
await browser.close();
