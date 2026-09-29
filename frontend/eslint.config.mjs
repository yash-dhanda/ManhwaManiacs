import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";


// The skin boundary (stack-decision §2.2, glass §15.2 "Lint"): a skin screen
// imports only the shared data layer, its own modules and the neutral files at
// the skins root, never legacy UI, the registry or the other skin. Regexes, not
// gitignore globs: a glob ban on a directory (`@/features/*`, `@/skins`) also
// bans every path under it, which would forbid `@/features/library/hooks`.
function skinBoundary(other) {
  return [
    {
      regex: "^@/(components|features/[^/]+/components)(/.*)?$",
      message: "Legacy UI is off limits in a skin. Build it from this skin's own primitives.",
    },
    {
      regex: "^@/features/[^/]+$",
      message:
        "Feature barrels re-export legacy components. Import the data module by its path, e.g. @/features/library/hooks.",
    },
    {
      regex: "^@/app(/.*)?$",
      message: "Route files are thin. Move shared logic into @/features or @/lib and import it from there.",
    },
    {
      regex: "^@/skins(/server)?$",
      message: "The registry is server-only and pulls in every skin. Import @/skins/types or this skin's own modules.",
    },
    {
      regex: `^(@/skins/|(\\.\\./){1,3})(${other}|legacy)(/.*)?$`,
      message: "Skins never import each other. Share through @/features, @/lib or the generated contract.",
    },
  ];
}

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    files: ["src/skins/cinematic/**"],
    rules: { "no-restricted-imports": ["error", { patterns: skinBoundary("glass") }] },
  },
  {
    files: ["src/skins/glass/**"],
    rules: { "no-restricted-imports": ["error", { patterns: skinBoundary("cinematic") }] },
  },
  {
    // The reader engine is skin-neutral: it never leans on UI the flip deletes.
    files: ["src/features/reader/engine/**"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: [
                "../components",
                "../components/**",
                "@/features/*/components/**",
                "@/components/**",
                "@/skins/**",
              ],
              message:
                "The reader engine is skin-neutral: no legacy components, shared UI or skins. Paint through slots and renderChrome.",
            },
          ],
        },
      ],
    },
  },
  {
    // The skin-neutral placeholder files every new skin shares.
    files: ["src/skins/pending.tsx", "src/skins/pending-shell.tsx", "src/skins/setup-redirect.ts"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              regex: "^@/(components|features|app)(/.*)?$",
              message: "The placeholder screen is skin-neutral: no legacy UI, data or routes.",
            },
            {
              regex: "^(@/skins/|\\.\\.?/)(cinematic|glass|legacy)(/.*)?$",
              message: "The placeholder screen belongs to no skin; it imports none of them.",
            },
          ],
        },
      ],
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
]);

export default eslintConfig;
