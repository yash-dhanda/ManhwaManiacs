import { expect, test, type Page } from "@playwright/test";

/**
 * Glass foundation (web/25): the material on /dev/glass-calibration. Needs `next dev` only (no sign-in, no
 * backend). One browser context per test, Chromium.
 *
 *   E2E_BASE_URL=http://127.0.0.1:3033 npx playwright test e2e/glass-foundation.spec.ts --workers=1
 */
const PAGE = "/dev/glass-calibration";
const bg = (page: Page, id: string) => page.locator(`[data-testid=${id}] > .glass__bg`);
const ready = async (page: Page, id = "t2-button") => {
  // hydrated and its map built
  await expect(page.locator(`[data-testid=${id}]`)).toHaveAttribute("data-map-builds", /\d+/, { timeout: 20_000 });
};
const backdrop = (page: Page, id: string) => bg(page, id).evaluate((el) => getComputedStyle(el).backdropFilter);
const fill = (page: Page, id: string) => bg(page, id).evaluate((el) => getComputedStyle(el).backgroundColor);

test.describe("tiers", () => {
  test("liquid refracts through the SVG lens, frosted is blur + 6 px, solid is opaque", async ({ page }) => {
    await page.goto(PAGE);
    await ready(page);
    expect(await backdrop(page, "t2-button")).toMatch(/url\(["']?#lens-/);
    await page.evaluate(() => { document.documentElement.dataset.glassRenderer = "frosted"; });
    const frosted = await backdrop(page, "t2-button");
    expect(frosted).not.toContain("url(");
    expect(frosted).toContain("blur(14px)"); // T2 blur 8 + 6

    await page.evaluate(() => { document.documentElement.dataset.solid = "on"; });
    expect(await backdrop(page, "t2-button")).toBe("none");
    expect(await fill(page, "t2-button")).toBe("rgb(28, 28, 34)");
    expect(await fill(page, "t4-menu")).toBe("rgb(38, 38, 46)");

    await page.goto(`${PAGE}?section=4`);
    await page.evaluate(() => { document.documentElement.dataset.solid = "on"; });
    expect(await fill(page, "tinted-button")).toBe("rgb(91, 74, 209)");
  });

  test("?renderer=frosted overrides the stamp", async ({ page }) => {
    await page.goto(`${PAGE}?renderer=frosted`);
    await expect(page.locator("html")).toHaveAttribute("data-glass-renderer", "frosted");
    expect(await backdrop(page, "t2-button")).not.toContain("url(");
  });

  test("Increase contrast adds the 1 px 55 % rim and raises the dim floor to 0.40", async ({ page }) => {
    await page.goto(`${PAGE}?section=6`);
    await expect(page.locator("[data-testid=demo-surface]")).toBeVisible();
    await page.getByRole("button", { name: "Dim shift" }).click(); // Lb 0.1: dim 0.262
    const dim = () => page.locator("[data-testid=demo-surface]").evaluate((el) => getComputedStyle(el).getPropertyValue("--glass-dim"));
    await expect.poll(async () => Number(await dim())).toBeCloseTo(0.262, 2);
    await page.getByRole("button", { name: "Increase contrast" }).click();
    await expect.poll(async () => Number(await dim())).toBeCloseTo(0.4, 2);
    const rim = await page.locator("[data-testid=demo-surface] > .glass__rim").evaluate((el) => {
      const s = getComputedStyle(el);
      return { pad: s.paddingTop, bg: s.backgroundColor };
    });
    expect(rim).toEqual({ pad: "1px", bg: "rgba(255, 255, 255, 0.55)" });
  });
});

test.describe("motion", () => {
  test("reduced motion pins the light and freezes the ambient drift", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto(PAGE);
    await ready(page);
    const angle = () => page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue("--mm-light-angle").trim());
    await page.mouse.move(10, 300);
    await page.mouse.move(1400, 300);
    await page.waitForTimeout(300);
    expect(await angle()).toBe("135deg");
    const anchors = () => page.evaluate(() => document.querySelector<HTMLElement>("[data-ambient-field]")!.getAttribute("style") ?? "");
    const before = await anchors();
    await page.waitForTimeout(15_000);
    expect(await anchors()).toBe(before);
    expect(before).not.toContain("--amb-x1");
  });

  test("a materialising surface is at full refraction from its first frame", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto(`${PAGE}?section=6`);
    await expect(page.locator("[data-testid=demo-surface]")).toHaveAttribute("data-map-builds", /\d+/, { timeout: 20_000 });
    await page.getByRole("button", { name: "Dematerialise", exact: true }).click();
    await expect(page.locator("[data-testid=demo-surface]")).toHaveCount(0);
    await page.evaluate(() => {
      const w = window as unknown as { __scales: string[] };
      w.__scales = [];
      new MutationObserver((rs) => {
        for (const r of rs) if (r.attributeName === "scale") w.__scales.push((r.target as Element).getAttribute("scale") ?? "");
      }).observe(document.querySelector("defs")!, { attributes: true, subtree: true, childList: true });
    });
    await page.getByRole("button", { name: "Materialise", exact: true }).click();
    await expect(page.locator("[data-testid=demo-surface]")).toHaveAttribute("data-map-builds", /\d+/, { timeout: 20_000 });
    await page.waitForTimeout(600);
    const scales = await page.evaluate(() => (window as unknown as { __scales: string[] }).__scales);
    expect(scales.length).toBeGreaterThan(0);
    expect(new Set(scales).size).toBe(1); // no ramp: never 0 and never in between
    expect(Number(scales[0])).toBeGreaterThan(0);
  });
});

