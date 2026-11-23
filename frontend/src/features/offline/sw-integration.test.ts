import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  API_BASE,
  CONTENT_VERSION,
  ORIGIN,
  RUNTIME_VERSION,
  createHarness,
  readIndex,
  route,
  type Harness,
} from "./sw-harness.testing";
import { buildNovelSaveRequest } from "./novel-save-request";

/**
 * The service worker, executed.
 *
 * `policy-contract.test.ts` proves the worker decides correctly; this proves it
 * then does what it decided — which cache the bytes land in, what comes back
 * with the network down, and what a profile switch can and cannot see. Those
 * are the failures that would only otherwise be found on a train.
 *
 * URLs are source-native (spec §3.2): the chapter payload is
 * `/reader/chapter/manifest?source=&series=&chapter=` and a page is
 * `/sources/{source}/pages/{page}/image`.
 */

const ALICE = { userId: 1, profileId: 10 };
const BOB = { userId: 1, profileId: 11 };
const ALICE_CACHE = `mm-offline-${CONTENT_VERSION}-u1p10`;
const BOB_CACHE = `mm-offline-${CONTENT_VERSION}-u1p11`;

const SOURCE = "asura";
const SERIES = "series/solo-levelling";
const CHAPTER = "ch/50";
const KEY = `chapter:${SOURCE}:${SERIES}:${CHAPTER}`;

const PAGE_ONE = `${API_BASE}/sources/${SOURCE}/pages/p1/image`;
const PAGE_TWO = `${API_BASE}/sources/${SOURCE}/pages/p2/image`;
const PAYLOAD =
  `${API_BASE}/reader/chapter/manifest` +
  `?source=${SOURCE}&series=${encodeURIComponent(SERIES)}&chapter=${encodeURIComponent(CHAPTER)}`;
const DOCUMENT_URL = `${ORIGIN}/reader/${SOURCE}/${encodeURIComponent(SERIES)}/ch/50`;
const BOOKMARKS = `${API_BASE}/reader/bookmarks`;
const ALICE_API_CACHE = `mm-api-${RUNTIME_VERSION}-u1p10`;

const CHAPTER_BODY = JSON.stringify({
  source_id: SOURCE,
  series_key: SERIES,
  chapter_key: CHAPTER,
  chapter_number: 50,
  page_count: 2,
  pages: [
    { number: 1, url: PAGE_ONE },
    { number: 2, url: PAGE_TWO },
  ],
  prev: "ch/49",
  next: "ch/51",
});

function savePayload(scope: { userId: number; profileId: number }) {
  return {
    key: KEY,
    sourceId: SOURCE,
    seriesKey: SERIES,
    chapterKey: CHAPTER,
    title: "Chapter 50",
    seriesTitle: "Solo Levelling",
    medium: "manga",
    scope,
    profileId: scope.profileId,
    documentUrl: DOCUMENT_URL,
    payloadUrl: PAYLOAD,
    payloadJson: CHAPTER_BODY,
    imageUrls: [PAGE_ONE, PAGE_TWO],
    extraUrls: [PAYLOAD],
  };
}

let harness: Harness;

async function boot(scope = ALICE, clientId = "client-a"): Promise<void> {
  await harness.dispatchInstall();
  await harness.dispatchActivate();
  await harness.dispatchMessage(
    { type: "mm-offline/set-scope", scope, apiBase: API_BASE },
    clientId,
  );
}

beforeEach(() => {
  harness = createHarness();
  harness.clients.push({ id: "client-b", messages: [] });
  route(harness, "/offline-fallback.html", { body: "<h1>offline</h1>" });
  route(harness, "/offline-fallback-cinematic.html", { body: "<h1>cinematic</h1>" });
  route(harness, "/offline-fallback-glass.html", { body: "<h1>glass</h1>" });
  route(harness, "/icons/icon-192.png", { body: "icon" });
  route(harness, "/icons/icon-512.png", { body: "icon" });
  route(harness, "/manifest.webmanifest", { body: "{}" });
  route(harness, "/library", { body: "<html>library</html>" });
  route(harness, "/downloads", { body: "<html>downloads</html>" });
  route(harness, PAGE_ONE, { body: "page-one-bytes", headers: { "content-type": "image/jpeg" } });
  route(harness, PAGE_TWO, { body: "page-two-bytes", headers: { "content-type": "image/jpeg" } });
  route(harness, PAYLOAD, { body: CHAPTER_BODY });
  route(harness, DOCUMENT_URL, { body: "<html>reader</html>" });
  route(harness, BOOKMARKS, { body: '[{"id":1,"anchor_index":7}]' });
});

describe("install and activate", () => {
  it("precaches the offline fallback so there is always something to render", async () => {
    await harness.dispatchInstall();
    const shell = harness.cacheFor(`mm-shell-${RUNTIME_VERSION}`);
    expect(await shell?.match("/offline-fallback.html")).toBeTruthy();
  });

  it("warms the installed app's start_url", async () => {
    await harness.dispatchInstall();
    await harness.dispatchActivate();
    const shell = harness.cacheFor(`mm-shell-${RUNTIME_VERSION}`);
    expect(await shell?.match("/library")).toBeTruthy();
  });

  it("warms /downloads, the one page the offline fallback links to", async () => {
    await harness.dispatchInstall();
    await harness.dispatchActivate();
    const shell = harness.cacheFor(`mm-shell-${RUNTIME_VERSION}`);
    expect(await shell?.match("/downloads")).toBeTruthy();
  });

  it("drops a superseded generation but never another profile's downloads", async () => {
    await harness.storage.open("mm-shell-v1");
    await harness.storage.open("mm-offline-c1-u1p10");
    await harness.storage.open(BOB_CACHE);
    await harness.storage.open("some-other-app");
    await harness.dispatchInstall();
    await harness.dispatchActivate();

    const names = await harness.cacheNames();
    expect(names).not.toContain("mm-shell-v1");
    // The old content generation is orphaned by the source-native migration.
    expect(names).not.toContain("mm-offline-c1-u1p10");
    expect(names).toContain(BOB_CACHE);
    expect(names).toContain("some-other-app");
  });
});

