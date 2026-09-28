# Discovery UX research: home, profiles, onboarding, search, library, downloads, settings, and skin engines

Written 2026-09-29 for the ManhwaManiacs 0-to-100 redesign (two skins: **Cinematic** and **Glass**, dark only, AMOLED `#000000` base; binding owner decisions live in `../inventory/00-decisions.md`).

This file studies how Netflix, Crunchyroll, Apple TV, Disney+, Apple Music, Spotify, Webtoon, Plex and Infuse build home/discovery, the profile picker, onboarding taste pickers, search, library shelves, downloads and settings. It then looks at real software that switches its whole personality (layout, assets, behaviour), not just its colours, and ends with the patterns to adopt per skin and an architecture for the skin engine.

**How to read the numbers.** Values marked *observed* come from the product, its docs, or a source listed at the end. Values marked *proposed* are my recommendation for ManhwaManiacs. They are starting points for the token and motion work, not measurements of anyone else's app.

---

## 1. Home and discovery

### 1.1 Hero spotlight

| App | What the hero does (observed) | What to take |
|---|---|---|
| **Netflix TV (2025 redesign, first since 2013)** | The navigation moved from a left rail to a persistent top bar (Search, Shows, Movies, Games, My Netflix). Rows stay, but each row now promotes a *featured* tile, more tiles autoplay video, and tiles carry labels such as "#1 in TV Shows", "New Season" or "Emmy Award Winner" before you open them. Recommendations re-rank in-session as you browse ("responsive recommendations"). A vocal part of the audience disliked the change: more motion, less density. | Labels on tiles carry the "why should I care" signal. In-session re-ranking is cheap to fake with our data (for example, after you open a romance title, pull romance rails up). Keep density up: the backlash was about losing scannability. |
| **Netflix web/mobile billboard** | A full-bleed key-art billboard. The title logo sits bottom-left over a left-to-bottom black gradient, with a white primary "Play" button (black text) and a translucent grey "More Info" button. Clones commonly measure the grey as `rgba(109,109,110,0.7)`. After a few seconds a trailer autoplays and the synopsis collapses so only the logo stays. On mobile the hero becomes a large rounded portrait card, and the page background picks up a colour gradient sampled from the art. | The "calm, then motion" sequence: static art, then delay, then motion, then copy collapses. On mobile, use a portrait hero card whose sampled colour bleeds into the page background. That suits manhwa covers, which are portrait. |
| **Disney+ (Oct 2025 redesign)** | Top horizontal navigation with a **For You** tab as home, which carries recommendations and continue-watching. Video plays inside the hero carousel. A "dynamic brand row" (Disney, Pixar, Marvel, Star Wars, NatGeo, Hulu, FX, ESPN, ABC News) shows each brand's latest titles. Rows moved to "cinematic poster-style" artwork, and badges were added ("Season Finale", "New Series", "New Movie"). The active profile is shown more prominently. | A brand row becomes a **source row** for us: each tile is a source (MangaDex-like, novel sites) showing its newest arrivals. Status badges are cheap and high-signal. Always show which profile is active. |
| **Apple TV app (tvOS 26 / iOS 26)** | The redesign moved rows to **portrait poster art** "that incorporates Liquid Glass" so more titles fit on screen. Playback controls are Liquid Glass floating over the video. A profile picker can appear when the device wakes. | The industry turned to portrait posters in 2025, and manhwa, manga and manhua covers are already portrait. Our cover art suits this layout without extra work. |
| **Plex (2025 "new experience", rewritten from scratch)** | The navigation was rebuilt as Home, Library, Live TV, On-Demand and Discover. Art gets far more space, and on mobile **the cover fades into a colour-matched gradient** behind the Watch and Save buttons. Discover shows what your Plex friends are watching and reviewing. Long-time users complained about losing density and about personal libraries being demoted. | A colour-matched fade from the cover into the page is the right move for series detail in both skins. "Friends are reading" is a direct precedent for our social feature. Keep the personal library first-class, because we *are* a personal-library app. |
| **Crunchyroll** | The home screen is a hero carousel, then Continue Watching, then rails for picks, top shows, simulcast season and your watchlist. The brand accent is orange (commonly cited as `#F47521`) on black. | Anime-native tone: a seasonal "simulcast" rail maps to an **"Updated this week"** rail driven by our update tracker. |
| **Webtoon (2025)** | A single hero ("home banner") with *Read Ep. 1* and *Subscribe*, followed by three full covers with tags. There is a **New & Hot** tab of short trailer-style animated previews, a per-weekday Daily schedule, and an AI recommender that uses onboarding answers, history and *preferred drawing style*. Analysts note that Webtoon keeps flip-flopping between a banner and a dense grid. | Two primary actions on the hero (Read ch. 1 / Add to library). A schedule by weekday. Art style is a real preference signal for comics. |

**The portrait-art problem.** Streaming heroes rely on landscape key art (16:9, a logo with transparency, trailers). Most of our sources expose one portrait cover and the chapter pages. There are three ways to build a strong hero without landscape art:

1. **Cover plus sampled backdrop.** Show the portrait cover at full height and fill the rest of the frame with a heavily blurred, scaled copy of the same cover (a Plex-style colour-matched fade). This works for every title.
2. **Panel reel (motion without video).** Take 3 to 6 tall panels from chapter 1, which the reader already fetches, and slowly pan down each strip (a vertical Ken Burns), crossfading between them. This is our version of Webtoon's trailers and Netflix's autoplay, and it costs nothing on the backend. *Proposed:* 7 s per panel and an 800 ms crossfade. Kodi's Estuary skin uses exactly `timeperimage 7000` and `fadetime 800` for its rotating backgrounds, which is a proven calm cadence.
3. **Typographic hero.** The title set huge using the signature letter-by-letter reveal (owner decision), over option 1. This is the fallback when a title has no pages cached.

### 1.2 Rails

Observed conventions across all nine apps:

- **Row title, then a horizontal scroller, with the next card peeking in** to signal scroll. On phones every app shows about 3.2 to 3.5 portrait cards per viewport width.
- **Row types:** continue watching; your list; "because you watched X"; Top 10 (Netflix draws giant outlined numerals behind the poster); new or updated; genre or brand rows; friend activity (Plex).
- **Badges on tiles** (Netflix, Disney+): Top 10, New Episode, New Season, Season Finale, award.
- **Desktop hover** (Netflix web): after roughly half a second of hover, the tile expands in place into a preview card with actions and metadata. On TV the focused tile scales up and the rest dim.
- **Rows as a feed** (Netflix 2025, Spotify): rows are ordered per user and re-ranked live.

For us, "because you read X", "similar series" and the AI rails are just more row types, so the rail component has to cope with rows that are loading, have failed ("AI unavailable") or are empty.

### 1.3 Continue watching becomes "Continue reading"

- **Netflix:** a thin red progress bar sits under each continue-watching tile, with an episode label ("S2:E4"). The overflow menu has *Remove from row* and *Episodes & info*.
- **Apple TV "Up Next":** once an episode is finished, the tile advances to the *next* episode rather than showing a full bar. The row is removable per item, and the same list surfaces at system level (Infuse ships an Up Next integration too).
- **Disney+ and Crunchyroll:** continue watching lives inside the For You/Home feed, second only to the hero.

*Proposed for us:* each tile shows `Ch. 142 · 63%` plus a 2 to 3 px progress bar. When a chapter is finished the tile flips to **"Next: Ch. 143"**. A **"New chapter"** badge appears when the update tracker found chapters newer than the last one read. Long-press or right-click offers *Remove*, *Mark read*, *Open series* and *Previously on…* (the AI recap feature from the decisions file).

