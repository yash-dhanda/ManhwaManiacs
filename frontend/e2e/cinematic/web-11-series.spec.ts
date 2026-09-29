import { expect, test, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { FOLLOW_ROUTE, MANGA, NOVEL, OUT, gridOverlay, mockSeries, signIn, type Mock, type MockOpts } from "./series-helpers";

/**
 * web/11: the Cinematic Feature and Book pages. Sign-in, profiles and the follow rows come from the real dev backend
 * (`backend/scripts/dev_stack.sh`, demo account); every series endpoint is a `page.route` fixture from
 * e2e/fixtures/series/. Proof screenshots land in docs/redesign/proof/web-11/.
 *
 *   E2E_BASE_URL=http://127.0.0.1:3049 npx playwright test e2e/cinematic/web-11-series.spec.ts
 */
mkdirSync(OUT, { recursive: true });
const DESKTOP = { width: 1440, height: 900 };
const PHONE = { width: 390, height: 844 };

let mock: Mock;
test.beforeEach(async ({ context, baseURL }) => {
  await signIn(context, baseURL!);
});

async function open(page: Page, url: string, o: MockOpts = {}, size = DESKTOP) {
  mock = await mockSeries(page, o);
  await page.setViewportSize(size);
  await page.goto(url);
  await page.addStyleTag({ content: "nextjs-portal{display:none!important}" });
}
const ready = (page: Page) => expect(page.locator("h1")).toBeVisible();
const settle = (page: Page, ms = 1100) => page.waitForTimeout(ms);
const tag = (s: { width: number; height: number }) => `${s.width}x${s.height}`;
async function shot(page: Page, name: string, fullPage = false) {
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(1300); // letters set, credits in, the 800 ms wash done
  await page.screenshot({ path: `${OUT}/${name}.png`, fullPage });
}
const rowByChapter = (page: Page, n: number) => page.locator("[data-row]").filter({ has: page.getByText(new RegExp(`^${n}$`), { exact: false }) }).first();
const box = async (page: Page, sel: string) => (await page.locator(sel).first().boundingBox())!;

test.describe("one page, two routes", () => {
  test("/sources/:s/series/:k and /library/:id render the same page, no redirect", async ({ page }) => {
    await open(page, MANGA);
    await ready(page);
    const title = await page.locator("h1").innerText();
    const tab = await page.getByRole("tab", { name: /CHAPTERS/ }).innerText();
    expect(page).toHaveURL(new RegExp(`${MANGA}$`));
    await page.goto(FOLLOW_ROUTE);
    await ready(page);
    expect(page).toHaveURL(new RegExp(`${FOLLOW_ROUTE}$`));
    expect(await page.locator("h1").innerText()).toBe(title);
    expect(await page.getByRole("tab", { name: /CHAPTERS/ }).innerText()).toBe(tab);
    expect(tab.replace(/\s+/g, "")).toContain("80".replace(/\d/g, (d) => "⁰¹²³⁴⁵⁶⁷⁸⁹"[Number(d)]));
    await expect(page).toHaveTitle("Dustland · ManhwaManiacs");
  });
});

test.describe("desktop spread", () => {
  test("geometry: text in columns 1-5, art in 6-12, clamp height; grid overlay", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await settle(page);
    const grid = await page.evaluate(() => {
      const cs = getComputedStyle(document.documentElement);
      const px = (n: string) => parseFloat(cs.getPropertyValue(n));
      return { max: cs.getPropertyValue("--mm-grid-max"), margin: px("--mm-grid-margin"), gutter: px("--mm-grid-gutter") };
    });
    const vw = 1440;
    const inner = Math.min(parseFloat(grid.max) || vw, vw) - grid.margin * 2;
    const col = (inner - 11 * grid.gutter) / 12;
    const left = (vw - inner) / 2;
    const colStart = (n: number) => left + (n - 1) * (col + grid.gutter);
    const art = await box(page, "img[alt$='cover']");
    const text = await page.locator("h1").boundingBox();
    expect(text!.x).toBeGreaterThanOrEqual(colStart(1) - 1);
    expect(text!.x + text!.width).toBeLessThanOrEqual(colStart(5) + col + 2);
    const artWrap = await page.locator("img[alt$='cover']").evaluate((el) => el.parentElement!.getBoundingClientRect().left);
    expect(artWrap).toBeGreaterThanOrEqual(colStart(6) - grid.gutter - 2);
    expect(artWrap).toBeLessThanOrEqual(colStart(6) + 2);
    expect(art.x + art.width).toBeGreaterThan(vw - 4);
    const spread = await page.locator("section[aria-label='Series'] > div:nth-of-type(2), [class*=spreadIn]").first().boundingBox();
    expect(Math.round(spread!.height)).toBe(Math.min(760, Math.max(520, Math.round(900 * 0.64))));
    await shot(page, `feature-${tag(DESKTOP)}`);
    await gridOverlay(page);
    await shot(page, "feature-grid-1440x900");
  });

  test("tablet spread is 4 + 4 columns", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, { width: 900, height: 1200 });
    await ready(page);
    await settle(page);
    const h1 = await page.locator("h1").boundingBox();
    const artLeft = await page.locator("img[alt$='cover']").evaluate((el) => el.parentElement!.getBoundingClientRect().left);
    expect(h1!.x + h1!.width).toBeLessThanOrEqual(900 / 2 + 8);
    expect(artLeft).toBeGreaterThanOrEqual(900 / 2 - 24);
    await shot(page, "feature-tablet-900x1200");
  });

  test("credits, kicker and actions", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await expect(page.getByText("MANHWA · ONGOING · 80 CHAPTERS")).toBeVisible();
    for (const k of ["STORY", "ART", "SOURCE", "STATUS", "UPDATED"]) await expect(page.getByText(k, { exact: true }).first()).toBeVisible();
    await expect(page.getByRole("link", { name: /Continue\s*CH 31 · p\.7/ })).toBeVisible();
    await expect(page.getByRole("link", { name: /Read all/ })).toHaveAttribute("href", /read-all/);
    for (const n of ["Following", "Favourite", "Notify", "Download", "More"]) await expect(page.getByRole("button", { name: n, exact: true }).first()).toBeVisible();
  });
});

