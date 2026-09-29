// Proof screenshots. Usage (dev stack running):
//   E2E_BASE_URL=http://127.0.0.1:3035 MM_PROOF_USER=.. MM_PROOF_PASSWORD=.. \
//   node scripts/proof.mjs --step web-16 --skin cinematic --routes routes.txt [--grid] [--reduced]
// TODO(web/03): the reviewed harness replaces this stand-in; `signIn` keeps its signature.
import { chromium } from "@playwright/test";
import { mkdirSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

export async function signIn(page, skin = "cinematic") {
  const user = process.env.MM_PROOF_USER;
  const pass = process.env.MM_PROOF_PASSWORD;
  if (!user || !pass) throw new Error("Set MM_PROOF_USER and MM_PROOF_PASSWORD.");
  await page.goto("/login");
  await page.locator("#login-username").fill(user);
  await page.locator("#login-password").fill(pass);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL(/\/(library|profiles)/);
  if (new URL(page.url()).pathname.startsWith("/profiles")) {
    await page.getByRole("button", { name: /^Read as / }).first().click();
    await page.waitForURL(/\/library/);
  }
  await page.context().addCookies([{ name: "mm-skin-debug", value: skin, domain: new URL(page.url()).hostname, path: "/" }]);
}

const GRID = `(() => {
  const g = document.createElement("div");
  g.id = "proof-grid";
  g.style.cssText = "position:fixed;inset:0;z-index:2147483647;pointer-events:none;display:grid;grid-template-columns:repeat(var(--n),1fr);gap:var(--gap);padding:0 var(--m);";
  const w = innerWidth;
  const [n, gap, m] = w >= 1024 ? [12, 24, Math.max(24, (w - 1280) / 2)] : w >= 600 ? [8, 16, 24] : [4, 16, 16];
  g.style.setProperty("--n", n); g.style.setProperty("--gap", gap + "px"); g.style.setProperty("--m", m + "px");
  for (let i = 0; i < n; i++) g.appendChild(Object.assign(document.createElement("i"), { style: "background:rgba(244,208,63,.10)" }));
  document.body.appendChild(g);
})()`;

const slug = (r) => r.replace(/^\//, "").replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "") || "root";

async function main() {
  const arg = (k) => { const i = process.argv.indexOf(`--${k}`); return i > 0 ? process.argv[i + 1] : undefined; };
  const step = arg("step"), skin = arg("skin") ?? "cinematic", routesFile = arg("routes");
  const grid = process.argv.includes("--grid"), reduced = process.argv.includes("--reduced");
  const base = process.env.E2E_BASE_URL ?? "http://127.0.0.1:3010";
  const out = path.resolve(fileURLToPath(import.meta.url), "../../../docs/redesign/proof", step);
  mkdirSync(out, { recursive: true });
  const routes = readFileSync(routesFile, "utf8").split("\n").map((l) => l.trim()).filter(Boolean);
  const sizes = { desktop: { width: 1440, height: 900 }, phone: { width: 390, height: 844 } };
  const browser = await chromium.launch();
  for (const [name, viewport] of Object.entries(sizes)) {
    const ctx = await browser.newContext({ baseURL: base, viewport, hasTouch: name === "phone", isMobile: name === "phone", deviceScaleFactor: name === "phone" ? 2 : 1, reducedMotion: reduced ? "reduce" : "no-preference" });
    const page = await ctx.newPage();
    await signIn(page, skin);
    for (const r of routes) {
      await page.goto(r, { waitUntil: "networkidle" }).catch(() => {});
      await page.waitForTimeout(Number(process.env.PROOF_WAIT ?? 6000));
      const f = `${slug(r)}-${name}`;
      await page.screenshot({ path: `${out}/${f}${reduced ? "-reduced" : ""}.png` });
      if (grid && !reduced) {
        await page.evaluate(GRID);
        await page.screenshot({ path: `${out}/${f}-grid.png` });
        await page.evaluate(() => document.getElementById("proof-grid")?.remove());
      }
    }
    await ctx.close();
  }
  await browser.close();
}
if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) await main();
