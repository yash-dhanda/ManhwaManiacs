import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

/**
 * `extractBuildAssets` reads a saved reader document and names the build files
 * it needs, so a saved chapter can render with the build's own cache gone.
 * Executed from the file that ships, like `policy-contract.test.ts`.
 */
const SOURCE = readFileSync(new URL("../../../public/sw-policy.js", import.meta.url), "utf8");

interface Policy {
  extractBuildAssets(html: string, origin?: string): string[];
  isBuildAssetPath(path: string): boolean;
}

const host: Record<string, unknown> = {};
new Function("self", SOURCE)(host);
const policy = host.MMOfflinePolicy as Policy;

const ORIGIN = "https://manhwa.example";

describe("extractBuildAssets", () => {
  it("reads script, stylesheet and preload references", () => {
    const html =
      '<html><head><link rel="stylesheet" href="/_next/static/css/app.1a2b.css" data-precedence="next"/>' +
      '<link rel="preload" as="font" href="/_next/static/media/inter.9f.woff2" crossorigin=""/>' +
      '<script src="/_next/static/chunks/webpack-aa.js" async=""></script>' +
      '<script src="/_next/static/chunks/main-app-bb.js" async=""></script></head></html>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual([
      "/_next/static/css/app.1a2b.css",
      "/_next/static/media/inter.9f.woff2",
      "/_next/static/chunks/webpack-aa.js",
      "/_next/static/chunks/main-app-bb.js",
    ]);
  });

  it("finds the chunks the flight data names without the prefix", () => {
    const html =
      '<script>self.__next_f.push([1,"5:I[\\"(app-pages-browser)/./node_modules/x.js\\",[\\"7177\\",\\"static/chunks/app/reader/page-cc.js\\",' +
      '\\"static/css/reader.dd.css\\"],\\"default\\"]\\n"])</script>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual([
      "/_next/static/chunks/app/reader/page-cc.js",
      "/_next/static/css/reader.dd.css",
    ]);
  });

  it("finds unescaped quotes too, and prefixed paths inside flight strings", () => {
    const html =
      "<script>var a=['static/chunks/x.js'];self.__next_f.push([1,\"HL[\\\"/_next/static/css/y.css\\\",\\\"style\\\"]\"])</script>";
    expect(policy.extractBuildAssets(html, ORIGIN).sort()).toEqual([
      "/_next/static/chunks/x.js",
      "/_next/static/css/y.css",
    ]);
  });

  it("names a file once, however many ways the page refers to it", () => {
    const html =
      '<script src="/_next/static/chunks/a.js"></script><script src="/_next/static/chunks/a.js?dpl=1"></script>' +
      '<script>self.__next_f.push([1,"[\\"static/chunks/a.js\\"]"])</script>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual(["/_next/static/chunks/a.js"]);
  });

  it("drops the query, which only varies how a file was asked for", () => {
    const html = '<script src="/_next/static/chunks/a.js?dpl=abc123"></script>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual(["/_next/static/chunks/a.js"]);
  });

  it("keeps same-origin absolute URLs and drops every other origin", () => {
    const html =
      `<script src="${ORIGIN}/_next/static/chunks/mine.js"></script>` +
      '<script src="https://cdn.other.example/_next/static/chunks/theirs.js"></script>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual(["/_next/static/chunks/mine.js"]);
  });

  it("ignores things that merely look similar", () => {
    const html =
      '<a href="/library">x</a><img src="/icons/icon-192.png"/>' +
      '<script>var s="the static/ folder";var t="/static/chunks/nope.js";</script>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual([]);
  });

  it("keeps percent-encoded route segments as the browser requests them", () => {
    const html = '<script src="/_next/static/chunks/app/reader/%5Bsource%5D/page-ee.js"></script>';
    expect(policy.extractBuildAssets(html, ORIGIN)).toEqual([
      "/_next/static/chunks/app/reader/%5Bsource%5D/page-ee.js",
    ]);
  });

  it("is safe on anything that is not a document", () => {
    expect(policy.extractBuildAssets("", ORIGIN)).toEqual([]);
    expect(policy.extractBuildAssets(null as unknown as string, ORIGIN)).toEqual([]);
  });
});

describe("isBuildAssetPath", () => {
  it("is the build's own immutable prefix and nothing wider", () => {
    expect(policy.isBuildAssetPath("/_next/static/chunks/a.js")).toBe(true);
    expect(policy.isBuildAssetPath("/_next/image?url=x")).toBe(false);
    expect(policy.isBuildAssetPath("/icons/icon-192.png")).toBe(false);
  });
});
