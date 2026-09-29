# Web 07 · Cinematic login, register, profiles and the 18+ gate

## Goal

Build the first Cinematic screens on the web: the splash as the session-resolving state (`AuthPending`), **Login** (the magazine-cover split), **Register** in its four variants, the profile picker **"Who's reading tonight?"** with the Iris into the shell, the **profile form** (new and edit) and **Manage profiles**, and the 18+ gate end to end: the certificate dialog from the profile form and from Settings → Content (the Settings screen mounts the same component in web/18), the stamp and `gate.confirm` haptic, invalidation of every mature-gated query, turning the gate off with its toast, the rating card, "absence, never a lock", and `features/offline/mature-filter.ts` so that every copy stored on this device follows the gate, with queued downloads of a hidden series pausing silently. Every element and state of web inventory §3 (L1–L9, RG1–RG5 and the register form) and §4 (P1–P8, PF1–PF8, PM1–PM8) is covered in the Cinematic design. At the end, the `ScreenId`s `login`, `register`, `profiles`, `profileNew`, `profileEdit` and `profilesManage` leave the Cinematic `PENDING` set.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §8.0.1 (Bare and Takeover frames), §8.0.3 (routes `login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage`, `onboarding`), §8.0.4 (Dip, Iris, Page), §8.0.7 (**`glass_available` is false**: the profile form hides the Edition row, the picker's step 4 cannot trigger), §8.0.9 (tablet rows for Login, Register, picker, profile form and Manage profiles).
   - §8.2 splash and pre-roll (outcomes), §8.3 Login, §8.4 Register, §8.5 profile picker (layouts, the Iris steps 1–4, profile-scope recovery, manage mode, keys, "never auto-skipped", states), §8.6 profile form and Manage profiles.
   - §7.24 the 18+ gate (mark, certificate dialog, confirm moment, turning off, **rating card**, per-series override, absence never a lock, **local copies follow the gate too**), §7.25 avatars (the twelve presets), §7.10 destructive confirms (profile delete, sign out), §7.21 switch states for server-backed switches, §2.1.6 mood grades and the form's 10 × 10 squares.
   - §5 events `tap.primary`, `select`, `toggle.on`/`toggle.off`, `profile.select`, `gate.confirm`, `delete.confirm`, `longpress.open`, `error`; §6 cues (`gate.confirm` → `impress`).
   - §10.1 (cover lines revealed by letters), §10.2 (typed headlines; `h1` for Login, Register and the picker question).
   - §12.2 wordmark (one-line masthead lockup with the Oxford rule, its first 12 % in `spot`), §12.5 voice (short, dry, full stops, no exclamation marks).
   - §14.4–§14.6, §14.11, §15.5 (profile columns), §15.7 (the **18+ on-device checklist**).
2. `docs/redesign/inventory/web.md` §3 (3.1 Login L1–L9, 3.2 Register RG1–RG5 and the register form's nine elements), §4 (4.1 picker P1–P8, 4.2 profile form PF1–PF8, 4.3 Manage profiles PM1–PM8), §6.5 (SG25–SG28, the Settings → Content switch this replaces), §18.1 A1–A6, §18.2 A10–A16, §18.3 A20–A21, §18.8 (downloads live in the service worker), §19.1 K1–K5, K16, §19.4 K48, §21 items 4 and 8.
3. `docs/redesign/inventory/capabilities.md` §1 ("the 18+ gate is absence, never a lock"), §5 (profiles), §6 (settings and the gate).
4. `docs/redesign/inventory/00-decisions.md`, `docs/redesign/stack-decision.md` §2.4–§2.5 (skin per profile, restart), `docs/redesign/00-baseline.md`.
5. `backend/core/content_rating.py` `resolve_series_rating` (read only): the precedence the local filter must mirror (override, then content rating, then source maturity; unknown stays visible).
6. Code you build on: the web/04–06 Cinematic primitives, Shell, overlays (`dip`, `irisClose`, `requestIrisOut`), `showRatingCard`, `useSplashDone`, `Wordmark`, `Monogram`; `frontend/src/features/{auth,profiles,preferences,offline,library}/*.ts` (`useLogin`, `useRegister`, `useBootstrapStatus`, `useLogout`, `resolveLoginScreenMode`, `resolveRegisterAvailability`, `shouldShowInviteField`, `useProfiles`, `useCreateProfile`, `useUpdateProfile`, `useDeleteProfile`, `useActiveProfileStore`, `matureToggleBlockReason`, the mature toggle mutation in `preferences/hooks.ts`, `MATURE_GATED_QUERY_ROOTS`, `protocol.ts`, `save-request.ts`, `novel-save-request.ts`, `download-queue.ts`, `hooks.ts`, `sw-harness.testing.ts`), `frontend/public/sw.js` and `sw-policy.js`, the web/02 skin module under `frontend/src/features/skin/`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git status --short && git branch --show-current     # clean inside frontend/ (other sessions' files elsewhere are theirs; never stage them); feat/vps-slim-source-native
ls frontend/src/skins/cinematic/Shell.tsx frontend/src/skins/cinematic/shell/{Overlays.tsx,rating-card.ts}
ls frontend/src/skins/cinematic/primitives/{CertificateDialog,Certificate,Switch,ConfirmDialog}.tsx frontend/src/skins/cinematic/primitives/rows/ReorderList.tsx
ls frontend/src/features/skin
ls backend/scripts/dev_stack.sh backend/scripts/seed_demo.py backend/scripts/README-dev-stack.md
grep -rn "onboarding_step\|notify_enabled" backend/routes/profiles.py | head -3
```

If the web/06 shell, the web/05 primitives, web/02's `features/skin`, or backend/00's profile columns and dev stack are missing, stop and report which step is incomplete.

## Skills to invoke

- `superpowers:writing-plans` first; save the plan at `docs/redesign/proof/web-07/plan.md`.
- `superpowers:subagent-driven-development` (or `superpowers:executing-plans`). Suggested slices: (a) auth screens, (b) picker and Iris, (c) profile form and Manage profiles, (d) the 18+ gate UI and rating card, (e) the local mature filter and service worker.
- `superpowers:test-driven-development` for `mature-filter.ts`, the service-worker gate, the copy maps, the date line, the time-aware question, the picker's next-route and restart decisions.
- `frontend-design:frontend-design`; `impeccable:impeccable` and `taste-skill:taste-skill` to critique the screenshots against `cinematic/DESIGN.md` (reject cards, rounded avatar tiles, gradients and pill buttons).
- `superpowers:verification-before-completion` before claiming done.

## Rules for this session

- **RAM guard** before every build, test run, `next dev`, dev stack or Playwright run:
  ```bash
  test "$(free -m | awk '/^Mem:/{print $7}')" -ge 1024 || { echo "RAM guard: under 1 GB available, stopping"; exit 1; }
  ```
  One heavy command at a time; stop `next dev` and the dev stack before `npm run build`.
- **Boundaries.** Work in `frontend/` only. Skin files import only data modules, `@/lib/**`, `@/services/**`, `@/types/**`, `@/stores/**`, `@/config/**`, the contract and the skin's own folder. Never edit `backend/` (if the API misbehaves, report it for the backend track), never `backend/connectors/`, never production containers or `/srv/manhwamaniacs/{app,data}`. Use only the dev stack and its dev database for tests; never production data.
- **Legacy.** Shared data-layer changes in this step (the mature filter, the worker's gate, two sessionStorage flags, profile types) apply to every skin; they must keep every existing test green and must not change any legacy screen except that mature local copies disappear while the gate is closed, which is the intended behaviour for everyone.
- **Utilities**: §2.8 / §3.5 names only; `node design/lint-utilities.mjs` passes.
- **Git.** Branch `feat/vps-slim-source-native`; explicit `git add` paths; conventional commits; **no AI or Claude attribution** of any kind (no `Co-Authored-By` trailer, no "Generated with" line, even if a tool reminder suggests one); no secrets, no `.claude/`, no dev-stack credentials in commits; push `git push origin feat/vps-slim-source-native` after each working step once `npm run build` passes.

## Scope: everything this step delivers

Screens live in `frontend/src/skins/cinematic/screens/{auth,profiles}/`; skin copy lives in `frontend/src/skins/cinematic/screens/auth/copy.ts` and `screens/profiles/copy.ts`. Register each screen in `frontend/src/skins/cinematic/index.ts` and remove its `ScreenId` from `PENDING`.

### 1. Data-layer additions (skin-neutral, first)

- `frontend/src/features/profiles/types.ts`: web/02 added `skin` to `Profile` and `UpdateProfilePayload`; add `onboarding_step: string | null`, `notify_enabled: boolean` and `daily_goal_minutes: number | null` to `Profile`, and `skin?: "cinematic" | "glass" | null` to `CreateProfilePayload` (backend/00 serves and accepts them).
- `frontend/src/app/providers.tsx`: when a signed-in session is lost to a 401 whose code is **not** `invalid_credentials` (verify that the existing global handler already ignores `invalid_credentials`; add the exclusion if it does not), set `sessionStorage['mm.signedOut'] = "1"`; when the profile-scope handler clears the active profile on `profile_required` / `profile_not_found`, set `sessionStorage['mm.profileGone'] = "1"`. Legacy ignores both keys.
- `frontend/src/features/skin/` (web/02) already has what the picker needs: the pure `resolveBootSkin({ rendered, debug, profileSkin, glassAvailable, defaultSkin })` in `boot.ts` and `restartInto({ cookie, skin, from, returnPath })` in `skin-storage.ts`. Change one thing in `SkinBoot.tsx`: it does not run its mismatch check while the pathname is the picker (`isPickerPath(pathname)` from `features/profiles/access.ts`), because the picker resolves the edition itself inside the Iris (cinematic §8.5 step 4); without this, `SkinBoot` would restart back onto `/profiles`. Extend `boot.test.ts` or `SkinBoot`'s test with that case.

### 2. AuthPending (§8.2, web G2, L1, RG1)

- On `/login` and `/register`, while `useCurrentUser()` or `useBootstrapStatus()` is unresolved, the screen shows the web/06 splash holding its masthead (on a warm load, the stacked lockup alone), with the 24 px leader dial after 400 ms; nothing of the form paints. A resolved signed-in user is sent to `/` with `router.replace` before the form paints (the Gate then routes to the picker when no profile is active).
- Verify the §8.2 outcomes end to end with the web/06 Gate and write them into the e2e spec: remembered profile → Tonight (Dip); signed in without a profile → picker (Dip); signed out → Login (Dip); offline with a cached user → the route in the offline edition; server unreachable with no cache → Login's unreachable variant.

### 3. Login (§8.3, web L1–L9) — `screens/auth/Login.tsx`

- **Desktop frame from 1024 px**: Bare frame on the 12-column grid, split like a magazine cover.
  - Columns 1–7, the typographic **cover**: at the top the date line in `type-folio`: `{WEEKDAY} {D} {MONTH} {YYYY} · No. 1` in upper case from the local date (`Intl.DateTimeFormat("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" })`, commas removed, e.g. `TUESDAY 29 SEPTEMBER 2026 · No. 1`; `No. 1` is literal: the sign-in cover is always the first issue); in the middle the wordmark as the one-line masthead lockup (`Wordmark variant="line"`: "Manhwa" Bodoni Moda Roman + "Maniacs" Bodoni Moda Italic, `wght` 800, `opsz` 96, tracking −0.035em, in `type-masthead`, with the Oxford rule under it whose first 12 % is `spot`; add the `line` variant to web/06's `brand/Wordmark.tsx` if only `stacked` exists); below it three cover lines in `type-pull`, each revealed by letters (`SetHeading as="p" trigger="signal"`), starting when `useSplashDone()` turns true and 400 ms apart: "Every source, one shelf." / "Novels, read aloud by thirty-one voices." / "Your year in chapters." No cover images (covers need a session).
  - A 1 px `rule.1` column rule between columns 7 and 8.
  - Columns 8–12, the form, vertically centred: kicker `SIGN IN`; `TypedHeadline as="h1"` "Welcome back."; the server line in `type-caption` `ink.45`, "Server: {window.location.host}"; `TextField` `Username` (autofocus, `autoComplete="username"`); `PasswordField` `Password` (`autoComplete="current-password"`, Show/Hide); a settings-style row with the `Switch` "Keep me signed in" (default on, the `remember` flag, K16); primary `Sign in` at the full column width (`loadingLabel` "Signing in…", shown after 400 ms); the error line under the button (`role="alert"`); the footer "Need an account? **Create one**" (a `link` to `/register`, rendered only when registration is open: `resolveRegisterAvailability(status) === "open"`).
- **600–1023 px** (§8.0.9): masthead lockup and date line at the top, all three cover lines above the form, the form in grid columns 2–7.
- **Phone frame below 600 px**: masthead lockup at 28 px and the date line at the top; the cover lines collapse to the first one; the form fills the rest; the footer link sits above the keyboard (export `viewport = { interactiveWidget: "resizes-content" }` from the `/login` and `/register` route files and make the footer `position: sticky; bottom: 0`).
- **Variants**: *bootstrap* (`resolveLoginScreenMode(status) === "bootstrap"`): kicker `FIRST ISSUE`, headline "Claim this server.", deck "Create the first account. It becomes the administrator." and the Register form inline in its bootstrap variant; *unreachable*: a `CORRECTION` `Notice` with the headline "We couldn't reach the server.", the API message as the deck, and `Try again` (refetches bootstrap status).
- **Keys**: `Enter` submits from either field; Tab order username → password → Show → switch → Sign in → Create one.
- **Signature moment and transitions**: in from the splash by Dip (the Gate); on a successful sign-in the form column fades out (160 ms `ease.lift`) while the cover's Oxford rule extends across the whole viewport width (480 ms `ease.settle`), then a Dip to the picker; to Register: Page (`CineLink`). Reduced motion: no rule extension, a 150 ms fade then the Dip.
- **States and copy** (`copy.ts`, by `ApiError.code`): signed out mid-session (on mount, when `sessionStorage['mm.signedOut']` is `"1"`: remove it and show the subtitle "You've been signed out. Sign in to carry on."); resolving (item 2); normal; pending (`Sign in` loading, fields disabled); `invalid_credentials` → "That username and password don't match." (`proof`); `account_disabled` → "This account has been turned off by the owner."; `rate_limited` or HTTP 429 → a `SLOW DOWN` line with the live countdown from `retryAfterMs` ("Try again in 12 s"); unreachable (the variant above); already signed in (item 2); bootstrap errors `bootstrap_window_expired` → "The window to claim this server has closed. Whoever runs the server has to create the first account." and `bootstrap_already_claimed` → "Someone has already claimed this server. Sign in instead." (the form switches to Sign in). Any other error: "Couldn't sign in. Try again."
- Calls: `useLogin()` (`POST /auth/login {username, password, remember}`) and `useBootstrapStatus()`; haptic `tap.primary` on submit (web no-op).

### 4. Register (§8.4, web RG1–RG5) — `screens/auth/Register.tsx`

- Same cover and form split as Login on the desktop frame, the same stacks below it. Kicker and headline by variant (`resolveRegisterAvailability`, `shouldShowInviteField`):
  - *Open*: `JOIN` / "Join this library.", footer "Already have an account? **Sign in**" (link to `/login`).
  - *Bootstrap*: `FIRST ISSUE` / "Claim this server.", button `Create the administrator account`.
  - *Invite required*: as Open plus the `Invite code` field with the placeholder "Ask whoever invited you".
  - *Closed*: a `Notice` with kicker `REGISTRATION CLOSED`, headline "This library isn't taking new readers.", deck "Ask the owner to create an account for you, then sign in.", primary `Back to sign in`.
- Fields: `Username` (autofocus; helper "3–64 letters, digits, dots, dashes or underscores, starting with a letter or digit."; validated live against `^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$` so the helper turns `proof` before submit), `Password` (helper "At least 8 characters"; `autoComplete="new-password"`), `Confirm password` (live "Passwords don't match." once both have content, `aria-invalid`), `Invite code` (conditional), `Display name` (optional, helper "How your name appears"), `Email` (optional, `type="email"`, `autoComplete="email"`, error "That email address doesn't look right."), the `Switch` "Keep me signed in" (default on). Primary `Create account` (`loadingLabel` "Creating account…").
- Server codes → copy: `username_taken` "That username is taken."; `invalid_username` turns the username helper `proof`; `invite_code_invalid` "That invite code isn't valid."; `invite_code_required` "This library needs an invite code." (and the field appears); `registration_disabled` switches to the Closed variant; `weak_password` "Choose a longer password: at least 8 characters."; `bootstrap_window_expired` and `bootstrap_already_claimed` as in Login; `rate_limited` / 429 the countdown line; network failure → the `CORRECTION` unreachable notice with `Try again`; anything else "Couldn't create the account. Try again."
- Transitions: in from Login by Page; out on success to the picker by Dip, where the new account lands on the picker's empty state ("Create your first profile.").
- States: resolving, unreachable, each variant, pending (fields disabled), field errors, server errors. Calls: `useRegister()` (`POST /auth/register`).

### 5. Profile picker "Who's reading tonight?" (§8.5, web P1–P8) — `screens/profiles/Picker.tsx`

- Takeover frame on `#000`, never auto-skipped (it shows whenever no profile is active on this device, even with one profile; it is also the skin gate).
- **Desktop frame**: top-left the wordmark small (20 px line lockup); top-right `Manage` (quiet; toggles manage mode) and `Switch account` (quiet; a `ConfirmDialog` with the arm: "Switch account? You'll be signed out on this device; saved chapters stay.", then `useLogout()` → `/login` with a Dip). Centre: `TypedHeadline as="h1"` in `type-masthead`, time-aware from the local clock: 05:00–11:59 "Who's reading this morning?", 12:00–17:59 "Who's reading this afternoon?", otherwise "Who's reading tonight?". Below, the cast: up to five 144 px avatars (web/04 `Avatar`) in a centred row 48 px apart, each a button (`aria-label` "Read as {name}") with the name in `type-subhead` italic and a credit line in `type-caption` `ink.45` that reads `NEW` when the profile's `onboarding_step` is not `"done"` and is empty otherwise (the picker never publishes reading activity). An 18+ profile shows the 20 px certificate at its avatar's bottom-right. "New profile": a 144 px circle outlined 1 px `ink.45` with a `plus` 32 Light and the label "New profile" (hidden at 5 profiles).
- **Tablet (600–1023 px)**: one centred row of 112 px avatars up to four, then a second row; from 900 px the desktop row of 144 px.
- **Phone frame**: the headline at 40 px on two lines; profiles in a 2-column grid of 112 px avatars with a 32 px row gap; New profile as the last cell; a 44 px top bar with `Manage` (quiet) and a `dots-three` overflow holding `Switch account…` (the same dialog).
- **Switch profile** (`/profiles?switch=1`, from the account menu, Index and the thumb-index long-press): a pushed takeover; a `bare` `arrow-left` icon button labelled "Back" precedes the wordmark and calls `router.back()`; the previous profile stays active until another is picked.
- **The Iris** (signature moment): tapping a profile runs:
  1. its avatar's ring draws a 2 px `spot` circle clockwise (an SVG circle's `stroke-dashoffset`, 320 ms `ease.set`) while the other profiles fade to 20 % and blur 4 px (320 ms);
  2. web/06's `irisClose(pickerRoot, { x, y, radius })` closes the black iris on the avatar (480 ms `ease.turn`); haptic `profile.select` as it lands;
  3. the profile becomes active (`useActiveProfileStore.getState().setActiveProfile(profile)`; the existing providers drop every profile-scoped cache), `requestIrisOut({ x, y })`, and `router.push(next)`: the next screen opens with the iris out (560 ms `ease.settle`) while its headline types. `next` is `/welcome?step=2` (`step=1` once `FLAGS.glassAvailable` is true, §8.0.7) for a profile whose `onboarding_step` is `null` **when the `onboarding` screen is no longer in the Cinematic `PENDING` set**, otherwise `/`;
  4. when `resolveBootSkin({ rendered: "cinematic", debug: readCookie("mm-skin-debug"), profileSkin: profile.skin, glassAvailable: FLAGS.glassAvailable, defaultSkin: DEFAULT_SKIN }).restartTo` is not null (possible only once `glass_available` is true), then at the end of step 2, inside the black: `setActiveProfile(profile)` and `restartInto({ cookie: "mm-skin", skin: restartTo, from: "cinematic", returnPath: "/" })` instead of step 3; no confirm, no undo. Put the decision in `picker-logic.ts` and unit-test it with the flag forced on and off.
  A tap during the iris skips to step 3. Reduced motion: a 200 ms cross-fade.
- **Profile-scope recovery**: on mount, when `sessionStorage['mm.profileGone']` is `"1"`, remove it and show the subtitle "That profile isn't available any more. Choose another."
- **Manage mode**: every avatar gets a `pencil-simple-line` 24 overlay on a 50 % black disc (`bg-paper-0/50`); tapping opens `/profiles/{id}/edit?from=picker`. Long-press 450 ms (touch) or right-click also opens Edit (haptic `longpress.open`).
- **Keys** (group "Profiles"): `←` / `→` move between profiles (roving `tabindex`), `Enter` selects, `e` edits the focused profile, `n` new profile, `m` toggles manage mode.
- **States**: loading (five flicker circles at the avatar size); one profile (one centred avatar plus New profile; `Enter` picks it); empty (`Notice` kicker `EMPTY HOUSE`, headline "Create your first profile.", deck "Profiles keep follows, progress and moods apart for everyone on this account.", primary `New profile`); error with no cached profile (`CORRECTION` notice + `Retry`); unreachable with a cached profile (the headline, deck "The server isn't answering. Continue as {name}, or retry.", a single avatar that continues offline, and `Retry`); limit reached (New profile hidden; the tooltip on `Manage` reads "5 profiles is the limit").
- Transitions: in by Dip (from Login, the account menu, Index); out by the Iris.

### 6. Profile form, new and edit (§8.6, web PF1–PF8) — `screens/profiles/ProfileForm.tsx`, `ProfileNew.tsx`, `ProfileEdit.tsx`

- Routes `/profiles/new` and `/profiles/:id/edit`. **Desktop frame**: the Manage profiles screen renders underneath (or the picker, when `?from=picker`) and the form opens in a right **column panel** (web/05 `Sheet` on the desktop frame); closing it calls `router.back()` when there is in-app history, else goes to `/profiles/manage`. **Phone frame**: a full page with the running head's back arrow. Columns 2–7 at 600–1023 px.
- Masthead: kicker `CASTING`, title "New profile" / "Edit {name}".
- Live preview: the 96 px avatar with the chosen mood grade glowing behind it (`MoodGrade` fills the top 30 vh live).
- `Name`: a `TextField` with `size="field"` (text in `type-field`, Bodoni Moda Italic 28–36; add the size to web/04's `TextField`), max 30 characters, with a folio counter `12/30` in `type-folio` `ink.45` at the right below the rule.
- `Avatar`: a radiogroup grid of the twelve avatars at 56 px, 6 × 2 on the desktop frame and 4 × 3 on the phone frame; the selected one gets the `spot` ring at 3 px offset; each has its name (Matinee, Newsreel, Romance, Usher, Critic, Premiere, Swordplay, Phantom, Illusionist, Late show, Marquee, Bookworm) as tooltip and `aria-label`. Arrow keys move the selection.
- `Mood`: seven single-select slug-line chips, each preceded by a 10 × 10 square of the grade colour with every sRGB channel × 3 for visibility: romantic `#4E2130`, action `#4E2718`, comedy `#45391E`, horror `#2D1E27`, slice_of_life `#2D3624`, fantasy `#362448`; `default` has no square. Labels: Default, Romantic, Action, Comedy, Horror, Slice of life, Fantasy. Helper: "Grades the top of the app while this profile is active. Never the reader."
- `Mature content (18+)`: the `MatureGateSwitch` (item 8) in form mode: turning it on opens the certificate; confirming sets the form value, which is saved with the form (`mature_content_enabled` in the `POST` / `PATCH`). When the name field is empty the certificate headline reads "Show mature content on this profile?".
- `Edition`: the segmented control `CINEMATIC │ GLASS` with kicker `EDITION` and caption "The look of the whole app for this profile." (writes `skin`). **Not rendered while `FLAGS.glassAvailable` is false.** Implement it behind the flag: for a new profile or a profile that is not the active one, the value is saved with the form and applies the next time the profile is picked; for the active profile with a changed edition, `Save changes` saves every other field first, then opens a `Dialog` titled "Restart in Glass?" with body "The app closes and reopens in the Glass edition, on this page." (plus "Downloads resume after the restart." when the download queue is not empty) and actions `Restart in Glass` (primary; calls web/02's `switchSkin()`) and `Stay in Cinematic` (quiet; keeps the other saved fields and leaves the edition as it was). Cover the branches with unit tests on the decision function.
- Actions: `Create profile` / `Save changes` (primary, `loadingLabel` "Saving…") and `Cancel` (quiet). Edit adds a `destructive` `Delete profile` at the bottom, confirmed by a `ConfirmDialog` with the arm: "Delete {name}? Its library, progress, bookmarks and collections go with it. This can't be undone." Deleting the active profile clears it on this device and lands on the picker by Dip with the subtitle "Deleted {name}."; deleting another profile returns to the previous screen.
- After a save: back to the previous screen with the subtitle "Saved {name}". A new profile created from the picker returns to the picker, which lists it.
- States and copy: loading (edit; galley lines at the field heights); not found (a `Notice`: "This profile no longer exists." + `Back`); save pending; empty name "Give this profile a name."; `profile_limit_reached` "5 profiles is the limit."; `invalid_profile_name` "Use 1 to 30 characters for the name."; any other server error "Couldn't save this profile." followed by the API message.
- Keys: `Enter` saves, `Esc` cancels.
- Calls: `useCreateProfile()` (`POST /profiles {name, avatar_key, mood, mature_content_enabled, skin}`), `useUpdateProfile()` (`PATCH /profiles/{id}`), `useDeleteProfile()`; when the active profile's `mature_content_enabled` changed, run the gate side effects of item 8.

### 7. Manage profiles (§8.6, web PM1–PM8) — `screens/profiles/ProfilesManage.tsx`

- App frame (`/profiles/manage`; the sidebar's footer `Profiles` lights; the phone running head title `PROFILES`); reachable from the picker's `Manage`, the sidebar footer, Index → Profiles and Settings → Profile & account, so it is reachable on every platform (fixes web inventory §21 item 4).
- Masthead: kicker `YOUR ACCOUNT`, title "Profiles", deck "Up to five reading profiles on this account."
- Rows (web/05 `ReorderList` of standard rows): 44 px avatar, name `type-title`, caption "{Mood} mood · 18+ on" or "· 18+ off", a `CURRENT` badge (fill `ink.100`, `#000` text, the `you` badge shape) on the active profile; trailing `Use` (quiet, an instant switch with no Iris, hidden on the current row), `Edit {name}` (`pencil-simple-line` icon button → the form), `Delete {name}` (`trash-simple` icon button → the same arming `ConfirmDialog`), a drag handle and a `dots-three` menu with Move up / Move down / Move to top / Move to bottom (writes `sort_order` with `PATCH /profiles/{id}` for each moved profile; announced).
- `New profile` primary, disabled at 5 with the tooltip "5 profiles is the limit".
- States: loading (5 galley rows), error (`CORRECTION` notice + `Retry`), empty (`Notice` kicker `NOTHING HERE YET`, headline "No profiles yet.", deck "Profiles keep follows, progress and moods apart for everyone on this account.", primary `New profile`).
- Keys: `Alt+↑` / `Alt+↓` reorder the focused row.
- Transitions: Page in and out.

### 8. The 18+ gate, end to end (§7.24, web SG25–SG28, PF5)

- `screens/shared/MatureGateSwitch.tsx`, one component in two modes, so the profile form and Settings → Content share one safeguard (fixing web inventory §21 item 8):
  - **Settings mode** (web/18 mounts it in Settings → Content): a settings row with label "Show mature content (18+)" and description "Adult sources, series, search results and recommendations. Off by default."; the web/05 `Switch` bound to the active profile's value through the existing mature toggle mutation in `features/preferences/hooks.ts` (`PUT /settings {mature_content_enabled}` with `X-Profile-Id`).
  - **Form mode** (profile form): writes the form value only.
  - Turning on opens web/05's `CertificateDialog` ("Show mature content on {profile}?"). `Enable 18+` runs `onConfirm`: in settings mode the `PUT`; then the certificate's **stamp** plays (fill `proof` 160 ms, the "18" knocks out to `#000`, back to the outline), haptic `gate.confirm` and cue `impress` fire, every root in `MATURE_GATED_QUERY_ROOTS` is invalidated with `queryClient.invalidateQueries({ queryKey: [root] })` so the next screen re-enters its skeleton, and the worker is told the new gate (item 10).
  - Turning off needs no confirmation: in settings mode the `PUT` runs at once, the same roots are invalidated, the worker is told, and the subtitle "18+ content hidden on {profile}" shows.
  - Blocked (no active profile, `matureToggleBlockReason(activeProfileId)`): the switch is disabled and the row shows the reason with a `Choose a profile` link to `/profiles?switch=1`.
  - Loading: the knob becomes the 12 px leader dial with `aria-busy`. Error: the switch reverts, the outline turns `proof` for 2000 ms and the line "Couldn't change this setting." appears.
- **Rating card** — `primitives/RatingCard.tsx` and `showMatureRatingCard(series)` built on web/06's `showRatingCard()`: top-left under the running head, a 20 px certificate + `18+` in `type-kicker` + descriptors in `type-caption` `ink.60`, all inside a `paper.0` box with 8 × 12 px padding (so the text never sits on art); fades in 480 ms (`dur.spread`) `ease.settle`, holds 3000 ms (`dur.hold.rating`), fades out 240 ms (`dur.line`) `ease.lift`; informational only, announced once in a polite live region ("Rated 18 plus: Violence, Sexual content"). Descriptors from the series' genres, case-insensitive substring matches, at most three, joined by " · ": `gore` → "Gore"; `violen` → "Violence"; `smut`, `ecchi`, `hentai`, `adult`, `erotic`, `sexual`, `mature` → "Sexual content"; `horror` → "Horror"; `psycholog` → "Psychological themes"; `drug` → "Drug use"; none matched → "Mature themes". Reduced motion: 150 ms fades. Its callers are the feature page (web/11) and reader start (web/12); here it appears in the auth gallery.
- **Absence, never a lock** (§7.24, §14.11): no Cinematic surface built in this step draws a blurred tile, a lock, a "hidden" count or any hint of gated content; the picker's 18+ marker only marks profiles whose own gate is open.

### 9. Local copies follow the gate — `frontend/src/features/offline/mature-filter.ts` (shared data layer, both skins)

- `isMatureLocal({ rating, matureOverride, contentRating, sourceMature })`: when the server's resolved `rating` is present, `rating === "mature"`; otherwise mirror `resolve_series_rating`: `matureOverride` when it is not null; else `true` when `contentRating` is a mature rating (reuse the client's existing rating helper if one exists, else treat `"mature"`, `"adult"`, `"erotica"`, `"pornographic"` as mature); else `sourceMature`; an unknown rating is **not** mature (it stays visible, as on the server).
- `filterMature(rows, gateOpen)` drops rows with `mature: true` unless the gate is open; `useMatureGateOpen()` returns the active profile's `mature_content_enabled` (from `useProfiles()` or `GET /settings`, false while unknown).
- Every local read on the web goes through this filter. The web's local stores today are the service worker's download index and its cached pages, payloads and images; the offline follow cache, the bookmark store and outbox and the progress outbox exist only in the app (`capabilities.md`), and the offline Tonight, Library and Downloads payloads arrive with web/08, web/09 and web/17, which must read them through `filterMature` (state this in `mature-filter.ts`'s header comment so those sessions see it).

### 10. The service worker follows the gate (`frontend/public/sw.js`, `sw-policy.js`, `features/offline/*`)

- `SaveChapterRequest` gains `mature: boolean`, computed by `buildSaveRequest` and the novel save builder with `isMatureLocal` from the series data they already receive; every saved record keeps it.
- New messages in `protocol.ts` `OFFLINE_MESSAGE` and the worker: `mm-offline/set-mature-gate {scope, open}` (persisted per scope with the worker's persisted state, so an offline cold start knows the last value; an unknown scope counts as closed); `mm-offline/restamp-mature {scope, sourceId, seriesKey, mature}`; `mm-offline/restamp-missing {scope, followedRatings, matureSources}` which stamps records saved before this step (followed rows' resolved `rating` first, then the source's `mature` flag, else `false`).
- While a scope's gate is closed: `snapshotFor(scope)` omits `mature` records from every list, count and badge, but keeps the storage totals (the meter is a device fact that names no series); the fetch handler does not answer navigations, payloads or images from a hidden record's cache entries (it falls through to the network; offline, a navigation gets the skin's offline fallback and a sub-resource a 404 response); retention sweeps and "Free up space" still act on hidden files by their normal rules; nothing says files are hidden. Reopening the gate brings everything back at once.
- `useMatureGateSync()` in `features/offline/hooks.ts`, called from `features/offline/components/ServiceWorkerBoundary.tsx` (which `app/(app)/layout.tsx` mounts for every skin, next to web/02's `SkinBoot`): posts `set-mature-gate` whenever the active profile's known gate value changes, and `restamp-missing` once per session when the followed index and sources are loaded. The followed-series update mutation in `features/library` posts `restamp-mature` after a successful `PATCH` that changes `mature_override`.
- The page-side download queue (`download-queue.ts` and its runner) skips `mature` items while the gate is closed, leaving them queued without any caption; a running save of a now-hidden series is cancelled with `cancel-save` and re-queued at its old position; when the gate reopens they resume.
- Tests (vitest, with `sw-harness.testing.ts`): `features/offline/mature-filter.test.ts` (the precedence table, including override false on a mature source and unknown staying visible) and `features/offline/mature-gate.sw.test.ts` (save a mature and a safe chapter, close the gate: the snapshot lists only the safe one with unchanged totals, the hidden record's cached document and images are not served from cache; reopen: both return; `restamp-mature` flips visibility; a record without `mature` is stamped by `restamp-missing`). Every existing offline test stays green.

### 11. Auth gallery, e2e and the 18+ checklist

- Gallery `frontend/src/app/(preview)/skin-preview/[skin]/auth/page.tsx` (development only): Login in the normal, bootstrap, unreachable, pending, invalid-credentials and rate-limited states; Register in Open, Bootstrap, Invite and Closed; the picker in loading, one profile, five profiles (New hidden), empty, error, unreachable with a cached profile, and manage mode; the Iris frozen mid-close (`freezeAt`); the profile form with the certificate open and at the stamp frame; Manage profiles loading and empty; the rating card. Fixture data only.
- Playwright `frontend/e2e/cinematic/auth-profiles.spec.ts` against the dev stack (credentials from `MM_PROOF_USER` / `MM_PROOF_PASSWORD`, the demo account in `backend/scripts/README-dev-stack.md`; signed-in cases use `signIn(context, { base, user, password, profile })` exported by `frontend/scripts/proof.mjs`, signed-out cases a fresh context; the `mm-skin-debug=cinematic` cookie; `sessionStorage['mm.skin.splash.cinematic']="1"` through `addInitScript` so the warm splash plays):
  - Login: Tab order username → password → Show → switch → Sign in → Create one; wrong password shows "That username and password don't match."; a correct sign-in lands on the picker.
  - Register: the username helper turns `proof` on `ab`; mismatched passwords show "Passwords don't match."; registering a throwaway `e2e-{timestamp}` account on the dev database lands on the picker's empty state.
  - Picker: the question matches the local hour; `→` then `Enter` picks the second profile, the Iris runs and the next screen is at `/`; `m` toggles manage mode and shows the pencils; `e` opens the edit form.
  - Profile form: name counter updates; the mature switch opens the certificate; `Enable 18+` stays disabled until the checkbox is checked; saving shows "Saved {name}".
  - Manage profiles: `Alt+↓` moves a row and announces the new position; Delete opens the arming dialog and a double click on the trigger does not delete.
  - Reduced motion: the Iris is a 200 ms cross-fade; typed headlines are complete on the first frame.
  - Hit targets ≥ 44 × 44 at 390 × 844 with touch emulation, ≥ 32 × 32 at 1440 × 900.
  - The spec saves screenshots of every screen and state into `docs/redesign/proof/web-07/`.
- **The 18+ on-device checklist (§15.7)**, run by hand on the dev stack and written to `docs/redesign/proof/web-07/18plus-checklist.md`: with the seeded profile whose gate is open, follow a series from a healthy non-18+ source, mark it mature with `PATCH /api/library/series/{followed_id} {"mature_override": true}`, save two of its chapters (the legacy series page's download control, reached with the debug row set to `LEGACY`, since the Cinematic series page is web/11), queue a third; switch back to `CINEMATIC`, close the gate through the profile form; then check, row by row, that the Downloads count in the thumb index and sidebar, the worker snapshot, the legacy Downloads screen, search and every badge show none of it and say nothing about it, that the queued chapter did not download and shows nowhere, and that a direct offline navigation to a saved chapter URL does not open it; reopen the gate and check it all returns and the queued chapter downloads. Rows whose Cinematic screen does not exist yet (Library offline, Tonight's offline edition, Bookmarks) are marked "arrives in web/09 / web/08 / web/10; re-run in web/24". Undo the override afterwards.

## File layout (create or change exactly these)

```
frontend/src/features/profiles/types.ts                                  profile fields (if missing)
frontend/src/app/providers.tsx                                           mm.signedOut, mm.profileGone flags
frontend/src/features/skin/SkinBoot.tsx (+ its test)                     skip the mismatch check on the picker path
frontend/src/features/offline/{mature-filter.ts,mature-filter.test.ts,mature-gate.sw.test.ts,protocol.ts,save-request.ts,novel-save-request.ts,download-queue.ts,hooks.ts,client.ts,components/ServiceWorkerBoundary.tsx}
frontend/src/features/library/hooks.ts                                   restamp after a mature_override PATCH
frontend/public/sw.js, frontend/public/sw-policy.js                      gate messages, snapshot filter, fetch refusal
frontend/src/app/(app)/login/page.tsx, frontend/src/app/(app)/register/page.tsx   viewport interactiveWidget export only
frontend/src/app/(preview)/skin-preview/[skin]/auth/page.tsx
frontend/src/skins/cinematic/
  index.ts                                    six screens registered, six ScreenIds removed from PENDING
  brand/Wordmark.tsx                          line variant
  primitives/{TextField.tsx (size="field"), RatingCard.tsx}
  screens/auth/{Login.tsx,Register.tsx,AuthCover.tsx,copy.ts,copy.test.ts,date-line.ts,date-line.test.ts}
  screens/profiles/{Picker.tsx,ProfileForm.tsx,ProfileNew.tsx,ProfileEdit.tsx,ProfilesManage.tsx,copy.ts,picker-logic.ts,picker-logic.test.ts}
  screens/shared/MatureGateSwitch.tsx
frontend/e2e/cinematic/auth-profiles.spec.ts
docs/redesign/proof/web-07/plan.md
docs/redesign/proof/web-07/… (screenshots, 18plus-checklist.md)
```

Do not touch `frontend/src/skins/glass/**`, `frontend/src/components/**`, `frontend/src/features/*/components/**` except the one call added to `features/offline/components/ServiceWorkerBoundary.tsx` (the legacy auth and profile components stay as the legacy skin), `mobile/`, `backend/`.

## Working steps, commits and pushes

1. `feat(web): profile fields, sign-out and profile-gone flags, SkinBoot idle on the picker` (1) → verify, push.
2. `feat(web-cinematic): login and register` (2, 3, 4).
3. `feat(web-cinematic): profile picker with the iris` (5) → verify, push.
4. `feat(web-cinematic): profile form and manage profiles` (6, 7).
5. `feat(web-cinematic): 18+ certificate flow and rating card` (8) → verify, push.
6. `feat(web): local copies follow the 18+ gate` (9, 10) → verify, push.
7. `test(web-cinematic): auth gallery and e2e` (11) → verify, push.
8. `docs(redesign): web-07 proof screenshots and 18+ checklist` → push.

## Acceptance criteria

- [ ] `login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage` render Cinematic screens and are gone from `PENDING`; the completeness test still passes.
- [ ] Every element and state of web inventory L1–L9, RG1–RG5 (and the nine register form elements), P1–P8, PF1–PF8, PM1–PM8 has its Cinematic counterpart as specified above, with the copy above.
- [ ] Login: the 7 | 5 cover split from 1024 px, the stacked tablet layout, the phone stack with the footer above the keyboard; the date line; cover lines revealed 400 ms apart; the typed `h1`; the rule-extension hand-off; every error state and variant.
- [ ] Register: four variants, live username and confirm validation, the server-code copy, `new-password` autocomplete.
- [ ] Picker: time-aware typed question, 144 / 112 px avatars with the 18+ marker and `NEW` credit, never skipped, the Iris (ring 320 ms, iris 480 ms `ease.turn`, iris out 560 ms `ease.settle`, `profile.select`), skip by tap, manage mode, keys, every state, switch-profile as a pushed takeover, and the step-4 restart through `resolveBootSkin` and `restartInto`, gated by `glass_available` (unit-tested with the flag forced on), with `SkinBoot` idle on the picker.
- [ ] Profile form: column panel on the desktop frame and full page on the phone frame, live mood preview, 30-character counter, avatar radiogroup, mood chips with the exact squares, the certificate path for 18+, the Edition row absent while `glass_available` is false, the arming delete, every error copy.
- [ ] Manage profiles: rows, `CURRENT`, Use without the Iris, edit, arming delete, drag and keyboard reorder writing `sort_order`, the Move items, states.
- [ ] 18+: one safeguard in both places; the stamp, `gate.confirm` and `impress`; every mature-gated root invalidated; the turn-off subtitle; the blocked, loading and error states; the rating card timings (480 / 3000 / 240 ms) and its `paper.0` ground; no lock, blur or count anywhere.
- [ ] Local copies: with the gate closed, mature records vanish from the worker snapshot, counts and badges, are not served from cache, and queued ones pause silently; reopening restores everything; storage totals never change; `mature-gate.sw.test.ts` proves it and the checklist file records the manual run.
- [ ] Reduced motion (OS and `data-motion="reduced"`): the Iris and the hand-offs become 150–200 ms fades; typed headlines and letter reveals follow §4.8.
- [ ] Keyboard: every screen fully usable without a pointer; focus lands on each screen's `h1` after navigation; dialogs and panels trap and return focus; the focus ring shows on `:focus-visible` only.
- [ ] Hit targets ≥ 44 × 44 on the phone frame and coarse pointers, ≥ 32 × 32 on a fine pointer.
- [ ] Legacy login, register, picker, forms and Settings → Content look exactly as before (before / after screenshots with both skin cookies unset).
- [ ] `node design/lint-utilities.mjs`, the ESLint skin boundary and `node design/build.mjs --check` pass; every vitest test that passed before still passes; lint 0 / 0; build passes.

## Verification

Record the vitest total before the first edit, then:

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend
test "$(free -m | awk '/^Mem:/{print $7}')" -ge 1024 || { echo "RAM guard"; exit 1; }
npm run typecheck
npm run lint            # 0 errors, 0 warnings
npm run test            # every earlier test passes; report old and new totals
npm run build           # passes; stop next dev and the dev stack first
```

Then, with the RAM guard before each, start the dev stack and `next dev` on port 3010 as `backend/scripts/README-dev-stack.md` and the usage header of `frontend/scripts/proof.mjs` describe:

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
export MM_PROOF_USER=<demo user from README-dev-stack> MM_PROOF_PASSWORD=<its password>
E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/cinematic
node scripts/proof.mjs --step web-07 --skin cinematic --no-auth --routes /login,/register --grid
node scripts/proof.mjs --step web-07 --skin cinematic --routes /profiles,/profiles/manage,/profiles/new --grid
node scripts/proof.mjs --step web-07 --skin cinematic --routes /profiles --reduced
node scripts/proof.mjs --step web-07 --skin cinematic --no-auth --routes /skin-preview/cinematic/auth
```

The frontend runs as the harness's usage header says (`NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`). Everything lands in `docs/redesign/proof/web-07/` at 1440 × 900 and 390 × 844 (plus 800 × 1024 for the tablet Login and picker). Use `playwright-cli -s=web-07` for ad-hoc sessions.

Mobile and backend: this step changes neither (the dev-stack backend is only used). Judge that by your own commits, never by the branch diff: every web step runs in parallel with its `mobile/NN` twin on the same branch, so `git diff origin/...HEAD -- mobile backend` is routinely non-empty with other sessions' work. `git show --stat --format= <hash>` for each commit of this step must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

## Report back

1. Done items by number (1–11), the six `ScreenId`s removed from `PENDING`, and anything not done with the reason.
2. `docs/redesign/proof/web-07/` file list and the 18+ checklist results; the impeccable and taste-skill critiques and the changes they caused.
3. Vitest before and after, Playwright passed / failed, lint, build, `build.mjs --check`, `lint-utilities`.
4. Commit SHAs, each pushed.
5. Open issues, including any backend behaviour that did not match `capabilities.md` or backend/00 (for the backend track), and every place the copy had to be written because `cinematic/DESIGN.md` gave none.

Next prompt: `docs/redesign/prompts/web/08-cinematic-tonight.md`.
