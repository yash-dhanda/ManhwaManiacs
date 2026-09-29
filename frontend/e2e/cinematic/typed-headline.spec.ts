import { expect, test } from "@playwright/test";
import { open, replay } from "./gallery";

const shown = (page: import("@playwright/test").Page) => page.locator('[data-testid="typed"] [data-typed="shown"]');
const len = async (page: import("@playwright/test").Page) => [...((await shown(page).textContent()) ?? "")].length;

test("one grapheme per 50 ms, caret blinks out when done", async ({ page }) => {
  await open(page);
  await replay(page); // warm: first mount pays module and font cost
  await page.waitForTimeout(2600);
  await page.locator("#reveals").scrollIntoViewIfNeeded();
  // Measure from the moment the new headline mounts (not from the click), so click latency cannot leak in: floor(t / 50) +- 1.
  const samples = await page.evaluate(() => new Promise<{ t: number; n: number }[]>((res) => {
    const sel = '[data-testid="typed"] [data-typed="shown"]';
    const before = document.querySelector(sel);
    const out: { t: number; n: number }[] = [];
    const mo = new MutationObserver(() => {
      const el = document.querySelector(sel);
      if (!el || el === before) return;
      mo.disconnect();
      const t0 = performance.now();
      for (const t of [500, 1000, 2100]) setTimeout(() => {
        out.push({ t: performance.now() - t0, n: [...(document.querySelector(sel)?.textContent ?? "")].length });
        if (out.length === 3) res(out);
      }, t);
    });
    mo.observe(document.body, { childList: true, subtree: true });
    (document.querySelector('[data-gallery="reveals-replay"]') as HTMLElement).click();
  }));
  for (const s of samples) expect(Math.abs(s.n - Math.min(40, Math.floor(s.t / 50))), `at ${Math.round(s.t)} ms`).toBeLessThanOrEqual(1);
  expect(samples[2].n).toBe(40);
  await expect(page.locator('[data-testid="typed"] .animate-caret-out')).toHaveCount(1);
  await expect(page.locator('[data-testid="typed"] .sr-only')).toHaveText("The night the city forgot its own names.");
});

test("click skips and stops the clock; Enter completes", async ({ page }) => {
  await open(page);
  await replay(page);
  await page.waitForTimeout(300);
  await page.locator('[data-testid="typed"] h2').click();
  expect(await len(page)).toBe(40);
  await page.waitForTimeout(200);
  expect(await len(page)).toBe(40);
  await page.locator('[data-gallery="reveals-replay"]').click();
  await page.locator('[data-testid="typed"] h2').focus();
  await page.keyboard.press("Enter");
  expect(await len(page)).toBe(40);
});

test("reduced motion: full text at once, no caret", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await open(page);
  await replay(page);
  await page.waitForTimeout(100);
  expect(await len(page)).toBe(40);
  await expect(page.locator('[data-testid="typed"] .bg-spot')).toHaveCount(0);
});
