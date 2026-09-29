import { expect, test } from "@playwright/test";
import { open, replay } from "./gallery";

const letters = (page: import("@playwright/test").Page) => page.locator('[data-testid="reveal-library"] .set-letter');
const opacity = (l: import("@playwright/test").Locator) => l.evaluate((e) => Number(getComputedStyle(e).opacity));

test("letters stagger in, then rest at 1", async ({ page }) => {
  await open(page);
  await page.locator("#reveals").scrollIntoViewIfNeeded();
  // sample inside the page so click and 200 ms probe share one clock
  const at200 = await page.evaluate(() => new Promise<{ first: number; last: number }>((res) => {
    (document.querySelector('[data-gallery="reveals-replay"]') as HTMLElement).click();
    setTimeout(() => {
      const l = document.querySelectorAll('[data-testid="reveal-library"] .set-letter');
      res({ first: Number(getComputedStyle(l[0]).opacity), last: Number(getComputedStyle(l[l.length - 1]).opacity) });
    }, 200);
  }));
  expect(at200.first).toBeGreaterThan(0);
  expect(at200.first).toBeLessThan(1);
  expect(at200.last).toBeLessThan(0.5);
  await page.waitForTimeout(1200);
  const l = letters(page);
  for (let i = 0; i < (await l.count()); i++) expect(await opacity(l.nth(i))).toBe(1);
  const h = page.locator('[data-testid="reveal-library"] h2');
  await expect(h).toHaveAttribute("aria-label", "Library");
  for (let i = 0; i < (await l.count()); i++) expect(await l.nth(i).evaluate((e) => e.parentElement?.getAttribute("aria-hidden"))).toBe("true");
});

test("reduced motion (OS): no transform, whole string fades in over 200 ms", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await open(page);
  await replay(page);
  const l = letters(page);
  for (let i = 0; i < (await l.count()); i++) expect(await l.nth(i).evaluate((e) => getComputedStyle(e).transform)).toBe("none");
  await page.waitForTimeout(400);
  expect(await opacity(page.locator('[data-testid="reveal-library"] h2'))).toBe(1);
});

test("reduced motion (html[data-motion=reduced])", async ({ page }) => {
  await open(page);
  await page.evaluate(() => { document.documentElement.dataset.motion = "reduced"; });
  await replay(page);
  const l = letters(page);
  for (let i = 0; i < (await l.count()); i++) expect(await l.nth(i).evaluate((e) => getComputedStyle(e).transform)).toBe("none");
});

test("as=p renders the text in an sr-only span", async ({ page }) => {
  await open(page);
  await expect(page.locator('[data-testid="reveal-p"] p > span.sr-only')).toHaveText("Welcome back");
});

test("long words: 358 px column at 200 % root fits; 160 px column falls back to plain text", async ({ page }) => {
  await open(page);
  await page.evaluate(() => { document.documentElement.style.fontSize = "200%"; });
  await replay(page);
  await page.waitForTimeout(1500);
  const box = page.getByTestId("narrow-358");
  expect(await box.evaluate((e) => e.scrollWidth <= e.clientWidth)).toBe(true);
  const narrow = page.getByTestId("narrow-160");
  await expect(narrow.locator(".set-letter")).toHaveCount(0);
  expect(await narrow.evaluate((e) => e.scrollWidth <= e.clientWidth)).toBe(true);
});
