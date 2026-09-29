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

export async function signIn(page: Page) {
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

// ---- limiter priorities, keys, group jump, states, reader jump ---------------

const shot = (page: Page, name: string, full = false) => page.screenshot({ path: path.join(PROOF, `state-${name}.png`), fullPage: full });
const searchItem = (id: string, title: string) => ({ kind: "source", source: "mangadex", series_id: id, title, cover_url: null, author: null, chapter_count: 12, extra: null });
const searchGroup = (source: string | null, name: string, status: "ok" | "error", items: unknown[] = []) => ({
  source, source_name: name, icon_url: null, status, error: status === "error" ? "boom" : null, total: items.length, has_more: false, items,
});
const searchBody = (groups: unknown[], extra: Record<string, unknown> = {}) => ({
  items: [], groups, sources_queried: groups.length, sources_failed: 0, sources_deferred: 0, tier: 1, next_tier: null, page: 1, has_more: false, ...extra,
});

test("P3 limiter: the search request goes out before any genre cover lookup", async ({ page }) => {
  const seen: string[] = [];
  page.on("request", (r) => {
    const u = new URL(r.url());
    if (u.pathname.endsWith("/sources/search")) seen.push("search");
    else if (u.searchParams.has("genre") && u.pathname.includes("/series")) seen.push("genre-cover");
  });
  await page.goto("/search?q=solo");
  await page.waitForTimeout(4000);
  expect(seen.length).toBeGreaterThan(0);
  expect(seen[0]).toBe("search");
});

test("keys: / focuses the field, 2 switches scope, arrow down enters results", async ({ page }) => {
  await page.route("**/api/sources/search*", (r) => r.fulfill({ json: searchBody([searchGroup("mangadex", "MangaDex", "ok", [searchItem("a", "Solo A")])]) }));
  await page.goto("/search?q=solo");
  await expect(page.getByText("Solo A").first()).toBeVisible();
  await page.locator("h1").focus();
  await page.keyboard.press("/");
  await expect(page.locator("input[type=search]")).toBeFocused();
  await page.locator("input[type=search]").focus();
  await page.keyboard.press("ArrowDown");
  await expect(page.locator("[data-poster]:focus").first()).toBeVisible();
  await page.locator("input[type=search]").focus();
  await page.locator("input[type=search]").blur();
  await page.keyboard.press("2");
  await expect(page).toHaveURL(/scope=library/);
});

test("group jump under reduced motion lands instantly", async ({ browser }) => {
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, reducedMotion: "reduce" });
  const page = await ctx.newPage();
  await signIn(page);
  const many = (p: string) => Array.from({ length: 24 }, (_, i) => searchItem(`${p}${i}`, `${p} title ${i}`));
  await page.route("**/api/sources/search*", (r) =>
    r.fulfill({ json: searchBody([searchGroup("mangadex", "MangaDex", "ok", many("m")), searchGroup("webtoons", "Webtoons", "ok", many("w"))]) }),
  );
  await page.goto("/search?q=title");
  await expect(page.getByText("m title 0").first()).toBeVisible();
  const before = await page.evaluate(() => document.scrollingElement!.scrollTop);
  await page.getByRole("navigation", { name: "Jump to source" }).getByRole("button", { name: /Webtoons/ }).click();
  await page.waitForTimeout(60);
  const after = await page.evaluate(() => document.scrollingElement!.scrollTop);
  expect(after).toBeGreaterThan(before);
  await page.waitForTimeout(400);
  expect(await page.evaluate(() => document.scrollingElement!.scrollTop)).toBe(after); // already at rest: no smooth scroll
  await ctx.close();
});

