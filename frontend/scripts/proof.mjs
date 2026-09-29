// Headless Playwright screenshot harness for the redesign's visual proof.
// # backend: see backend/scripts/README-dev-stack.md (uvicorn 127.0.0.1:8010, dev SQLite, never production data)
// # frontend: free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010
// # then:     MM_PROOF_USER=… MM_PROOF_PASSWORD=… node scripts/proof.mjs --step web-08 --skin cinematic --routes /,/library
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(HERE, "..", "..");

const USAGE = `Usage: node scripts/proof.mjs --step <name> --routes <list|file> [flags]

| Flag | Meaning | Default |
|---|---|---|
| --step <name> | Output folder docs/redesign/proof/<name>/ (from the repo root) | required |
| --routes <list or file> | Comma-separated routes, or a .txt file, one route per line (# comments) | required |
| --skin <legacy|cinematic|glass> | Sets the mm-skin-debug cookie before the first navigation | no cookie |
| --base <url> | Dev server | http://127.0.0.1:3010 |
| --session <name> | Signed-in storage state at $TMPDIR/mm-proof-<name>.json, reused while GET /api/auth/me answers 200 | step name, "/" -> "-" |
| --profile <name> | Profile to activate | first profile in GET /api/profiles |
| --no-auth | Skip sign-in (for /login, /register) | off |
| --dpr3 | Also capture 440x956 at deviceScaleFactor 3 | off |
| --grid | Also press Control+Shift+KeyG per shot and save a -grid copy | off |
| --reduced | reducedMotion "reduce"; files get -reduced | off |
| --viewport-only | Viewport screenshots instead of full page | full page |
| --settle <ms> | Wait after networkidle and fonts.ready | 1500 |
| --help | Print this usage | |

Credentials: MM_PROOF_USER and MM_PROOF_PASSWORD only.
Files: <skin|default>-<slug>-<w>x<h>[@3x][-reduced][-grid].png
`;

const BOOL = new Set(["no-auth", "dpr3", "grid", "reduced", "viewport-only", "help"]);

export function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) throw new Error(`Unexpected argument: ${a}`);
    const k = a.slice(2);
    if (BOOL.has(k)) out[k] = true;
    else out[k] = argv[++i];
  }
  return out;
}

export function slugify(route) {
  if (route === "/") return "home";
  return route.replace(/^\/+/, "").replace(/[/?=&%]/g, "-").replace(/-+/g, "-");
}

export function proofFileName({ skin, route, w, h, dpr3, reduced, grid }) {
  return `${skin || "default"}-${slugify(route)}-${w}x${h}${dpr3 ? "@3x" : ""}${reduced ? "-reduced" : ""}${grid ? "-grid" : ""}.png`;
}

