# Redesign baseline (2026-09-28)

Health check taken before the Cinematic + Glass redesign, on the VPS dev checkout.
Nothing was changed, committed, or pushed.

- Branch: `feat/vps-slim-source-native` at `130d6fd`, working tree clean
- Toolchain: Node v22.22.1, Next.js 16.2.9 (Turbopack), Flutter 3.44.6

## Frontend (`frontend/`, v2.6.1)

| Check | Result | Errors | Warnings |
|---|---|---|---|
| `npm run lint` (eslint) | pass, exit 0 | 0 | 0 |
| `npm run build` (next build) | pass, exit 0, compiled in 9.6s | 0 | 0 |

The only non-route output from the build is the Next.js anonymous telemetry notice
and the `proxyTimeout: 120000` experiment line, which are both informational.

## Mobile (`mobile/`)

| Check | Result |
|---|---|
| `flutter analyze` | No issues found (29.7s) |
| `flutter test` | All 2012 tests passed, 0 failed, 0 skipped (4m14s) |

`pub get` reports 72 packages with newer versions that the current constraints do not
allow. This is informational only, not a failure.

## GitHub push key

`ssh -T git@github.com` returned
`Hi yash-dhanda/ManhwaManiacs! You've successfully authenticated, but GitHub does not provide shell access.`

Authentication works. The key is a **deploy key scoped to `yash-dhanda/ManhwaManiacs`**,
not an account key, so it can reach only this repository. SSH alone cannot show
whether the deploy key has write access. The first real push will prove it. Push
remote is `git@github.com:yash-dhanda/ManhwaManiacs.git`; fetch uses HTTPS.

## Memory (shared with production)

| Point | Available MB |
|---|---|
| Before lint | 5027 |
| Before `next build` | 5013 |
| Lowest during `next build` | 3882 |
| Before `flutter analyze` | 5016 |
| Before `flutter test` | 5055 |
| Lowest during `flutter test` | 3443 |

Total RAM is 7746 MB and swap already had 778 MB in use. Available memory never
dropped near the 1 GB stop limit. A watchdog polled `free -m` every 2s during the build
and the tests, ready to kill them under 1024 MB. It did not trigger.

## Notes

- `docs/redesign/` did not exist before this file. The design contract named in the
  box's CLAUDE.md (`cinematic/DESIGN.md`, `glass/DESIGN.md`, `prompts/`) is not in the
  repo yet.
