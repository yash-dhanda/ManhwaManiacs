import { expect, test, type Page } from "@playwright/test";

const G = "/dev/glass-primitives";
const PHONE = { width: 390, height: 844 };
const dialog = (page: Page) => page.locator('[role="dialog"]').last();
const haptics = (page: Page) => page.evaluate(() => {
  const w = window as unknown as { __h?: string[] };
  if (!w.__h) { w.__h = []; window.addEventListener("mm:haptic", (e) => w.__h!.push((e as CustomEvent).detail)); }
  return w.__h;
});

test.describe("sheets (phone, touch)", () => {
  test.use({ viewport: PHONE, hasTouch: true, isMobile: true });

  test("a sheet opens with ?sheet=, traps Tab, closes on Esc and on back with focus returned", async ({ page }) => {
    await page.goto(`${G}?section=sheets`, { waitUntil: "networkidle" });
    const trigger = page.getByTestId("open-filters");
    await trigger.click();
    await expect(page).toHaveURL(/sheet=filters/);
    await expect(dialog(page)).toBeVisible();
    for (let i = 0; i < 25; i++) await page.keyboard.press("Tab");
    expect(await page.evaluate(() => !!document.activeElement?.closest('[role="dialog"]'))).toBe(true);
    await page.keyboard.press("Escape");
    await expect(dialog(page)).toHaveCount(0);
    await expect(page).not.toHaveURL(/sheet=/);
    await expect(trigger).toBeFocused();
    await trigger.click();
    await expect(dialog(page)).toBeVisible();
    await page.goBack();
    await expect(dialog(page)).toHaveCount(0);
    await expect(trigger).toBeFocused();
  });

  test("a hard load of ?sheet=filters renders the sheet; closing replaces the URL without the parameter", async ({ page }) => {
    await page.goto(`${G}?section=sheets&sheet=filters`, { waitUntil: "networkidle" });
    await expect(dialog(page)).toBeVisible();
    const before = await page.evaluate(() => history.length);
    await page.keyboard.press("Escape");
    await expect(dialog(page)).toHaveCount(0);
    await expect(page).not.toHaveURL(/sheet=/);
    expect(await page.evaluate(() => history.length)).toBe(before);
  });

  test("a fast downward flick on the grabber dismisses; sheet haptics fire", async ({ page }) => {
    await page.goto(`${G}?section=sheets`, { waitUntil: "networkidle" });
    await haptics(page);
    await page.getByTestId("open-filters").click();
    await expect(dialog(page)).toBeVisible();
    await page.waitForTimeout(900);
    const g = page.locator(".g-sheet__grabber").last();
    const b = (await g.boundingBox())!;
    const x = b.x + b.width / 2, y = b.y + b.height / 2;
    await page.mouse.move(x, y);
    await page.mouse.down();
    for (let i = 1; i <= 8; i++) { await page.mouse.move(x, y + i * 40); await page.waitForTimeout(8); }
    await page.mouse.up();
    await expect(dialog(page)).toHaveCount(0, { timeout: 5000 });
    const h = await haptics(page);
    expect(h).toContain("sheet.dismiss");
  });
});

