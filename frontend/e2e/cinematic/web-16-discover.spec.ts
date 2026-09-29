import path from "node:path";
import { expect, test, type Page } from "@playwright/test";

/**
 * web/16 checks: titles and route focus, reduced motion, hit targets, mocked
 * search states. Runs against a live stack (E2E_BASE_URL) with the seeded demo
 * account (MM_PROOF_USER / MM_PROOF_PASSWORD). TODO(web/03): use signIn from
 * scripts/proof.mjs once that harness lands.
 */
const USER = process.env.MM_PROOF_USER;
const PASSWORD = process.env.MM_PROOF_PASSWORD;
test.skip(!USER || !PASSWORD, "Set MM_PROOF_USER and MM_PROOF_PASSWORD.");

const PROOF = path.resolve(__dirname, "../../../docs/redesign/proof/web-16");

async function signIn(page: Page) {
  await page.goto("/login");
  await page.locator("#login-username").fill(USER!);
  await page.locator("#login-password").fill(PASSWORD!);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL(/\/(library|profiles)/);
  if (new URL(page.url()).pathname.startsWith("/profiles")) {
    await page.getByRole("button", { name: /^Read as / }).first().click();
    await page.waitForURL(/\/library/);
  }
  const url = new URL(page.url());
  await page.context().addCookies([{ name: "mm-skin-debug", value: "cinematic", domain: url.hostname, path: "/" }]);
}

const ROUTES: Array<[string, string]> = [
  ["/search", "Discover · ManhwaManiacs"],
  ["/sources", "Sources · ManhwaManiacs"],
  ["/ocr", "Dialogue search · ManhwaManiacs"],
];

test.beforeEach(async ({ page }) => {
  await signIn(page);
});

for (const [route, title] of ROUTES) {
  test(`title and route focus ${route}`, async ({ page }) => {
    await page.goto(route);
    await expect(page).toHaveTitle(title);
    await expect(page.locator("h1")).toBeFocused();
  });
}

test("reduced motion: placeholder complete, no running letter reveal", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/search");
  await page.waitForTimeout(250);
  const running = await page.evaluate(() =>
    document.getAnimations().filter((a) => (a as CSSAnimation).animationName === "letter" && a.playState === "running").length,
  );
  expect(running).toBe(0);
  const ghost = await page.locator("input[type=search]").getAttribute("placeholder");
  expect(ghost).toBe("Search every source");
});

for (const [route] of ROUTES) {
  test(`hit targets ${route}`, async ({ browser }) => {
    for (const [w, h, min] of [[390, 844, 44], [1440, 900, 32]] as const) {
      const ctx = await browser.newContext({ viewport: { width: w, height: h }, hasTouch: w < 768 });
      const page = await ctx.newPage();
      await signIn(page);
      await page.goto(route);
      await page.waitForTimeout(600);
      const small = await page.evaluate((m) => {
        const bad: string[] = [];
        for (const el of document.querySelectorAll<HTMLElement>("main button, main a, main [role=tab], main select, main input")) {
          if (el.closest(".sr") || getComputedStyle(el).display === "none") continue;
          const r = el.getBoundingClientRect();
          if (r.width === 0 || r.height === 0) continue;
          if (r.width < m || r.height < m) bad.push(`${el.tagName} ${(el.textContent ?? "").trim().slice(0, 24)} ${Math.round(r.width)}x${Math.round(r.height)}`);
        }
        return bad;
      }, min);
      expect(small, `${route} @${w}`).toEqual([]);
      await ctx.close();
    }
  });
}

test("search states: partial, failed group, rate limited", async ({ page }) => {
  const group = (source: string | null, name: string, status: "ok" | "error", items: unknown[] = []) => ({
    source, source_name: name, icon_url: null, status, error: status === "error" ? "boom" : null, total: items.length, has_more: false, items,
  });
  const item = (id: string, title: string) => ({ kind: "source", source: "mangadex", series_id: id, title, cover_url: null, author: null, chapter_count: 12, extra: null });
  await page.route("**/api/sources/search*", async (route) => {
    const tier = new URL(route.request().url()).searchParams.get("tier");
    const body = {
      items: [],
      groups: [group(null, "Library", "ok"), group("mangadex", "MangaDex", "ok", [item("a", "Solo A"), item("b", "Solo B")]), group("dead", "Dead Source", "error")],
      sources_queried: 3, sources_failed: 1, sources_deferred: 77, tier: Number(tier), next_tier: tier === "1" ? 2 : null, page: 1, has_more: false,
    };
    if (tier === "2") return new Promise(() => {}); // tier 2 never answers: the partial state
    await route.fulfill({ json: body });
  });
  await page.goto("/search?q=solo");
  await expect(page.getByText("results so far")).toBeVisible();
  await expect(page.getByText("This source didn't answer.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Retry" })).toBeVisible();
  await page.screenshot({ path: path.join(PROOF, "state-partial.png"), fullPage: true });

  await page.unroute("**/api/sources/search*");
  await page.route("**/api/sources/search*", (route) => route.fulfill({ status: 429, json: { code: "rate_limited", message: "slow" } }));
  await page.goto("/search?q=solo2");
  await expect(page.getByText("SLOW DOWN")).toBeVisible();
  await page.screenshot({ path: path.join(PROOF, "state-rate-limited.png") });
});