test.describe("tabs and rows", () => {
  test("tabs are sticky, and 1 2 [ ] switch them", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    const tabs = page.getByRole("tab");
    await expect(tabs).toHaveCount(2);
    await expect(tabs.nth(0)).toContainText("01");
    await expect(tabs.nth(1)).toContainText("DETAILS");
    await page.mouse.move(700, 500);
    await page.keyboard.press("2");
    await expect(tabs.nth(1)).toHaveAttribute("aria-selected", "true");
    await page.keyboard.press("[");
    await expect(tabs.nth(0)).toHaveAttribute("aria-selected", "true");
    await page.keyboard.press("]");
    await expect(tabs.nth(1)).toHaveAttribute("aria-selected", "true");
    await page.keyboard.press("1");
    await page.evaluate(() => window.scrollTo(0, 1400));
    await settle(page, 200);
    const b = await tabs.first().boundingBox();
    expect(b!.y).toBeLessThan(60);
  });

  test("rows: 56 px, 56 px numbers, dot for a null number, READING band, virtualised", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    const rows = page.locator("[data-row]");
    expect(await rows.count()).toBeLessThan(80);
    expect(await rows.count()).toBeGreaterThan(5);
    const r = await rows.first().boundingBox();
    expect(Math.round(r!.height)).toBe(57 - 1 + 0); // 56 px + 1 px rule
    const num = await rows.first().locator("a").first().evaluate((el) => ({ cols: getComputedStyle(el).gridTemplateColumns.split(" ")[0], align: getComputedStyle(el.firstElementChild!).textAlign }));
    expect(num.cols).toBe("56px");
    expect(num.align).toBe("right");
    await page.getByLabel("Go to chapter").fill("31");
    await page.keyboard.press("Enter");
    await expect(page.getByText("READING")).toBeVisible();
    await page.getByLabel("Go to chapter").fill("41");
    await page.keyboard.press("Enter");
    await expect(page.locator("[data-row]").filter({ hasText: /^·/ }).first()).toBeVisible();
    await page.getByLabel("Go to chapter").fill("212");
    await expect(page.getByText("No chapter 212 in this series.")).toBeVisible();
    await page.getByLabel("Go to chapter").fill("");
    await expect(page.getByText("Type a chapter number.")).toBeVisible();
    await shot(page, "feature-chapters-1440x900");
  });

  test("hover prefetch: one P3 manifest after 150 ms, none for a shorter hover", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await settle(page, 600);
    const before = mock.manifests.length;
    const row = page.locator("[data-row]").nth(7);
    await row.scrollIntoViewIfNeeded();
    const link = row.locator("a").first();
    await link.hover();
    await page.waitForTimeout(70);
    await page.mouse.move(5, 5);
    await page.waitForTimeout(500);
    expect(mock.manifests.length).toBe(before);
    await link.hover();
    await page.waitForTimeout(500);
    expect(mock.manifests.length).toBe(before + 1);
    expect(mock.manifests.at(-1)).toContain("chapter=c73");
  });
});

