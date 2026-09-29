import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { SCREEN_IDS, type ScreenId } from "./contract.generated";
import { screens as cine, PENDING as cinePending } from "./cinematic/index";
import { screens as glass, PENDING as glassPending } from "./glass/index";
import Pending from "./pending";
import SetupRedirect from "./setup-redirect";

// web/24 sets cinematic to true, web/45 sets glass to true (release gates).
const MUST_BE_COMPLETE = { cinematic: false, glass: false };

/*
 * Never import ./index or ./legacy/*: that would pull the whole legacy UI tree
 * into node. The two new skins must map every ScreenId, and their PENDING set
 * must be exactly the ids still mapped to the placeholder.
 */
const SKINS = [
  ["cinematic", cine, cinePending],
  ["glass", glass, glassPending],
] as const;

describe.each(SKINS)("%s skin completeness", (name, screens, pending) => {
  const map = screens as Record<string, unknown>;

  it("maps exactly the contract's ScreenIds, each to a function", () => {
    expect(Object.keys(map).sort()).toEqual([...SCREEN_IDS].sort());
    for (const id of SCREEN_IDS) expect(typeof map[id], id).toBe("function");
  });

  it("PENDING is exactly the set of ids mapped to the placeholder", () => {
    for (const id of pending) expect(SCREEN_IDS).toContain(id);
    const placeholders = SCREEN_IDS.filter((id) => map[id] === Pending);
    expect([...pending].sort()).toEqual([...placeholders].sort());
  });

  it("setup is the server redirect", () => {
    expect(map.setup).toBe(SetupRedirect);
  });

  it("is complete when its release gate says so", () => {
    console.info(`${name} pending: ${pending.size} / ${SCREEN_IDS.length}`);
    if (MUST_BE_COMPLETE[name]) expect([...pending] as ScreenId[]).toEqual([]);
  });
});

// The (app) layout waits for the page to settle the 404 status (see
// ./screen-status): a route file that never does would hang the request.
describe("(app) route files", () => {
  const dir = join(process.cwd(), "src", "app", "(app)");
  const pages = readdirSync(dir, { recursive: true, encoding: "utf8" }).filter((f) => /(^|\/)page\.tsx$/.test(f));

  it.each(pages)("%s settles the screen status", (file) => {
    expect(readFileSync(join(dir, file), "utf8")).toMatch(/\b(renderScreen|markScreenMissing)\(/);
  });
});