describe("saving a chapter", () => {
  it("stores every page under the saving profile's own cache", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    const cache = harness.cacheFor(ALICE_CACHE);
    expect(await cache?.match(PAGE_ONE)).toBeTruthy();
    expect(await cache?.match(PAGE_TWO)).toBeTruthy();
    expect(await cache?.match(PAYLOAD)).toBeTruthy();
    expect(await cache?.match(DOCUMENT_URL)).toBeTruthy();

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].status).toBe("ready");
    expect(index?.entries[KEY].savedPages).toBe(2);
    expect(index?.entries[KEY].bytes).toBeGreaterThan(0);
    expect(index?.entries[KEY].medium).toBe("manga");
  });

  it("uses the payload the page already had instead of asking again", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    expect(harness.fetched.filter((url) => url === PAYLOAD)).toHaveLength(0);
  });

  it("resumes without re-downloading what is already stored", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    const firstPass = harness.fetched.filter((url) => url === PAGE_ONE).length;

    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    expect(harness.fetched.filter((url) => url === PAGE_ONE).length).toBe(firstPass);
  });

  it("reports holes rather than claiming a chapter is saved", async () => {
    harness.routes.delete(PAGE_TWO);
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].status).toBe("partial");
    expect(index?.entries[KEY].savedPages).toBe(1);
    expect(index?.entries[KEY].failed).toBe(1);
  });

  it("refuses to save with no profile, rather than picking one", async () => {
    await boot();
    const reply = await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: { ...savePayload(ALICE), scope: null },
    });
    expect(reply.ok).toBe(false);
    expect(reply.reason).toBe("no-scope");
  });

  it("pauses instead of deleting unread chapters when the device is full", async () => {
    await boot();
    // No headroom at all, and nothing finished that could be evicted.
    harness.estimate = { usage: 9_999_000_000, quota: 10_000_000_000 };
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].status).toBe("paused");
  });
});

describe("reading with no network", () => {
  it("serves a saved page image from the device", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: PAGE_ONE, destination: "image" });
    expect(outcome.handled).toBe(true);
    expect(await outcome.response?.text()).toBe("page-one-bytes");
  });

  it("serves the saved chapter manifest so the reader can render at all", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: PAYLOAD });
    expect(await outcome.response?.text()).toBe(CHAPTER_BODY);
  });

  it("falls back to a cached document, then to the offline page", async () => {
    await boot();
    await harness.dispatchFetch({ url: `${ORIGIN}/library`, mode: "navigate" });

    harness.offline = true;
    const cached = await harness.dispatchFetch({ url: `${ORIGIN}/library`, mode: "navigate" });
    expect(await cached.response?.text()).toBe("<html>library</html>");

    const unvisited = await harness.dispatchFetch({
      url: `${ORIGIN}/library/statistics`,
      mode: "navigate",
    });
    expect(await unvisited.response?.text()).toBe("<h1>cinematic</h1>");
  });

  it("opens a saved chapter's document that was never visited as a document", async () => {
    // The realistic path to a saved chapter: the user clicked through to the
    // reader inside the SPA, so the browser NEVER issued a navigation for the
    // reader route and the document cache has no copy of it. Saving fetches the
    // document on purpose for exactly this case; a cold offline launch (or a
    // reload on the train) must get it back rather than the offline page.
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: DOCUMENT_URL,
      mode: "navigate",
    });
    expect(await outcome.response?.text()).toBe("<html>reader</html>");
  });

  it("does not serve a saved document to a profile that did not save it", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );

    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: DOCUMENT_URL,
      mode: "navigate",
      clientId: "client-b",
    });
    expect(await outcome.response?.text()).toBe("<h1>cinematic</h1>");
  });

  it("does not let the document cache grow without bound", async () => {
    await boot();
    for (let index = 0; index < 70; index += 1) {
      const url = `${ORIGIN}/library/${index}`;
      route(harness, url, { body: `series ${index}` });
      await harness.dispatchFetch({ url, mode: "navigate" });
    }
    const pages = harness.cacheFor(`mm-pages-${RUNTIME_VERSION}`);
    expect((await (pages as { keys(): Promise<unknown[]> }).keys()).length).toBeLessThanOrEqual(
      60,
    );
    // The most recent visits survive; the oldest are the ones dropped.
    expect(await pages?.match(`${ORIGIN}/library/69`)).toBeTruthy();
    expect(await pages?.match(`${ORIGIN}/library/0`)).toBeUndefined();
  });

  it("ignores the query string when matching a cached reader document", async () => {
    await boot();
    await harness.dispatchFetch({ url: DOCUMENT_URL, mode: "navigate" });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: `${DOCUMENT_URL}?page=12`,
      mode: "navigate",
    });
    expect(await outcome.response?.text()).toBe("<html>reader</html>");
  });
});

describe("bookmarks with no network", () => {
  it("hands back the last listing it saw", async () => {
    await boot();
    await harness.dispatchFetch({ url: BOOKMARKS });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: BOOKMARKS });
    expect(outcome.handled).toBe(true);
    expect(await outcome.response?.text()).toBe('[{"id":1,"anchor_index":7}]');
  });

  it("prefers the live listing whenever there is one", async () => {
    await boot();
    await harness.dispatchFetch({ url: BOOKMARKS });

    // A bookmark added since. A stale-first strategy would not show it.
    route(harness, BOOKMARKS, { body: '[{"id":2},{"id":1,"anchor_index":7}]' });
    const outcome = await harness.dispatchFetch({ url: BOOKMARKS });
    expect(await outcome.response?.text()).toBe('[{"id":2},{"id":1,"anchor_index":7}]');
  });

  it("fails honestly when it has never seen the listing", async () => {
    await boot();
    harness.offline = true;

    const outcome = await harness.dispatchFetch({ url: BOOKMARKS });
    // The screen shows its offline state rather than an empty bookmark list,
    // which would read as "you have no bookmarks".
    expect(outcome.response?.type ?? "error").toBe("error");
  });

  it("keeps one profile's saved places out of another's", async () => {
    await boot();
    await harness.dispatchFetch({ url: BOOKMARKS });
    expect(await harness.cacheNames()).toContain(ALICE_API_CACHE);

    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-a",
    );
    harness.offline = true;

    const outcome = await harness.dispatchFetch({ url: BOOKMARKS });
    expect(outcome.response?.type ?? "error").toBe("error");
  });
});