test.describe("mark read", () => {
  test("Mark read, Mark read up to here, Mark unread send the batch and delete requests, with Undo", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    const first = page.locator("[data-row]").first();
    await first.click({ button: "right" });
    await page.getByRole("menuitem", { name: "Mark read", exact: true }).click();
    await expect.poll(() => mock.progressBatch.length).toBe(1);
    const row = mock.progressBatch[0][0] as Record<string, unknown>;
    expect(row).toMatchObject({ source_id: "mangapill", series_key: "9748/dustland", chapter_key: "c80", chapter_number: 80, scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true });
    expect(row.last_page).toBe(row.page_count);
    await expect(page.getByText("Marked chapter 80 read.")).toBeVisible();
    await page.getByRole("button", { name: "Undo" }).click();
    await expect.poll(() => mock.progressDelete.length).toBe(1);
    expect(mock.progressDelete[0]).toMatchObject({ source_id: "mangapill", chapter_keys: ["c80"] });

    await first.click({ button: "right" });
    await page.getByRole("menuitem", { name: "Mark read up to here" }).click();
    await expect(page.getByText("Marked 49 chapters read.")).toBeVisible();
    const up = mock.progressBatch.at(-1)!;
    expect(up.length).toBe(49);
    expect(up.map((r) => (r as { chapter_key: string }).chapter_key)).not.toContain("c41");

    await page.getByRole("button", { name: "Oldest" }).or(page.getByRole("button", { name: "OLDEST" })).click();
    await page.locator("[data-row]").first().click({ button: "right" });
    await page.getByRole("menuitem", { name: "Mark unread" }).click();
    await expect.poll(() => mock.progressDelete.length).toBe(2);
    expect(mock.progressDelete[1]).toMatchObject({ chapter_keys: ["c1"] });
    await expect(page.getByText("Marked chapter 1 unread.")).toBeVisible();
  });

  test("every mark control is disabled offline with 'Needs a connection.'", async ({ page, context }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await context.setOffline(true);
    await page.evaluate(() => window.dispatchEvent(new Event("offline")));
    const first = page.locator("[data-row]").first();
    await first.click({ button: "right" });
    for (const name of ["Mark read", "Mark read up to here", "Mark unread"]) {
      const item = page.getByRole("menuitem", { name, exact: true });
      await expect(item).toHaveAttribute("aria-disabled", "true");
      await expect(item).toHaveAttribute("title", "Needs a connection.");
    }
    await expect(page.getByRole("button", { name: "Favourite" })).toBeDisabled();
    await page.keyboard.press("Escape");
    await settle(page, 300);
    await shot(page, "feature-offline-saved-1440x900");
  });
});

test.describe("overflow and 18+", () => {
  test("the radio group sends true, false and null, each with its toast", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    const more = page.getByRole("button", { name: "More", exact: true });
    await more.click();
    await shot(page, "feature-overflow-1440x900");
    await page.getByRole("menuitemradio", { name: "Treat as 18+" }).click();
    await expect(page.getByText("Treating Dustland as 18+.")).toBeVisible();
    await more.click();
    await page.getByRole("menuitemradio", { name: "Treat as not 18+" }).click();
    await expect(page.getByText("Treating Dustland as not 18+.")).toBeVisible();
    await more.click();
    await shot(page, "feature-mature-override-1440x900");
    await page.getByRole("menuitemradio", { name: "Use the source's rating" }).click();
    await expect(page.getByText("Using the source's rating.")).toBeVisible();
    expect(mock.patches.map((p) => (p as { mature_override: unknown }).mature_override)).toEqual([true, false, null]);
  });
});

test.describe("At a glance and DETAILS", () => {
  test("stat, status, time here, tags with suggestions, shelves, OCR coverage", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await expect(page.getByText("CHAPTERS READ")).toBeVisible();
    await expect(page.getByText("30 / 80")).toBeVisible();
    for (const k of ["READING", "PLAN TO READ", "ON HOLD", "DONE", "DROPPED", "NOT STARTED"]) await expect(page.getByRole("button", { name: k, exact: true }).first()).toBeVisible();
    await expect(page.getByText("YOUR TIME HERE 10 H 5 M")).toBeVisible();
    await expect(page.getByText("SUGGESTED")).toBeVisible();
    await expect(page.getByText("Dialogue indexed for 34 of 80 chapters")).toBeVisible();
    await expect(page.getByRole("button", { name: "Add to shelf", exact: false }).first()).toBeVisible();
    await page.getByText("CHAPTERS READ").scrollIntoViewIfNeeded();
    await shot(page, "feature-at-a-glance-1440x900");
  });

  test("the SUGGESTED line is absent when /ai/tags is unavailable", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, { tags: "off" });
    await ready(page);
    await expect(page.getByText("CHAPTERS READ")).toBeVisible();
    await expect(page.getByText("SUGGESTED")).toHaveCount(0);
  });

  test("DETAILS: drop cap 84 px on 28 px leading, genre links, enrichment credits", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await page.keyboard.press("2");
    const cap = page.locator("p[class*=dropcap]").first();
    await expect(cap).toBeVisible();
    const st = await cap.evaluate((el) => ({ size: parseFloat(getComputedStyle(el, "::first-letter").fontSize), line: parseFloat(getComputedStyle(el).lineHeight) }));
    expect(st.size).toBe(84);
    expect(st.line).toBe(28);
    await expect(page.getByRole("link", { name: "Action" })).toHaveAttribute("href", "/sources/mangapill?genre=Action");
    await expect(page.getByText("8.4")).toBeVisible();
    await expect(page.getByRole("link", { name: /Read on Webtoon/ })).toBeVisible();
    await page.getByRole("tablist").evaluate((el) => el.scrollIntoView());
    await shot(page, "feature-details-1440x900");
  });

  test("enrichment credits are absent for a null answer", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, { enrichment: "null" });
    await ready(page);
    await page.keyboard.press("2");
    await expect(page.getByRole("link", { name: "Action" })).toBeVisible();
    await expect(page.getByText(/ANILIST/)).toHaveCount(0);
    await expect(page.getByRole("link", { name: /Read on Webtoon/ })).toHaveCount(0);
  });
});

