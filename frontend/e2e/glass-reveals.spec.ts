import { expect, test } from "@playwright/test";

const URL = "/dev/glass-primitives?section=reveals";
test.use({ viewport: { width: 1440, height: 900 } });

test("typing runs at 200 ms with focus on the heading, caret follows, completes by 3 s, skips on pointer", async ({ page }) => {
  await page.goto(URL, { waitUntil: "domcontentloaded" });
  const h = page.getByTestId("typed-greeting");
  await page.waitForTimeout(200);
  await h.focus();
  const op = (i: number) => h.locator("[data-g]").nth(i).evaluate((e) => Number(getComputedStyle(e).opacity));
  expect(await op(9)).toBeLessThan(0.1);
  await page.waitForTimeout(150);
  await expect(h).toHaveAttribute("data-typing", "run");
  // caret past grapheme 0 whenever grapheme 6 is visible
  const seen = await page.evaluate(async () => {
    const el = document.querySelector('[data-testid="typed-greeting"]')!;
    const g6 = el.querySelectorAll("[data-g]")[6], caret = el.querySelector(".caret")!;
    let bad = 0;
    for (let i = 0; i < 40; i++) { if (Number(getComputedStyle(g6).opacity) > 0.9 && getComputedStyle(caret).translate.startsWith("0px")) bad++; await new Promise((r) => setTimeout(r, 40)); }
    return bad;
  });
  expect(seen).toBe(0);
  await page.waitForTimeout(3000);
  for (let i = 0; i < 18; i++) expect(await op(i)).toBe(1);
});

test("pointerdown completes the typing", async ({ page }) => {
  await page.goto(URL, { waitUntil: "domcontentloaded" });
  const h = page.getByTestId("typed-greeting");
  await page.waitForTimeout(150);
  await h.dispatchEvent("pointerdown");
  await expect(h).toHaveClass(/is-done/);
});

test("a key press with focus on body completes the typing", async ({ page }) => {
  await page.goto(URL, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(150);
  await page.evaluate(() => (document.activeElement as HTMLElement | null)?.blur());
  await page.keyboard.press("x");
  await expect(page.getByTestId("typed-greeting")).toHaveClass(/is-done/);
});

test("below-the-fold headers wait for 25 % visibility, at most two run at once, reload shows rest", async ({ page }) => {
  await page.goto(URL, { waitUntil: "domcontentloaded" });
  const heads = ["a", "b", "c"].map((k) => page.getByTestId(`rail-head-${k}`));
  for (const h of heads) await expect(h).toHaveAttribute("data-reveal", "wait");
  const box = await page.getByTestId("three-rails").boundingBox();
  await page.evaluate((y) => window.scrollTo(0, y - 300), box!.y);
  let maxRun = 0, sawThird = false;
  for (let i = 0; i < 60; i++) {
    const st = await Promise.all(heads.map((h) => h.getAttribute("data-reveal")));
    maxRun = Math.max(maxRun, st.filter((s) => s === "run").length);
    if (st[2] === "run" && st.filter((s) => s === "done").length >= 1) sawThird = true;
    await page.waitForTimeout(100);
  }
  expect(maxRun).toBeLessThanOrEqual(2);
  expect(sawThird || (await heads[2].getAttribute("data-reveal")) === "done").toBe(true);
  await page.reload({ waitUntil: "domcontentloaded" });
  await expect(page.getByTestId("typed-greeting")).toHaveClass(/is-done/);
  await expect(heads[0]).toHaveAttribute("data-reveal", "done");
});

test("the long heading animates per word", async ({ page }) => {
  await page.goto(URL, { waitUntil: "domcontentloaded" });
  const n = await page.getByTestId("long-head").locator(".word[style]").count();
  expect(n).toBeGreaterThan(5);
  expect(await page.getByTestId("long-head").locator(".g").count()).toBe(0);
});

test.describe("reduced motion", () => {
  test("full text at once, no caret", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto(URL, { waitUntil: "domcontentloaded" });
    const h = page.getByTestId("typed-greeting");
    await expect(h).toHaveClass(/is-done/);
    expect(await h.locator("[data-g]").nth(9).evaluate((e) => getComputedStyle(e).opacity)).toBe("1");
    expect(await h.locator(".caret").evaluate((e) => getComputedStyle(e).display)).toBe("none");
  });
});
