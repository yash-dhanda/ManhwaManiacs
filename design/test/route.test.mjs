import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { buildRoute, makeRoutes } from "../lib/route.mjs";

const contract = JSON.parse(readFileSync(new URL("../contract.json", import.meta.url), "utf8"));
const R = makeRoutes(contract.screens);

test("path segments are percent-encoded", () => {
  assert.equal(R.feature("mangadex", "a/b c%"), "/sources/mangadex/series/a%2Fb%20c%25");
  assert.equal(R.reader("s1", "x!y", "é"), "/reader/s1/x!y/%C3%A9");
});

test("query strings follow URLSearchParams in insertion order", () => {
  assert.equal(R.recap("s1", "k", { to: "12" }), "/recap/s1/k?to=12");
  assert.equal(R.library({ q: "solo leveling", fav: 1 }), "/library?q=solo+leveling&fav=1");
  assert.equal(R.discover({ q: "a~b*c é" }), "/search?q=a%7Eb*c+%C3%A9");
});

test("settings takes an optional section", () => {
  assert.equal(R.settings(), "/settings");
  assert.equal(R.settings("reading-manga"), "/settings/reading-manga");
});

test("undefined and null query values are skipped", () => {
  assert.equal(buildRoute("/library", [], { q: undefined, fav: null, sort: "az" }), "/library?sort=az");
  assert.equal(buildRoute("/library", [], {}), "/library");
});