describe("profile isolation", () => {
  it("does not show one profile's saved chapters to another", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    const asBob = await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );
    expect((asBob.state as { entries: unknown[] }).entries).toHaveLength(0);
  });

  it("does not serve one profile's saved pages to another's tab", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );

    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: PAGE_ONE,
      destination: "image",
      clientId: "client-b",
    });
    // Bob's tab gets a network failure, exactly as if the page had never been
    // saved — not Alice's bytes.
    expect(outcome.response).toBeNull();
    expect(outcome.error).toBeTruthy();
  });

  it("keeps serving the right tab after another tab switches profile", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );

    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: PAGE_ONE,
      destination: "image",
      clientId: "client-a",
    });
    expect(await outcome.response?.text()).toBe("page-one-bytes");
  });

  it("stops serving saved content once the profile is cleared", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage({
      type: "mm-offline/set-scope",
      scope: null,
      apiBase: API_BASE,
    });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: PAGE_ONE, destination: "image" });
    expect(outcome.response).toBeNull();
  });
});

describe("what is never cached", () => {
  it("does not touch auth, online or offline", async () => {
    await boot();
    const outcome = await harness.dispatchFetch({ url: `${API_BASE}/auth/me` });
    expect(outcome.handled).toBe(false);
    const names = await harness.cacheNames();
    for (const name of names) {
      const cache = harness.cacheFor(name);
      expect(await cache?.match(`${API_BASE}/auth/me`)).toBeUndefined();
    }
  });

  it("does not touch a mutation", async () => {
    await boot();
    for (const method of ["POST", "PATCH", "DELETE"]) {
      const outcome = await harness.dispatchFetch({
        url: `${API_BASE}/reader/progress`,
        method,
      });
      expect(outcome.handled).toBe(false);
    }
  });

  it("does not answer a ranged request from a cache it cannot fill", async () => {
    await boot();
    const outcome = await harness.dispatchFetch({
      url: PAGE_ONE,
      destination: "image",
      headers: { range: "bytes=0-100" },
    });
    expect(outcome.handled).toBe(false);
  });
});

describe("stale-while-revalidate", () => {
  it("answers from cache and refreshes behind it, per profile", async () => {
    const listUrl = `${API_BASE}/library/series?limit=20`;
    route(harness, listUrl, { body: '["first"]' });
    await boot();

    const first = await harness.dispatchFetch({ url: listUrl });
    expect(await first.response?.text()).toBe('["first"]');

    route(harness, listUrl, { body: '["second"]' });
    const second = await harness.dispatchFetch({ url: listUrl });
    // The cached copy answers now; the refreshed one lands behind it.
    expect(await second.response?.text()).toBe('["first"]');

    const third = await harness.dispatchFetch({ url: listUrl });
    expect(await third.response?.text()).toBe('["second"]');
    expect(await harness.cacheNames()).toContain(ALICE_API_CACHE);
  });

  it("caches nothing per-profile when there is no profile", async () => {
    await harness.dispatchInstall();
    await harness.dispatchActivate();
    await harness.dispatchMessage({
      type: "mm-offline/set-scope",
      scope: null,
      apiBase: API_BASE,
    });
    const listUrl = `${API_BASE}/library/series`;
    route(harness, listUrl, { body: "[]" });

    await harness.dispatchFetch({ url: listUrl });
    const names = await harness.cacheNames();
    expect(names.filter((name) => name.startsWith("mm-api-"))).toEqual([]);
  });
});

describe("the per-profile API cache is bounded", () => {
  // The browser evicts per origin and takes the whole origin, saved chapters
  // included, so the cache that grows with ordinary browsing is the one that
  // must not. Mirrors MAX_API_ENTRIES / MAX_API_AGE_MS in sw.js.
  const CAP = 200;
  const DAY = 24 * 60 * 60_000;
  const START = 1_700_000_000_000;

  function seriesUrl(index: number): string {
    return `${API_BASE}/library/series/${index}/chapters`;
  }

  async function open(index: number): Promise<void> {
    route(harness, seriesUrl(index), { body: `{"id":${index}}` });
    await harness.dispatchFetch({ url: seriesUrl(index) });
  }

  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(START);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("drops the oldest entries past the cap, on write", async () => {
    await boot();
    for (let index = 0; index < CAP + 50; index += 1) await open(index);

    const cache = harness.cacheFor(ALICE_API_CACHE)!;
    expect(cache.entries.size).toBeLessThanOrEqual(CAP);
    expect(await cache.match(seriesUrl(CAP + 49))).toBeTruthy();
    expect(await cache.match(seriesUrl(0))).toBeUndefined();
  });

  it("ages a week-old entry out on the next stale-while-revalidate write", async () => {
    await boot();
    await open(1);
    vi.setSystemTime(START + 8 * DAY);
    await open(2);

    const cache = harness.cacheFor(ALICE_API_CACHE)!;
    expect(await cache.match(seriesUrl(1))).toBeUndefined();
    expect(await cache.match(seriesUrl(2))).toBeTruthy();
  });

  it("ages it out on an offline-fallback write just the same", async () => {
    await boot();
    await open(1);
    vi.setSystemTime(START + 8 * DAY);
    await harness.dispatchFetch({ url: BOOKMARKS });

    const cache = harness.cacheFor(ALICE_API_CACHE)!;
    expect(await cache.match(seriesUrl(1))).toBeUndefined();
    expect(await cache.match(BOOKMARKS)).toBeTruthy();
  });

  it("keeps an entry that is merely a day old", async () => {
    await boot();
    await open(1);
    vi.setSystemTime(START + 1 * DAY);
    await open(2);

    const cache = harness.cacheFor(ALICE_API_CACHE)!;
    expect(await cache.match(seriesUrl(1))).toBeTruthy();
    expect(await cache.match(seriesUrl(2))).toBeTruthy();
  });

  it("serves a stored entry back without its bookkeeping changing the body", async () => {
    await boot();
    await open(1);
    harness.offline = true;

    const outcome = await harness.dispatchFetch({ url: seriesUrl(1) });
    expect(await outcome.response?.text()).toBe('{"id":1}');
  });
});

