# SideStore fields for release/00 (cinematic DESIGN.md 12.3)

Edit the dict returned around line 1576 of `backend/routes/app_distribution.py` (`"tintColor"` at 1580, app `"iconURL"` at 1599, `"screenshots"` at 1605).

| Field | Value |
|---|---|
| `name` | `ManhwaManiacs` (unchanged) |
| `tintColor` | `#F4D03F` |
| `iconURL` | `{base}/app/media/app-icon.png` (now the new 1024 icon, `mobile/docs/screenshots/app-icon.png`) |
| `subtitle` | `Every source, one shelf.` |
| `localizedDescription` | `Every source. One shelf. Novels, read aloud. Your year in chapters. Read together.` |
| `screenshotURLs` and `screenshots` (emit both keys, same five URLs; SideStore reads either) | `{base}/app/media/front-01-every-source.png`, `front-02-long-scroll.png`, `front-03-novels-read-aloud.png`, `front-04-year-in-chapters.png`, `front-05-read-together.png` |

The screenshots are 1320 x 2868, captured by web/24; they are the five `_SHOWCASE` names backend/07 serves, and release/00 copies web/24's frames under them.