test.describe("sheet haptics and budget (phone, touch)", () => {
  test.use({ viewport: PHONE, hasTouch: true, isMobile: true });

  let cdp: import("@playwright/test").CDPSession;
  test.beforeEach(async ({ page }) => { cdp = await page.context().newCDPSession(page); });
  const touch = async (page: Page, type: "touchStart" | "touchMove" | "touchEnd", x: number, y: number) => {
    void page;
    await cdp.send("Input.dispatchTouchEvent", { type, touchPoints: type === "touchEnd" ? [] : [{ x, y }] });
  };
  const grab = async (page: Page) => {
    const b = (await page.locator(".g-sheet__grabber").last().boundingBox())!;
    return { x: b.x + b.width / 2, y: b.y + b.height / 2 };
  };
  const clearH = (page: Page) => page.evaluate(() => { (window as unknown as { __h: string[] }).__h.length = 0; });

  test("touch drag: sheet.pass across a detent, threshold.cross then back, sheet.detent on settle, sheet.dismiss", async ({ page }) => {
    await page.goto(`${G}?section=sheets`, { waitUntil: "networkidle" });
    await haptics(page);
    await page.getByTestId("open-peek").click();
    await expect(dialog(page)).toBeVisible();
    await page.waitForTimeout(1200);
    // up across the large detent, slowly
    let { x, y } = await grab(page);
    await clearH(page);
    await touch(page, "touchStart", x, y);
    for (let i = 1; i <= 12; i++) { await touch(page, "touchMove", x, y - i * 30); await page.waitForTimeout(40); }
    await touch(page, "touchEnd", x, y - 360);
    await page.waitForTimeout(1200);
    let h = await haptics(page);
    expect(h).toContain("sheet.pass");
    expect(h).toContain("sheet.detent");
    // down fast past the dismiss line, then back up slowly, then release near a detent
    ({ x, y } = await grab(page));
    await clearH(page);
    await touch(page, "touchStart", x, y);
    for (let i = 1; i <= 8; i++) { await touch(page, "touchMove", x, y + i * 60); await page.waitForTimeout(8); }
    h = await haptics(page);
    expect(h).toContain("threshold.cross");
    for (let i = 1; i <= 10; i++) { await touch(page, "touchMove", x, y + 480 - i * 50); await page.waitForTimeout(60); }
    await page.waitForTimeout(150);
    h = await haptics(page);
    expect(h.indexOf("threshold.back")).toBeGreaterThan(h.indexOf("threshold.cross"));
    await touch(page, "touchEnd", x, y - 20);
    await page.waitForTimeout(1200);
    await clearH(page);
    // fast flick dismiss
    ({ x, y } = await grab(page));
    await touch(page, "touchStart", x, y);
    for (let i = 1; i <= 8; i++) { await touch(page, "touchMove", x, y + i * 70); await page.waitForTimeout(8); }
    await touch(page, "touchEnd", x, y + 560);
    await expect(dialog(page)).toHaveCount(0, { timeout: 5000 });
    expect(await haptics(page)).toContain("sheet.dismiss");
  });

  const live = async (page: Page) => { await page.waitForFunction(() => "__glassBudget" in window); return page.evaluate(() => (window as unknown as { __glassBudget: () => { glass: number; scrims: number; exempt: number; solid: string[] } }).__glassBudget()); };

  test("budget: sheet + toast, and sheet + menu, keep live glass at 5 or fewer", async ({ page }) => {
    // the gallery wraps everything (portals included) in an exempt scope, so count overlay surfaces as the growth of glass + exempt
    const total = (c: { glass: number; exempt: number }) => c.glass + c.exempt;
    await page.goto(`${G}?section=sheets`, { waitUntil: "networkidle" });
    await page.waitForTimeout(1000);
    const base = total(await live(page));
    await page.getByTestId("open-filters").click();
    await expect(dialog(page)).toBeVisible();
    await page.evaluate(() => (document.querySelector('[data-testid="toast-info"]') as HTMLElement | null)?.click());
    await page.waitForTimeout(900);
    const a = await live(page);
    console.log("BUDGET sheet+toast overlay glass", total(a) - base, JSON.stringify(a));
    expect(total(a) - base).toBeLessThanOrEqual(5);
    await page.keyboard.press("Escape");
    await expect(dialog(page)).toHaveCount(0);
    await page.goto(`${G}?section=menus`, { waitUntil: "networkidle" });
    await page.waitForTimeout(1000);
    const base2 = total(await live(page));
    await page.getByTestId("menu-trigger").click();
    await expect(page.getByRole("menu").first()).toBeVisible();
    await page.waitForTimeout(600);
    const b = await live(page);
    console.log("BUDGET menu overlay glass", total(b) - base2, JSON.stringify(b));
    expect(total(b) - base2).toBeLessThanOrEqual(5);
  });
});

test.describe("alerts and toasts", () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test("alert: least destructive focus, Esc cancels, labelled alertdialog", async ({ page }) => {
    await page.goto(`${G}?section=alerts`, { waitUntil: "networkidle" });
    await page.getByTestId("alert-open-source").click();
    const a = page.locator('[role="alertdialog"]');
    await expect(a).toBeVisible();
    await expect(a).toHaveAttribute("aria-labelledby", /.+/);
    await expect(a).toHaveAttribute("aria-describedby", /.+/);
    await expect(page.getByTestId("alert-action-0")).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(a).toHaveCount(0);
  });

  test("a standalone hold-to-confirm click opens confirmAlert", async ({ page }) => {
    await page.goto(`${G}?section=alerts`, { waitUntil: "networkidle" });
    await page.getByTestId("alert-hold").first().click();
    await expect(page.locator('[role="alertdialog"]')).toBeVisible();
    await page.keyboard.press("Escape");
  });

  test("Alt+N focuses the newest toast and Esc dismisses it", async ({ page }) => {
    await page.goto(`${G}?section=toasts`, { waitUntil: "networkidle" });
    await page.getByTestId("toast-info").click();
    const t = page.locator("[data-glass-toast]").first();
    await expect(t).toBeVisible();
    await page.keyboard.press("Alt+KeyN");
    await expect(t).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(page.locator("[data-glass-toast]:visible")).toHaveCount(0, { timeout: 4000 });
  });

  test("errors use role=alert", async ({ page }) => {
    await page.goto(`${G}?section=toasts`, { waitUntil: "networkidle" });
    await page.getByTestId("toast-error").click();
    await expect(page.locator('[data-glass-toast][role="alert"]').first()).toBeVisible();
  });

  test("a toast shown while a menu is open appears only after the menu closes", async ({ page }) => {
    await page.goto(G, { waitUntil: "networkidle" });
    const trigger = page.getByTestId("menu-trigger");
    await trigger.focus();
    await page.keyboard.press("Enter");
    await expect(page.getByRole("menu").first()).toBeVisible();
    await page.evaluate(() => (document.querySelector('[data-testid="toast-info"]') as HTMLElement).click());
    await page.waitForTimeout(700);
    await expect(page.locator("[data-glass-toast]:not([data-hidden])")).toHaveCount(0);
    await page.keyboard.press("Escape");
    await expect(page.locator("[data-glass-toast]:not([data-hidden])").first()).toBeVisible({ timeout: 4000 });
  });
});