test.describe("rating card and gate", () => {
  test("appears for a mature series for 3000 ms and never blocks", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, { mature: true });
    const card = page.getByRole("note", { name: "Rated 18+" });
    await expect(card).toBeVisible();
    await settle(page, 700);
    await shot(page, "feature-rating-card-1440x900");
    expect(await card.evaluate((el) => getComputedStyle(el).pointerEvents)).toBe("none");
    await expect.poll(() => card.evaluate((el) => Number(getComputedStyle(el).opacity)), { timeout: 6000 }).toBeLessThan(0.01);
  });

  test("a gate-hidden or removed series shows the NOT IN THIS ISSUE notice", async ({ page }) => {
    await open(page, MANGA, { seriesStatus: 404 });
    await expect(page.getByText("NOT IN THIS ISSUE")).toBeVisible();
    await expect(page.getByRole("heading", { name: "This series isn't available here any more." })).toBeVisible({ timeout: 8000 });
    await expect(page.getByText("It may have been removed from its source.")).toBeVisible();
    await expect(page.getByText(/18\+|mature/i)).toHaveCount(0);
    await expect(page.getByRole("link", { name: "Back to Tonight" })).toBeVisible();
    await shot(page, "feature-notavailable-1440x900");
  });
});

test.describe("Lightbox", () => {
  const lb = (page: Page) => page.getByRole("dialog", { name: "Cover" });
  test("opens from double-click, v and View cover; closes with x, Esc, back and a drag down", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await settle(page, 500);
    await page.locator("img[alt$='cover']").first().dblclick();
    await expect(lb(page)).toBeVisible();
    await settle(page, 600);
    await shot(page, "feature-lightbox-1440x900");
    await page.getByRole("button", { name: "Close" }).click();
    await expect(lb(page)).toHaveCount(0);
    await page.mouse.move(700, 700);
    await page.keyboard.press("v");
    await expect(lb(page)).toBeVisible();
    expect(page.url()).toContain("view=cover");
    await page.keyboard.press("Escape");
    await expect(lb(page)).toHaveCount(0);
    await page.getByRole("button", { name: "More", exact: true }).click();
    await page.getByRole("menuitem", { name: "View cover" }).click();
    await expect(lb(page)).toBeVisible();
    await page.goBack();
    await expect(lb(page)).toHaveCount(0);
    await page.keyboard.press("v");
    await expect(lb(page)).toBeVisible();
    await page.mouse.move(700, 300);
    await page.mouse.down();
    await page.mouse.move(700, 470, { steps: 6 });
    await page.mouse.up();
    await expect(lb(page)).toHaveCount(0);
  });
});