describe("retention and eviction", () => {
  // A fixed clock: the retention rule is `now - readAt >= retentionMs`, and with
  // a real wall clock the millisecond between stamping `readAt` and running the
  // sweep is not guaranteed to have elapsed — which is the timing race that made
  // this suite flaky. Faking `Date` makes every step's "now" explicit.
  const START = 1_700_000_000_000;

  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(START);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  async function saveAndFinish(): Promise<void> {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage({
      type: "mm-offline/mark-finished",
      scope: ALICE,
      key: KEY,
    });
  }

  it("stamps a finish time and clears it when the chapter is reopened", async () => {
    await saveAndFinish();
    let index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].readAt).toBe(START);

    vi.setSystemTime(START + 60_000);
    await harness.dispatchMessage({
      type: "mm-offline/mark-opened",
      scope: ALICE,
      key: KEY,
    });
    index = await readIndex(harness, ALICE_CACHE);
    // Re-reading cancels the deletion instead of it vanishing mid-scroll.
    expect(index?.entries[KEY].readAt).toBeNull();
  });

  it("deletes a finished chapter's pages once its retention has passed", async () => {
    await saveAndFinish();
    // Retention of one minute; the sweep runs an hour later, so it is due.
    await harness.dispatchMessage({
      type: "mm-offline/set-retention",
      scope: ALICE,
      retentionMs: 60_000,
    });
    vi.setSystemTime(START + 60 * 60_000);
    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY]).toBeUndefined();
    const cache = harness.cacheFor(ALICE_CACHE);
    expect(await cache?.match(PAGE_ONE)).toBeUndefined();
  });

  it("never deletes the chapter that is open, even when it is due", async () => {
    await saveAndFinish();
    // The reader sends mark-opened on mount, which both clears the timer and
    // marks this chapter as the one on screen.
    await harness.dispatchMessage({
      type: "mm-offline/mark-opened",
      scope: ALICE,
      key: KEY,
    });
    await harness.dispatchMessage({
      type: "mm-offline/set-retention",
      scope: ALICE,
      retentionMs: 60_000,
    });
    // Reaching the last page again while still on it: due, and on screen.
    vi.setSystemTime(START + 60 * 60_000);
    await harness.dispatchMessage({
      type: "mm-offline/mark-finished",
      scope: ALICE,
      key: KEY,
    });
    vi.setSystemTime(START + 120 * 60_000);
    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY]).toBeDefined();
  });

  it("can be turned off entirely", async () => {
    await saveAndFinish();
    await harness.dispatchMessage({
      type: "mm-offline/set-retention",
      scope: ALICE,
      retentionMs: null,
    });
    vi.setSystemTime(START + 30 * 24 * 60 * 60_000);
    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY]).toBeDefined();
  });

  it("evicts the oldest finished chapter under pressure", async () => {
    await saveAndFinish();
    await harness.dispatchMessage({
      type: "mm-offline/chapter-closed",
      key: KEY,
    });
    harness.estimate = { usage: 9_999_000_000, quota: 10_000_000_000 };
    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY]).toBeUndefined();
  });

  /**
   * A quota meter that answers from what is actually stored.
   *
   * The harness reports a fixed estimate, and with a constant "still full" the
   * question below cannot be asked at all: whether giving up the disposable
   * caches is ENOUGH to stop the worker reaching for a saved chapter. Bodies
   * in this suite are a few hundred bytes, so they are scaled into the range
   * the storage rules are actually written in.
   */
  const QUOTA = 10_000_000_000;
  const METER_FLOOR = 8_500_000_000;
  const METER_SCALE = 100_000;

  function meterStorage(): void {
    const workerNavigator = harness.self.navigator as {
      storage: { estimate: () => Promise<{ usage: number; quota: number }> };
    };
    workerNavigator.storage = {
      estimate: async () => {
        let bytes = 0;
        for (const name of await harness.cacheNames()) {
          for (const stored of harness.cacheFor(name)?.entries.values() ?? []) {
            bytes += stored.body.length;
          }
        }
        return { usage: METER_FLOOR + bytes * METER_SCALE, quota: QUOTA };
      },
    };
  }

  /** Fill the origin with the things that exist only to save a round trip. */
  async function fillDisposableCaches(): Promise<void> {
    for (let index = 0; index < 20; index += 1) {
      const api = `${API_BASE}/library/series/${index}`;
      route(harness, api, { body: "a".repeat(500) });
      await harness.dispatchFetch({ url: api });

      const document = `${ORIGIN}/series/${index}`;
      route(harness, document, { body: "d".repeat(500) });
      await harness.dispatchFetch({ url: document, mode: "navigate" });
    }
    const chunk = `${ORIGIN}/_next/static/chunks/app.js`;
    route(harness, chunk, { body: "app" });
    await harness.dispatchFetch({ url: chunk });
  }

  it("gives up the disposable caches before it takes a saved chapter", async () => {
    await saveAndFinish();
    await harness.dispatchMessage({ type: "mm-offline/chapter-closed", key: KEY });
    await fillDisposableCaches();
    meterStorage();

    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY]).toBeDefined();
    expect(await harness.cacheFor(ALICE_CACHE)?.match(PAGE_ONE)).toBeTruthy();
    expect(harness.cacheFor(ALICE_API_CACHE)?.entries.size ?? 0).toBe(0);
    expect(harness.cacheFor(`mm-pages-${RUNTIME_VERSION}`)?.entries.size ?? 0).toBe(0);
  });

  it("keeps the build the saved chapter has to be rendered with", async () => {
    await saveAndFinish();
    await harness.dispatchMessage({ type: "mm-offline/chapter-closed", key: KEY });
    await fillDisposableCaches();
    meterStorage();

    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });

    // Dropping these would leave the downloads intact and unopenable, which is
    // the same loss by another route.
    expect(harness.cacheFor(`mm-static-${RUNTIME_VERSION}`)?.entries.size ?? 0).toBeGreaterThan(0);
    expect(harness.cacheFor(`mm-shell-${RUNTIME_VERSION}`)?.entries.size ?? 0).toBeGreaterThan(0);
  });
});