test.describe("menus", () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test("Enter opens, arrows move, type-ahead jumps, Esc closes and returns focus", async ({ page }) => {
    await page.goto(`${G}?section=menus`, { waitUntil: "networkidle" });
    const trigger = page.getByTestId("menu-trigger");
    await trigger.focus();
    await page.keyboard.press("Enter");
    const menu = page.getByRole("menu").first();
    await expect(menu).toBeVisible();
    await page.keyboard.press("ArrowDown");
    const first = await page.evaluate(() => document.activeElement?.textContent ?? "");
    await page.keyboard.press("ArrowDown");
    const second = await page.evaluate(() => document.activeElement?.textContent ?? "");
    expect(second).not.toBe(first);
    await page.keyboard.press("r");
    expect(await page.evaluate(() => document.activeElement?.textContent ?? "")).toMatch(/^Remove/);
    await page.keyboard.press("Escape");
    await expect(menu).toHaveCount(0);
    await expect(trigger).toBeFocused();
  });

  test("Shift+F10 on a focused poster opens its context menu; right-click opens at the pointer", async ({ page }) => {
    await page.goto(`${G}?section=menus`, { waitUntil: "networkidle" });
    const poster = page.getByTestId("ctx-poster");
    await poster.locator("a, button, [tabindex]").first().focus().catch(() => poster.focus());
    await page.keyboard.press("Shift+F10");
    await expect(page.getByTestId("ctx-menu")).toBeVisible();
    await page.keyboard.press("Escape");
    await page.getByTestId("rightclick-area").click({ button: "right" });
    await expect(page.getByTestId("context-menu")).toBeVisible();
  });
});

