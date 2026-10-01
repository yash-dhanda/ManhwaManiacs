# mobile/40 inventory map

Every inventory item of `docs/redesign/inventory/mobile.md` this step owns, mapped to its Glass counterpart (scope item of
`prompts/mobile/40-glass-you-about-admin-status.md`) or to the step and file that built it. Paths are under `mobile/lib/skins/glass/`.

## S22 More (tab 4) -> You hub (`screens/you/`)

| # | Item | Glass |
|---|---|---|
| 1 | AppBar "More" + ContentModeChip | B (large title "You", `GlassScaffold`) + B1 `GlassContentModeSwitch` in `profile_block.dart` (novels on) |
| 2 | Section headers | B5 grouped-list headers Library, Settings, Administration, About (`you_lists.dart`) |
| 3 | Updates + unread badge | B5 Library "Updates" with `GlassBadge.count` ("Updates, 3 new") |
| 4 | Collections | B5 Library "Collections" (capability `collections`) |
| 5 | Switch profile | B1 "Switch profile" (`profile_block.dart`) |
| 6 | Reading History | B5 Library "History" |
| 7 | Bookmarks | B5 Library "Bookmarks" (capability `bookmarks`) |
| 8 | Statistics | B2 Reading card -> `Routes.numbers` (`reading_card.dart`) |
| 9 | Recommendations | B5 Library "For you" |
| 10 | Settings | B5 Settings group (every section of `mobile/39`'s registry) |
| 11 | Storage | B5 Settings "Storage" -> Downloads -> Storage; F `/settings/storage` redirect (`router.dart`) |
| 12 | Dialogue Search (OCR + manga) | B5 Library "Dialogue search" (manga mode, `ocr` capability, `ocrFeatureVisibleProvider`) |
| 13 | Backup & Restore | B5 Settings "Backup" (admin) -> G |
| 14 | Update-available banner | B5 About update row "Update available · 3.5.1" -> `?sheet=app-update` (sheet built by mobile/29, `shell/app_update_sheet.dart`) |
| 15 | Dialog "Install now" | built by mobile/29 (`shell/app_update_sheet.dart`, the install steps) |
| 16 | Snackbar "Could not open" | built by mobile/29 (`shell/app_update_sheet.dart`, toast "Couldn't open {site}") |
| 17 | What's New | B5 About "What's New" -> `?sheet=whats-new` (mobile/29 `shell/whats_new_sheet.dart`) |
| 18 | App info tile | B5 About version row "ManhwaManiacs 3.5.0 (57)" |

## S28 Settings, items 16 to 27 (Server, About, Debug tabs)

| # | Item | Glass |
|---|---|---|
| 16 | Server connection heading | H (`screens/settings/server_section.dart`, the Settings section "Server") |
| 17 | TextField "API base URL" | H1 `GlassTextField(kind: url)` |
| 18 | "Save URL" + snackbar / validation | H1, H2 Save, the Setup lines with the shake, toast "Server URL saved and applied" |
| 19 | "Reset to default" | H1, H2 toast "Reset to the default address" |
| 20 | Loading / error | H3 field skeleton, "Couldn't read the saved address" + Try again |
| 21 | App card | built by mobile/39 (`screens/settings/about_section.dart`); B5 version row |
| 22 | Updates card (Android) | built by mobile/39 (`about_section.dart`); B5 You update row |
| 23 | Updates card (iOS SideStore) | built by mobile/39 (`about_section.dart`); B5 "Managed by SideStore" |
| 24 | "Open source licenses" (stock LicensePage) | I2 the Glass licences sheet (`screens/settings/licenses_sheet.dart`, `?sheet=licenses`) |
| 25 | Diagnostics link card | I1 Settings "Diagnostics" (`screens/settings/diagnostics_section.dart`) |
| 26 | Reset reader settings | built by mobile/39 (`screens/settings/reader_defaults_section.dart`, About row "Reset reader settings") |
| 27 | Dialog "Reset reader settings?" | built by mobile/39 (`reader_defaults_section.dart`) |

## S29 Password & security -> D (`screens/settings/security_section.dart`)

| # | Item | Glass |
|---|---|---|
| 1 | AppBar | D, the section page title "Security" |
| 2 | Change password card | D1 (fields with eyes, every client line, `invalid_credentials`, `weak_password`, `rate_limited` countdown, success toast) |
| 3 | Sessions card | D2 (refresh icon with the spinner, device glyphs, "This device", rows, skeletons, error, "No active sessions") |
| 4 | Dialog "Sign out this device?" | D2 swipe, ⋯ and custom action -> `confirmAlert` |
| 5 | Sign out everywhere card | D3 `danger` notice + `HoldToConfirm` |
| 6 | Dialog "Sign out everywhere?" | D3 the alert with the acknowledgement switch |

## S30 Members -> E (`screens/settings/members_section.dart`)

| # | Item | Glass |
|---|---|---|
| 1 | AppBar | E, the section page title "Members" |
| 2 | Error box | E6 inline error + Try again; refused actions show `cannot_manage_self` / `forbidden` (`copy/errors.dart`) |
| 3 | Skeleton / empty | E6 3 row skeletons; "Only your account so far" |
| 4 | Member card | E2 phone rows (badges Admin · You · Deactivated, the subtitle, swipe and ⋯ actions); E3 tablet table |
| 5 | Dialog "Delete @user?" | E4 the in-alert `HoldToConfirm` with the visible fallback |
| 6 | Pull to refresh, ordering | E5 footer Refresh + pull to refresh; `sortMembers` |

## S32 Storage

| # | Item | Glass |
|---|---|---|
| 1 | AppBar | F: `/settings/storage` redirects to `/downloads?tab=storage` (the Storage tab of mobile/32, built in parallel; `/downloads` is still on the pending body in this worktree) |
| 2 | Downloads storage card | built by mobile/32 (Downloads -> Storage tab) |
| 3 | Image cache card | built by mobile/32 (Downloads -> Storage tab, §8.22 cache cards) |
| 4 | Metadata cache card | built by mobile/32 (Downloads -> Storage tab) |

## S33 Backup & Restore -> G (`screens/settings/backup_section.dart`)

| # | Item | Glass |
|---|---|---|
| 1 | AppBar | G, the section page title "Backup" |
| 2 | Pending-restore banner | G2 `warning` notice + "Cancel staged restore" |
| 3 | Export card | G3 the include-caches switch, "Preparing…", the liquid progress, the share sheet, "Saved …" |
| 4 | Import card | G4 the `danger`-barred Restore section, "Choose backup file", the file line and validation |
| 5 | Dialog "Restore this backup?" | G4 the alert with the four bullets and the RESTORE phrase field |
| 6 | Dialog "Restore staged" | G4 "Restore staged. Restart the server to finish." |
| 7 | Snackbars | G3 inline `danger` line; G4 inline file errors |

## S34 Diagnostics -> I1 (`screens/settings/diagnostics_section.dart`)

| # | Item | Glass |
|---|---|---|
| 1 | AppBar | I1, the section page title "Diagnostics" |
| 2 | Section headings | I1 grouped-list headers Rendering performance, Display, Device, Image cache, Glass, Development |
| 3 | Performance card | I1 FPS (`iris400`), Jank (`jankTone`), Worst, Average, CPU build, GPU raster, Samples, the two placeholders |
| 4 | Display card | I1 Android refresh rate, capability, resolution; iOS line |
| 5 | Device card | I1 Platform, CPU cores, Screen, App version, Build mode |
| 6 | Image cache card | I1 Live images, Cached, Memory |

## G8, G9, G12

| Item | Glass |
|---|---|
| G8 What's New | built by mobile/29 (`shell/whats_new_sheet.dart`, `?sheet=whats-new`); opened from B5 About |
| G9 App update | B5 You update row (each `appUpdateProvider` state; iOS SideStore); the sheet is mobile/29's `shell/app_update_sheet.dart` |
| G12 Haptics vocabulary | the §5.2 events this step fires through `GlassHaptics`: `toggle.on/off` (switches), `detent.tick/magnet/limit` (interval slider), `hold.ramp/done` (Sign out everywhere, Delete), `delete.confirm`, `refresh.arm/done` (pull to refresh), `error` (shakes), `success` (toasts) |