describe("removal", () => {
  it("takes exactly what the chapter put there", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage({
      type: "mm-offline/remove-chapter",
      scope: ALICE,
      key: KEY,
    });

    const cache = harness.cacheFor(ALICE_CACHE);
    expect(await cache?.match(PAGE_ONE)).toBeUndefined();
    expect(await cache?.match(PAGE_TWO)).toBeUndefined();
    expect(await cache?.match(PAYLOAD)).toBeUndefined();
    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY]).toBeUndefined();
  });

  it("clears one profile's caches without touching another's", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(BOB),
    }, "client-b");

    await harness.dispatchMessage({ type: "mm-offline/clear-scope", scope: BOB });

    expect(await harness.cacheNames()).toContain(ALICE_CACHE);
    expect(await harness.cacheNames()).not.toContain(BOB_CACHE);
  });
});

describe("downloading a novel", () => {
  /**
   * The spec calls a whole-series download mobile-only because "the web has no
   * on-device store". The web has this one, and a prose chapter fits it without
   * a new message, a new cache or a new rule: it is a `SaveChapterRequest` with
   * no images whose payload is `GET /novels/chapter`. This is that claim
   * executed rather than asserted — save it, cut the network, open it.
   */
  const NOVEL_SOURCE = "novelbin";
  const NOVEL_SERIES = "book/lotm";
  const NOVEL_CHAPTER = "ch/12";
  const NOVEL_KEY = `chapter:${NOVEL_SOURCE}:${NOVEL_SERIES}:${NOVEL_CHAPTER}`;
  const NOVEL_BODY = JSON.stringify({
    source_id: NOVEL_SOURCE,
    series_key: NOVEL_SERIES,
    chapter_key: NOVEL_CHAPTER,
    title: "Chapter 12",
    chapter_number: 12,
    paragraphs: ["The fog rolled in.", "Klein woke."],
    prev: "ch/11",
    next: "ch/13",
    word_count: 6,
  });

  function novelPayload() {
    return buildNovelSaveRequest({
      ref: {
        sourceId: NOVEL_SOURCE,
        seriesKey: NOVEL_SERIES,
        chapterKey: NOVEL_CHAPTER,
      },
      title: "Chapter 12",
      seriesTitle: "Lord of the Mysteries",
      scope: ALICE,
      apiBase: API_BASE,
      origin: ORIGIN,
      payloadJson: NOVEL_BODY,
    });
  }

  it("serves the chapter text with no network at all", async () => {
    await boot();
    const payload = novelPayload();
    route(harness, payload.documentUrl, { body: "<html>novel</html>" });
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: payload.payloadUrl });
    expect(outcome.handled).toBe(true);
    expect(await outcome.response?.text()).toBe(NOVEL_BODY);
  });

  it("settles as ready — a chapter with no images has no pages to miss", async () => {
    await boot();
    const payload = novelPayload();
    route(harness, payload.documentUrl, { body: "<html>novel</html>" });
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[NOVEL_KEY]).toMatchObject({
      status: "ready",
      pageCount: 0,
      failed: 0,
      stale: false,
      // /downloads reads this to open prose in the novel reader. Without it the
      // row linked to the page reader, which answers "This chapter has no
      // pages." over bytes that are all present.
      medium: "novel",
    });
  });

  it("is never flagged stale by the page-drift check, which is about images", async () => {
    await boot();
    const payload = novelPayload();
    route(harness, payload.documentUrl, { body: "<html>novel</html>" });
    route(harness, payload.payloadUrl, { body: NOVEL_BODY });
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload });

    // Online again: the live answer wins, and the saved copy is refreshed as it
    // passes. Prose carries no `pages`, so there is no drift to find.
    await harness.dispatchFetch({ url: payload.payloadUrl });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[NOVEL_KEY].stale).toBe(false);
  });

  it("opens a downloaded book cold, with the reader route never navigated to", async () => {
    await boot();
    const payload = novelPayload();
    route(harness, payload.documentUrl, { body: "<html>novel</html>" });
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload });

    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: payload.documentUrl,
      mode: "navigate",
    });
    expect(await outcome.response?.text()).toBe("<html>novel</html>");
  });

  it("keeps one profile's book out of another's", async () => {
    await boot();
    const payload = novelPayload();
    route(harness, payload.documentUrl, { body: "<html>novel</html>" });
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload });

    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );
    harness.offline = true;
    const outcome = await harness.dispatchFetch({
      url: payload.payloadUrl,
      clientId: "client-b",
    });
    // Handled, and refused: Bob's tab is answered from Bob's cache, which does
    // not exist — never from Alice's, and never from a shared default.
    expect(outcome.handled).toBe(true);
    expect(outcome.response?.ok).toBe(false);
    expect(await outcome.response?.text()).not.toContain("Klein");
  });
});

describe("drift after a re-list", () => {
  it("flags a saved chapter whose page urls moved", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    // A re-list reassigns the source's page URLs; every saved image is keyed by
    // the old ones.
    route(harness, PAYLOAD, {
      body: JSON.stringify({
        source_id: SOURCE,
        series_key: SERIES,
        chapter_key: CHAPTER,
        chapter_number: 50,
        page_count: 2,
        pages: [
          { number: 1, url: `${API_BASE}/sources/${SOURCE}/pages/x91/image` },
          { number: 2, url: `${API_BASE}/sources/${SOURCE}/pages/x92/image` },
        ],
        prev: "ch/49",
        next: "ch/51",
      }),
    });
    await harness.dispatchFetch({ url: PAYLOAD });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].stale).toBe(true);
  });

  it("leaves an unchanged chapter alone", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    await harness.dispatchFetch({ url: PAYLOAD });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].stale).toBe(false);
  });
});

