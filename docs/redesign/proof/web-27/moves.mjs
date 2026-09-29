// Runs the eight web/27 moves at both sizes and prints the recorder's figures (software raster, headless).
import { chromium } from "@playwright/test";
const B = "http://127.0.0.1:3033/dev/glass-primitives";
const browser = await chromium.launch();
const out = {};
for (const phone of [false, true]) {
  const tag = phone ? "390x844" : "1440x900";
  const ctx = await browser.newContext(phone ? { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true } : { viewport: { width: 1440, height: 900 } });
  const page = await ctx.newPage();
  const acc = []; const collect = async () => { try { acc.push(...await page.evaluate(() => (window.__glassMoves?.() ?? []))); } catch {} };
  const go = async (q) => { await collect(); await page.goto(`${B}${q}`, { waitUntil: "networkidle" }); await page.waitForTimeout(800); };
  const w = (ms = 1500) => page.waitForTimeout(ms);
  const tid = (id) => page.getByTestId(id).first();
  await go("?section=sheets");
  if (phone) { await tid("open-filters").click(); await w(); await page.keyboard.press("Escape"); await w(); await tid("open-peek").click(); await w();
    const b = await page.locator(".g-sheet__grabber").last().boundingBox(); const x = b.x + b.width / 2, y = b.y + b.height / 2;
    await page.mouse.move(x, y); await page.mouse.down(); for (let i = 1; i <= 10; i++) { await page.mouse.move(x, y - i * 30); await page.waitForTimeout(20); } await page.mouse.up(); await w();
    await page.keyboard.press("Escape"); await w(); }
  else { await tid("open-panel-demo").click(); await w(); await page.keyboard.press("Escape"); await w(); }
  await go("?section=menus"); await tid("menu-trigger").click(); await w(); await page.keyboard.press("Escape"); await w();
  await go("?section=toasts"); await tid("toast-info").click(); await w(2500);
  await go("?section=image-viewer"); await tid("image-thumb").click(); await w(); await page.keyboard.press("+"); await w(); await page.keyboard.press("Escape"); await w();
  await go("?section=sliders"); { const r = tid("scrub-plain"); await r.scrollIntoViewIfNeeded(); const b = await r.boundingBox();
    await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2); await page.mouse.down(); await page.mouse.move(b.x + b.width / 2 + 20, b.y + b.height / 2 + 30, { steps: 6 }); await w(800); await page.mouse.up(); await w(); }
  await go("?section=pull-to-refresh");
  if (phone) { const p = tid("pull"); await p.scrollIntoViewIfNeeded(); const b = await p.boundingBox(); const cx = b.x + b.width / 2, y0 = b.y + 40;
    const cdp = await ctx.newCDPSession(page); const t = (type, y) => cdp.send("Input.dispatchTouchEvent", { type, touchPoints: type === "touchEnd" ? [] : [{ x: cx, y }] });
    await t("touchStart", y0); for (let d = 5; d <= 120; d += 5) { await t("touchMove", y0 + d); await page.waitForTimeout(16); } await t("touchEnd", y0 + 120); await w(3000); }
  else await page.evaluate(() => window.dispatchEvent(new Event("noop")));
  await collect();
  const agg = {};
  for (const r of acc) if (r.end !== null) { const a = (agg[r.label] ??= { runs: 0, ms: [], frames: 0, dropped: 0 }); a.runs++; a.ms.push(Math.round(r.end - r.start)); a.frames += r.frames; a.dropped += r.dropped; }
  out[tag] = agg;
  await ctx.close();
}
await browser.close();
console.log(JSON.stringify(out));
