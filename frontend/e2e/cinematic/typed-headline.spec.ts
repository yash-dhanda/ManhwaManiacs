import { expect, test } from "@playwright/test";
import { open, replay } from "./gallery";

const shown = (page: import("@playwright/test").Page) => page.locator('[data-testid="typed"] [data-typed="shown"]');
const len = async (page: import("@playwright/test").Page) => [...((await shown(page).textContent()) ?? "")].length;

test("one grapheme per 50 ms, caret blinks out when done", async ({ page }) => {
  await open(page);
  await replay(page);
  const t0 = Date.now();
  await page.waitForTimeout(500 - (Date.now() - t0));
  expect(Math.abs((await len(page)) - 10)).toBeLessThanOrEqual(3);
  await page.waitForTimeout(500);
  expect(Math.abs((await len(page)) - 20)).toBeLessThanOrEqual(3);
  await page.waitForTimeout(1200);
  expect(await len(page)).toBe(40);
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
