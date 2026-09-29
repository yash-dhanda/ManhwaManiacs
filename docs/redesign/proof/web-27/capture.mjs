import { chromium } from "@playwright/test";
const OUT = "../docs/redesign/proof/web-27/";
const B = "http://127.0.0.1:3033/dev/glass-primitives";
const SECTIONS = ["sheets", "alerts", "toasts", "tabs", "sliders", "toggles", "menus", "banners", "image-viewer", "scroll-edges", "pull-to-refresh", "content-mode"];
const failed = [];
const browser = await chromium.launch();
const mk = async (phone, extra = {}) => {
  const ctx = await browser.newContext(phone ? { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, deviceScaleFactor: 2, ...extra } : { viewport: { width: 1440, height: 900 }, ...extra });
  const page = await ctx.newPage();
  return page;
};
const shot = async (page, name) => { await page.screenshot({ path: `${OUT}${name}.png` }); };
const step = async (name, fn) => { try { await fn(); } catch (e) { failed.push(`${name}: ${String(e.message).split("\n")[0]}`); } };
const go = async (page, q) => { await page.goto(`${B}${q}`, { waitUntil: "networkidle" }); await page.waitForTimeout(700); };

// per section: desktop, phone, solid, contrast
for (const [phone, tag] of [[false, "desktop"], [true, "phone"]]) {
  const page = await mk(phone);
  for (const s of SECTIONS) await step(`${s}-${tag}`, async () => { await go(page, `?section=${s}`); await shot(page, `${s}-${tag}`); });
  await page.context().close();
}
{
  const page = await mk(false);
  for (const s of SECTIONS) {
    await step(`${s}-solid`, async () => { await go(page, `?section=${s}`); await page.evaluate(() => { document.documentElement.dataset.solid = "on"; }); await page.waitForTimeout(400); await shot(page, `${s}-solid-desktop`); });
    await step(`${s}-contrast`, async () => { await go(page, `?section=${s}`); await page.evaluate(() => { document.documentElement.dataset.contrast = "more"; }); await page.waitForTimeout(400); await shot(page, `${s}-contrast-desktop`); });
  }
  await page.context().close();
}
// phone sheets
{
  const page = await mk(true);
  const dlg = () => page.locator('[role="dialog"]').last();
  await step("sheet-medium", async () => { await go(page, "?section=sheets"); await page.getByTestId("open-filters").click(); await page.waitForTimeout(1300); await shot(page, "sheet-medium-phone"); });
  await step("sheet-large", async () => {
    await page.keyboard.press("Escape"); await page.waitForTimeout(800);
    await go(page, "?section=sheets"); await page.getByTestId("open-large-only").click(); await page.waitForTimeout(1300); await shot(page, "sheet-large-recession-phone");
  });
  await step("sheet-stacked", async () => {
    await page.keyboard.press("Escape"); await page.waitForTimeout(800);
    await go(page, "?section=sheets"); await page.getByTestId("open-filters").click(); await page.waitForTimeout(1200);
    await page.getByTestId("open-recommend").click(); await page.waitForTimeout(1300); await shot(page, "sheet-stacked-phone");
  });
  await step("sheet-rubberband", async () => {
    await go(page, "?section=sheets"); await page.getByTestId("open-large-only").click(); await page.waitForTimeout(1300);
    const g = page.locator(".g-sheet__grabber").last(); const b = await g.boundingBox();
    const x = b.x + b.width / 2, y = b.y + b.height / 2;
    await page.mouse.move(x, y); await page.mouse.down();
    for (let i = 1; i <= 10; i++) { await page.mouse.move(x, y - i * 8); await page.waitForTimeout(16); }
    await shot(page, "sheet-rubberband-phone"); await page.mouse.up();
  });
  await step("alert-error-phone", async () => {
    await go(page, "?section=alerts"); await page.getByTestId("alert-open-error").click(); await page.waitForTimeout(700);
    await page.getByTestId("alert-action-1").click(); await page.waitForTimeout(900); await shot(page, "alert-error-phone");
  });
  await step("toasts-stacked", async () => {
    await go(page, "?section=toasts"); await page.getByTestId("toast-two").click(); await page.waitForTimeout(1300); await shot(page, "toasts-stacked-phone");
  });
  await step("context-lift", async () => {
    await go(page, "?section=menus");
    const p = page.getByTestId("ctx-poster"); await p.scrollIntoViewIfNeeded(); const b = await p.boundingBox();
    const x = b.x + b.width / 2, y = b.y + b.height / 2;
    await page.mouse.move(x, y); await page.mouse.down(); await page.waitForTimeout(1200); await shot(page, "context-lift-phone"); await page.mouse.up();
  });
  await step("image-viewer-zoomed", async () => {
    await go(page, "?section=image-viewer"); await page.getByTestId("image-thumb").click(); await page.waitForTimeout(1200);
    await page.keyboard.press("+"); await page.keyboard.press("+"); await page.waitForTimeout(900); await shot(page, "image-viewer-zoomed-phone");
  });
  await step("image-viewer-dismiss", async () => {
    await go(page, "?section=image-viewer"); await page.getByTestId("image-thumb").click(); await page.waitForTimeout(1300);
    await page.mouse.move(195, 420); await page.mouse.down();
    for (let i = 1; i <= 8; i++) { await page.mouse.move(195, 420 + i * 12); await page.waitForTimeout(20); }
    await shot(page, "image-viewer-dismiss-drag-phone"); await page.mouse.up();
  });
  await step("pull", async () => {
    await go(page, "?section=pull-to-refresh");
    const pull = page.getByTestId("pull"); await pull.scrollIntoViewIfNeeded(); const b = await pull.boundingBox();
    const cx = b.x + b.width / 2, y0 = b.y + 40;
    const cdp = await page.context().newCDPSession(page);
    const t = (type, y) => cdp.send("Input.dispatchTouchEvent", { type, touchPoints: type === "touchEnd" ? [] : [{ x: cx, y }] });
    await t("touchStart", y0);
    for (let d = 5; d <= 60; d += 5) { await t("touchMove", y0 + d); await page.waitForTimeout(16); }
    await shot(page, "pull-droplet-60px-phone");
    for (let d = 65; d <= 110; d += 5) { await t("touchMove", y0 + d); await page.waitForTimeout(16); }
    await page.waitForTimeout(250); await shot(page, "pull-snapped-phone");
    await t("touchEnd", y0 + 110);
  });
  await step("scrub", async () => {
    await go(page, "?section=sliders");
    const r = page.getByTestId("scrub-plain").first(); await r.scrollIntoViewIfNeeded(); const b = await r.boundingBox();
    await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2); await page.mouse.down(); await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2 + 30, { steps: 6 }); await page.waitForTimeout(700);
    await shot(page, "scrub-lens-phone"); await page.mouse.up();
  });
  await step("speed-dial", async () => {
    await go(page, "?section=sliders"); const o = page.getByTestId("dial-open").first(); await o.scrollIntoViewIfNeeded(); await o.click(); await page.waitForTimeout(900); await shot(page, "speed-dial-phone");
  });
  await page.context().close();
}
// desktop overlays
{
  const page = await mk(false);
  const open = async (id) => { await go(page, "?section=sheets"); await page.getByTestId(`open-${id}`).click(); await page.waitForTimeout(1300); };
  await step("panel", async () => { await open("panel-demo"); await shot(page, "panel-desktop"); });
  await step("window", async () => { await open("window-demo"); await shot(page, "window-desktop"); });
  await step("detail", async () => { await open("detail-demo"); await shot(page, "detail-window-desktop"); });
  await step("offer", async () => { await open("offer-demo"); await shot(page, "offer-popover-desktop"); });
  await step("alert-source", async () => {
    await go(page, "?section=alerts"); await page.getByTestId("alert-open-source").click(); await page.waitForTimeout(130); await shot(page, "alert-from-source-desktop");
  });
  await step("toast-undo", async () => { await go(page, "?section=toasts"); await page.getByTestId("toast-undo-open").click(); await page.waitForTimeout(3200); await shot(page, "toast-undo-rim-desktop"); });
  await step("menu-bloom", async () => { await go(page, "?section=menus"); await page.getByTestId("menu-trigger").click(); await page.waitForTimeout(140); await shot(page, "menu-bloom-desktop"); });
  await page.context().close();
}
await browser.close();
console.log("FAILED:", failed.length ? "\n" + failed.join("\n") : "none");
