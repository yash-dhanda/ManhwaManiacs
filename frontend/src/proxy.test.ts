import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { legacyServes, matchRoute } from "./proxy";

// Every (app) route file, with a URL that lands on it: the proxy's table must agree with the files.
const dir = join(process.cwd(), "src", "app", "(app)");
const files = readdirSync(dir, { recursive: true, encoding: "utf8" }).filter((f) => /(^|\/)page\.tsx$/.test(f));
const cases = files.map((file) => {
  const url = "/" + file.replace(/\/?page\.tsx$/, "").replace(/\[\.\.\.\w+\]/, "a/b").replace(/\[\w+\]/g, "x1");
  const id = readFileSync(join(dir, file), "utf8").match(/renderScreen\("(\w+)"/)?.[1];
  return [file, url, id] as const;
});

describe("proxy route table", () => {
  it.each(cases)("%s (%s) matches its screen", (_file, url, id) => {
    expect(matchRoute(url)?.id).toBe(id);
  });
});

describe("legacyServes", () => {
  it.each(["/setup", "/welcome", "/circle", "/circle/p1", "/settings/profile", "/no-such-page", "/library/a/b", "/profiles/new"])(
    "%s is a 404",
    (url) => expect(legacyServes(url)).toBe(false),
  );
  it.each(["/login", "/library", "/library/browse", "/library/f1", "/settings", "/reader/s/k/1/2", "/admin/status", "/more"])(
    "%s is served",
    (url) => expect(legacyServes(url)).toBe(true),
  );
});
