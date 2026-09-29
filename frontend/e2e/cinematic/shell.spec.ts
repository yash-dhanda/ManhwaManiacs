import path from "node:path";
import { pathToFileURL } from "node:url";
import { expect, test, type BrowserContext, type Page } from "@playwright/test";

// The proof harness is plain ESM (import.meta); Playwright's CJS transform would break a static import, so load it natively.
type SignIn = (context: BrowserContext, o: { base: string; user?: string; password?: string; profile?: string }) => Promise<unknown>;
const loadSignIn = async (): Promise<SignIn> => (await (new Function("u", "return import(u)") as (u: string) => Promise<{ signIn: SignIn }>)(pathToFileURL(path.resolve(__dirname, "../../scripts/proof.mjs")).href)).signIn;

/**
 * web/06 shell checks against a live stack (E2E_BASE_URL) with the seeded demo account (MM_PROOF_USER / MM_PROOF_PASSWORD),
 * in the Cinematic skin through the `mm-skin-debug` cookie.
 */
const USER = process.env.MM_PROOF_USER;
const PASSWORD = process.env.MM_PROOF_PASSWORD;
test.skip(!USER || !PASSWORD, "Set MM_PROOF_USER and MM_PROOF_PASSWORD.");

const PROOF = path.resolve(__dirname, "../../../docs/redesign/proof/web-06/states");
const SPLASH_KEY = "mm.skin.splash.cinematic";
const shot = (page: Page, name: string) => page.screenshot({ path: path.join(PROOF, `${name}.png`) });

async function enter(context: BrowserContext, base: string, warm = true) {
  // The dev overlay's portal would swallow pointer events.
  await context.addInitScript(() => { document.addEventListener("DOMContentLoaded", () => { const s = document.createElement("style"); s.textContent = "nextjs-portal{display:none!important}"; document.head.append(s); }); });
  const signIn = await loadSignIn();
  await signIn(context, { base, user: USER, password: PASSWORD, profile: "Riya" });
  await context.addCookies([{ name: "mm-skin-debug", value: "cinematic", url: base }]);
  if (warm) await context.addInitScript((k) => { try { sessionStorage.setItem(k, "1"); } catch { /* ignore */ } }, SPLASH_KEY);
}
const splashGone = (page: Page) => expect(page.locator("[data-splash]")).toHaveCount(0, { timeout: 8000 });
const width = (page: Page, sel: string) => page.locator(sel).first().evaluate((el) => Math.round(el.getBoundingClientRect().width));

test.beforeEach(async ({ context, baseURL }) => { await enter(context, baseURL!); });

test.describe("sidebar", () => {
  test("248 px at 1440, 72 px at 1024, mod+b toggles, overlay below 1280 closes on Esc", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/library");
    await splashGone(page);
    await expect.poll(() => width(page, 'nav[aria-label="Contents"]')).toBe(248);
    await page.keyboard.press("Control+b");
    await expect.poll(() => width(page, 'nav[aria-label="Contents"]')).toBe(72);
    await page.keyboard.press("Control+b");
    await expect.poll(() => width(page, 'nav[aria-label="Contents"]')).toBe(248);
    await page.evaluate(() => localStorage.removeItem("mm.sidebar"));
    await page.setViewportSize({ width: 1024, height: 768 });
    await expect.poll(() => width(page, 'nav[aria-label="Contents"]')).toBe(72);
    await shot(page, "sidebar-spine-1024x768");
    await page.locator("[data-sidebar-toggle]").first().click();
    const overlay = page.locator('nav[data-overlay="true"]');
    await expect(overlay).toBeVisible();
    expect(await width(page, 'nav[data-overlay="true"]')).toBe(248);
    await shot(page, "sidebar-overlay-1024x768");
    await page.keyboard.press("Escape");
    await expect(overlay).toHaveCount(0);
  });

  test("exactly one item is current: /library/collections lights 06 Collections", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/library/collections");
    const cur = page.locator('nav[aria-label="Contents"] [aria-current="page"]');
    await expect(cur).toHaveCount(1);
    await expect(cur).toContainText("Collections");
    await expect(cur).toContainText("06");
  });
});

