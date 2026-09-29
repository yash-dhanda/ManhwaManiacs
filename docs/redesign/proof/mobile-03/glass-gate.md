# Glass device gate: owner checklist and decision

Commit under test: fill in `git rev-parse --short HEAD` of the integrated build (the `build-ios` run for that commit publishes the IPA).

## Setup

- iPhone: update through SideStore to the build `ios-build.yml` published for that commit.
- Android flagship: the signed APK you build. Settings, Diagnostics: turn "Use the highest refresh rate everywhere" on.
- Open Settings, Debug, Diagnostics, Edition (debug), "Glass device gate".

## Runs

Each run is one Auto-fling (10 s). Afterwards write down FPS, JANK and WORST from the readout pill.

| Run | iPhone FPS / JANK / WORST | Android FPS / JANK / WORST |
|---|---|---|
| LIQUID, sheet closed | | |
| LIQUID, sheet at medium | | |
| FROST, sheet closed | | |
| FROST, sheet at medium | | |

## Visual checks

- The rim is visible over black and over white posters.
- The checkerboard band bends under LIQUID glass.
- No white flash when the page opens.
- No flicker when the bar minimises on scroll down and restores on scroll up.
- The sheet snaps between medium and large with no visible dropped frame.
- Tab reaches LIQUID/FROST, Auto-fling and Sheet with a visible focus ring (hardware keyboard, tablet).

## Pass rule

On the iPhone, LIQUID passes when both LIQUID runs show FPS >= 115, JANK < 5 % and WORST < 16.7 ms with no visual fault. Otherwise the decision is FROST (flagship-only: no third option). Android results are recorded for glass 15.7 but do not decide.

Known difference: the FROST twin has no saturate 1.8 (Flutter has no backdrop colour filter), so compare colour by eye only.

Decision: awaiting the owner's device pass (mobile/25 must not start before this line reads LIQUID or FROST)
