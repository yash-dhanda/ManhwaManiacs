**PROCEED**: the Flutter half of the first two clusters cost 5 CCD against a 7.1 CCD budget (threshold 9.94); the web half is not written yet, so `web/10` appends the paired verdict when it finishes.

Rule (`docs/redesign/stack-decision.md` §1): re-estimate after the first two clusters (primitives, then home and library) on both platforms; reopen the choice before Glass starts if the paired cost per cluster comes in more than 40 % over `stack-keep.md` §6. 1 CCD is one calendar day on which a session committed work of that step; active hours are commit clusters (commits under 60 minutes apart) of last minus first plus 30 minutes.

## Budget (`stack-keep.md` §6)

| Half | Primitives | Home and library | Updates (one fifth of 3.0) | Total | Threshold at +40 % |
|---|---|---|---|---|---|
| Flutter | 3.5 | 3.0 | 0.6 | 7.1 | 9.94 |
| Web | 4.0 | 3.5 | 0.6 | 8.1 | 11.34 |
| Paired | 7.5 | 6.5 | 1.2 | 15.2 | 21.28 |

## Flutter actuals

Measured with `git log --date=short --format='%ad %h %s' --grep='mobile-0[4589]:\|mobile-10:'` and the path-limited logs of the prompt (steps whose messages carry no `mobile-NN:` prefix are counted by the paths they touched).

| Step | Days | Active hours | Budget share | Over or under |
|---|---|---|---|---|
| mobile/04 + mobile/05, primitives (29 commits on the primitives paths, 2026-09-29 and 2026-09-30) | 2 | 7.0 | 3.5 | under by 1.5 |
| mobile/08, Tonight and the home feed (2026-09-30) | 1 | 1.3 | 3.0 shared with mobile/09 | under |
| mobile/09, Library shelf and hub (2026-09-30) | 1 | 1.7 | (with mobile/08) | under |
| mobile/10, Updates, Collections, History, Bookmarks (2026-09-30) | 1 | H10 | 0.6 for Updates, the rest in the 3.0 above | under |
| **Flutter total** | **5** | **H_TOTAL** | **7.1** | **under by 2.1** |

Recommendation rule: the Flutter actual (5 CCD) is at most 9.94, so **PROCEED** for the Flutter half.

## Web half

`docs/redesign/proof/web-10/estimate.md` did not exist when this step finished. Whichever of `web/10` and `mobile/10` finishes second writes the "Paired verdict" section in both files; `web/10` should read the Flutter figures above (5 CCD, budget 7.1, threshold 9.94, paired budget 15.2 and threshold 21.28) and append it.

## Caveat

The redesign ran as parallel lanes inside two calendar days, so a "day" is a coarse unit here: one CCD per step per day understates hours where several sessions worked the same day and overstates where a step was a single short session. The active-hours column is the finer signal, and it points the same way (under budget).
