import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

/*
 * Legacy's `@theme` and the generated shared theme both define some keys.
 * Legacy wins in Tailwind, so each new skin must re-point every such key at
 * its own `--mm-…` token in legacy-bridge.css. This test computes the overlap
 * from the files, so a new generated key cannot slip past the bridge.
 */
const SRC = join(process.cwd(), "src");
const read = (...p: string[]) => readFileSync(join(SRC, ...p), "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
const globals = readFileSync(join(SRC, "app", "globals.css"), "utf8");
const bridge = read("skins", "legacy-bridge.css");
const NEW_SKINS = ["cinematic", "glass"] as const;

/** Bodies of every `@theme …{ … }` block whose prelude is exactly `prelude`. */
function blocks(css: string, prelude: RegExp): string[] {
  return [...css.matchAll(new RegExp(`${prelude.source}\\s*\\{([\\s\\S]*?)\\n\\}`, "g"))].map((m) => m[1]);
}

const legacyKeys = new Set(
  blocks(read("app", "globals.css"), /@theme/).flatMap((b) => [...b.matchAll(/(--[\w-]+)\s*:/g)].map((m) => m[1])),
);
const generated = new Map(
  blocks(read("skins", "theme.generated.css"), /@theme inline/).flatMap((b) =>
    [...b.matchAll(/(--[\w-]+)\s*:\s*var\((--mm-[\w-]+)/g)].map((m) => [m[1], m[2]] as const),
  ),
);
const overlap = [...generated].filter(([key]) => legacyKeys.has(key));

const tokens = Object.fromEntries(
  NEW_SKINS.map((skin) => {
    const file = join(SRC, "skins", skin, "tokens.generated.css");
    return [skin, existsSync(file) ? readFileSync(file, "utf8") : null];
  }),
) as Record<(typeof NEW_SKINS)[number], string | null>;

/**
 * The skin that owns a `--mm-…` target: the one whose tokens declare it, else
 * the one whose tokens use it (fonts are declared by next/font, web/01). A
 * target no generated tokens file mentions belongs to Glass while Glass's
 * tokens are not generated yet (shared/01).
 */
function owner(target: string): string {
  const esc = target.replace(/[-]/g, "\\-");
  const declares = NEW_SKINS.filter((s) => tokens[s] && new RegExp(`${esc}\\s*:`).test(tokens[s]!));
  if (declares.length) return declares[0];
  const uses = NEW_SKINS.filter((s) => tokens[s] && new RegExp(`var\\(${esc}[,)]`).test(tokens[s]!));
  if (uses.length) return uses[0];
  expect(tokens.glass, `no skin's tokens mention ${target}`).toBeNull();
  return "glass";
}

function bridgeRule(skin: string): string {
  const m = bridge.match(new RegExp(`html\\[data-skin="${skin}"\\]\\s*\\{([^}]*)\\}`));
  return m ? m[1] : "";
}

describe("legacy bridge", () => {
  it("finds the keys both themes define", () => {
    expect(overlap.length).toBeGreaterThan(0);
    expect(overlap.map(([k]) => k)).toContain("--font-display");
  });

  it.each(overlap)("%s is re-pointed at %s for its skin", (key, target) => {
    const skin = owner(target);
    const decl = new RegExp(`${key.replace(/-/g, "\\-")}\\s*:\\s*var\\(${target.replace(/-/g, "\\-")}\\)\\s*;`);
    expect(bridgeRule(skin), `html[data-skin="${skin}"] must declare ${key}: var(${target})`).toMatch(decl);
  });

  it("imports the generated theme before legacy's @theme block", () => {
    const generatedImport = globals.indexOf('@import "../skins/theme.generated.css";');
    const legacyTheme = globals.search(/^@theme \{/m);
    expect(generatedImport).toBeGreaterThan(-1);
    expect(legacyTheme).toBeGreaterThan(-1);
    expect(generatedImport).toBeLessThan(legacyTheme);
  });
});