describe("skin messages and per-skin offline fallback", () => {
  const META = "mm-sw-meta";
  async function stored(): Promise<string | undefined> {
    const hit = await harness.cacheFor(META)?.match("/__skin");
    return hit?.text();
  }
  async function offlineNav(): Promise<string> {
    harness.offline = true;
    const out = await harness.dispatchFetch({ url: "/never-cached", mode: "navigate" });
    return (await out.response?.text()) ?? "";
  }

  it("stores the skin at /__skin in mm-sw-meta", async () => {
    await boot();
    await harness.dispatchMessage({ type: "skin", skin: "glass" });
    expect(await stored()).toBe("glass");
  });

  it("ignores an unknown skin", async () => {
    await boot();
    await harness.dispatchMessage({ type: "skin", skin: "neon" });
    expect(await stored()).toBeUndefined();
  });

  it("serves the glass fallback after glass", async () => {
    await boot();
    await harness.dispatchMessage({ type: "skin", skin: "glass" });
    expect(await offlineNav()).toContain("glass");
  });

  it("serves the cinematic fallback after cinematic and with nothing stored", async () => {
    await boot();
    expect(await offlineNav()).toContain("cinematic");
    await harness.dispatchMessage({ type: "skin", skin: "cinematic" });
    expect(await offlineNav()).toContain("cinematic");
  });

  it("serves the legacy fallback after legacy", async () => {
    await boot();
    await harness.dispatchMessage({ type: "skin", skin: "legacy" });
    expect(await offlineNav()).toContain("offline");
  });

  it("keeps mm-sw-meta through an activate", async () => {
    await boot();
    await harness.dispatchMessage({ type: "skin", skin: "glass" });
    await harness.dispatchActivate();
    expect(await stored()).toBe("glass");
  });

  it("skin-changed drops the pages cache and re-fetches saved html documents", async () => {
    route(harness, DOCUMENT_URL, { body: "<html>old</html>", headers: { "content-type": "text/html" } });
    await boot();
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload: savePayload(ALICE) });
    await harness.dispatchFetch({ url: `${ORIGIN}/library`, mode: "navigate" });
    expect(harness.cacheFor(`mm-pages-${RUNTIME_VERSION}`)).toBeTruthy();
    route(harness, DOCUMENT_URL, { body: "<html>new</html>", headers: { "content-type": "text/html" } });
    harness.fetched.length = 0;
    await harness.dispatchMessage({ type: "skin-changed", skin: "glass" });
    expect(await harness.storage.has(`mm-pages-${RUNTIME_VERSION}`)).toBe(false);
    expect(harness.fetched).toContain(DOCUMENT_URL);
    expect(harness.fetched).not.toContain(PAGE_ONE);
    const hit = await harness.cacheFor(ALICE_CACHE)?.match(DOCUMENT_URL);
    expect(await hit?.text()).toBe("<html>new</html>");
    expect(await stored()).toBe("glass");
  });

  it("skin-changed offline keeps the old saved document", async () => {
    route(harness, DOCUMENT_URL, { body: "<html>old</html>", headers: { "content-type": "text/html" } });
    await boot();
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload: savePayload(ALICE) });
    harness.offline = true;
    await harness.dispatchMessage({ type: "skin-changed", skin: "glass" });
    const hit = await harness.cacheFor(ALICE_CACHE)?.match(DOCUMENT_URL);
    expect(await hit?.text()).toBe("<html>old</html>");
  });
});

describe("saved page images across viewport widths", () => {
  // The reader bakes a width derived from the viewport into every page URL
  // (`?w=`), so the same page is asked for under a different URL after a
  // rotation, a resize or a zoom than the one it was saved under.
  const SAVED_ONE = `${PAGE_ONE}?w=1170`;
  const SAVED_TWO = `${PAGE_TWO}?w=1170`;

  async function savePortrait(): Promise<void> {
    route(harness, SAVED_ONE, { body: "page-one-bytes", headers: { "content-type": "image/jpeg" } });
    route(harness, SAVED_TWO, { body: "page-two-bytes", headers: { "content-type": "image/jpeg" } });
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: { ...savePayload(ALICE), imageUrls: [SAVED_ONE, SAVED_TWO] },
    });
    harness.offline = true;
  }

  it("serves a page saved in portrait to a landscape reader", async () => {
    await savePortrait();
    const outcome = await harness.dispatchFetch({
      url: `${PAGE_ONE}?w=2304`,
      destination: "image",
    });
    expect(await outcome.response?.text()).toBe("page-one-bytes");
  });

  it("serves it to a zoomed reader that asks with no width at all", async () => {
    await savePortrait();
    const outcome = await harness.dispatchFetch({ url: PAGE_TWO, destination: "image" });
    expect(await outcome.response?.text()).toBe("page-two-bytes");
  });

  it("still keys the chapter manifest by its query", async () => {
    await savePortrait();
    const other = await harness.dispatchFetch({
      url:
        `${API_BASE}/reader/chapter/manifest` +
        `?source=${SOURCE}&series=${encodeURIComponent(SERIES)}&chapter=${encodeURIComponent("ch/51")}`,
    });
    expect(other.response?.type).toBe("error");
    const same = await harness.dispatchFetch({ url: PAYLOAD });
    expect(await same.response?.text()).toBe(CHAPTER_BODY);
  });
});