test.describe("Move to another source", () => {
  test("candidates, mapping sentence, keep-old checkbox, Move, toast", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await page.mouse.move(700, 700);
    await page.keyboard.press("m");
    await expect(page.getByText("MOVE TO ANOTHER SOURCE")).toBeVisible();
    await expect(page.getByText(/CHAPTERS 150/)).toBeVisible();
    await expect(page.getByText(/WeebCentral|didn't answer/i).first()).toBeVisible();
    await settle(page, 400);
    await shot(page, "feature-repoint-candidates-1440x900");
    await page.getByRole("button", { name: /MangaDex/ }).first().click();
    await expect(page.getByText(/Your place moves by chapter number\. You're on chapter 31; MangaDex has chapters 1–150, so chapter 31 there becomes your place\./)).toBeVisible();
    await expect(page.getByLabel(/Keep following it on MangaPill too/)).not.toBeChecked();
    await settle(page, 300);
    await shot(page, "feature-repoint-mapping-1440x900");
    await page.getByLabel(/Keep following it on MangaPill too/).check();
    await page.getByRole("button", { name: "Move", exact: true }).click();
    await expect.poll(() => mock.repoints.length).toBe(1);
    expect(mock.repoints[0]).toEqual({ source_id: "mangadex", series_key: "md-dustland", keep_old: true });
    await expect(page.getByText("Moved to MangaDex. You're on chapter 31.")).toBeVisible();
    await expect(page).toHaveURL(/mangadex\/series\/md-dustland/);
  });
});

test.describe("states", () => {
  const states: [string, MockOpts, RegExp, string][] = [
    ["chapters-unavailable", { chapters: "empty" }, /MangaDex lists 80 chapters but returned none just now|lists 80 chapters/, ""],
    ["no-chapters", { chapters: "empty", reported: 0 }, /No chapters yet\. The source hasn't published any\./, ""],
    ["error", { seriesStatus: 500 }, /Couldn't load this series\./, ""],
  ];
  for (const size of [DESKTOP, PHONE]) {
    for (const [name, o, text] of states) {
      test(`${name} at ${tag(size)}`, async ({ page }) => {
        await open(page, FOLLOW_ROUTE, o, size);
        await expect(page.getByText(text).first()).toBeVisible({ timeout: 20_000 });
        await settle(page, 300);
        await shot(page, `feature-${name}-${tag(size)}`);
      });
    }
    test(`loading at ${tag(size)}`, async ({ page }) => {
      await open(page, FOLLOW_ROUTE, { delayMs: 6000 }, size);
      await settle(page, 1200);
      await shot(page, `feature-loading-${tag(size)}`);
    });
    test(`chapters offline at ${tag(size)}`, async ({ page, context }) => {
      await open(page, FOLLOW_ROUTE, {}, size);
      await ready(page);
      await context.setOffline(true);
      await page.evaluate(() => window.dispatchEvent(new Event("offline")));
      await page.route("**/api/sources/mangapill/series/9748%2Fdustland/chapters", (r) => r.abort());
      await settle(page, 300);
      await shot(page, `feature-chapters-offline-${tag(size)}`);
    });
  }
  test("offline with nothing saved says so", async ({ page, context }) => {
    await context.setOffline(true);
    mock = await mockSeries(page, {});
    await page.setViewportSize(DESKTOP);
    await page.goto(FOLLOW_ROUTE).catch(() => undefined);
    await context.setOffline(false);
  });
  test("offline-saved and not-available at phone size", async ({ page, context }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    await context.setOffline(true);
    await page.evaluate(() => window.dispatchEvent(new Event("offline")));
    await settle(page, 300);
    await shot(page, "feature-offline-saved-390x844");
    await context.setOffline(false);
    await page.evaluate(() => window.dispatchEvent(new Event("online")));
    await open(page, MANGA, { seriesStatus: 404 }, PHONE);
    await expect(page.getByText("NOT IN THIS ISSUE")).toBeVisible();
    await shot(page, "feature-notavailable-390x844");
  });
});

test.describe("select mode and downloads", () => {
  test("Shift-click range, quick picks with counts, Download N", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await page.getByRole("button", { name: "Select", exact: true }).click();
    const bar = page.getByRole("region", { name: "Chapter selection" });
    await expect(bar).toContainText("Select chapters to download");
    await expect(bar.getByRole("button", { name: /^Next 10/ })).toBeVisible();
    await expect(bar.getByRole("button", { name: /^All unread/ })).toBeVisible();
    const rows = page.locator("[data-row]");
    await rows.nth(1).locator("a").first().click();
    await rows.nth(4).locator("a").first().click({ modifiers: ["Shift"] });
    await expect(bar).toContainText("4 SELECTED");
    await settle(page, 300);
    await shot(page, "feature-select-1440x900");
    await bar.getByRole("button", { name: /^Next 10/ }).click();
    await expect(bar).toContainText("10 SELECTED");
    await expect(bar.getByRole("button", { name: /^Download 10/ })).toBeEnabled();
    await bar.getByRole("button", { name: "Done" }).click();
    await expect(bar).toHaveCount(0);
  });
});

test.describe("motion", () => {
  const rows = (page: Page) => page.evaluate(() => (window.__mmMotion ?? []).map((r) => ({ ...r })));

  test("match cut in 480 ms, back 336 ms; Page in 320 ms, Page out 224 ms; overlay rows", async ({ page }) => {
    await open(page, MANGA);
    await ready(page);
    await page.evaluate(() => (window as unknown as { next: { router: { push: (u: string) => void } } }).next.router.push("/library/6"));
    await expect.poll(async () => (await rows(page)).some((r) => r.name === "matchCut")).toBe(true);
    const cut = (await rows(page)).find((r) => r.name === "matchCut")!;
    expect(cut.measured).toBe(480);
    await settle(page, 700);
    await page.goBack();
    await expect.poll(async () => (await rows(page)).some((r) => r.name === "matchCutBack")).toBe(true);
    expect((await rows(page)).find((r) => r.name === "matchCutBack")!.measured).toBe(336);
    // Page in / out: to and from a page with no cover.
    await settle(page, 700);
    await page.evaluate(() => (window as unknown as { next: { router: { push: (u: string) => void } } }).next.router.push("/sources"));
    await expect.poll(async () => (await rows(page)).some((r) => r.name === "pageOut")).toBe(true);
    expect((await rows(page)).find((r) => r.name === "pageOut")!.measured).toBe(224);
    await settle(page, 700);
    await page.evaluate(() => (window as unknown as { next: { router: { push: (u: string) => void } } }).next.router.push("/library/6"));
    await expect.poll(async () => (await rows(page)).some((r) => r.name === "pageIn")).toBe(true);
    expect((await rows(page)).find((r) => r.name === "pageIn")!.measured).toBe(320);
    await ready(page);
    await settle(page, 600);
    // Continue: the Column wipe into the reader.
    await page.getByRole("link", { name: /Continue/ }).click();
    await expect.poll(async () => (await rows(page)).some((r) => r.name === "columnWipe"), { timeout: 8000 }).toBe(true);
    const wipe = (await rows(page)).find((r) => r.name === "columnWipe")!;
    expect(wipe.planned).toBe(872);
    expect(wipe.measured).toBeGreaterThan(800);
    expect(wipe.measured).toBeLessThan(872 + 300);
    await expect(page).toHaveURL(/\/reader\//);
  });

  test("the overlay lists the rows without a proof row", async ({ page }) => {
    await open(page, MANGA);
    await ready(page);
    await page.evaluate(() => (window as unknown as { next: { router: { push: (u: string) => void } } }).next.router.push("/library/6"));
    await settle(page, 900);
    await page.goBack();
    await settle(page, 900);
    await page.keyboard.press("Control+Shift+M");
    const overlay = page.getByRole("region", { name: "Motion timings" });
    await expect(overlay).toContainText("matchCut");
    await expect(overlay.locator("[data-over]")).toHaveCount(0);
    await shot(page, "feature-motion-timings-1440x900");
  });

  test("the wipe closes 12 blades on desktop", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await settle(page, 600);
    await page.getByRole("link", { name: /Continue/ }).click();
    await expect(page.locator("[data-mm-wipe]")).toHaveAttribute("data-mm-wipe", "12");
  });
});

test.describe("reduced motion", () => {
  test.use({ reducedMotion: "reduce" });
  test("the wipe is one cross-fade, Drift stops at 1.03, the Lightbox fades 150 ms", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    const drift = await page.locator("img[alt$='cover']").first().evaluate((el) => {
      const c = getComputedStyle(el);
      return { name: c.animationName, transform: c.transform };
    });
    expect(drift.name).toBe("none");
    expect(drift.transform).toBe("matrix(1.03, 0, 0, 1.03, 0, 0)");
    await page.keyboard.press("v");
    const lb = page.getByRole("dialog", { name: "Cover" });
    await expect(lb).toBeVisible();
    expect(await lb.evaluate((el) => getComputedStyle(el).animationDuration)).toBe("0.15s");
    await page.keyboard.press("Escape");
    await page.getByRole("link", { name: /Continue/ }).click();
    await expect(page.locator("[data-mm-wipe]")).toHaveAttribute("data-mm-wipe", "1");
    await expect.poll(async () => (await page.evaluate(() => window.__mmMotion ?? [])).find((r) => r.name === "columnWipe")?.planned, { timeout: 8000 }).toBe(200);
  });
});

test.describe("phone (390 x 844)", () => {
  test.use({ viewport: PHONE, hasTouch: true, isMobile: true, deviceScaleFactor: 2 });

  test("hero: 4:5 cover, title block over its lower quarter, full-width actions, labelled icons", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    await settle(page);
    const art = await page.locator("[class*=phoneArt]").boundingBox();
    expect(Math.round(art!.height)).toBe(Math.round((PHONE.width * 5) / 4));
    const h1 = await page.locator("h1").boundingBox();
    expect(h1!.y).toBeLessThan(art!.y + art!.height);
    expect(h1!.y).toBeGreaterThan(art!.y + art!.height * 0.55);
    const primary = await page.getByRole("link", { name: /Continue/ }).boundingBox();
    expect(primary!.width).toBeGreaterThan(PHONE.width - 48);
    for (const k of ["FOLLOW", "FAVOURITE", "NOTIFY", "DOWNLOAD"]) await expect(page.getByText(k, { exact: true }).first()).toBeVisible();
    await shot(page, "feature-390x844");
  });

  test("the tab pager snaps and the rule follows", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    const pager = page.getByTestId("pager");
    expect(await pager.evaluate((el) => getComputedStyle(el).scrollSnapType)).toContain("x mandatory");
    await pager.evaluate((el) => el.scrollTo({ left: el.clientWidth * 0.5 }));
    await expect.poll(() => page.getByTestId("tab-rule").evaluate((el) => new DOMMatrix(getComputedStyle(el).transform).m41)).toBeGreaterThan(50);
    await pager.evaluate((el) => el.scrollTo({ left: el.clientWidth }));
    await expect(page.getByRole("tab").nth(1)).toHaveAttribute("aria-selected", "true");
    await settle(page, 400);
    await shot(page, "feature-details-390x844");
    await page.getByRole("tab").first().click();
    await expect.poll(() => pager.evaluate((el) => el.scrollLeft)).toBe(0);
  });

  test("swipe left past half the slab marks read; long-press opens the row menu", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    const touch = async (target: string, type: string, x: number, y = 0) =>
      page.evaluate(
        ([sel, t, cx, cy]) => {
          const el = document.querySelector(sel as string) as HTMLElement;
          const r = el.getBoundingClientRect();
          const tc = new Touch({ identifier: 1, target: el, clientX: (cx as number) === 0 ? r.right - 40 : (cx as number), clientY: r.top + r.height / 2 + (cy as number) });
          el.dispatchEvent(new TouchEvent(t as string, { bubbles: true, cancelable: true, touches: t === "touchend" ? [] : [tc], changedTouches: [tc], targetTouches: t === "touchend" ? [] : [tc] }));
        },
        [target, type, x, y] as const,
      );
    const row = "[data-row='0'] > div";
    await page.locator("[data-row='0']").scrollIntoViewIfNeeded();
    await touch(row, "touchstart", 0);
    await touch(row, "touchmove", 300);
    await touch(row, "touchmove", 200);
    await expect(page.locator("[data-row='0'] [class*=slab]")).toBeVisible();
    await shot(page, "feature-swipe-390x844");
    await touch(row, "touchend", 200);
    await expect.poll(() => mock.progressBatch.length).toBe(1);
    expect((mock.progressBatch[0][0] as { chapter_key: string }).chapter_key).toBe("c80");
    // long-press
    await touch("[data-row='1'] > div", "touchstart", 0);
    await page.waitForTimeout(600);
    await expect(page.getByRole("menuitem", { name: "Mark read", exact: true })).toBeVisible();
    await touch("[data-row='1'] > div", "touchend", 0);
  });

  test("hit targets are at least 44 x 44 on the phone frame", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    await settle(page, 500);
    const small = await page.evaluate(() => {
      const bad: string[] = [];
      for (const el of document.querySelectorAll<HTMLElement>("button, a[href][class*=btn], a[href][class*=icon], [role=tab]")) {
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        if (r.width === 0 || cs.visibility === "hidden" || cs.display === "none" || cs.opacity === "0") continue;
        if (el.closest("nextjs-portal")) continue;
        if (r.width < 43.5 || r.height < 43.5) bad.push(`${el.getAttribute("aria-label") ?? el.textContent?.trim().slice(0, 20)} ${Math.round(r.width)}x${Math.round(r.height)}`);
      }
      return bad;
    });
    expect(small).toEqual([]);
  });

  for (const [name, o] of [
    ["chapters-unavailable", { chapters: "empty" }],
    ["no-chapters", { chapters: "empty", reported: 0 }],
  ] as [string, MockOpts][]) {
    test(`phone ${name}`, async ({ page }) => {
      await open(page, FOLLOW_ROUTE, o, PHONE);
      await settle(page, 1500);
    });
  }

  test("select mode and the repoint sheet on the phone", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    await page.getByRole("button", { name: "Select", exact: true }).click();
    await page.locator("[data-row]").nth(1).locator("a").first().tap();
    await settle(page, 300);
    await shot(page, "feature-select-390x844");
    await page.getByRole("button", { name: "Done" }).click();
    await page.getByRole("button", { name: "More", exact: true }).first().click();
    await page.getByRole("menuitem", { name: "Move to another source…" }).click();
    await expect(page.getByText("MOVE TO ANOTHER SOURCE")).toBeVisible();
    await settle(page, 600);
    await shot(page, "feature-repoint-390x844");
  });

  test("lightbox on the phone", async ({ page }) => {
    await open(page, FOLLOW_ROUTE, {}, PHONE);
    await ready(page);
    await page.keyboard.press("v");
    await settle(page, 700);
    await shot(page, "feature-lightbox-390x844");
  });
});

