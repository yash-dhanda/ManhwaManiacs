# mobile/40 plan

Lane M40, worktree `wt/M40` on `redesign/M40`. One task per scope item; pure modules test-first. Order: A, then the primitives
additions, then the settings sections (C to I), the You hub (B), System status (J), the cross-cutting checks (K), captures.

| Task | Scope | Files | Test |
|---|---|---|---|
| 1 | A1 daily goal | `features/library/utils/daily_goal.dart`, `features/library/providers/daily_goal_provider.dart`, `profile_scope.dart` (invalidators) | `test/features/library/daily_goal_test.dart` |
| 2 | A2 backup export option | `features/settings/services/backup_download.dart` (`include_cache` only when true; share origin) | `test/features/settings/backup_download_test.dart` |
| 3 | A3 You cards | `features/library/utils/you_cards.dart` | `test/features/library/you_cards_test.dart` |
| 4 | A4 licences | `tool/licenses/build_licences.dart`, `features/settings/utils/{licenses,package_versions.g}.dart`, `assets/licenses/{CC0-1.0.txt,art_and_sounds.json}`, `main.dart` | `test/features/settings/licenses_test.dart` |
| 5 | A5 jank tone | `core/diagnostics/jank_tone.dart` (moved out of `diagnostics_snapshot.dart`, re-exported) | `test/core/diagnostics/jank_tone_test.dart` |
| 6 | D1 password checks (shared) | `features/auth/utils/password_change_check.dart` | `test/features/auth/password_change_check_test.dart` |
| 7 | primitives | `slider.dart` + `slider_math.dart` (`magnet`), `cards/health_bead.dart` (`pulseKey`, `flickerKey`, the painted sphere), `unsaved_changes_bar.dart`; gallery entries | `slider_math_test.dart` |
| 8 | C Notifications | `screens/settings/notifications_section.dart` | `test/skins/glass/settings/mobile_40_sections_test.dart` |
| 9 | D Security | `screens/settings/security_section.dart` | same |
| 10 | E Members | `screens/settings/members_section.dart` | same |
| 11 | F Storage redirect, Administration list | `router.dart`, `screens/settings/admin_section.dart` | same |
| 12 | G Backup | `screens/settings/backup_section.dart` | same |
| 13 | H Server | `screens/settings/server_section.dart` | same |
| 14 | I1 Diagnostics; dev index rows moved | `screens/settings/diagnostics_section.dart`, `dev/glass_dev_index.dart` | same, `dev_pages_test.dart` |
| 15 | I2 Licences sheet | `screens/settings/licenses_sheet.dart`, `shell/overlays.dart` registration | same |
| 16 | registry | `settings_sections.dart` (`sectionsBuiltLater` empty), `settings_screen.dart` bodies | `settings_pure_test.dart`, `settings_screen_test.dart` |
| 17 | B You hub | `screens/you/{you_screen,profile_block,reading_card,wrapped_card,circle_card,you_lists,orb_lift,you_glyphs}.dart`, `router.dart` | `test/skins/glass/you/you_screen_test.dart` |
| 18 | J System status | `screens/status/{status_screen,summary_banner,backend_card,checker_card,recent_checks,source_health}.dart`, `router.dart` | `test/skins/glass/status/status_screen_test.dart` |
| 19 | K hit targets, reduced motion, solid, contrast | — | `test/skins/glass/you/mobile_40_a11y_test.dart` |
| 20 | captures and proof | `test/screenshots/glass/mobile_40_you_admin_status_shots_test.dart`, this folder | the harness run |

Shared fixtures for the widget tests and captures: `test/skins/glass/you/m40_rig.dart`.
