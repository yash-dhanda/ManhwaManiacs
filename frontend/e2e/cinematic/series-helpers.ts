import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { BrowserContext, Page, Request, Route } from "@playwright/test";

const dir = join(__dirname, "..", "fixtures", "series");
export const fx = (name: string) => JSON.parse(readFileSync(join(dir, name), "utf8"));
const cover = readFileSync(join(dir, "cover.svg"), "utf8");

export const MANGA = "/sources/mangapill/series/9748%2Fdustland";
export const FOLLOW_ROUTE = "/library/6";
export const NOVEL = "/sources/standardebooks/series/dustland-novel";
export const OUT = join(__dirname, "..", "..", "..", "docs", "redesign", "proof", "web-11");

export const USERNAME = process.env.E2E_USERNAME ?? "demo";
export const PASSWORD = process.env.E2E_PASSWORD ?? "maniacs-demo-2026";

/** Sign in over the API (the Cinematic login screen is not built yet), pick Riya, force the Cinematic skin. */
let session: { cookies: Awaited<ReturnType<BrowserContext["cookies"]>>; owner: number } | null = null; // one login per worker: the endpoint is rate limited

export async function signIn(ctx: BrowserContext, baseURL: string) {
  await ctx.addCookies([{ name: "mm-skin-debug", value: "cinematic", url: baseURL }]);
  if (!session) {
    const r = await ctx.request.post(`${baseURL}/api/auth/login`, { data: { username: USERNAME, password: PASSWORD } });
    if (!r.ok()) throw new Error(`login failed: ${r.status()}`);
    const owner = (await (await ctx.request.get(`${baseURL}/api/auth/me`)).json()).id;
    session = { cookies: await ctx.cookies(), owner };
  } else await ctx.addCookies(session.cookies);
  const me = { id: session.owner };
  await ctx.addInitScript(
    ([id, owner]) => {
      try {
        localStorage.setItem(
          "mm.active-profile",
          JSON.stringify({ state: { activeProfile: { id, name: "Riya", avatar_key: "default", mood: "fantasy" }, ownerUserId: owner }, version: 0 }),
        );
      } catch {}
    },
    [1, me.id] as const,
  );
}

const json = (route: Route, body: unknown, status = 200) =>
  route.fulfill({ status, contentType: "application/json", body: JSON.stringify(body) });

export interface Mock {
  progressBatch: unknown[][];
  progressDelete: unknown[];
  patches: unknown[];
  manifests: string[];
  repoints: unknown[];
  requests: Request[];
}

export interface MockOpts {
  novel?: boolean;
  /** series detail status; 404 answers series_not_found */
  seriesStatus?: number;
  chapters?: "ok" | "empty" | "error";
  reported?: number;
  mature?: boolean;
  tags?: "available" | "off";
  enrichment?: "ok" | "null";
  delayMs?: number;
}