test.describe("global keys", () => {
  test.beforeEach(async ({ page }) => { await page.setViewportSize({ width: 1440, height: 900 }); });

  test("g 2 goes to /library; g 1 1 to /circle; g 1 then a pause to /", async ({ page }) => {
    await page.goto("/search");
    await splashGone(page);
    await page.evaluate(() => { (window as unknown as { __twos: number }).__twos = 0; window.addEventListener("keydown", (e) => { if (e.key === "2") (window as unknown as { __twos: number }).__twos++; }); });
    await page.keyboard.press("g");
    await expect(page.locator("[data-g-chip]")).toContainText("G");
    await page.keyboard.press("2");
    await expect(page).toHaveURL(/\/library$/);
    expect(await page.evaluate(() => (window as unknown as { __twos: number }).__twos)).toBe(0);
    await page.keyboard.press("g"); await page.keyboard.press("1"); await page.keyboard.press("1");
    await expect(page).toHaveURL(/\/circle$/);
    await page.goto("/search");
    await splashGone(page);
    await page.keyboard.press("g"); await page.keyboard.press("1");
    await page.waitForTimeout(700);
    await expect(page).toHaveURL(/\/$/);
  });

  test("mod+k opens the palette, filters, arrows and Enter navigate, Esc restores focus", async ({ page }) => {
    await page.goto("/search");
    await splashGone(page);
    const trigger = page.locator("[data-search-trigger]");
    await trigger.focus();
    await page.keyboard.press("Control+k");
    const dlg = page.getByRole("dialog", { name: "Search or jump" });
    await expect(dlg).toBeVisible();
    const field = dlg.getByRole("searchbox");
    await expect(field).toBeFocused();
    await shot(page, "palette-open-1440x900");
    await field.fill("hist");
    await expect(dlg.getByRole("option").first()).toContainText(/History/i);
    await shot(page, "palette-filtered-1440x900");
    await page.keyboard.press("Escape");
    await expect(dlg).toHaveCount(0);
    await expect(trigger).toBeFocused();
    await page.keyboard.press("Control+k");
    await page.getByRole("dialog", { name: "Search or jump" }).getByRole("searchbox").fill("hist");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await expect(page).not.toHaveURL(/\/search$/);
  });

  test("? opens the keyboard sheet and it lists Alt+T", async ({ page }) => {
    await page.goto("/search");
    await splashGone(page);
    await page.keyboard.press("?");
    const dlg = page.getByRole("dialog", { name: "Keyboard" });
    await expect(dlg).toBeVisible();
    await expect(dlg).toContainText("Go to notifications");
    await expect(dlg).toContainText("Alt");
    await shot(page, "keyboard-sheet-1440x900");
  });
});

test.describe("focus and titles", () => {
  test("the skip link is the first Tab stop and moves focus to main h1", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/");
    await splashGone(page);
    await expect(page.locator("main h1")).toBeVisible();
    await page.keyboard.press("Tab");
    await expect(page.getByRole("link", { name: "Skip to content" })).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(page.locator("main h1")).toBeFocused();
  });

  test("a sidebar navigation focuses the new h1 and sets the title", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/library/collections");
    await splashGone(page);
    await page.locator('nav[aria-label="Contents"]').getByRole("link", { name: /Discover/ }).click();
    await expect(page).toHaveURL(/\/search/);
    await expect(page.locator("main h1")).toBeFocused();
    await expect(page).toHaveTitle(/· ManhwaManiacs$/);
  });
});

test.describe("phone 390 x 844", () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });

  test("thumb index: five tabs at least 44 x 44, the notch on the active tab, the running title after the masthead scrolls", async ({ page }) => {
    await page.goto("/search");
    await splashGone(page);
    const tabs = page.locator('nav[aria-label="Sections"] a');
    await expect(tabs).toHaveCount(5);
    for (const box of await tabs.evaluateAll((els) => els.map((e) => { const r = e.getBoundingClientRect(); return [r.width, r.height]; }))) { expect(box[0]).toBeGreaterThanOrEqual(44); expect(box[1]).toBeGreaterThanOrEqual(44); }
    await expect(page.locator('[data-notch="discover"]')).toHaveCount(1);
    await expect(page.locator('a[data-tab="discover"]')).toHaveAttribute("aria-current", "page");
    const title = page.locator(".cine-head-title");
    await expect(title).toHaveCSS("opacity", "0");
    await page.evaluate(() => { const s = document.createElement("div"); s.style.height = "3000px"; document.querySelector("main")!.appendChild(s); });
    await page.evaluate(() => window.scrollTo(0, 900));
    await expect(title).toHaveCSS("opacity", "1");
    await shot(page, "thumb-index-390x844");
  });
});