test("the T2 focus ring is the two-tone ring and is not clipped", async ({ page }) => {
  await page.goto(PAGE);
  await ready(page);
  await page.locator("[data-testid=t2-button]").focus();
  await page.keyboard.press("Shift+Tab");
  await page.keyboard.press("Tab");
  await expect(page.locator("[data-testid=t2-button]")).toBeFocused();
  const shadow = await page.locator("[data-testid=t2-button]").evaluate((el) => getComputedStyle(el).boxShadow);
  expect(shadow).toContain("rgb(0, 0, 0) 0px 0px 0px 2px");
  expect(shadow).toContain("rgb(188, 176, 255) 0px 0px 0px 4px");
  expect(shadow).toContain("rgba(188, 176, 255, 0.28)");
  await page.locator("[data-testid=t2-button]").screenshot({ path: "test-results/focus-ring-t2.png", animations: "disabled" });
});

test("the seventh live glass surface warns once; a three-layer overlap renders the lowest solid", async ({ page }) => {
  const warns: string[] = [];
  page.on("console", (m) => { if (m.type() === "warning" && m.text().includes("[glass]")) warns.push(m.text()); });
  await page.goto(PAGE);
  await ready(page);
  const add = page.getByRole("button", { name: /Add glass surface/ });
  await add.click();
  await add.click();
  expect(warns).toHaveLength(0); // 4 + 2 = 6
  await add.click(); // 7
  await expect(page.locator("[data-testid=count]")).toContainText("7 / 6");
  await expect.poll(() => warns.length).toBe(1);
  await page.waitForTimeout(300);
  expect(warns).toHaveLength(1);

  await page.getByRole("button", { name: "Stack test" }).click();
  await expect(page.locator("[data-testid=stack-low]")).toHaveAttribute("data-forced-solid", "", { timeout: 5000 });
  expect(await bg(page, "stack-low").evaluate((el) => getComputedStyle(el).backdropFilter)).toBe("none");
});

test("resizing the T4 menu rebuilds its map once, at least 100 ms after the last resize", async ({ page }) => {
  await page.goto(PAGE);
  await ready(page, "t4-menu");
  await page.waitForTimeout(500);
  const result = await page.evaluate(async () => {
    const el = document.querySelector<HTMLElement>("[data-testid=t4-menu]")!;
    const builds = () => Number(el.dataset.mapBuilds);
    const start = builds();
    let rebuilt = 0;
    new MutationObserver(() => { rebuilt = performance.now(); }).observe(el, { attributes: true, attributeFilter: ["data-map-builds"] });
    let lastResize = 0;
    for (const w of [250, 262, 274, 286, 300]) {
      el.style.width = `${w}px`;
      lastResize = performance.now();
      await new Promise((r) => setTimeout(r, 30));
    }
    await new Promise((r) => setTimeout(r, 800));
    return { delta: builds() - start, gap: rebuilt - lastResize };
  });
  expect(result.delta).toBe(1);
  expect(result.gap).toBeGreaterThanOrEqual(100);
});