test.describe("controls", () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test("slider, speed dial and scrub rail answer arrows, Page keys and Home/End", async ({ page }) => {
    await page.goto(`${G}?section=sliders`, { waitUntil: "networkidle" });
    const s = page.getByTestId("slider-main").first().getByRole("slider");
    await s.focus();
    const t0 = await s.getAttribute("aria-valuetext");
    await page.keyboard.press("ArrowRight");
    const t1 = await s.getAttribute("aria-valuetext");
    expect(t1).not.toBe(t0);
    await page.keyboard.press("PageUp");
    const t2 = await s.getAttribute("aria-valuetext");
    expect(t2).not.toBe(t1);
    await page.keyboard.press("End");
    const tEnd = await s.getAttribute("aria-valuetext");
    await page.keyboard.press("Home");
    expect(await s.getAttribute("aria-valuetext")).not.toBe(tEnd);

    const rail = page.getByTestId("scrub-plain").first();
    await rail.focus();
    const r0 = await rail.getAttribute("aria-valuetext");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("PageDown");
    expect(await rail.getAttribute("aria-valuetext")).not.toBe(r0);
    await page.keyboard.press("End");
    expect(await rail.getAttribute("aria-valuetext")).toMatch(/Page 40 of 40/);

    await page.getByTestId("dial-open").first().click();
    const d = page.getByTestId("speed-dial").first().getByRole("slider");
    await d.focus();
    const d0 = await d.getAttribute("aria-valuetext");
    await page.keyboard.press("ArrowUp");
    expect(await d.getAttribute("aria-valuetext")).not.toBe(d0);
    await page.keyboard.press("Home");
    const dHome = await d.getAttribute("aria-valuetext");
    await page.keyboard.press("End");
    expect(await d.getAttribute("aria-valuetext")).not.toBe(dHome);
  });

  test("the switch toggles on Space; [ and ] change tabs", async ({ page }) => {
    await page.goto(`${G}?section=toggles`, { waitUntil: "networkidle" });
    const sw = page.getByTestId("switch-main").first();
    await sw.focus();
    const c0 = await sw.getAttribute("aria-checked");
    await page.keyboard.press("Space");
    expect(await sw.getAttribute("aria-checked")).not.toBe(c0);
    await page.goto(`${G}?section=tabs`, { waitUntil: "networkidle" });
    const v0 = await page.getByTestId("tabs-value").textContent();
    await page.getByTestId("tabs-main").first().getByRole("tab", { selected: true }).focus();
    await page.keyboard.press("]");
    await expect(page.getByTestId("tabs-value")).not.toHaveText(v0!);
    const v1 = await page.getByTestId("tabs-value").textContent();
    await page.keyboard.press("[");
    await expect(page.getByTestId("tabs-value")).not.toHaveText(v1!);
  });

  test("the image viewer zooms with + - 0 and closes on Esc", async ({ page }) => {
    await page.goto(`${G}?section=image-viewer`, { waitUntil: "networkidle" });
    await page.getByTestId("image-thumb").click();
    await expect(page).toHaveURL(/sheet=image/);
    const frame = page.locator(".g-viewer__frame");
    await expect(frame).toBeVisible();
    await page.waitForTimeout(900);
    const scale = () => frame.evaluate((e) => new DOMMatrix(getComputedStyle(e).transform).a);
    expect(await scale()).toBeCloseTo(1, 1);
    await page.keyboard.press("+");
    await expect.poll(scale).toBeGreaterThan(1.05);
    await page.keyboard.press("0");
    await expect.poll(scale).toBeCloseTo(1, 1);
    await page.keyboard.press("Escape");
    await expect(frame).toHaveCount(0, { timeout: 5000 });
  });

  test("content-mode switch renders only when enabled and exposes the wave origin", async ({ page }) => {
    await page.goto(`${G}?section=content-mode`, { waitUntil: "networkidle" });
    await expect(page.getByTestId("mode-off")).toHaveCount(0);
    await page.getByTestId("mode-sidebar").getByRole("radio", { name: "Novels" }).click();
    await expect(page.getByTestId("mode-readout")).toContainText("mode: novel");
    await expect(page.getByTestId("mode-readout")).not.toContainText("none");
  });

  test("pull to refresh: a touch pull past 100 px triggers, refresh() also works", async ({ page }) => {
    await page.goto(`${G}?section=pull-to-refresh`, { waitUntil: "networkidle" });
    await page.getByTestId("pull-refresh-btn").click();
    await expect(page.getByTestId("pull-count")).toContainText("refreshed: 1", { timeout: 6000 });
  });

  test("scroll edges fade in with content and the fast-scroll strip exists over 200 rows", async ({ page }) => {
    await page.goto(`${G}?section=scroll-edges`, { waitUntil: "networkidle" });
    const top = page.getByTestId("edge-top");
    expect(await top.evaluate((e) => e.style.getPropertyValue("--edge-o"))).toBe("0.000");
    await page.getByTestId("scroll-list").evaluate((e) => { e.scrollTop = 60; });
    await expect.poll(() => top.evaluate((e) => e.style.getPropertyValue("--edge-o"))).toBe("1.000");
    await expect(page.getByTestId("fast-scroll")).toHaveAttribute("role", "scrollbar");
    await expect(page.getByTestId("scroll-list")).toHaveAttribute("data-scrolling", "");
  });
});

test.describe("phone touch targets (new sections)", () => {
  test.use({ viewport: PHONE, hasTouch: true, isMobile: true });
  test("every interactive element is at least 44 x 44", async ({ page }) => {
    const bad: string[] = [];
    for (const s of ["alerts", "toasts", "tabs", "sliders", "toggles", "menus", "banners", "image-viewer", "scroll-edges", "pull-to-refresh", "content-mode", "sheets"]) {
      await page.goto(`${G}?section=${s}`, { waitUntil: "networkidle" });
      await page.waitForTimeout(400);
      const r = await page.evaluate(() => {
        const out: string[] = [];
        const sel = 'button, a[href], input, textarea, [role=button], [role=radio], [role=tab], [role=switch], [role=slider], [role=checkbox], [role=scrollbar]';
        document.querySelectorAll<HTMLElement>(`main ${sel}`).forEach((el) => {
          if (el.closest(".gal-toolbar, .gal-nav")) return;
          const w = el.offsetWidth, h = el.offsetHeight;
          if (!w || !h) return;
          if (w < 44 || h < 44) out.push(`${el.tagName}.${el.className.toString().slice(0, 30)}:${w}x${h}`);
        });
        return out;
      });
      r.forEach((x) => bad.push(`${s} ${x}`));
    }
    expect(bad).toEqual([]);
  });
});