### 1.4 The "My" hub

Netflix **My Netflix** (mobile) folds Continue Watching, My List, Remind Me, downloads and liked titles into one tab. Webtoon **MY** holds subscribed series, history, downloads, comments and coins. Crunchyroll **My Lists** holds Watchlist, Crunchylists (custom lists), History and Downloads. This is the pattern for our Library tab: one personal hub where downloads and history live next to the shelves rather than as separate top-level tabs.

### 1.5 Short-form discovery feeds

Netflix began testing a **TikTok-style vertical clip feed** on mobile in 2025, alongside a **conversational AI search** ("something funny and upbeat"). Webtoon's **New & Hot** plays short animated previews. For us this is a **panel-reel feed**: full-screen vertical swipes, one title per screen, auto-panning its best panels, with *Read* / *Add* / *Not for me*. It is cheap because pages already stream through the reader pipeline, and it is a natural home for "recommend to a friend" (social).

---

## 2. "Who's watching": the profile picker

| App | Observed |
|---|---|
| **Netflix** | A full-screen "Who's watching?" grid of square avatars with names below. PIN-protected profiles show a lock icon, and the **Profile Lock PIN is 4 digits**; it is also required to play that profile's *downloads*. Manage Profiles puts the grid into an edit mode. |
| **Disney+** | Circular avatars with "Who's Watching?", Edit Profiles and Add Profile. Kids profiles look different. The 2025 redesign keeps the active profile visible in the top nav. |
| **Apple TV (tvOS 26)** | Can show the profile picker **every time the device wakes**, in the Liquid Glass interface. It is a setting (Settings, then Users and Accounts, then Who's Watching?). |
| **Crunchyroll (2024)** | Up to **5 profiles** per account at no extra cost, launched with **30 avatars** of anime characters, each profile with its own watchlist and recommendations. |
| **Plex** | Plex Home managed users, each with an optional 4-digit PIN, switched from a streamlined user menu. |
| **Infuse** | Profiles follow the OS user (Apple TV/Mac user switching). Each profile holds its own home-screen layout, shares, library data, watch history, ratings, parental controls and Trakt link. A fresh profile looks like a new install. |

What this means for us: we have **accounts** (logins) above **profiles** (isolated reading worlds), the 18+ gate, and 2 to 3 people. So:

- The picker shows the current account's profiles, plus a quiet **"Switch account"** entry (the Plex Home equivalent).
- Each avatar carries a small **18+ marker** when that profile has mature content enabled, and a **lock** when it has a PIN (the Netflix model: 4 digits, also required to open that profile's downloads offline).
- Avatars should come from our own world. Crunchyroll's anime-avatar set is the precedent: offer avatar crops from covers or panels of series the person has read.
- Selecting a profile is the most emotional transition in the app and should be a signature moment in each skin (see section 9). If profiles can have different skins, **the profile tap is also the skin restart** (section 10.5), so that transition hides the reload.
- Optional "show picker on launch" behaviour, the Apple TV "who's watching on wake" idea, as a per-account setting.

---

## 3. Onboarding and taste pickers

| App | Mechanic (observed) |
|---|---|
| **Spotify** | Right after sign-up: "choose 3 or more artists you like". Round artist photos in a grid with a search field on top. Each pick **injects related artists into the grid** near the tapped one, so the grid learns while you tap. It gets people from install to listening in under two minutes. Podcasts get a similar picker. |
| **Apple Music (classic)** | The **red bubbles**. Genres float as circles: tap once to like (the bubble grows), tap twice to love (it grows more), long-press to dismiss (it pops). A second screen repeats this for artists within the chosen genres. Bubble size carries preference strength, the one taste picker with three levels instead of a binary. |
| **Netflix** | New profiles have historically been asked to pick titles they like ("choose 3") from a poster grid to seed the rows. |
| **Webtoon (2025)** | Onboarding asks for **genres and themes**, and the recommender also weighs **preferred drawing style**. |
| **Mihon** (manga reader, Apache-2.0, `github.com/mihonapp/mihon`, cloned at `design-ref/mihon`) | A utility onboarding in exactly four steps: `ThemeStep` (with a pure-black AMOLED toggle), `StorageStep`, `PermissionStep`, `GuidesStep`. **The theme is step one**, so the app looks like *yours* before you do anything else. |

*Proposed onboarding for us (per new profile, 5 screens, each skippable):*

1. **Pick your skin.** Two live previews side by side (Cinematic / Glass), each a miniature running home screen. This is Mihon's "theme first" precedent. Choosing it here triggers the skin restart once, at the end of onboarding, not in the middle.
2. **Formats.** Manhwa, manga, manhua and novels as four big tiles, multi-select.
3. **Genres as bubbles** (Apple Music mechanic): tap to like, tap twice to love, hold to dismiss. It gives three-level weights to the AI recommender for free.
4. **Art style** (the Webtoon signal, and the one question only a comics app can ask). Show 6 to 9 **panel crops** as unlabelled images (full-colour webtoon painting, crisp cel, B&W screentone manga, manhua 3D/CG, sketchy indie…) and let the person tap the ones they like. The images do the explaining.
5. **Seed titles** (the Spotify mechanic): a poster grid drawn from steps 2 to 4. Each pick pulls similar titles in next to it. Ask for 3 or more, and show a live "your home is ready" count.

The 18+ question belongs to profile creation (it is a gate, not a taste), keeping the existing confirm-your-age step. The downloads storage cap is asked later, the first time the person downloads (Netflix asks storage questions in context, not at signup).

---

## 4. Search

| App | Observed |
|---|---|
| **Netflix** | The empty state shows top searches. Results update per keystroke as a poster grid. In 2025 an opt-in **conversational AI search** on iOS ("I want something funny and upbeat"), built with OpenAI. |
| **Spotify** | The empty state is **Recent searches** (with Clear) above **Browse all**: colour tiles per genre with a cover **tilted about 25° into the corner**. Results come as a top result, then typed sections behind filter chips. |
| **Apple Music (iOS 26)** | Search is its own **tab role**: a separate glass circle at the trailing end of the floating tab bar that **morphs into a bottom-anchored search field** when tapped. A segmented control switches scope between **Apple Music** and **Your Library**. The empty state is a grid of category tiles. |
| **Disney+ / Apple TV** | The empty state is collections and genre tiles. Results appear as a poster grid, with Apple TV mixing in people and channels. |
| **Crunchyroll** | Recent searches, then results split by type (series vs episodes). The browse page adds Sub/Dub, genre and sort filters. |
| **Webtoon (2025)** | Keyword search now matches beyond exact titles. |
| **Mihon/Tachiyomi family** | Genre filters are **tri-state** (include / exclude / ignore) inside a sheet, with sort as a separate control. Readers of this kind of app expect it. |

*Proposed search model for us:*

- **Empty state:** recent searches (already stored per profile in `mobile/lib/features/library/utils/recent_searches.dart`), then "Trending on your sources", then a **Browse** grid of genre tiles (the Spotify tile with a tilted cover), then an entry into **Search by dialogue** (OCR).
- **Scopes** as one segmented control (the Apple Music pattern): **Library · Sources · Dialogue · Novel text**. The OCR dialogue search is a feature no competitor has, so it gets a scope, not a hidden menu.
- **Ask mode:** a natural-language query sent to the external AI API ("like Solo Leveling but with a female lead"), with a visible *AI unavailable* state that falls back to keyword search.
- **Filters:** a chip row for the common ones (status, format, source), then a sheet with tri-state genres and sort.
- **Keyboard (web):** `/` or `Ctrl+K` focuses search from anywhere, arrow keys move through results, Enter opens.

---

## 5. Library shelves and collections

| App | Observed |
|---|---|
| **Spotify Your Library** | **Dynamic filter chips** (Playlists, Artists, Albums, Podcasts, **Downloaded**) that re-compute the available chips as you drill down. Sort options: Recents, Recently added, Alphabetical, Creator. A grid/list toggle. A search inside the library. Up to four pinned items at the top. |
| **Apple Music Library** | **Pins** at the top (iOS 18+), then an editable category list (Playlists, Artists, Albums, Songs, Genres, **Downloaded**, …) that you reorder or hide with Edit, then a Recently Added grid. |
| **Netflix My Netflix** | A hub rather than a library: Continue Watching, My List, Remind Me, liked titles, trailers watched, downloads. |
| **Crunchyroll My Lists** | Watchlist (filterable and sortable), **Crunchylists** (user-named custom lists), History, Downloads. |
| **Plex** | A dedicated Library tab for personal media, with type chips, sort, and collections as first-class items. |
| **Infuse 8.4** | Pin favourite folders and library categories to the Home screen (previously Apple TV-only, now on iPhone, iPad, Mac and Vision Pro). The home layout is per profile. |

*Proposed library structure for us:* **Pins** (up to 6, any series or collection) → **shelves** (Reading, Plan to read, Completed, On hold, Dropped, plus user collections) → a **filter chip row** (Manhwa, Manga, Manhua, Novels, Downloaded, Unread, Updated) → **sort** (Last read, Updated, Added, A–Z, Unread count) → **grid/list toggle**. Collections are the social surface: shared collections carry the avatars of the profiles that share them. Downloads and History are entries inside the Library hub, not separate top-level tabs (Netflix, Webtoon and Crunchyroll all agree on this).

---

## 6. Downloads

### 6.1 What the leaders do (observed)

- **Netflix.** Downloads live under My Netflix. They are grouped by show (poster, episode count, total size), and an edit mode lets you multi-select and delete. When empty, the screen offers "Find more to download". **Smart Downloads** has two parts. *Download Next Episode* deletes a watched episode and fetches the next one on Wi-Fi. *Downloads for You* auto-downloads recommendations into a **per-profile allocation of 1, 3 or 5 GB**. In App Settings a **three-segment storage bar** (Used / Netflix / Free) sits next to download quality and "Delete all downloads". PIN-locked profiles need the PIN to play their downloads.
- **Spotify.** "Downloaded" is a library *filter*, not a place. Settings has a Storage page with Clear cache and Remove all downloads, and an SD-card location on Android.
- **Apple Music.** Downloaded is a library category. The per-item state moves from a cloud-arrow button to a progress ring with a stop square in the centre, then disappears once downloaded (a small downloaded glyph appears in lists). The system settings offer *Optimize Storage*.
- **Crunchyroll.** Per-episode download buttons plus **Download All** per season. Downloads sit under My Lists. A default **download quality** lives in account settings (Medium/Low trades size for resolution).
- **Webtoon.** Downloads live inside MY, grouped by series.

### 6.2 Our downloads model (from the current code, `mobile/lib/features/downloads`)

- Chapter states: `queued`, `downloading`, `complete`, `failed`. Retrying a failed chapter returns it to `queued`. Downloads run in the foreground only, so a chapter found `downloading` at launch simply resumes.
- Queue pause reasons: `backgrounded`, `cap`.
- Storage caps: 2 / 5 / 10 / 20 GB / unlimited.
- Retention ("delete after read"): off / 24 h / 48 h / 7 days. This is our *Download Next Episode*.

### 6.3 Proposed downloads screen (both skins, visuals differ)

- **Header:** a storage meter with three segments, **other apps · ManhwaManiacs · free**, plus the cap as a marker line on the bar and a tap target into the cap chips. When the cap is reached, the bar's end cap turns amber and the queue shows its `cap` pause reason inline.
- **Smart row** under the meter: *Delete after reading* (retention) and *Auto-download new chapters for followed series* (our *Downloads for You*: update-tracker driven, not recommendation driven, which is more useful for a reader).
- **Active queue** pinned at the top while it has items: one row per series with an aggregated progress ring and "Pause all" / "Resume all". Each state has its own glyph: queued (hollow ring), downloading (determinate ring + %), paused (two bars), paused-by-cap (ring + small amber stop), failed (red `!` + Retry), complete (filled check).
- **Library of downloads** grouped by series: cover, "37 chapters · 412 MB", last read. A series opens its chapter list with per-chapter swipe-to-delete.
- **Bulk actions:** a *Select* mode with checkboxes, then a bottom action bar (Delete, Export, Mark read), plus "Select all read chapters" as a one-tap cleanup (read chapters are the most common thing to delete).
- **Empty state:** "Nothing offline yet" plus a rail of your Continue reading series with one-tap *Download next 5 chapters*.

---

## 7. Settings information architecture

- **Netflix App Settings (mobile)** is flat and short: Video Playback (cellular data), Downloads (Wi-Fi only, Smart Downloads, quality, location, delete all, storage bar), Notifications, About, Diagnostics (network check, playback specification).
- **Spotify (2023+ grouping):** Account, **Content and display**, Privacy and social, Notifications, Apps and devices, **Data-saving and offline**, **Media quality**, About, plus a Storage page with the meter.
- **Discord (2025):** four themes, **Light / Ash / Dark / Onyx**, where Onyx is true AMOLED black. Themes can be assigned independently to the device's light and dark modes ("Same as device theme"). There are three **UI density** options (default, spacious, compact), contrast and saturation sliders in Accessibility, and a search field at the top of settings. Its shape rule, circles for people and squircles for things, keeps avatars and objects visually distinct.
- **Telegram:** a profile header card on top, then grouped cards, with appearance options live-previewed in a mock chat.
- **iOS Settings / Apple apps:** grouped inset lists, search at top, destructive actions isolated at the bottom of their group.

*Proposed IA for us (existing capabilities mapped, nothing invented):*

1. **Profile card** (avatar, name, account, *Switch profile*): the Telegram/iOS header pattern.
2. **Appearance:** Skin (Cinematic / Glass, restart), plus per-skin extras (UI sounds opt-in per the decisions file, reduced-motion override).
3. **Reading:** Manhwa reader (direction, fit, auto next chapter, keep awake, volume keys, lock controls, auto-scroll speed), Novel reader (paper theme, type, page-turn style), **Voices** (the 31 TTS voices with self-introducing previews).
4. **Downloads & storage:** meter, cap, retention, auto-download, export, clear cache.
5. **Content:** 18+ gate (with its confirmation), sources.
6. **People:** profiles, members, social visibility (what others can see of your activity).
7. **Feedback:** haptics (rich per skin), sounds.
8. **Data & privacy:** backup/restore, reading history, stats and Wrapped sharing.
9. **Security:** password, profile PIN.
10. **Advanced:** server URL, diagnostics, system status.
11. **About:** version, build, what's new, licences, update.

There is a settings search at the top in both skins (Discord, iOS). Sign out goes last, isolated.

---

## 8. Apps that switch their whole personality, not just colours

### 8.1 A taxonomy

| Tier | What changes | Examples (observed) |
|---|---|---|
| **1. Token themes** | Colours (sometimes wallpaper, sometimes density). Layout and components stay the same. | **Telegram** cloud themes, **Discord** Light/Ash/Dark/Onyx + density, **Mihon** colour schemes + AMOLED toggle, **Kodi Estuary** `colors/*.xml` (14 colour files: brown, charcoal, midnight…), **FFXIV** UI themes |
| **2. Asset skins on a fixed layout** | Every bitmap, font and sound can change. Positions and behaviour are fixed by the host. | **Winamp classic** `.wsz` (zip of `MAIN.BMP`, `CBUTTONS.BMP`, `TITLEBAR.BMP`… plus `viscolor.txt`, `region.txt`, `pledit.txt`), **osu!** legacy skins, **FFXIV** "Classic FF" (pixelated icons) |
| **3. Layout skins** | The skin defines windows, layouts, controls and actions. The host provides data and commands. | **Kodi** skins (one XML per window), **VLC skins2** `.vlt`, **Winamp modern** `.wal` (XML + PNG + compiled MAKI scripts, freeform shapes), **KLWP** presets |
| **4. Personality bundles** | A curated bundle of several dimensions applied in one tap, then tweakable. | **Niagara Launcher** themes (`.nlt`: wallpaper, icon pack, font and size, clock style, theme colour, widgets), **Obsidian** themes + Style Settings, **Telegram** (theme + chat wallpaper + message colours) |

**ManhwaManiacs is tier 3 with tier 4's curation.** Each skin owns whole screens (owner decision: "screen implementations"). There are exactly two of them, both first-party.

### 8.2 Deep dives: what each one teaches

**Kodi (skin.estuary, cloned at `design-ref/kodi-xbmc/addons/skin.estuary`, CC BY-SA 4.0 + GPL-2.0, `github.com/xbmc/xbmc`).** This is the closest analogue to what we are building.
- A skin is an add-on (`addon.xml`) declaring `xbmc.gui.skin` with per-aspect-ratio resolutions (16:9 at 1920×1080 default, 21:9, 19.5:9, 4:3…).
- **Every window is its own XML file:** `Home.xml`, `DialogVideoInfo.xml`, `MyPVRGuide.xml`, `DialogKeyboard.xml`, 100+ files. A skin re-implements screens, not just styles.
- **`Defaults.xml` sets per-control-type defaults**, for example every `label` gets `font13`, white text, `scrollspeed 40`, and every `multiimage` gets `fadetime 800` and `timeperimage 7000`. These are component variants at skin level.
- **`Includes_*.xml` hold reusable fragments** (18 animation includes, 17 button includes, 20 home includes), and `Constants_1080.xml` / `Font.xml` / `colors/defaults.xml` (`background FF000000`, `button_focus FF12A0C7`, …) act as the token layer.
- `themes/` (curial, flat) are **texture packs inside one skin**: tier-2 variation nested in tier 3.
- The data contract is the **infolabel/boolean API** (`ListItem.Title`, `Player.Playing`, …). The skin only binds to it and never fetches.
- **On a skin change, Kodi reloads its whole GUI, then asks whether to keep the change, and reverts to the previous skin if nobody answers within a few seconds.** Safe switching is a first-class concern.

**VLC skins2.** A `.vlt` (tar.gz or zip) with a `theme.xml`: `Theme` → `Bitmap`/`Font` resources → `Window` → **several `Layout`s per window, one visible at a time** → controls (`Button` with up/down/over bitmaps, `Text`, `Slider` along Bézier paths, `Playtree`). Actions such as `main.setLayout(mini)` switch layouts at runtime. Bindings go to player state variables (`vlc.isPlaying`, `$T` time, `$V` volume). **Switching between the native Qt interface and skins requires restarting VLC.** Lesson: a different *interface* is a restart, while variations *inside* an interface can be live.

**Final Fantasy XIV.** UI themes (Dark, Light, Classic FF, Clear Blue/White/Green/Grey/Pink) swap the entire HUD's art. **Changing theme requires logging in again.** A game with a huge UI chose a restart boundary over live-swapping every texture.

**osu! (lazer, MIT code, `github.com/ppy/osu`, cloned at `design-ref/osu`).** `osu.Game/Skinning` defines a small interface: `ISkin { GetDrawableComponent(lookup); GetTexture(name); GetSample(info); GetConfig(lookup) }`. Every skinnable element is a `SkinnableDrawable(lookup, defaultImplementation)`. The skin is asked for a component, and if it has none the default implementation renders (**fallback per component**). Built-in skins (`ArgonSkin`, `ArgonProSkin`, `TrianglesSkin`, `DefaultLegacySkin`, `RetroSkin`) are code, while user skins are asset folders. `SkinLayoutInfo` serialises in-game skin-editor layouts. Lesson: fallback suits *user-made, partial* skins. Two complete first-party skins are better served by **strict completeness** (section 10.6).

**Winamp / Webamp (MIT, `github.com/captbaritone/webamp`, cloned at `design-ref/webamp`).** Classic skins are sprite sheets cut by coordinates: `skinSprites.ts` maps every sprite name to `{x, y, width, height}`, and `skinParser.js` reads `viscolor.txt` and `region.txt` (non-rectangular window masks). The layout is fixed at 275×116 for the main window. Winamp 3/5 **modern skins** (`.wal`) moved to XML layouts, PNG assets and MAKI scripting, so skins could reshape windows freely. That was the jump from tier 2 to tier 3, and it made modern skins much harder to author. Lesson: two hand-built skins beat a skin *format*.

**Telegram.** Cloud themes are objects with `slug`, `title` and `document`, plus settings: `base_theme` (Classic, Day, Night, Tinted, Arctic), `accent_color`, `outbox_accent_color`, up to four `message_colors` with `message_colors_animated`, `wallpaper` and `wallpaper_settings` (`intensity`, `rotation`). Per-platform files: Android `.attheme` (key=colour list, optional embedded wallpaper), Desktop `.tdesktop-theme` (zip of colours + background). Themes are shared by `t.me/addtheme/<slug>`, and opening one shows a **live preview of your real chat list before Apply**. Per-chat themes can be set by emoji. Lesson: **preview with your own data before committing**.

**Discord (2025).** Tier 1 done well: Light/Ash/Dark/**Onyx** (true black for OLED), independent light and dark assignments, three densities, and accessibility contrast and saturation sliders. Lesson: even a tier-1 system names its themes as *moods*, which is how we should name and explain Cinematic and Glass.

**Niagara Launcher.** A theme bundles wallpaper, icon pack, font and size, clock style, theme colour and widgets. It is applied in one tap, and **every part stays individually tweakable afterwards**. Community themes are shared as `.nlt` files. Lesson: a *personality* is a coordinated bundle across dimensions, and people want one tap with the option to adjust afterwards. We deliberately allow **no** post-tweaks beyond reading preferences (owner decision: no accent picker). The skin is the product's opinion.

**KLWP / KWGT (Kustom).** Presets are full home-screen layouts, **globals** are named variables shared across a preset (colours, sizes, toggles), and **Komponents** are reusable sub-presets exposing their own globals. Global variants can switch automatically (light at day, dark at night). Lesson: separate *tokens* (globals) from *components* (komponents) from *layouts* (presets). This is the same three-layer split as Kodi's colours, Defaults/Includes and window XMLs.

**Obsidian.** A theme is `manifest.json` + `theme.css` overriding CSS custom properties. The **Style Settings** plugin reads `/* @settings */` YAML blocks in any theme or snippet CSS and turns them into a settings UI that sets CSS variables or toggles `body` classes. Lesson for the web: **CSS custom properties plus a root attribute** remain the right token transport, and structural changes need a component switch, not more variables.

### 8.3 Cross-cutting lessons

1. **Screens belong to the skin; data belongs to the host.** Kodi's infolabels, VLC's `vlc.*` variables and osu!'s lookups all expose data, and the skin decides everything visual. Never put `if (skin === 'glass')` inside a shared screen.
2. **Three layers inside a skin:** tokens (colours, type, radii, motion), component variants (Kodi `Defaults.xml`, KLWP komponents), screens and layouts (Kodi window XMLs, VLC layouts).
3. **A restart boundary is normal and honest.** VLC and FFXIV (re-login) require one, and Kodi reloads the whole GUI. The owner's "app restarts" decision has good company, and it removes a whole class of half-swapped-state bugs.
4. **Make switching safe and reversible.** Kodi keeps a revert countdown, Telegram previews before applying. For us that means a live preview before switching and an **Undo** window after it.
5. **Name skins as moods** (Discord's Onyx, FFXIV's Classic FF), and show them as living previews, not swatches.
6. **Fallback suits user skins; completeness suits first-party skins.** osu! falls back per component because third parties ship partial skins. We ship two complete skins, so any missing screen is a bug to catch at build time.

---

## 9. Patterns to adopt

Every item is phrased as a decision. Values are *proposed* unless marked otherwise.

### 9.1 Cinematic skin (Netflix / Apple TV / Crunchyroll energy)

**Home and discovery**
1. **Full-bleed hero spotlight.** Desktop: a 16:9 stage, `min(56.25vw, 82vh)` tall, with the cover-plus-sampled-backdrop composition from 1.1 and a panel reel after a **2 s calm delay**. Pan speed is about 24 px/s, each panel lasts **7 s**, and panels crossfade over **800 ms**. The copy block (title, tags, synopsis) collapses to the title alone **4 s** after motion starts, as Netflix's billboard does.
2. **Hero title** uses the signature letter reveal from the decisions file: per letter `opacity 0→1`, `translateY 0.35em→0`, `blur 8px→0`, **450 ms** each, **28 ms** stagger, ease `cubic-bezier(0.22, 1, 0.36, 1)`. The main page headline uses the **50 ms per character** typing reveal (binding).
3. **Hero actions:** a solid white primary (`#FFFFFF` fill, `#000000` text, 4 px radius, 44 px tall, Read icon + "Read Ch. 1" or "Continue Ch. 142"), and a translucent secondary (`rgba(255,255,255,0.16)` fill, 4 px radius, "Details"). The Netflix-grey family, but on AMOLED black.
4. **Mobile hero** is a portrait card (cover, 12 px radius, 86% of viewport width, centred) whose **sampled dominant colour** fills the page top as a vertical gradient (`colour at 55% → #000 at 100%` over 70vh). This is Netflix mobile's dynamic backdrop.
5. **Top navigation, not a side rail**, following the Netflix 2025 TV and Disney+ 2025 redesigns. Desktop: a transparent bar over the hero that turns solid `#000` after **64 px** of scroll (200 ms fade), with format pills **Manhwa · Manga · Manhua · Novels** on the left and Search, Updates and the profile avatar on the right. Mobile: the same pills below a slim top bar, and a solid black 5-tab bottom bar (Home, Discover, Library, Updates, More).
6. **Rails:** portrait 2:3 posters, **4 px radius** (Netflix-tight), gap 8 px on mobile / 12 px on desktop, 3.3 cards visible on phones and 6.5 at 1440 px. Row titles 18/20 px semibold with `-0.01em` tracking, and the reveal animation runs when a row enters the viewport (once).
7. **Desktop hover card:** after **400 ms** of hover the poster grows to **1.35×** into a preview card (panel-reel thumbnail, Read / Add / More buttons, genre chips, match or "because you read" reason). Grow over 240 ms `cubic-bezier(0.2, 0, 0, 1)`, and the neighbouring cards do not move. Keyboard focus shows the same card on a focus ring.
8. **Top 10 rail** with giant outlined numerals (Archivo at wdth 62, 180 px tall, 2 px `rgba(255,255,255,0.5)` stroke, black fill) behind each poster. "Top 10 on your sources this week".
9. **Badges** in the top-left corner of posters: `NEW CH.`, `UPDATED`, `COMPLETED`, `TOP 10`, `18+`. 10 px uppercase, `0.06em` tracking, 2 px radius. The accent fill is reserved for NEW CH.
10. **Continue reading row** second on the page, with a **3 px accent progress bar** flush with the poster bottom, a `Ch. 142 · 63%` caption, and the Up Next flip to "Next: Ch. 143". An **Updated this week** rail (the Crunchyroll simulcast analogue) follows.
11. **Source row** (the Disney+ brand-row analogue): wide 16:9 tiles, one per source, each showing a collage of its three newest covers.
12. **One hot accent**, used only for progress, NEW badges and the focus ring. Suggested `#FF3D2E`: distinct from Netflix `#E50914` and Crunchyroll `#F47521`, and readable on `#000`. Everything else is white at 100/72/48/24% opacity over black.
13. **Type:** a condensed display face for titles and numerals (**Archivo** variable, OFL, `wdth` 62–125 axis, used at wdth 75–85) and a neutral UI face (**Geist**, OFL). Titles run at `-0.02em` tracking, UI text at 14/15/17 px.

**Profile picker**
14. A full-screen `#000` stage with "Who's reading?" typed at 50 ms per character. Square avatars **144 px** (desktop) / **96 px** (mobile), **6 px radius**, names 15 px below. Hovering or focusing adds a 3 px white ring and 1.06× scale over 160 ms.
15. On selection the chosen avatar scales to 1.25× while everything else fades to black over **420 ms**. The avatar then flies to the top-right nav slot (shared element) as the home hero fades in. If the profile's skin differs from the current one, the black frame is where the restart happens (10.5).

**Search, library, downloads, settings**
16. **Search is a full-screen overlay:** a 40 px text field with a caret blinking at 1 Hz, scopes as underlined text tabs, results as a poster grid, and the Browse grid as 16:9 genre tiles with a cover tilted 25° (the Spotify tile, recoloured from the cover's dominant hue).
17. **Library is a "My Shelf" hub** (My Netflix): Continue reading, Downloads, Collections, History as rails. The full shelf is a dense poster grid with the chip row and sort. Collections are 16:9 tiles with a three-cover fanned collage.
18. **Downloads:** a flat black list grouped by series, with a sticky bottom storage meter (8 px bar, three segments: other `rgba(255,255,255,0.24)`, ours `#FF3D2E`, free `rgba(255,255,255,0.08)`) and a text line "4.1 GB of 10 GB cap · 21 GB free". Select mode turns rows into checkboxes, and a solid bottom action bar slides up over 200 ms.
19. **Settings** use two panes on desktop (left category list at 280 px, detail on the right) and full-bleed section headers with the reveal animation on mobile.
20. **Screen transitions:** page to page as a **fade through black** (outgoing to black over 180 ms, incoming over 260 ms, `cubic-bezier(0.4, 0, 0.2, 1)`). Poster to series detail as a shared-element expand (poster → detail cover, 380 ms). Theatrical, never bouncy.

### 9.2 Glass skin (Apple Liquid Glass / visionOS depth)

**Rules inherited from Apple's Liquid Glass guidance (observed)**
- Glass belongs to the **navigation and control layer** that floats over content. Never make content (lists, posters, pages) glass.
- **No glass on glass.** Group neighbouring glass controls in one container so they sample the same backdrop and can morph into each other (SwiftUI `GlassEffectContainer(spacing:)`, `glassEffectID`).
- The **clear** variant only goes over rich, bright media. Otherwise use the regular (frostier) variant.
- **Concentric corners:** inner radius = outer radius − padding.
- Reduced Transparency means more frost, Increased Contrast means borders, Reduced Motion means calmer transitions. iOS 26.1 added a user-facing *Tinted* option that raises opacity, so a user-level "more solid" switch is expected in this kind of design.

**The AMOLED problem, and the fix.** Glass over pure `#000000` has nothing to refract and reads as a flat grey smear. So the Glass skin **always keeps imagery under the chrome**: an ambient backdrop layer made from the current context's art (a blurred cover on detail, a slow-drifting mesh of the top three cover colours on home, the current page on the reader), blurred to **80 px**, saturated **1.6×**, at **40%** opacity over `#000`. The base stays AMOLED black at the edges and in the reader. The glass has something to bend.

**Home and discovery**
1. **Floating tab bar:** a capsule inset **21 pt** from the sides and bottom (the iOS 26 value), 11 pt labels, and **Search as a separate glass circle** at the trailing end that morphs into a bottom-anchored search field. On scroll down it **minimises to the active tab only** and expands again on scroll up (the `tabBarMinimizeBehavior(.onScrollDown)` pattern).
2. **Bottom accessory above the tab bar** (Apple Music's mini player slot): **"Now reading / Now listening"** showing the current chapter with a progress ring, or the novel **TTS mini-player** (voice avatar, play/pause, skip). It collapses inline next to the minimised tab bar.
3. **Hero is a floating card, not a full bleed:** a portrait cover card (continuous corners, **28 px** radius) sitting *in front of* its own blurred enlargement, with parallax. The card tilts up to **±6°** with device motion or pointer position, and a specular highlight follows the tilt (a white radial gradient at 12% opacity). Swiping moves to the next spotlight with a spring.
4. **Rails** as depth: posters at **16 px** continuous radius, a 1 px inner highlight `rgba(255,255,255,0.10)` on the top edge, and a soft shadow `0 18px 40px rgba(0,0,0,0.55)`. The focused or pressed poster lifts (scale 1.04, shadow deepens) on a **snappy spring**.
5. **Continue reading as glass "stacks":** each series is a card with the next chapter's first panel peeking behind it, like a deck. Progress is a thin ring around the chapter number, not a bar.
6. **Series detail opens as a sheet** over home rather than a page push. Home recedes (scale **0.94**, dims to 60%, blur 8 px) as in visionOS and iOS stacked sheets, with detents *medium* and *large*. The poster **zooms** from its tile into the sheet header (the iOS 18+ zoom navigation transition; framer-motion `layoutId` on web, `Hero` in Flutter).
7. **Motion is springs only**, using Apple's three presets. **smooth** (duration 0.5 s, bounce 0) for sheets and page changes, **snappy** (0.5 s, bounce 0.15) for buttons, toggles and tab changes, **bouncy** (0.5 s, bounce 0.3) sparingly for delight (adding to library, streak flame). framer-motion 12: `transition={{ type: "spring", visualDuration: 0.5, bounce: 0.15 }}`. Flutter: `SpringDescription.withDurationAndBounce` where the SDK has it (added in recent Flutter releases; check the pinned SDK), otherwise `SpringDescription.withDampingRatio`.
8. **Glass surface recipe (web):** `background: rgba(255,255,255,0.07)`, `backdrop-filter: blur(24px) saturate(180%)`, `border: 1px solid rgba(255,255,255,0.14)`, and an inner top highlight `inset 0 1px 0 rgba(255,255,255,0.18)`. The refraction and lensing layer comes from the dedicated glass libraries already cloned in `design-ref/` (liquid-glass-react, flutter_liquid_glass, liquid_glass_widgets), which the rendering research covers.
9. **Type:** SF Pro on iOS through the system font. Elsewhere **Inter** variable (OFL) with display optical sizing, large titles **34 px bold** and body **17 px** (the iOS scale), secondary text at 60% white. The letter reveal still runs on section titles, but softer: 8 px blur, 20 ms stagger, on a smooth spring instead of a bezier.
10. **Buttons are capsules.** Primary is a tinted glass capsule (glass fill + 22% accent tint). Secondary is clear glass. Icon buttons are 44 px glass circles (the Apple minimum target). Suggested accent: an ice-violet `#9C8CFF` used only as glass tint, never as a flat fill.

**Profile picker**
11. Profiles float as **glass orbs** (circular avatars, 112 px, circles for people per Discord's rule) over an ambient collage of each profile's current reads, which cross-fades as you hover or focus each orb. Selecting one: the chosen orb **morphs** into the tab-bar avatar chip (a glass morph), the others blur out (blur 0→20 px, opacity to 0, smooth spring), and the ambient backdrop becomes that profile's home backdrop.

**Search, library, downloads, settings**
12. **Search** is bottom-anchored (thumb zone). Scopes are a glass segmented control (Library · Sources · Dialogue · Novel text) with a sliding glass thumb that stretches while moving. Suggestions appear as glass rows *above* the field, closest to the thumb.
13. **Library:** a pinned grid (up to 6) of glass tiles on top, then a category list (Apple Music pattern), a chip row that scrolls under the glass nav, and sort and filter in a **medium-detent sheet**. Collections render as **fanned card stacks** with depth, and a tap fans them open (a bouncy spring).
14. **Downloads:** the storage meter is a **glass capsule with a liquid fill** (ours in accent tint, others frosted, free clear) whose meniscus settles with a spring when values change. Select mode morphs the *Select* button into a **floating glass toolbar** (Delete · Export · Mark read) that sits in the bottom accessory slot. Swipe actions on rows.
15. **Settings:** iOS-style grouped inset lists on dark glass cards (24 px radius, concentric 12 px inner items), a big profile card on top, settings search in the nav, and a glass sidebar on desktop web.
16. **Transitions:** sheets and zooms instead of pages; pushes use a parallax slide (incoming 100%→0, outgoing 0→−30% while dimming) on the smooth spring. Nothing fades through black. Depth replaces darkness.

### 9.3 Shared across skins (behaviour and data, not visuals)

- The profile picker's semantics: account → profiles, 18+ marker, 4-digit PIN lock that also guards offline downloads, optional "ask on launch".
- The onboarding sequence (skin → formats → genre bubbles → art style → seed titles), and the storage cap asked in context on the first download.
- Search scopes (Library, Sources, Dialogue, Novel text), Ask mode with an AI-unavailable fallback, tri-state genre filters, per-profile recent searches, `/` and `Ctrl+K` on web.
- Library structure: pins, shelves, filter chips, sort, grid/list toggle, collections (shared collections for social).
- The downloads model: three-segment meter, cap marker, retention (delete after read), update-driven auto-download, per-state glyph set, a bulk select mode, "Select all read".
- The settings IA from section 7, with search.
- Row types: continue reading (with Up Next flip), updated this week, because you read X, AI picks (with loading, empty and unavailable states), Top 10, per-source newest, friends are reading.

---

## 10. Skin engine architecture

### 10.1 Principles (from section 8)

1. **Two complete, first-party skins.** No skin file format, no marketplace, no partial skins, no per-component fallback between skins.
2. **The skin owns everything visual:** tokens, fonts, component variants, navigation shell, screens, transitions, haptic map, sound map, splash, wordmark treatment.
3. **The shared core owns everything that is not visual:** API clients, stores/providers, query hooks, the reader engine (page fetching, prefetch, progress sync), download queue, TTS engine, auth, the 18+ gate, profile isolation.
4. **Route paths are the contract between the two.** Both skins implement the same path set, so deep links, notifications and shared links work whatever skin the recipient uses. A skin may *present* a route differently (a page in Cinematic, a sheet in Glass).
5. **Switching is a restart** (VLC, FFXIV, Kodi precedent, owner decision), with a preview before and an undo after.

### 10.2 What a skin exports (one interface per platform)

```
Skin
├── id: 'cinematic' | 'glass'
├── tokens        colour, type scale, radii, spacing, elevation, blur, motion curves/springs
├── fonts         the families this skin loads (only the active skin's fonts ship)
├── haptics       semantic event → pattern   (tap, select, toggle, success, error, sheet-detent, page-turn …)
├── sounds        semantic event → asset     (off by default; opt-in in Settings)
├── Shell         navigation chrome (top nav + pills | floating tab bar + accessory + sidebar)
├── screens       Record<ScreenId, Screen>   home, discover, search, library, series, reader-manhwa,
│                                            reader-novel, updates, downloads, profiles, onboarding,
│                                            settings/*, stats, wrapped, social, …
├── transitions   route-change + shared-element behaviour
└── Splash        the skin-specific launch/restart moment
```

The screen list is the stable contract. The data each screen needs comes from shared hooks or providers, such as `useHomeFeed()` / `homeFeedProvider` returning typed rows (`{kind: 'continue' | 'updated' | 'because' | 'ai' | 'top10' | 'source' | 'friends', state: 'loading' | 'ready' | 'empty' | 'unavailable', items}`), so both skins render the same truth differently.

### 10.3 Web (Next.js 16.2 App Router, React 19.2, Tailwind 4, framer-motion 12)

```
frontend/src/
├── core/                  shared: api, stores (zustand), query hooks, reader engine, downloads, tts
├── skins/
│   ├── types.ts           SkinId, ScreenId, Skin interface
│   ├── cinematic/         tokens.css, fonts.ts, Shell.tsx, screens/*, motion.ts, haptics.ts
│   ├── glass/             tokens.css, fonts.ts, Shell.tsx, screens/*, motion.ts, haptics.ts
│   └── index.ts           export const skins = { cinematic, glass } satisfies Record<SkinId, Skin>
└── app/                   thin route files only
```

**Picking the skin before first paint.** The current app resolves appearance per (user, profile) from localStorage in a blocking `<head>` script (`features/preferences/appearance-boot-source.ts`), because the server cannot know the client-selected profile. That works for attributes, but a skin changes *which components render*, and Server Components have to know that on the server. So:

- Store the skin in the profile's preferences (the source of truth, per profile, synced).
- Mirror the **active profile's skin into a cookie** `mm-skin` whenever a profile is selected or the skin changes. On the server, `const skin = (await cookies()).get('mm-skin')?.value ?? 'cinematic'` (`cookies()` is async in Next 15+).
- The profile picker renders in whatever skin the cookie holds, because it is pre-profile by definition. On selection, if the chosen profile's skin differs from the cookie, set the cookie and reload. That reload *is* the restart, hidden inside the profile-entry transition. This keeps the existing rule that no profile ever sees another profile's look after it is selected.

**Thin route files and free code-splitting.** A route file is a Server Component that chooses the skin's screen:

```tsx
// app/library/page.tsx
import { skins } from '@/skins';
import { getSkin } from '@/skins/server';
export default async function Page() {
  const { screens } = skins[await getSkin()];
  return <screens.library />;
}
```

RSC only sends client-component references for the tree it actually rendered, so the browser downloads only the active skin's client chunks. There is no `next/dynamic` registry to maintain. `satisfies Record<ScreenId, …>` on each skin's `screens` makes a missing screen a **type error**, which is the build-time completeness check (osu!'s fallback deliberately not adopted).

**Tokens.** Each skin's `tokens.css` defines its custom properties under `[data-skin="cinematic"]` / `[data-skin="glass"]` on `<html>` (set server-side from the cookie, so no flash). Tailwind 4 maps them in `@theme`. For the rare *shared primitive* that differs only cosmetically (a focus ring, a skeleton shimmer), add variants instead of branching in JavaScript:

```css
@custom-variant cinematic (&:where([data-skin=cinematic], [data-skin=cinematic] *));
@custom-variant glass     (&:where([data-skin=glass], [data-skin=glass] *));
/* usage: class="cinematic:rounded-[4px] glass:rounded-full" */
```

These variants are for tiny shared pieces only. Anything bigger than a primitive lives in the skin folder.

**Motion.** Each skin's `Shell` wraps its tree in `<MotionConfig transition={skinDefault} reducedMotion="user">`. Cinematic's default is a tween (`duration 0.24, ease [0.2, 0, 0, 1]`), Glass's is a spring (`visualDuration 0.5, bounce 0.15`). Shared elements use `layoutId` inside each skin (poster → detail).

**Fonts.** Declare `next/font` instances inside each skin's `fonts.ts`, imported only by that skin's `Shell`. Verify in the network panel that the inactive skin's fonts are not preloaded. If they are, move the font import to the skin's root layout component.

### 10.4 Mobile (Flutter 3.22+, Riverpod 2.5, go_router 14)

```
mobile/lib/
├── core/                  shared: api, repositories, providers, reader engine, downloads queue, tts
├── skins/
│   ├── skin.dart          enum SkinId; abstract interface class Skin
│   ├── routes.dart        shared path constants (the contract)
│   ├── cinematic/         cinematic_skin.dart, tokens.dart (ThemeExtension), shell.dart, screens/…
│   └── glass/             glass_skin.dart,     tokens.dart (ThemeExtension), shell.dart, screens/…
└── main.dart
```

```dart
enum SkinId { cinematic, glass }

abstract interface class Skin {
  ThemeData get theme;                  // carries ThemeExtension<SkinTokens>
  GoRouter buildRouter(Ref ref);        // same paths from routes.dart; skin-specific pages, shell, transitions
  Widget splash();
  Map<HapticEvent, HapticPattern> get haptics;
}
```

- **Boot:** read `SkinId` from SharedPreferences in `main()` before `runApp`. The device cache mirrors the active profile's skin, as on the web. Pass it in as `ProviderScope(overrides: [skinIdProvider.overrideWithValue(id)])`, so the first frame is already the right skin.
- **Per-skin navigation:** each skin builds its own `GoRouter` from the shared path constants. Cinematic uses a `ShellRoute` with top pills and a solid bottom bar. Glass uses a `StatefulShellRoute` with the floating tab bar, bottom accessory, and series detail as a sheet page (a custom `Page` subclass in its `pageBuilder`). Transitions are set per route through `CustomTransitionPage`, so the two skins differ in structure, not just in theme.
- **Restart without a dependency:** a ~15-line `AppRestart` StatefulWidget above the `ProviderScope` whose `restart()` swaps a `UniqueKey`. That disposes every provider and rebuilds from `main`'s logic, which re-reads the saved skin. This is a true in-process restart: caches cleared, router rebuilt, theme swapped. There is no need for `flutter_phoenix` or a native process kill.
- **Downloads survive:** downloads are already foreground-only, and a chapter found `downloading` at startup resumes (`download_chapter_state.dart`), so a restart simply resumes the queue. Show "Downloads will resume after restart" in the confirm sheet when the queue is active.
- **Completeness check:** one small test that loops over `ScreenId.values` for both skins and asserts each has a route builder. It is the Dart equivalent of the TypeScript `satisfies`.

### 10.5 The switch flow (both platforms)

1. **Settings → Appearance → Skin.** Two **live previews** (miniature, looping home screens of each skin, Telegram's "preview before apply"), the current one marked. Tapping the other opens a confirm sheet: "Restart into Glass" / "Stay in Cinematic", with the downloads note when relevant.
2. **Outgoing transition in the old skin:** Cinematic fades to black with the wordmark (500 ms). Glass blurs everything to 40 px and fades (smooth spring).
3. **Persist:** profile preference (server), then the device mirror (cookie / SharedPreferences), then restart (`location.reload()` / `AppRestart.restart()`).
4. **Incoming:** the **new skin's splash** plays (that skin's signature moment), then the app lands on the same route it left from (save the current path before restarting, and restore it via the shared path contract).
5. **Undo for 10 s:** a toast in the new skin, "Switched to Glass · Undo", in the spirit of Kodi's keep-or-revert countdown but non-blocking, because both skins are known-good.
6. **Profile switch:** if the target profile's skin differs, steps 2 to 4 run inside the profile-entry transition, with no confirm and no undo, because it is the profile's saved choice.

### 10.6 Explicitly not building (and when to add it)

- **A skin file format, import or sharing** (Winamp, Telegram, Niagara): only worth it if third parties ever make skins. We have two users and two skins.
- **Per-component fallback between skins** (osu!): it would let a half-finished Glass screen show up in Cinematic's clothes. Completeness is enforced by types and one test instead.
- **Live switching without restart:** the owner decided on a restart, and it removes half-swapped state (open sheets, in-flight shared-element animations, cached layouts). Revisit only if restart time becomes noticeable (budget: under 1.5 s from confirm to the new splash).
- **User tweaks inside a skin** (Niagara, Style Settings): out by decision (no accent picker). Reading preferences remain, since they belong to the reader rather than the skin.

---

## Sources

Streaming, music and comics apps
- Netflix Tudum, "Netflix's New Layout: What to Know About the TV Redesign": https://www.netflix.com/tudum/articles/netflix-new-tv-layout
- Netflix Tudum, new homepage user guide: https://www.netflix.com/tudum/articles/netflix-new-homepage-layout-user-guide
- SFist, first Netflix homepage redesign in 12 years: https://sfist.com/2025/05/09/netflix-debuts-new-homepage-for-first-time-in-12-years/
- Hollywood Reporter, user reaction to the Netflix redesign: https://www.hollywoodreporter.com/tv/tv-news/netflix-new-layout-homepage-why-changed-1236263688/
- CNBC, Netflix homepage revamp and OpenAI search: https://www.cnbc.com/2025/05/07/netflix-homepage-app-revamp-openai-tool.html
- CNN, Netflix vertical video feed and AI search: https://www.cnn.com/2025/05/07/media/netflix-new-home-page-ai-search-vertical-video
- Netflix Help, Downloads for You: https://help.netflix.com/en/node/119204
- Netflix Help, Smart Downloads: https://help.netflix.com/en/node/122916
- Netflix Help, Download Next Episode: https://help.netflix.com/en/node/101262
- Netflix Help, Profile Lock PIN: https://help.netflix.com/en/node/114277
- Disney+ redesign, 9to5Mac: https://9to5mac.com/2025/10/02/disney-reveals-app-redesign-coming-soon-to-ios-and-tvos/
- Disney+ redesign, Hollywood Reporter: https://www.hollywoodreporter.com/business/business-news/disney-plus-homepage-refresh-hulu-expansion-1236391770/
- Apple Newsroom, tvOS 26 / Apple TV redesign: https://www.apple.com/newsroom/2025/06/apple-tv-brings-a-beautiful-redesign-and-enhanced-home-entertainment-experience/
- TechCrunch, tvOS 26 Liquid Glass and profile switching: https://techcrunch.com/2025/06/09/apple-tvs-tvos-26-gets-liquid-glass-treatment-and-profile-switching-feature/
- Apple Newsroom, Liquid Glass design: https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/
- Liquid Glass SwiftUI reference (conorluddy): https://github.com/conorluddy/LiquidGlassReference
- LearnUI, iOS 26 design guidelines (21 pt tab bar inset, 11 pt labels, 44 pt targets, 34 pt large title): https://www.learnui.design/blog/ios-design-guidelines-templates.html
- Medium / Design Bootcamp, iOS 26 tab bar: https://medium.com/design-bootcamp/dont-design-junk-in-the-new-ios-26-tab-bar-4de8e842da89
- Plex, "It's Go Time: The New Plex Experience": https://www.plex.tv/blog/its-go-time-the-new-plex-experience-is-here/
- Android Police, Plex mobile redesign: https://www.androidpolice.com/plex-app-major-redesign-mobile/
- PCWorld, Plex new experience: https://www.pcworld.com/article/2653520/plexs-new-experience-arrives-6-things-to-know-before-updating.html
- Firecore, Infuse multiple user profiles: https://support.firecore.com/hc/en-us/articles/33562286594071-Multiple-User-Profiles
- AlternativeTo, Infuse 8.4 home-screen favourites: https://alternativeto.net/news/2026/3/infuse-8-4-introduces-extras-intro-skipping-home-screen-favorites-and-improved-playback
- Crunchyroll profiles (5 profiles, 30 avatars): https://www.aol.com/crunchyroll-profiles-finally-becoming-thing-195041131.html
- Crunchyroll Help, offline downloads: https://help.crunchyroll.com/article/how-do-i-download-content-to-watch-offline
- Webtoon press release on personalisation, New & Hot, onboarding: https://about.webtoon.com/press-release/183
- Webtoonish, Webtoon home banner analysis: https://www.webtoonish.com/p/home-banner-again-with-webtoons
- Webtoon Support, May 2025 product features: https://webtoon.zendesk.com/hc/en-us/articles/37307930084756-Product-Feature-Announcement-May-6th-2025
- Spotify Newsroom, Your Library filters and grid: https://newsroom.spotify.com/2021-04-29/listeners-can-explore-their-spotify-collections-faster-and-easier-with-a-new-your-library-2/
- Spotify Support, storage: https://support.spotify.com/us/article/storage-information/
- Spotify onboarding analysis: https://medium.com/@TheAhmadkabir/how-spotify-onboards-new-users-and-what-id-improve-as-a-pm-c05b4eb318df
- iMore, Apple Music red bubbles: https://www.imore.com/how-tell-apple-music-what-you

Skin and personality systems
- Kodi, HOW-TO: Change skins: https://kodi.wiki/view/HOW-TO:Change_skins
- Kodi Estuary source (local clone `design-ref/kodi-xbmc/addons/skin.estuary`), upstream https://github.com/xbmc/xbmc (Estuary: CC BY-SA 4.0 + GPL-2.0)
- VLC skins2 authoring guide: https://www.videolan.org/vlc/skins2-create.html
- VLC user docs, skins (restart required): https://docs.videolan.me/vlc-user/desktop/3.0/en/addons/skins.html
- Final Fantasy XIV Lodestone, changing the UI theme: https://na.finalfantasyxiv.com/uiguide/faq/faq-other/setting_theme.html
- osu! lazer skinning (local clone `design-ref/osu`, `osu.Game/Skinning`), upstream https://github.com/ppy/osu (code MIT)
- Webamp (local clone `design-ref/webamp`), https://github.com/captbaritone/webamp (MIT)
- Winamp skin formats: http://justsolve.archiveteam.org/wiki/Winamp_Skin
- Telegram API, themes: https://core.telegram.org/api/themes
- Discord blog, squircles, styles and spacing: https://discord.com/blog/improving-mobile-with-squircles-styles-and-spacing
- PC Gamer, Discord desktop themes and density: https://www.pcgamer.com/software/discord-drops-big-update-with-completely-new-in-game-overlay-and-new-dark-themes-for-the-desktop-client/
- Niagara Launcher help, themes: https://help.niagaralauncher.app/article/188-theming
- Niagara Pro features: https://help.niagaralauncher.app/article/40-niagara-pro-features
- Kustom Komponents (XDA): https://xdaforums.com/t/kustom-official-kustom-komponents.2926485/
- Obsidian Style Settings: https://github.com/obsidian-community/obsidian-style-settings
- Mihon onboarding and themes (local clone `design-ref/mihon`), https://github.com/mihonapp/mihon (Apache-2.0)