test.describe("desktop hit targets", () => {
  test("at least 32 x 32 on the fine pointer", async ({ page }) => {
    await open(page, FOLLOW_ROUTE);
    await ready(page);
    await settle(page, 500);
    const small = await page.evaluate(() => {
      const bad: string[] = [];
      for (const el of document.querySelectorAll<HTMLElement>("button, a[href][class*=btn], a[href][class*=icon], [role=tab]")) {
        const r = el.getBoundingClientRect();
        const cs = getComputedStyle(el);
        if (r.width === 0 || cs.visibility === "hidden" || cs.display === "none") continue;
        if (r.width < 31.5 || r.height < 31.5) bad.push(`${el.getAttribute("aria-label") ?? el.textContent?.trim().slice(0, 20)} ${Math.round(r.width)}x${Math.round(r.height)}`);
      }
      return bad;
    });
    expect(small).toEqual([]);
  });
});

test.describe("the Book page", () => {
  test("front matter: masthead, byline, 56 px rule, facts, plate; keys", async ({ page }) => {
    await open(page, NOVEL, { novel: true });
    await ready(page);
    await settle(page);
    await expect(page.locator("h1")).toHaveAccessibleName("The Salt Road");
    await expect(page.getByText(/^NOVEL · ONGOING/)).toBeVisible();
    await expect(page.getByText("by E. M. Harrow")).toBeVisible();
    const rule = await page.locator("[class*=rule56]").boundingBox();
    expect(Math.round(rule!.width)).toBe(56);
    await expect(page.getByText(/CHAPTERS 450/)).toBeVisible();
    const plate = await page.locator("img[alt$='cover']").boundingBox();
    expect(Math.round(plate!.width)).toBe(168);
    expect(Math.round(plate!.height)).toBe(248);
    await expect(page.getByRole("link", { name: /Start reading/ })).toBeVisible();
    await expect(page.getByRole("link", { name: /Listen/ })).toBeVisible();
    await shot(page, "book-1440x900");
  });

  test("contents: 400-row window, Show more, ?chapter= centres the row", async ({ page }) => {
    await open(page, NOVEL, { novel: true });
    await ready(page);
    await expect(page.locator("[data-row]")).toHaveCount(400);
    await expect(page.getByRole("button", { name: /Show more chapters \(50\)/ })).toBeVisible();
    await page.getByRole("button", { name: /Show more chapters/ }).click();
    await expect(page.locator("[data-row]")).toHaveCount(450);
    await page.goto(`${NOVEL}?chapter=n430`);
    await page.addStyleTag({ content: "nextjs-portal{display:none!important}" });
    const focused = page.locator("[aria-current=location]").first();
    await expect(focused).toBeVisible();
    await expect(page.getByRole("button", { name: /Show earlier chapters/ })).toBeVisible();
    const b = await focused.boundingBox();
    expect(Math.abs(b!.y + b!.height / 2 - 450)).toBeLessThan(120);
    await shot(page, "book-contents-window-1440x900");
  });

  test("go-to list, Enter jumps, Pick chapters opens select mode", async ({ page }) => {
    await open(page, NOVEL, { novel: true });
    await ready(page);
    await page.getByLabel("Go to chapter").fill("12");
    await expect(page.getByRole("button", { name: /Chapter 12:/ })).toBeVisible();
    await shot(page, "book-goto-1440x900");
    await page.getByLabel("Go to chapter").fill("999");
    await expect(page.getByText("No chapter 999 in this book.")).toBeVisible();
    await page.getByLabel("Go to chapter").fill("");
    await page.getByRole("button", { name: "Pick chapters", exact: true }).first().click();
    await expect(page.getByRole("region", { name: "Chapter selection" })).toBeVisible();
    await shot(page, "book-pick-chapters-1440x900");
  });

  test("book states: loading, error, contents empty", async ({ page }) => {
    await open(page, NOVEL, { novel: true, delayMs: 6000 });
    await settle(page, 1200);
    await shot(page, "book-loading-1440x900");
  });
  test("book error", async ({ page }) => {
    await open(page, NOVEL, { novel: true, seriesStatus: 500 });
    await expect(page.getByText("Couldn't load this book.")).toBeVisible({ timeout: 20_000 });
    await settle(page, 300);
    await shot(page, "book-error-1440x900");
  });
  test("book contents empty", async ({ page }) => {
    await open(page, NOVEL, { novel: true, chapters: "empty", reported: 0 });
    await expect(page.getByText(/No chapters yet/)).toBeVisible({ timeout: 20_000 });
    await shot(page, "book-contents-empty-1440x900");
  });
  test("book at 390 x 844", async ({ page }) => {
    await open(page, NOVEL, { novel: true }, PHONE);
    await ready(page);
    await settle(page, 600);
    await shot(page, "book-390x844");
  });
});

test.describe("download marks gallery", () => {
  test("the seven marks with their tooltips", async ({ page }) => {
    await page.setViewportSize(DESKTOP);
    await page.goto("/skin-preview/cinematic/download-marks");
    const marks = page.getByTestId("marks").locator("button");
    await expect(marks).toHaveCount(7);
    const titles = await marks.evaluateAll((els) => els.map((e) => e.getAttribute("title")));
    expect(titles).toEqual([
      "Download",
      "Queued to download",
      "Downloading, 30 percent",
      "Downloaded — opens with no connection",
      "Failed, tap to retry",
      "Paused — this browser is out of room",
      "The source changed these pages — download it again",
    ]);
    await shot(page, "download-marks-gallery-1440x900");
  });
});
