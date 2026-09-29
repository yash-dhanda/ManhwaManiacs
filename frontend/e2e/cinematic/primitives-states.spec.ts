import { expect, test } from "@playwright/test";
import { mkdirSync } from "node:fs";
import path from "node:path";
import { open } from "./gallery";

const OUT = path.resolve(__dirname, "../../../docs/redesign/proof/web-04/states");
mkdirSync(OUT, { recursive: true });

test("states at 1440x900: default, hover, focus-visible, pressed", async ({ page }) => {
  test.setTimeout(240_000);
  await page.setViewportSize({ width: 1440, height: 900 });
  await open(page);
  const ids = await page.locator("[data-gallery]").evaluateAll((els) => els.map((e) => e.getAttribute("data-gallery")!).filter((v, i, a) => a.indexOf(v) === i && !v.startsWith("rail-") && v !== "reveals-replay"));
  for (const id of ids) {
    const el = page.locator(`[data-gallery="${id}"]`).first();
    await el.scrollIntoViewIfNeeded();
    await page.waitForTimeout(80);
    const shot = (s: string) => el.screenshot({ path: path.join(OUT, `${id}-${s}.png`) }).catch(() => undefined);
    await shot("default");
    await el.hover(); await shot("hover");
    await page.mouse.move(0, 0);
    await page.mouse.move(5, 5);
    await page.evaluate(() => (document.activeElement as HTMLElement | null)?.blur());
    await page.locator("body").press("Home").catch(() => undefined);
    await el.scrollIntoViewIfNeeded();
    await el.focus();
    await page.keyboard.press("Shift+Tab"); await page.keyboard.press("Tab"); // keyboard modality => :focus-visible
    const focusable = await el.evaluate((e) => e === document.activeElement || e.contains(document.activeElement));
    if (focusable) {
      const active = page.locator(":focus");
      const st = await active.evaluate((e) => { const c = getComputedStyle(e); return { w: c.outlineWidth, sh: c.boxShadow }; });
      // Fields (INPUT/TEXTAREA) use the 2 px spot underline as their focus indicator, not the square double ring, so they skip the outline and halo assertions.
      if (st.w !== "0px" && !(await active.evaluate((e) => e.tagName === "INPUT" || e.tagName === "TEXTAREA"))) {
        expect(st.w, `${id} outline`).toBe("2px");
        expect(st.sh, `${id} halo`).toContain("0px 0px 0px 6px");
      }
    }
    await shot("focus");
    await page.evaluate(() => (document.activeElement as HTMLElement | null)?.blur());
    const box = await el.boundingBox();
    if (box) { await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2); await page.mouse.down(); await shot("pressed"); await page.mouse.up(); }
  }
});

test("hit areas: >= 32 fine pointer", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await open(page);
  const small = await page.locator("main button, main a[href], main input, main textarea").evaluateAll((els) =>
    els.filter((e) => { const r = e.getBoundingClientRect(); const cs = getComputedStyle(e); return r.width > 0 && cs.visibility !== "hidden" && (r.width < 31.5 || r.height < 31.5) && !e.closest("[aria-hidden=true]") && (e as HTMLInputElement).type !== "hidden"; }).map((e) => `${e.tagName}:${(e.getAttribute("aria-label") ?? e.textContent ?? "").slice(0, 30)}:${Math.round(e.getBoundingClientRect().width)}x${Math.round(e.getBoundingClientRect().height)}`));
  expect(small).toEqual([]);
});

test.describe("coarse pointer at 390x844", () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  test("hit areas: >= 44", async ({ page }) => {
    await open(page);
    const small = await page.locator("main button, main a[href]").evaluateAll((els) =>
      els.filter((e) => { const r = e.getBoundingClientRect(); const cs = getComputedStyle(e); return r.width > 0 && cs.visibility !== "hidden" && (r.width < 43.5 || r.height < 43.5) && !e.closest("[aria-hidden=true]"); }).map((e) => `${e.tagName}:${(e.getAttribute("aria-label") ?? e.textContent ?? "").slice(0, 30)}:${Math.round(e.getBoundingClientRect().width)}x${Math.round(e.getBoundingClientRect().height)}`));
    expect(small).toEqual([]);
  });
});