/** Every series-page endpoint except auth, profile and the follow rows, which the real dev backend answers. */
export async function mockSeries(page: Page, o: MockOpts = {}): Promise<Mock> {
  const m: Mock = { progressBatch: [], progressDelete: [], patches: [], manifests: [], repoints: [], requests: [] };
  page.on("request", (r) => {
    const u = new URL(r.url());
    if (u.pathname.startsWith("/api/reader/chapter/manifest")) m.manifests.push(u.search);
    if (r.method() === "PATCH" && u.pathname.startsWith("/api/library/series/")) m.patches.push(r.postDataJSON());
    if (r.method() === "POST" && u.pathname === "/api/reader/progress/batch") m.progressBatch.push(r.postDataJSON());
    if (r.method() === "DELETE" && u.pathname === "/api/reader/progress") m.progressDelete.push(r.postDataJSON());
    if (r.method() === "POST" && u.pathname.endsWith("/repoint")) m.repoints.push(r.postDataJSON());
    m.requests.push(r);
  });
  const series = fx(o.novel ? "novel-series.json" : "manga-series.json");
  if (o.reported !== undefined) series.chapter_count = o.reported;
  const chapters = fx(o.novel ? "novel-chapters.json" : "manga-chapters.json");
  const later = async () => (o.delayMs ? new Promise((r) => setTimeout(r, o.delayMs)) : undefined);

  await page.route("**/api/sources/*/series/*/cover*", (r) => r.fulfill({ contentType: "image/svg+xml", body: cover }));
  await page.route("**/api/cover.svg", (r) => r.fulfill({ contentType: "image/svg+xml", body: cover }));
  await page.route(/\/api\/sources\/mangapill\/series\/9748%2Fdustland$/, async (r) => {
    await later();
    return o.seriesStatus === 404 ? json(r, { code: "series_not_found", detail: "not found" }, 404) : o.seriesStatus ? json(r, { detail: "bad" }, o.seriesStatus) : json(r, series);
  });
  await page.route(/\/api\/sources\/standardebooks\/series\/dustland-novel$/, async (r) => {
    await later();
    return o.seriesStatus === 404 ? json(r, { code: "series_not_found", detail: "not found" }, 404) : o.seriesStatus ? json(r, { detail: "bad" }, o.seriesStatus) : json(r, series);
  });
  await page.route(/\/api\/sources\/(mangapill\/series\/9748%2Fdustland|standardebooks\/series\/dustland-novel)\/chapters$/, async (r) => {
    await later();
    if (o.chapters === "error") return json(r, { detail: "upstream" }, 502);
    return json(r, o.chapters === "empty" ? [] : chapters);
  });
  await page.route(/\/api\/sources\/mangadex\/series\/md-dustland\/chapters$/, (r) => json(r, fx("other-chapters.json")));
  await page.route("**/api/sources/search*", (r) => json(r, fx("search.json")));
  await page.route("**/api/reader/progress/series*", (r) => json(r, fx(o.novel ? "manga-progress.json" : "manga-progress.json").filter((p: { source_id: string }) => (o.novel ? false : p.source_id === "mangapill"))));
  await page.route("**/api/reader/progress/batch", (r) => json(r, []));
  await page.route(/\/api\/reader\/progress$/, (r) => (r.request().method() === "DELETE" ? json(r, { deleted: 1 }) : r.continue()));
  await page.route("**/api/reader/chapter/manifest*", (r) => json(r, fx("manifest.json")));
  await page.route("**/api/series/enrichment*", (r) => json(r, o.enrichment === "null" ? null : fx("enrichment.json")));
  await page.route("**/api/ai/tags*", (r) => (o.tags === "off" ? json(r, { detail: "nope" }, 404) : json(r, fx("tags-available.json"))));
  await page.route("**/api/ocr/coverage*", (r) => json(r, fx("ocr-coverage.json")));
  await page.route("**/api/novels/chapters", (r) => json(r, { chapters: [] }));
  await page.route("**/api/novels/audio/series*", (r) => json(r, fx("novel-audio.json")));
  await page.route("**/api/library/series/6/repoint", (r) => json(r, fx("repoint.json")));
  await page.route(/\/api\/library\/series\/6$/, async (r) => {
    if (r.request().method() !== "GET") return r.continue();
    try {
      const body = await (await r.fetch()).json();
      if (o.mature) body.rating = "mature";
      body.ambient = series.ambient;
      return await json(r, body);
    } catch {
      return; // the page went away mid-request
    }
  });
  return m;
}

/** A 12-column overlay over the page (the grid-overlay screenshots). */
export async function gridOverlay(page: Page) {
  await page.addStyleTag({
    content: `body::after{content:"";position:fixed;inset:0;pointer-events:none;z-index:2147483600;margin-inline:auto;max-width:var(--mm-grid-max);padding-inline:var(--mm-grid-margin);box-sizing:border-box;background:repeating-linear-gradient(to right,rgba(255,0,80,.14) 0,rgba(255,0,80,.14) calc((100% - 11*var(--mm-grid-gutter))/12),transparent calc((100% - 11*var(--mm-grid-gutter))/12),transparent calc((100% - 11*var(--mm-grid-gutter))/12 + var(--mm-grid-gutter)));background-clip:content-box}`,
  });
}