function readRoutes(spec) {
  if (spec.endsWith(".txt") && fs.existsSync(spec)) {
    return fs
      .readFileSync(spec, "utf8")
      .split("\n")
      .map((l) => l.replace(/#.*/, "").trim())
      .filter(Boolean);
  }
  return spec.split(",").map((r) => r.trim()).filter(Boolean);
}

/** Sign in through the context's request API and seed the active profile before any page script runs. */
export async function signIn(context, { base, user, password, profile }) {
  const login = await context.request.post(`${base}/api/auth/login`, {
    data: { username: user, password },
  });
  if (!login.ok()) throw new Error(`Sign-in failed: HTTP ${login.status()}`);
  const me = await (await context.request.get(`${base}/api/auth/me`)).json();
  const profiles = await (await context.request.get(`${base}/api/profiles`)).json();
  const list = Array.isArray(profiles) ? profiles : (profiles.items ?? []);
  const chosen = (profile && list.find((p) => p.name === profile)) || list[0];
  if (!chosen) throw new Error("No profile to activate");
  const active = { id: chosen.id, name: chosen.name, avatar_key: chosen.avatar_key ?? null, mood: chosen.mood };
  await seedProfile(context, active, me.id);
  return { userId: me.id, profile: active };
}

async function seedProfile(context, activeProfile, ownerUserId) {
  // Matches features/profiles/store.ts persist options (version 0).
  const value = JSON.stringify({ state: { activeProfile, ownerUserId }, version: 0 });
  await context.addInitScript((v) => {
    try { localStorage.setItem("mm.active-profile", v); } catch {}
  }, value);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { console.log(USAGE); return 0; }
  if (!args.step || !args.routes) { console.error(USAGE); return 2; }
  const user = process.env.MM_PROOF_USER;
  const password = process.env.MM_PROOF_PASSWORD;
  if (!args["no-auth"] && (!user || !password)) {
    console.error("Set MM_PROOF_USER and MM_PROOF_PASSWORD (the demo account in backend/scripts/README-dev-stack.md)");
    return 2;
  }
  let chromium;
  try {
    ({ chromium } = await import("playwright"));
  } catch {
    console.error("playwright is not installed: npm install, then npx playwright install chromium");
    return 2;
  }
  const base = (args.base ?? "http://127.0.0.1:3010").replace(/\/$/, "");
  const routes = readRoutes(args.routes);
  const outDir = path.join(REPO_ROOT, "docs", "redesign", "proof", args.step);
  fs.mkdirSync(outDir, { recursive: true });
  const session = (args.session ?? args.step).replace(/\//g, "-");
  const statePath = path.join(process.env.TMPDIR || os.tmpdir(), `mm-proof-${session}.json`);
  const settle = Number(args.settle ?? 1500);

  let browser;
  try {
    browser = await chromium.launch();
  } catch (e) {
    if (/Executable doesn't exist|playwright install/i.test(String(e))) {
      console.error("Chromium is missing: npx playwright install chromium");
      return 2;
    }
    throw e;
  }

  const viewports = [{ w: 1440, h: 900, dpr: 1 }, { w: 390, h: 844, dpr: 1 }];
  if (args.dpr3) viewports.push({ w: 440, h: 956, dpr: 3 });
  const skinCookie = args.skin
    ? [{ name: "mm-skin-debug", value: args.skin, url: base }]
    : [];
  let failed = false;

  try {
    for (const vp of viewports) {
      const reuse = !args["no-auth"] && fs.existsSync(statePath);
      const context = await browser.newContext({
        viewport: { width: vp.w, height: vp.h },
        deviceScaleFactor: vp.dpr,
        reducedMotion: args.reduced ? "reduce" : "no-preference",
        ...(reuse ? { storageState: statePath } : {}),
      });
      if (skinCookie.length) await context.addCookies(skinCookie);
      if (!args["no-auth"]) {
        let ok = false;
        if (reuse) ok = (await context.request.get(`${base}/api/auth/me`)).status() === 200;
        if (ok) {
          // Storage state carries localStorage of the origin; re-seed to be safe.
          const me = await (await context.request.get(`${base}/api/auth/me`)).json();
          const profiles = await (await context.request.get(`${base}/api/profiles`)).json();
          const list = Array.isArray(profiles) ? profiles : (profiles.items ?? []);
          const chosen = (args.profile && list.find((p) => p.name === args.profile)) || list[0];
          await seedProfile(context, { id: chosen.id, name: chosen.name, avatar_key: chosen.avatar_key ?? null, mood: chosen.mood }, me.id);
        } else {
          await signIn(context, { base, user, password, profile: args.profile });
        }
        await context.storageState({ path: statePath });
      }
      const page = await context.newPage();
      for (const route of routes) {
        let status = 0;
        try {
          const res = await page.goto(base + route, { waitUntil: "load" });
          status = res ? res.status() : 0;
          await page.waitForLoadState("networkidle").catch(() => {});
          await page.evaluate(() => document.fonts.ready);
          await page.waitForTimeout(settle);
        } catch (e) {
          console.error(`${route} ${vp.w}x${vp.h}: navigation error: ${e.message}`);
          failed = true;
          continue;
        }
        console.log(`${status} ${route} ${vp.w}x${vp.h}`);
        if (status >= 500) failed = true;
        const name = (grid) => proofFileName({ skin: args.skin, route, w: vp.w, h: vp.h, dpr3: vp.dpr === 3, reduced: args.reduced, grid });
        const opts = { fullPage: !args["viewport-only"] };
        await page.screenshot({ path: path.join(outDir, name(false)), ...opts });
        if (args.grid) {
          await page.keyboard.press("Control+Shift+KeyG");
          await page.waitForTimeout(300);
          await page.screenshot({ path: path.join(outDir, name(true)), ...opts });
          await page.keyboard.press("Control+Shift+KeyG");
        }
      }
      await context.close();
    }
  } finally {
    await browser.close();
  }
  return failed ? 1 : 0;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  main().then((c) => process.exit(c), (e) => { console.error(e); process.exit(1); });
}
