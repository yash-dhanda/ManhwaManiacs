import { expect, test, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import path from "node:path";
import { open } from "./gallery";

const OUT = path.resolve(__dirname, "../../../docs/redesign/proof/web-05/overlays");
mkdirSync(OUT, { recursive: true });
const g = (page: Page, id: string) => page.locator(`[data-gallery="${id}"]`).first();
const trigger = (page: Page, id: string) => g(page, `w5-trigger-${id}`);
const shot = (page: Page, name: string) => page.screenshot({ path: path.join(OUT, `${name}.png`) });
const desktop = (page: Page) => page.setViewportSize({ width: 1440, height: 900 });
const phone = (page: Page) => page.setViewportSize({ width: 390, height: 844 });
const within = (page: Page, sel: string) => page.evaluate((s) => !!document.activeElement?.closest(s), sel);

test.describe("sheets", () => {
  test("phone: Rise, focus inside, Tab trapped, Esc returns focus, history entry closes on back", async ({ page }) => {
    await phone(page); await open(page);
    const t = trigger(page, "sheet"); await t.scrollIntoViewIfNeeded(); await t.click();
    const sheet = g(page, "w5-sheet"); await expect(sheet).toBeVisible();
    expect(await within(page, '[data-gallery="w5-sheet"]')).toBe(true);
    await page.waitForTimeout(500); await shot(page, "sheet-phone");
    for (let i = 0; i < 8; i++) { await page.keyboard.press("Tab"); expect(await within(page, '[data-gallery="w5-sheet"]')).toBe(true); }
    await page.keyboard.press("Escape"); await expect(sheet).toBeHidden();
    await expect(t).toBeFocused();
    const h = trigger(page, "sheet-history"); await h.click();
    await expect(g(page, "w5-sheet")).toBeVisible(); expect(page.url()).toContain("sheet=type");
    await page.goBack(); await expect(g(page, "w5-sheet")).toBeHidden(); expect(page.url()).not.toContain("sheet=");
  });
  test("desktop: a right column panel at least 400 px wide", async ({ page }) => {
    await desktop(page); await open(page);
    const t = trigger(page, "sheet"); await t.scrollIntoViewIfNeeded(); await t.click();
    const sheet = g(page, "w5-sheet"); await expect(sheet).toBeVisible(); await page.waitForTimeout(500);
    const b = (await sheet.boundingBox())!;
    expect(b.width).toBeGreaterThanOrEqual(400); expect(Math.round(b.x + b.width)).toBe(1440);
    await shot(page, "panel-desktop");
    await page.keyboard.press("Escape"); await expect(sheet).toBeHidden();
  });
  for (const id of ["sheet-loading", "sheet-error", "sheet-live"]) {
    test(`phone capture ${id}`, async ({ page }) => {
      await phone(page); await open(page);
      const t = trigger(page, id); await t.scrollIntoViewIfNeeded(); await t.click(); await page.waitForTimeout(900);
      await shot(page, id); await page.keyboard.press("Escape");
    });
  }
});

test.describe("dialogs and the arm", () => {
  test("double-click opens it and does not confirm; Enter at 500 ms does nothing; ready at 1100 ms confirms", async ({ page }) => {
    await desktop(page); await open(page);
    const t = trigger(page, "destructive"); await t.scrollIntoViewIfNeeded();
    await t.dblclick();
    const d = g(page, "w5-confirm-destructive");
    await expect(d).toBeVisible();
    const confirm = d.getByRole("button", { name: "Remove" });
    await confirm.focus(); await page.waitForTimeout(500);
    await expect(confirm).toHaveAttribute("aria-disabled", "true"); await shot(page, "dialog-arming");
    await page.keyboard.press("Enter"); await expect(d).toBeVisible();
    await page.waitForTimeout(700);
    await expect(d.getByRole("status")).toHaveText("Ready"); await expect(confirm).not.toHaveAttribute("aria-disabled", "true");
    await shot(page, "dialog-armed");
    await page.keyboard.press("Enter"); await expect(d).toBeHidden();
  });
  test("Cancel works at 100 ms and initial focus is on it", async ({ page }) => {
    await desktop(page); await open(page);
    const t = trigger(page, "destructive"); await t.scrollIntoViewIfNeeded(); await t.click();
    const d = g(page, "w5-confirm-destructive"); await expect(d).toBeVisible();
    await expect(d.getByRole("button", { name: "Cancel" })).toBeFocused();
    await page.waitForTimeout(100); await d.getByRole("button", { name: "Cancel" }).click(); await expect(d).toBeHidden();
  });
  test("heavy confirm needs the phrase as well as the arm", async ({ page }) => {
    await desktop(page); await open(page);
    const t = trigger(page, "phrase"); await t.scrollIntoViewIfNeeded(); await t.click();
    const d = g(page, "w5-confirm-phrase"); await expect(d).toBeVisible(); await page.waitForTimeout(1200);
    const confirm = d.getByRole("button", { name: "Restore" });
    await expect(confirm).toHaveAttribute("aria-disabled", "true");
    await d.getByRole("textbox").fill("restore"); await expect(confirm).not.toHaveAttribute("aria-disabled", "true");
    await shot(page, "dialog-heavy");
    await confirm.click(); await expect(d).toBeHidden();
  });
  test("pending and error states", async ({ page }) => {
    await desktop(page); await open(page);
    for (const id of ["pending", "error"]) {
      const t = trigger(page, id); await t.scrollIntoViewIfNeeded(); await t.click();
      await page.waitForTimeout(1300); await shot(page, `dialog-${id}`);
      if (id === "error") await expect(page.getByRole("alert").filter({ hasText: "did not accept" })).toBeVisible();
      await page.keyboard.press("Escape");
      if (id === "pending") await expect(g(page, "w5-confirm-pending")).toBeVisible(); // Esc is ignored while a request runs
      else await expect(g(page, "w5-confirm-error")).toBeHidden();
      if (id === "pending") await page.reload().then(() => open(page));
    }
  });
});

test("menus: arrows, type-ahead, Esc returns focus, right-click opens at the pointer", async ({ page }) => {
  await desktop(page); await open(page);
  const t = g(page, "w5-menu-trigger"); await t.scrollIntoViewIfNeeded(); await t.click();
  const menu = page.getByRole("menu"); await expect(menu).toBeVisible();
  await page.keyboard.press("ArrowDown"); await page.keyboard.press("ArrowDown");
  const active = () => page.evaluate(() => document.activeElement?.textContent ?? "");
  expect(await active()).toContain("Favourite");
  await page.keyboard.press("Home"); expect(await active()).toContain("Open");
  await page.keyboard.press("End"); expect(await active()).toContain("Remove");
  await page.keyboard.press("f"); expect(await active()).toContain("Favourite");
  await page.waitForTimeout(350); await shot(page, "menu-open");
  await page.keyboard.press("Escape"); await expect(menu).toBeHidden(); await expect(t).toBeFocused();
  const target = g(page, "w5-context-target"); await target.scrollIntoViewIfNeeded();
  const box = (await target.boundingBox())!;
  await page.mouse.click(box.x + 40, box.y + 20, { button: "right" });
  await expect(page.getByRole("menu")).toBeVisible();
  const mb = (await page.getByRole("menu").boundingBox())!;
  expect(Math.abs(mb.x - (box.x + 40))).toBeLessThan(24); expect(Math.abs(mb.y - (box.y + 20))).toBeLessThan(24);
  await page.keyboard.press("Escape");
});

test.describe("toasts", () => {
  test("Alt+T focuses the region; a focused toast outlives its hold; max two visible", async ({ page }) => {
    await desktop(page); await open(page);
    const info = trigger(page, "toast-info"); await info.scrollIntoViewIfNeeded(); await info.click();
    await expect(page.getByRole("status").filter({ hasText: "Library updated." })).toBeVisible();
    await page.keyboard.press("Alt+KeyT");
    expect(await page.evaluate(() => !!document.activeElement?.closest("[data-sonner-toaster]"))).toBe(true);
    await page.waitForTimeout(4600);
    await expect(page.getByText("Library updated.")).toBeVisible();
    await page.keyboard.press("Escape").catch(() => undefined);
  });
  test("three at once show at most two; error uses role alert", async ({ page }) => {
    await desktop(page); await open(page);
    const t = trigger(page, "toast-three"); await t.scrollIntoViewIfNeeded(); await t.click(); await page.waitForTimeout(500);
    expect(await page.locator('[data-sonner-toast][data-visible="true"]').count()).toBeLessThanOrEqual(2);
    await trigger(page, "toast-error").click(); await expect(page.getByRole("alert").filter({ hasText: "Could not reach" })).toBeVisible();
    await page.waitForTimeout(300); await shot(page, "toasts-stacked");
  });
});

test("tabs: ] moves to the next tab and the indicator ends under it", async ({ page }) => {
  await desktop(page); await open(page);
  const tabs = g(page, "w5-tabs"); await tabs.scrollIntoViewIfNeeded();
  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await page.keyboard.press("]");
  const second = tabs.getByRole("tab", { name: "Details" });
  await expect(second).toHaveAttribute("aria-selected", "true");
  await page.waitForTimeout(600);
  const [i, t] = await Promise.all([tabs.locator(".cine-tab-indicator").boundingBox(), second.boundingBox()]);
  expect(Math.abs(i!.x - t!.x)).toBeLessThan(2); expect(Math.abs(i!.width - t!.width)).toBeLessThan(2);
  await page.keyboard.press("["); await expect(tabs.getByRole("tab", { name: /Chapters/ })).toHaveAttribute("aria-selected", "true");
});

test("stepper and slider keys", async ({ page }) => {
  await desktop(page); await open(page);
  const step = g(page, "w5-stepper"); await step.scrollIntoViewIfNeeded();
  const val = step.getByRole("status");
  await step.getByRole("button", { name: /Increase/ }).focus(); await page.keyboard.press("Enter");
  await expect(val).toContainText("Chapters ahead, 4");
  for (let i = 0; i < 8; i++) await step.getByRole("button", { name: /Increase/ }).click();
  await expect(step.getByRole("button", { name: /Increase/ })).toHaveAttribute("aria-disabled", "true");
  const slider = g(page, "w5-slider").getByRole("slider"); await slider.scrollIntoViewIfNeeded(); await slider.focus();
  const v0 = Number(await slider.inputValue());
  await page.keyboard.press("ArrowRight"); expect(Number(await slider.inputValue())).toBe(v0 + 1);
  await page.keyboard.press("Home"); expect(Number(await slider.inputValue())).toBe(12);
  await page.keyboard.press("Shift+ArrowRight"); expect(Number(await slider.inputValue())).toBe(22);
  await page.keyboard.press("End"); expect(Number(await slider.inputValue())).toBe(28);
  await expect(g(page, "w5-slider-disabled").getByRole("slider")).toBeDisabled();
});

test("lightbox: focus on Close, ?view=cover, Esc returns focus, = zooms and the chip shows", async ({ page }) => {
  await desktop(page); await open(page);
  const cover = g(page, "w5-lightbox-cover"); await cover.scrollIntoViewIfNeeded(); await cover.click();
  const box = page.getByRole("dialog", { name: "Cover of Salt and Iron" }); await expect(box).toBeVisible();
  await expect(box.getByRole("button", { name: "Close" })).toBeFocused();
  expect(page.url()).toContain("view=cover");
  await page.keyboard.press("="); await expect(box.getByText("125%")).toBeVisible();
  await box.locator("img").last().dblclick();
  await page.waitForTimeout(400); await shot(page, "lightbox");
  await page.keyboard.press("Escape"); await expect(box).toBeHidden(); await expect(cover).toBeFocused();
  expect(page.url()).not.toContain("view=cover");
});

test.describe("reduced motion", () => {
  test("overlay transitions are opacity-only and short; the arm shows full at 1000 ms without a fill", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await desktop(page); await open(page);
    const check = async (sel: string) => page.locator(sel).first().evaluate((el) => { const c = getComputedStyle(el); return { props: c.transitionProperty, dur: c.transitionDuration }; });
    await trigger(page, "sheet").scrollIntoViewIfNeeded(); await trigger(page, "sheet").click(); await expect(g(page, "w5-sheet")).toBeVisible();
    let s = await check('[data-gallery="w5-sheet"]'); expect(s.props).toBe("opacity"); expect(parseFloat(s.dur) * 1000).toBeLessThanOrEqual(200);
    await page.keyboard.press("Escape"); await expect(g(page, "w5-sheet")).toBeHidden();
    await trigger(page, "destructive").click(); const d = g(page, "w5-confirm-destructive"); await expect(d).toBeVisible();
    s = await check('[data-gallery="w5-confirm-destructive"]'); expect(s.props).toBe("opacity"); expect(parseFloat(s.dur) * 1000).toBeLessThanOrEqual(200);
    const rule = d.locator(".cine-arm-rule");
    await page.waitForTimeout(400);
    expect(await rule.evaluate((e) => getComputedStyle(e).transform)).toMatch(/matrix\(0,|none|matrix\(0, 0/);
    await page.waitForTimeout(800);
    expect(await rule.evaluate((e) => getComputedStyle(e).transform)).toBe("matrix(1, 0, 0, 1, 0, 0)");
    await page.keyboard.press("Escape");
    await g(page, "w5-menu-trigger").scrollIntoViewIfNeeded(); await g(page, "w5-menu-trigger").click();
    s = await check('[data-gallery="w5-menu"]'); expect(s.props).toBe("opacity"); expect(parseFloat(s.dur) * 1000).toBeLessThanOrEqual(200);
    await page.keyboard.press("Escape");
    const cover = g(page, "w5-lightbox-cover"); await cover.scrollIntoViewIfNeeded(); await cover.click(); await page.waitForTimeout(300);
    await expect(page.getByRole("dialog", { name: /Cover of/ })).toBeVisible(); await page.keyboard.press("Escape");
  });
});

test("hit targets: >= 44 on the phone frame with touch, >= 32 on desktop", async ({ browser }) => {
  for (const [w, h, touch, min] of [[390, 844, true, 44], [1440, 900, false, 32]] as const) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, hasTouch: touch, isMobile: touch, baseURL: process.env.E2E_BASE_URL });
    const page = await ctx.newPage(); await open(page);
    const small = await page.evaluate((m) => {
      const from = document.getElementById("sheets")!.getBoundingClientRect().top + scrollY;
      return [...document.querySelectorAll<HTMLElement>("main button, main [role=switch], main [role=checkbox], main [role=radio], main [role=tab], main a[href]")]
        .filter((e) => e.getBoundingClientRect().top + scrollY >= from && !e.closest("[aria-hidden=true]") && !e.closest("[role=toolbar]"))
        .map((e) => { const t = (e.closest("label") ?? e) as HTMLElement; const r = t.getBoundingClientRect(); return { n: `${e.tagName}:${e.getAttribute("aria-label") ?? e.textContent?.slice(0, 24)}`, w: Math.round(r.width), h: Math.round(r.height), gone: r.width === 0 }; })
        .filter((x) => !x.gone && (x.w < m - 0.5 || x.h < m - 0.5)).map((x) => `${x.n} ${x.w}x${x.h}`);
    }, min);
    expect(small, `${w}x${h}`).toEqual([]);
    await ctx.close();
  }
});