test("an unknown URL renders the in-frame 404 inside the Shell", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/does-not-exist");
  await splashGone(page);
  await expect(page.locator("[data-cine-shell] main h1")).toContainText("This page doesn't exist.");
  await expect(page.locator('nav[aria-label="Contents"]')).toBeVisible();
  await shot(page, "not-found-1440x900");
});

test("offline shows OFFLINE EDITION and going online shows BACK ONLINE for about two seconds", async ({ page, context }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/search");
  await splashGone(page);
  await context.setOffline(true);
  await expect(page.getByText("OFFLINE EDITION").first()).toBeVisible();
  await shot(page, "offline-badge-1440x900");
  await context.setOffline(false);
  await expect(page.getByText("BACK ONLINE").first()).toBeVisible();
  await expect(page.getByText("BACK ONLINE")).toHaveCount(0, { timeout: 4000 });
});

test.describe("splash", () => {
  test.beforeEach(async ({ context }) => { await context.addInitScript((k) => { try { sessionStorage.removeItem(k); } catch { /* ignore */ } }, SPLASH_KEY); });

  test("cold start: the lockup is up by 1,400 ms and the layer is gone after the hand-off", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/library");
    await expect(page.locator("[data-splash]")).toHaveCount(1);
    await page.waitForTimeout(700);
    await expect(page.locator("[data-splash-lockup]")).toBeVisible();
    await splashGone(page);
    expect(await page.evaluate((k) => sessionStorage.getItem(k), SPLASH_KEY)).toBe("1");
  });

  test("warm start: only fades, no letters", async ({ page }) => {
    await page.addInitScript((k) => { try { sessionStorage.setItem(k, "1"); } catch { /* ignore */ } }, SPLASH_KEY);
    await page.goto("/library");
    await expect(page.locator("[data-splash] .set-letter")).toHaveCount(0);
    await splashGone(page);
  });

  test("reduced motion: no letter transforms", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto("/library");
    await page.waitForTimeout(500);
    const moving = await page.evaluate(() => [...document.querySelectorAll("[data-splash] .set-letter")].filter((e) => getComputedStyle(e).transform !== "none").length);
    expect(moving).toBe(0);
    await splashGone(page);
  });
});

test.describe("column wipe", () => {
  test("12 blades cover the viewport and navigation happens after the close", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/library");
    await splashGone(page);
    await page.evaluate(() => void (window as unknown as { __cine: { enterReader: (h: string, o: { entry: string }) => void } }).__cine.enterReader("/sources", { entry: "wipe" }));
    await expect(page.locator("[data-blade]")).toHaveCount(12);
    expect(new URL(page.url()).pathname).toBe("/library");
    const rects = await page.locator("[data-blade]").evaluateAll((els) => els.map((e) => { const r = e.getBoundingClientRect(); return [r.left, r.right]; }));
    expect(rects[0][0]).toBeCloseTo(0, 0);
    expect(rects[11][1]).toBeCloseTo(1440, 0);
    for (let i = 1; i < 12; i++) expect(rects[i][0]).toBeCloseTo(rects[i - 1][1], 0);
    await expect(page).toHaveURL(/\/sources$/);
    await expect(page.locator("[data-blade]")).toHaveCount(0, { timeout: 4000 });
  });

  test("reduced motion: a fade, no blades", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/library");
    await splashGone(page);
    await page.evaluate(() => void (window as unknown as { __cine: { enterReader: (h: string, o: { entry: string }) => void } }).__cine.enterReader("/sources", { entry: "wipe" }));
    await expect(page).toHaveURL(/\/sources$/);
    expect(await page.locator("[data-blade]").count()).toBe(0);
  });
});

test("reduced motion: page transitions are opacity-only", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/library");
  const names = await page.evaluate(() => {
    const out: string[] = [];
    const walk = (rules: CSSRuleList, inReduce: boolean) => { for (const r of Array.from(rules)) {
      if (r instanceof CSSMediaRule) walk(r.cssRules, inReduce || r.conditionText.includes("reduce"));
      else if (inReduce && r.cssText.includes("view-transition") && /mm-(page|dip|dissolve)/.test(r.cssText)) out.push(r.cssText);
    } };
    for (const sheet of Array.from(document.styleSheets)) { try { walk(sheet.cssRules, false); } catch { /* cross-origin */ } }
    return out;
  });
  expect(names.length).toBeGreaterThan(0);
  for (const css of names) { expect(css).toContain("mm-vt-fade"); expect(css).not.toContain("translateX"); }
});