test("state screenshots: idle, failed group, no results, error, offline, opening", async ({ page, context }) => {
  await page.goto("/search");
  await page.waitForTimeout(9000);
  await shot(page, "idle", true);

  await page.route("**/api/sources/search*", (r) => r.fulfill({ json: searchBody([searchGroup("dead", "Dead Source", "error")], { sources_failed: 1 }) }));
  await page.goto("/search?q=solo");
  await expect(page.getByText("This source didn't answer.")).toBeVisible();
  await shot(page, "failed-group");

  await page.unroute("**/api/sources/search*");
  await page.route("**/api/sources/search*", (r) => r.fulfill({ json: searchBody([searchGroup(null, "Library", "ok")]) }));
  await page.goto("/search?q=qzxwv");
  await expect(page.getByText("NOTHING FOUND", { exact: true })).toBeVisible();
  await shot(page, "no-results");

  await page.unroute("**/api/sources/search*");
  await page.route("**/api/sources/search*", (r) => r.fulfill({ status: 500, json: { code: "internal", message: "x" } }));
  await page.goto("/search?q=solo3&scope=sources");
  await expect(page.getByText("Search didn't finish.")).toBeVisible({ timeout: 40_000 });
  await shot(page, "error");
  await page.unroute("**/api/sources/search*");

  await page.goto("/search?q=solo4");
  await page.waitForTimeout(500);
  await context.setOffline(true);
  await page.goto("/search?q=offline").catch(() => {});
  await page.evaluate(() => window.dispatchEvent(new Event("offline")));
  await page.waitForTimeout(600);
  await shot(page, "offline");
  await context.setOffline(false);

  await page.route("**/api/sources/mangadex/series*", async (r) => { await new Promise((res) => setTimeout(res, 6000)); await r.continue(); });
  await page.goto("/sources/mangadex");
  await page.waitForTimeout(1200);
  await shot(page, "opening");
  await page.unroute("**/api/sources/mangadex/series*");
});

test("dialogue states: results, nothing found, error", async ({ page }) => {
  const hit = { source_id: "mangadex", series_key: "s1", chapter_key: "c1", word_count: 120, engine: "x", snippet: "I will <mark>solo</mark> this dungeon.", highlighted_terms: ["solo"], page: 3, box: { x: 0.2, y: 0.3, w: 0.3, h: 0.1 } };
  await page.route("**/api/ocr/search*", (r) => r.fulfill({ json: { items: [hit], total: 1, offset: 0, limit: 20, has_more: false } }));
  await page.goto("/ocr?q=solo");
  await page.waitForTimeout(1500);
  await shot(page, "dialogue-results");
  await page.unroute("**/api/ocr/search*");
  await page.route("**/api/ocr/search*", (r) => r.fulfill({ json: { items: [], total: 0, offset: 0, limit: 20, has_more: false } }));
  await page.goto("/ocr?q=qzxwv");
  await expect(page.getByText("NOTHING FOUND", { exact: true })).toBeVisible();
  await shot(page, "dialogue-nothing-found");
  await page.unroute("**/api/ocr/search*");
  await page.route("**/api/ocr/search*", (r) => r.fulfill({ status: 500, json: { code: "internal", message: "x" } }));
  await page.goto("/ocr?q=solo");
  await expect(page.getByText("Dialogue search didn't finish.")).toBeVisible();
  await shot(page, "dialogue-error");
});

test("reader jump: seeks by matched text and toasts, or falls back to the chapter start", async ({ page }) => {
  const seed = (pageNo: number | null) =>
    page.addInitScript((p) => {
      sessionStorage.setItem("mm.dialogue.jump", JSON.stringify({ sourceId: "mangadex", seriesKey: "s1", chapterKey: "c1", q: "solo", page: p, box: null }));
    }, pageNo);
  const chapter = (texts: Array<{ page: number; text: string }>) =>
    page.route("**/api/ocr/chapter*", (r) =>
      r.fulfill({ json: { source_id: "mangadex", series_key: "s1", chapter_key: "c1", language: "en", engine: "x", word_count: 9, updated_at: null, page_texts: texts.map((t) => ({ ...t, boxes: null })) } }),
    );
  await seed(null);
  await chapter([{ page: 1, text: "hello" }, { page: 4, text: "the Solo levelling" }]);
  await page.goto("/reader/mangadex/s1/c1");
  await expect(page.getByText("Found on page 4.")).toBeVisible();
  await shot(page, "reader-jump-found");

  await page.unroute("**/api/ocr/chapter*");
  await chapter([{ page: 1, text: "nothing here" }]);
  await page.goto("/reader/mangadex/s1/c1");
  await seed(null);
  await page.reload();
  await expect(page.getByText("Opened at the chapter start. The line is in this chapter.")).toBeVisible();
  await shot(page, "reader-jump-chapter-start");
});
