import { expect, test } from "@playwright/test";
import { open } from "./gallery";

test("one tab stop per rail, arrows, slate", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await open(page);
  const rail = page.locator('[data-gallery="rail-ready"]');
  await rail.scrollIntoViewIfNeeded();
  await expect(rail.locator('[data-rail-item][tabindex="0"]')).toHaveCount(1);
  const first = rail.locator('[data-rail-item]').first();
  await first.focus();
  await page.keyboard.press("ArrowRight");
  await expect(rail.locator('[data-rail-item]').nth(1)).toBeFocused();
  await page.keyboard.press("ArrowDown");
  await expect(page.locator('[data-gallery="rail-second"] [data-rail-item][tabindex="0"]')).toBeFocused();
  await page.keyboard.press("ArrowUp");
  await expect(rail.locator('[data-rail-item]').nth(1)).toBeFocused();
  const poster = rail.locator('[data-rail-item]').nth(1);
  await page.keyboard.press("Space");
  await expect(poster).toHaveAttribute("aria-expanded", "true");
  await expect(page.locator('[role="dialog"] button').first()).toBeFocused();
  await expect(page.locator('[role="dialog"] button').first()).toHaveText(/Read/);
  await page.keyboard.press("Escape");
  await expect(poster).toHaveAttribute("aria-expanded", "false");
  await expect(poster).toBeFocused();
});