describe("an interrupted save", () => {
  it("is recorded as partial when a write throws, and the pages are told", async () => {
    await boot();
    harness.failPut = (cacheName, url) => cacheName === ALICE_CACHE && url === PAYLOAD;
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });

    const index = await readIndex(harness, ALICE_CACHE);
    expect(index?.entries[KEY].status).toBe("partial");

    const states = harness.clients[0].messages.filter(
      (message) => (message as { type?: string }).type === "mm-offline/state",
    ) as Array<{ state: { entries: Array<{ key: string; status: string }> } }>;
    const last = states[states.length - 1];
    expect(last.state.entries.find((entry) => entry.key === KEY)?.status).toBe("partial");
  });

  it("is reported partial, not saving, by a worker that is not running it", async () => {
    await boot();
    await harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    // The worker was killed mid-save: the entry on disk still says "saving".
    const cache = harness.cacheFor(ALICE_CACHE);
    const stored = await readIndex(harness, ALICE_CACHE);
    stored!.entries[KEY].status = "saving";
    await cache!.put(
      `${ORIGIN}/__mm-offline/index.json`,
      new Response(JSON.stringify(stored)),
    );

    const restarted = createHarness({ storage: harness.storage });
    await restarted.dispatchMessage({
      type: "mm-offline/set-scope",
      scope: ALICE,
      apiBase: API_BASE,
    });
    const reply = await restarted.dispatchMessage({ type: "mm-offline/get-state" });
    const state = reply.state as { entries: Array<{ key: string; status: string }> };
    expect(state.entries.find((entry) => entry.key === KEY)?.status).toBe("partial");
  });

  it("keeps a save that is really running as saving", async () => {
    route(harness, PAGE_TWO, { hang: true });
    await boot();
    const saving = harness.dispatchMessage({
      type: "mm-offline/save-chapter",
      payload: savePayload(ALICE),
    });
    for (let turn = 0; turn < 20; turn += 1) await new Promise((r) => setTimeout(r, 0));
    const reply = await harness.dispatchMessage({ type: "mm-offline/get-state" });
    const state = reply.state as { entries: Array<{ key: string; status: string }> };
    expect(state.entries.find((entry) => entry.key === KEY)?.status).toBe("saving");
    await harness.dispatchMessage({ type: "mm-offline/cancel-save", key: KEY });
    void saving;
  });
});

describe("the offline fallback's Downloads link", () => {
  async function visitOtherPages(count: number): Promise<void> {
    for (let index = 0; index < count; index += 1) {
      const url = `${ORIGIN}/series/${index}`;
      route(harness, url, { body: `series ${index}` });
      await harness.dispatchFetch({ url, mode: "navigate" });
    }
  }

  it("still opens after the document cache has turned over", async () => {
    await boot();
    await visitOtherPages(61);
    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: `${ORIGIN}/downloads`, mode: "navigate" });
    expect(await outcome.response?.text()).toBe("<html>downloads</html>");
  });

  it("still opens after storage pressure drops the disposable caches", async () => {
    await boot();
    harness.estimate = { usage: 9_999_000_000, quota: 10_000_000_000 };
    await harness.dispatchMessage({ type: "mm-offline/sweep", scope: ALICE });
    expect(await harness.storage.has(`mm-pages-${RUNTIME_VERSION}`)).toBe(false);

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: `${ORIGIN}/library`, mode: "navigate" });
    expect(await outcome.response?.text()).toBe("<html>library</html>");
  });

  it("serves the copy from the last visit, not the one from activation", async () => {
    await boot();
    route(harness, "/downloads", { body: "<html>downloads v2</html>" });
    await harness.dispatchFetch({ url: `${ORIGIN}/downloads`, mode: "navigate" });
    await harness.storage.delete(`mm-pages-${RUNTIME_VERSION}`);

    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: `${ORIGIN}/downloads`, mode: "navigate" });
    expect(await outcome.response?.text()).toBe("<html>downloads v2</html>");
  });

  it("is refreshed in place when the skin changes, and kept when offline", async () => {
    await boot();
    route(harness, "/downloads", { body: "<html>downloads glass</html>" });
    await harness.dispatchMessage({ type: "skin-changed", skin: "glass" });
    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: `${ORIGIN}/downloads`, mode: "navigate" });
    expect(await outcome.response?.text()).toBe("<html>downloads glass</html>");

    await harness.dispatchMessage({ type: "skin-changed", skin: "legacy" });
    const kept = await harness.dispatchFetch({ url: `${ORIGIN}/downloads`, mode: "navigate" });
    expect(await kept.response?.text()).toBe("<html>downloads glass</html>");
  });

  it("does not stand in for a page that was never warmed", async () => {
    await boot();
    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: `${ORIGIN}/downloads/other`, mode: "navigate" });
    expect(await outcome.response?.text()).toBe("<h1>cinematic</h1>");
  });
});

describe("a cache write never decides the response", () => {
  const STATIC_URL = `${ORIGIN}/_next/static/chunks/app.abc123.js`;

  it("serves a build asset the cache has no room for", async () => {
    route(harness, STATIC_URL, { body: "chunk" });
    await boot();
    harness.failPut = (cacheName) => cacheName === `mm-static-${RUNTIME_VERSION}`;
    const outcome = await harness.dispatchFetch({ url: STATIC_URL });
    expect(outcome.error).toBeNull();
    expect(outcome.response?.status).toBe(200);
    expect(await outcome.response?.text()).toBe("chunk");
  });

  it("serves a stale-while-revalidate answer the cache has no room for", async () => {
    const listUrl = `${API_BASE}/library/series?limit=20`;
    route(harness, listUrl, { body: '["fresh"]' });
    await boot();
    harness.failPut = (cacheName) => cacheName === ALICE_API_CACHE;
    const outcome = await harness.dispatchFetch({ url: listUrl });
    expect(outcome.error).toBeNull();
    expect(outcome.response?.type).not.toBe("error");
    expect(await outcome.response?.text()).toBe('["fresh"]');
  });
});

describe("activation does not wait on a stalled connection", () => {
  it("settles within the warm-fetch bound when the warm fetches never answer", async () => {
    vi.useFakeTimers();
    try {
      route(harness, "/library", { hang: true });
      route(harness, "/downloads", { hang: true });
      await harness.dispatchInstall();

      let settled = false;
      const activation = harness.dispatchActivate().then(() => {
        settled = true;
      });
      await vi.advanceTimersByTimeAsync(5_500);
      expect(settled).toBe(true);
      await activation;
    } finally {
      vi.useRealTimers();
    }
  });

  it("still deletes superseded caches and claims clients first", async () => {
    vi.useFakeTimers();
    try {
      await harness.storage.open("mm-shell-v1");
      route(harness, "/library", { hang: true });
      route(harness, "/downloads", { hang: true });
      await harness.dispatchInstall();
      const activation = harness.dispatchActivate();
      await vi.advanceTimersByTimeAsync(5_500);
      await activation;
      expect(await harness.cacheNames()).not.toContain("mm-shell-v1");
    } finally {
      vi.useRealTimers();
    }
  });
});

describe("a saved chapter keeps the build files it renders with", () => {
  const CHUNK_X = `${ORIGIN}/_next/static/chunks/x.js`;
  const CHUNK_Y = `${ORIGIN}/_next/static/chunks/y.js`;
  const STATIC_CACHE = `mm-static-${RUNTIME_VERSION}`;
  const READER_HTML =
    '<html><head><script src="/_next/static/chunks/x.js" async=""></script></head><body>' +
    '<script>self.__next_f.push([1,"[\\"static/chunks/y.js\\"]"])</script></body></html>';

  const KEY_TWO = `chapter:${SOURCE}:${SERIES}:ch/51`;
  const PAGE_THREE = `${API_BASE}/sources/${SOURCE}/pages/p3/image`;
  const PAYLOAD_TWO = `${PAYLOAD}2`;
  const DOCUMENT_TWO = `${ORIGIN}/reader/${SOURCE}/${encodeURIComponent(SERIES)}/ch/51`;

  function secondPayload() {
    return {
      ...savePayload(ALICE),
      key: KEY_TWO,
      chapterKey: "ch/51",
      title: "Chapter 51",
      documentUrl: DOCUMENT_TWO,
      payloadUrl: PAYLOAD_TWO,
      payloadJson: CHAPTER_BODY,
      imageUrls: [PAGE_THREE],
      extraUrls: [],
    };
  }

  beforeEach(() => {
    route(harness, DOCUMENT_URL, { body: READER_HTML, headers: { "content-type": "text/html" } });
    route(harness, DOCUMENT_TWO, { body: READER_HTML, headers: { "content-type": "text/html" } });
    route(harness, PAGE_THREE, { body: "page-three-bytes", headers: { "content-type": "image/jpeg" } });
    route(harness, CHUNK_X, { body: "chunk-x", headers: { "content-type": "text/javascript" } });
    route(harness, CHUNK_Y, { body: "chunk-y", headers: { "content-type": "text/javascript" } });
  });

  async function save(payload = savePayload(ALICE)): Promise<void> {
    await harness.dispatchMessage({ type: "mm-offline/save-chapter", payload });
  }

  async function offlineChunk(url: string): Promise<string | null> {
    const outcome = await harness.dispatchFetch({ url });
    return outcome.response && outcome.response.type !== "error" && outcome.response.ok
      ? outcome.response.text()
      : null;
  }

  it("serves both chunks with the build's own cache gone", async () => {
    await boot();
    await save();
    await harness.storage.delete(STATIC_CACHE);
    harness.offline = true;

    expect(await offlineChunk(CHUNK_X)).toBe("chunk-x");
    expect(await offlineChunk(CHUNK_Y)).toBe("chunk-y");
    // Only what the document named, and a build's own query does not matter.
    expect(await offlineChunk(`${ORIGIN}/_next/static/chunks/z.js`)).toBeNull();
    expect(await offlineChunk(`${CHUNK_X}?dpl=abc`)).toBe("chunk-x");
  });

  it("serves a saved build file when the server no longer has it", async () => {
    await boot();
    await save();
    harness.routes.delete(CHUNK_X);
    expect(await offlineChunk(CHUNK_X)).toBe("chunk-x");
  });

  it("copies from the build cache instead of downloading a file twice", async () => {
    await boot();
    await harness.dispatchFetch({ url: CHUNK_X });
    harness.fetched.length = 0;
    await save();
    expect(harness.fetched).not.toContain(CHUNK_X);
    expect(harness.fetched).toContain(CHUNK_Y);
    expect(await harness.cacheFor(ALICE_CACHE)?.match(CHUNK_X)).toBeTruthy();
  });

  it("records them as the chapter's own, without counting them as pages", async () => {
    await boot();
    await save();
    const index = await readIndex(harness, ALICE_CACHE);
    const entry = index!.entries[KEY];
    expect(entry.urls).toEqual(expect.arrayContaining([CHUNK_X, CHUNK_Y]));
    expect(entry.pageCount).toBe(2);
    expect(entry.savedPages).toBe(2);
    expect(entry.failed).toBe(0);
    expect(entry.status).toBe("ready");
  });

  it("does not hold the chapter back when a build file cannot be fetched", async () => {
    harness.routes.delete(CHUNK_Y);
    await boot();
    await save();
    const index = await readIndex(harness, ALICE_CACHE);
    expect(index!.entries[KEY].status).toBe("ready");
    expect(index!.entries[KEY].failed).toBe(0);
  });

  it("picks them up when the chapter is saved again", async () => {
    harness.routes.delete(CHUNK_Y);
    await boot();
    await save();
    expect(await harness.cacheFor(ALICE_CACHE)?.match(CHUNK_Y)).toBeUndefined();

    route(harness, CHUNK_Y, { body: "chunk-y" });
    await save();
    expect(await harness.cacheFor(ALICE_CACHE)?.match(CHUNK_Y)).toBeTruthy();
    const index = await readIndex(harness, ALICE_CACHE);
    expect(index!.entries[KEY].urls).toEqual(expect.arrayContaining([CHUNK_X, CHUNK_Y]));
  });

  it("keeps a shared file until the last chapter that lists it is removed", async () => {
    await boot();
    await save();
    await save(secondPayload());
    await harness.storage.delete(STATIC_CACHE);
    harness.offline = true;

    await harness.dispatchMessage({ type: "mm-offline/remove-chapter", scope: ALICE, key: KEY });
    expect(await offlineChunk(CHUNK_X)).toBe("chunk-x");
    expect(await offlineChunk(CHUNK_Y)).toBe("chunk-y");

    await harness.dispatchMessage({ type: "mm-offline/remove-chapter", scope: ALICE, key: KEY_TWO });
    expect(await offlineChunk(CHUNK_X)).toBeNull();
    expect(await offlineChunk(CHUNK_Y)).toBeNull();
  });

  it("does not hand one profile's saved build files to another", async () => {
    await boot();
    await save();
    await harness.storage.delete(STATIC_CACHE);
    await harness.dispatchMessage(
      { type: "mm-offline/set-scope", scope: BOB, apiBase: API_BASE },
      "client-b",
    );
    harness.offline = true;
    const outcome = await harness.dispatchFetch({ url: CHUNK_X, clientId: "client-b" });
    expect(outcome.response?.type ?? "error").toBe("error");
  });
});
