# Shared 03: UI sound sets and soundscape audio

## Goal

Produce every audio file the two skins ship, reproducibly, from recipes in the repo. You will write `design/sounds/recipes.json` (one parametric recipe per UI cue and per synthesised loop) and `design/sounds/render.mjs`, which renders them with `sox` (plus `ffmpeg` for encoding and loudness), and deliver: the Cinematic "Press Room" cues (13, cinematic §6) and the Glass "Meniscus" cues (28, glass §6) as 48 kHz 16-bit mono WAV masters for the app and Ogg Opus plus AAC `.m4a` for the web, with the lengths and peak levels of the §6 tables; Cinematic's eight 90-second seamless soundscape loops (cinematic §9.4.2) as Ogg Vorbis and AAC `.m4a` in `backend/media/soundscapes/`, each command line recorded in `SOURCES.md`; and the intake for Glass's eighteen recorded soundscape layers (glass §9.4.2, §12.7): Deep's three layers synthesised now, a `SOURCES.md` template for the fifteen CC0 recordings the owner will pick from freesound.org, and `design/sounds/trim-loop.mjs`, which trims, loops, normalises and encodes whatever the owner drops in and names every file still missing. Glass's procedural soundscape layers stay code (web/44, mobile/44). Nothing in the app plays these files yet: web/02 and mobile/02 build the players.

## Read first

1. `docs/redesign/inventory/00-decisions.md` (a UI sound layer per skin, off by default; the ambient soundscape is one of the four new features).
2. `docs/redesign/cinematic/DESIGN.md` §6 (the thirteen cues, their events, lengths and recipes; 48 kHz 16-bit mono, 5 ms fades, the ≤ 384 KB budget, key of G, low-pass below 5 kHz, 0.3 s small-room reverb at 12 % wet, peaks: ticks −30 dBFS, confirmations −20, the logo sting −12; the event map), §9.4.2 (the eight loops, 90 s seamless, 48 kHz, OGG Vorbis 96 kbps and m4a/AAC, about 1 MB each, `SOURCES.md`, the picker descriptions), §15.5 row `GET /app/soundscapes/{id}.{ext}` (ids and folder), §15.11 row `sox`.
3. `docs/redesign/glass/DESIGN.md` §6 (the A-major pentatonic scale, "struck glass" and water timbres, velocity and depth pitch, levels, the cue table with recipes, lengths and peaks, the production paragraph), §9.4.2 (six scenes × three layers, the procedural recipes including Deep's, the recorded layers: 90 s seamless loops, Opus 96 kb/s `.ogg` and AAC-LC 96 kb/s `.m4a`, CC0 only, Deep synthesised), §12.7 row "Soundscape recordings", §15.11 row `sox`.
4. `docs/redesign/prompts/shared/00-design-contract-and-token-generator.md` and `shared/01-…` and their outputs: the `sounds` (cue to file stem) and `soundEvents` maps in `design/tokens/cinematic.json` and `design/tokens/glass.json`; `design/build.mjs --check`.
5. `docs/redesign/prompts-plan.json` entry for `docs/redesign/prompts/backend/07-media-routes-and-install-page.md` (it serves `backend/media/soundscapes/` at `/app/soundscapes/{id}.{ext}` and Glass layers at the id URL `/app/soundscapes/glass-{scene}-{layer}.{ext}` of glass §15.5, with `/app/soundscapes/glass/{scene}-{layer}.{ext}` kept as an alias).
6. `docs/redesign/00-baseline.md`.
7. Facts checked on this box on 2026-09-29: neither `sox` nor `ffmpeg` is installed; Ubuntu 26.04's candidates are `sox` 14.7.0.9 and `ffmpeg` 8.0.1; `sudo -n true` succeeds (passwordless sudo).

## Skills to invoke

- `superpowers:writing-plans` before writing any file.
- `superpowers:executing-plans` (inline; the work is sequential rendering) or `superpowers:subagent-driven-development` with one subagent per skin's cue set and one for the loops; verify with `git status` and `design/sounds/check.mjs`, not their reports.
- `superpowers:test-driven-development` for `design/sounds/wav.mjs` (WAV read/write, peak, RMS) and the loop crossfade: write node:test cases first.
- `impeccable`: not a sound tool; use its critique mode only on the proof sheets' legibility.
- `taste-skill:taste-skill`: listen-through review list in the report (below) replaces it; invoke it to phrase the per-cue review notes consistently.
- `frontend-design`: not needed; no web UI here.
- `superpowers:verification-before-completion` before claiming done.

## Guardrails

- **Track rule.** The shared track owns `design/` and `brand/` plus the generated files they write into `frontend/`, `mobile/` and `backend/media/`. This step may create or change only `design/sounds/**`, `design/build.mjs` (one call), `frontend/public/sounds/**`, `mobile/assets/sounds/**`, `backend/media/soundscapes/**` and `docs/redesign/proof/shared-03/**`. Do not touch `mobile/pubspec.yaml` (mobile/02 declares the assets) or any backend code (backend/07 serves the files). Stage with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a`.
- **Tools.** Install once: `sudo apt-get install -y sox libsox-fmt-all ffmpeg` (check `df -h /` first; stop if under 2 GB free). The ledgers name `sox` 14.4.2; this box gets 14.7.0.9, which has every effect used below; record the output of `sox --version` and `ffmpeg -version | head -1` in both `SOURCES.md` files. If `apt-get` fails, do not improvise: write `design/sounds/synth.mjs` (pure Node: sine, exponential chirp, white/pink/brown noise, one-pole low- and high-pass, RBJ band-pass biquad, the envelopes below, a Schroeder reverb, 16-bit WAV output) covering exactly the recipe operations of this file, record "`node design/sounds/synth.mjs <recipe>`" as the command in `SOURCES.md`, and for encoding use `npm install --prefix design/sounds/.tools --save-exact ffmpeg-static@5.3.0` (git-ignore `.tools/`) and its binary path.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every heavy command (the loop renders, `npm run typecheck`, `npm run test`, `npm run build`, `flutter analyze`, `flutter test`); stop if `available` is under 1024 MB. Never two at once. Never `flutter build`.
- **Git.** Branch `feat/vps-slim-source-native`; one commit per working step; `git push origin feat/vps-slim-source-native` after each. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line), whatever a tool suggests. Never commit secrets or `.claude/`. Never commit third-party audio that is not CC0 1.0.

## Before you start (dependency: shared/01)

This step depends on `docs/redesign/prompts/shared/01-glass-tokens-haptics-motion-names-contrast.md` (and through it shared/00): the cue stems and event maps it renders come from `design/tokens/{cinematic,glass}.json`. From the repo root run `ls design/tokens/cinematic.json design/tokens/glass.json design/build-haptics.mjs design/check-contrast.mjs` and `node design/build.mjs --check`, and confirm with `node -e "for (const s of ['cinematic','glass']) { const t = JSON.parse(require('fs').readFileSync('design/tokens/' + s + '.json', 'utf8')); console.log(s, Object.keys(t.sounds).length, 'cues'); }"` that it prints `cinematic 13 cues` and `glass 28 cues`. If anything is missing or different, stop and report which step is incomplete; do not edit the token files here.

## Scope: what this step delivers, item by item

### 1. Shared rendering rules (`design/sounds/render.mjs`, `design/sounds/wav.mjs`)

- Every cue master: 48,000 Hz, 16-bit PCM, mono WAV, exactly the table's length (`pad 0 1 trim 0 <length>` as the last timing step), linear fade-in and fade-out each `min(5 ms, length / 2)` (`fade t <in> <length> <out>`), then `norm <peak>` so the sample peak is the table's dBFS. Cue sums: layers are rendered as separate `sox -n -r 48000 -b 16 -c 1 <tmp>.wav synth …` commands and mixed with `sox -m` (each layer padded by `pad <delay>` for its start time).
- Envelopes used by the recipes (sox has no envelope generator, so each maps to `fade`): `exp(d)` = attack 1 ms then `fade l 0.001 <d> <d>` (a logarithmic fade-out, the audible shape of an exponential decay of length d); `swell(d)` = `fade h <d/2> <d> <d/2>`; `hold` = no fade. Frequency glides use sox's exponential sweep syntax `sine <f1>:<f2>`. A time-varying low-pass ("sweeping 300 → 1800 Hz") is a stepped approximation: 12 equal segments, cut-off interpolated exponentially between the two values, each segment filtered with `lowpass <f>`, joined with `splice -q <segment boundary>,0.005`.
- "Struck glass" (Glass): a sine at f plus a sine at 2.76 f at −14 dB (`remix 1v1,2v0.2` after a two-tone `synth`), `exp(decay)`. "Muted" (Cinematic `done`): a sine at f plus a sine at 4 f at −20 dB, `exp(180 ms)`, low-passed 3 kHz.
- Cinematic skin post-chain, applied to every Cinematic cue before the timing step: `lowpass 5000 reverb 30 50 20 0 0 -18.4 channels 1` (small room; −18.4 dB wet gain = 12 % amplitude).
- Every command line render.mjs runs is appended, in order, to the output's record (item 5): the files must be reproducible from the repo alone.
- `design/sounds/wav.mjs` (stdlib): `readWav(buf) → {rate, channels, bits, frames, samples: Float32Array[]}` for 16-bit PCM, `writeWav({rate, channels, samples})`, `peakDbfs(samples)`, `rmsDb(samples, from, to)`. node:test cases in `design/sounds/test/wav.test.mjs`: a written-then-read 1 kHz sine keeps its peak within 0.01 dB; a 441-sample file reads 441 frames.

### 2. Cinematic "Press Room" cues (cinematic §6)

Files: `mobile/assets/sounds/cinematic/<stem>.wav`, `frontend/public/sounds/cinematic/<stem>.ogg` and `.m4a`, stems from `design/tokens/cinematic.json` `sounds`. Key of G. Lengths include the reverb tail. Total WAV size must be ≤ 384 KB (3,740 ms of audio: 359,040 bytes plus 13 headers).

| Stem | Length | Peak | Recipe (layers at start time; the post-chain applies to all) |
|---|---|---|---|
| `tick` | 10 ms | −30 | Felt key: white noise 10 ms `bandpass 2200 3q`; plus sine 90 Hz 20 ms at −6 dB (truncated by the length) |
| `set` | 60 ms | −20 | Type slug: two clicks (1 ms white noise `highpass 2000`) at 0 and 12 ms; body sine 900 Hz `exp(40 ms)` from 0 |
| `impress` | 140 ms | −20 | Letterpress: sine 70 Hz `exp(90 ms)`; felt click (the `tick` noise layer) at 0 ms and again at 45 ms at −10 dB, matching the `impress` haptic (T@0, T@0.045) |
| `turn` | 160 ms | −20 | Paper swish: pink noise 160 ms `sinc 800-5000`, `swell(160 ms)` |
| `wipe` | 420 ms | −20 | Air rush: pink noise 300 ms with the stepped low-pass 300 → 1800 Hz, `fade h 0.100 0.300 0.020`; thump sine 60 Hz `exp(120 ms)` at 300 ms |
| `done` | 300 ms | −20 | Muted vibraphone G4 392.00, B4 493.88, D5 587.33 at 0, 60, 120 ms |
| `bell` | 450 ms | −20 | Small bell G6 1568 Hz as the static FM spectrum of ratio 3.5, index 1.0: sines 1568 (1.0), 3920 (0.575), 7056 (0.575), 9408 (0.150), 12544 (0.150) (Bessel amplitudes J0 0.765, J1 0.440, J2 0.115, normalised to J0), `exp(450 ms)`; the 5 kHz post low-pass leaves 1568 and 3920 |
| `pass` | 220 ms | −20 | Paper slide: pink noise 180 ms `sinc 1000-4000`, `swell(180 ms)`; soft G5 784 Hz tick, sine `exp(30 ms)` at 160 ms, −6 dB |
| `error` | 180 ms | −20 | Two dull knocks: G3 196.00 Hz at 0 ms and F♯3 185.00 Hz at 90 ms, each sine `exp(70 ms)` with a 3 ms white-noise transient `lowpass 1500`; whole layer `lowpass 700` |
| `toggle-on` | 40 ms | −30 | One click at 2.6 kHz: sine 2600 `exp(6 ms)` plus 2 ms white noise `bandpass 2600 4q` |
| `toggle-off` | 40 ms | −30 | The same at 1.9 kHz |
| `sheet` | 120 ms | −30 | Low paper slide: pink noise 120 ms `sinc 300-2000`, `swell(120 ms)` |
| `reel` | 1600 ms | −12 | Projector motor: brown noise 900 ms `sinc 80-1200` `tremolo 12 60`, `fade h 0.150 0.900 0.300`; pad: sines G2 98.00 and D3 146.83 from 0 to 1180 ms with the stepped low-pass 300 → 2400 Hz and `fade h 0.600 1.180 0.100`, −6 dB; the whole `impress` recipe at 1180 ms, +6 dB against the pad (the "hit" of the §12.4 impression) |

### 3. Glass "Meniscus" cues (glass §6)

Files: `mobile/assets/sounds/glass/<stem>.wav`, `frontend/public/sounds/glass/<stem>.ogg` and `.m4a`. Scale A-major pentatonic: A4 440, A5 880.00, B5 987.77, C♯6 1108.73, E6 1318.51, F♯6 1479.98, A6 1760.00 Hz. No post-chain except where a row names one. Glass §6 sets "under 320 KB for the whole set", but its lengths add up to 5,682 ms, which is 545,472 bytes at 48 kHz 16-bit mono: keep the lengths and the format, and report the budget conflict (item 8).

| Stem | Length | Peak | Recipe |
|---|---|---|---|
| `tap` | 24 ms | −26 | Struck glass A6 1760 (+ 4857.6 at −14 dB), `exp(18 ms)` (glass §6 example: `synth 0.024 sine 1760 sine 4857.6 remix …`) |
| `tick` | 8 ms | −30 | Sine 2640 `exp(6 ms)` (the runtime raises pitch up to +3 semitones with scrub speed) |
| `toggle-on` | 110 ms | −24 | Struck glass C♯6 at 0 ms then E6 at 50 ms, each `exp(50 ms)` |
| `toggle-off` | 110 ms | −24 | E6 at 0, C♯6 at 50 ms, each `exp(50 ms)` |
| `sheet-up` | 120 ms | −28 | Sine glide `520:1040` over 110 ms, `fade h 0.010 0.110 0.030` |
| `sheet-down` | 120 ms | −28 | Sine glide `1040:520`, same envelope |
| `push-1` | 100 ms | −26 | Struck-glass glide A5 → B5 (`880:987.77`, partial glide `2428.8:2726.2`) over 90 ms, 5 ms attack, `exp(90 ms)` |
| `push-2` | 100 ms | −26 | B5 → C♯6, same shape |
| `push-3` | 100 ms | −26 | C♯6 → E6 |
| `push-4` | 100 ms | −26 | E6 → F♯6 |
| `back` | 90 ms | −29 | Reverse glide B5 → A5 over 80 ms (`push-1` reversed in pitch, 3 dB quieter); the runtime sets `playbackRate` to the step ratio of the current depth (web/02, mobile/02) |
| `root` | 140 ms | −26 | Descending run E6, C♯6, A5 at 0, 40, 80 ms, struck glass, each `exp(60 ms)` |
| `fan` | 140 ms | −26 | Four struck-glass grains A5, C♯6, E6, A6 at 0, 30, 60, 90 ms, each `exp(40 ms)` |
| `dive` | 300 ms | −22 | Sine A4 440 swell `fade h 0.120 0.280 0.020`, with the stepped low-pass 3000 → 600 Hz (the only downward sound) |
| `droplet` | 80 ms | −24 | Sine chirp `700:1400` over 60 ms, `exp(60 ms)` |
| `throw` | 100 ms | −24 | Pink noise 90 ms `bandpass 1200 1.4q`, `swell(90 ms)` (the runtime shifts it with `playbackRate` to `1200 + min(|v|, 3000) × 0.6` Hz) |
| `catch` | 20 ms | −30 | Sine 440 `exp(12 ms)`, `lowpass 1500` |
| `add` | 400 ms | −18 | Struck-glass dyad A5 + E6, `exp(380 ms)` |
| `download-done` | 360 ms | −18 | Arpeggio A5, C♯6, E6 at 0, 45, 90 ms, struck glass, each `exp(270 ms)` |
| `error` | 200 ms | −20 | Two soft taps E5 659.25 at 0 ms and C♯5 554.37 at 100 ms, each sine `exp(90 ms)` |
| `unlock` | 180 ms | −20 | Glide `880:1318.51` with the partial glide `2428.8:3639.1` at −14 dB over 170 ms, `exp(180 ms)` |
| `shimmer` | 260 ms | −20 | Five A6 struck-glass grains at 0, 40, 80, 120, 160 ms, levels −12, −9, −6, −3, 0 dB, each `exp(60 ms)` |
| `pop` | 40 ms | −24 | Chirp `900:1800` over 30 ms, `exp(30 ms)` |
| `chapter` | 320 ms | −22 | Struck glass A4 440 (+ 1214.4 at −14 dB), `exp(300 ms)` |
| `flip` | 140 ms | −24 | Struck-glass taps E6 at 0 and A6 at 60 ms, each `exp(70 ms)` |
| `send` | 200 ms | −22 | Glide `1479.98:1760` over 140 ms then a 60 ms tail, `exp(200 ms)` |
| `melt` | 420 ms | −18 | Descending glide `1760:880` over 400 ms with the struck-glass partial, then `reverb 50 50 100 0 0 -8` (plate, 40 % wet) and `channels 1` |
| `logo` | 1400 ms | −12 | A5, C♯6, E6, A6 struck glass at 0, 24, 48, 72 ms, each `exp(600 ms)`; air pad: pink noise 1200 ms `sinc 2000-8000`, `fade h 0.400 1.200 0.800`, −18 dB, from 100 ms |

### 4. Web and app encodings (both cue sets)

- App: the WAV masters themselves in `mobile/assets/sounds/<skin>/`.
- Web: `ffmpeg -y -i <stem>.wav -c:a libopus -b:a 96k -ac 1 <stem>.ogg` (Ogg Opus) and `ffmpeg -y -i <stem>.wav -c:a aac -b:a 96k -ac 1 -movflags +faststart <stem>.m4a` (AAC-LC with the edit list that trims encoder priming). web/02 picks `.ogg` when `new Audio().canPlayType('audio/ogg; codecs="opus"')` is non-empty, else `.m4a`.
- Decoding either web file back with ffmpeg must give the master's length within 2 ms (checked in item 7).

### 5. Cinematic soundscape loops (cinematic §9.4.2)

Ids and files: `backend/media/soundscapes/{projector-room,rain-on-glass,night-city,cafe,night-wind,low-drone,afternoon-park,temple-bells}.{ogg,m4a}`. The plan for this series has all eight synthesised (cinematic §9.4.2 had allowed CC0 recordings for five of them; a synthesised file carries no third-party licence, and the owner can replace any of those five later with a CC0 recording through `trim-loop.mjs`, updating its `SOURCES.md` row).

Common rules:
- 48 kHz, stereo. Render 96 s, then make the loop in Node (`wav.mjs`): cross-fade the last 6 s into the first 6 s with an equal-power curve (sin/cos) and keep exactly 90.000 s (4,320,000 frames). Event layers are placed on a 90 s timeline modulo 90 s, so a tail that crosses the end wraps to the start.
- Random choices come from mulberry32 seeded with the 32-bit FNV-1a hash of the loop id, so every render is identical.
- Bed layers are sox commands (`synth 96 <noise|sine …>` plus the named filters); event layers are short sox renders (6 variants per event type, variant chosen by the PRNG) mixed into the timeline by Node at PRNG times with the stated rate, level and a random pan (equal-power, −0.8 to 0.8) where stated.
- Loudness: measure integrated loudness with `ffmpeg -i <wav> -af ebur128=peak=true -f null -`, apply a `sox … gain <delta>` to reach −26 LUFS (±1), then true peak must be ≤ −3 dBTP (if not, lower the gain until it is, and record the final LUFS).
- Encode: `ffmpeg -y -i <loop>.wav -c:a libvorbis -b:a 96k <id>.ogg` and `ffmpeg -y -i <loop>.wav -c:a aac -b:a 96k -movflags +faststart <id>.m4a` (about 1.1 MB each).
- Seam check (item 7): RMS of the last 250 ms and the first 250 ms within 1.5 dB, and the absolute sample difference across the seam below 0.02 of full scale in both channels.

| Id | Description (the picker line, §9.4.2) | Recipe (levels are relative before loudness normalisation) |
|---|---|---|
| `projector-room` | "A soft hum with distant reel ticks." | Bed: brown noise `sinc 60-400` `tremolo 0.2 20`, 0 dB; hum: sines 50 Hz and 100 Hz (−12 dB) at −18 dB; reel ticks: 4 ms white-noise clicks `lowpass 2000` at 24 per second (period 41.67 ms, ±3 % PRNG jitter), −20 dB (§9.4.2's own recipe) |
| `rain-on-glass` | "Steady rain on a window." | Bed: pink noise `highpass 400 lowpass 6000`, 0 dB; droplets: sine 2–4 kHz (PRNG) `exp(4 ms)`, Poisson 8–20 per second (rate itself drifting by the PRNG every 5 s), random pan, −8 dB; room tone: brown noise `lowpass 200`, −12 dB |
| `night-city` | "Distant traffic after dark." | Bed: brown noise `lowpass 500` `tremolo 0.05 40`, 0 dB; hiss: pink noise `highpass 3000`, −22 dB; three distant horns per loop (PRNG times): sines 392 and 440 Hz together, 400 ms `swell`, `lowpass 1000`, `reverb 50 50 100`, −14 dB, random pan |
| `cafe` | "Low voices and cups." | Murmur: pink noise `sinc 300-3000` `tremolo 3 30 tremolo 5.3 20`, 0 dB; cups: struck sines 3–5 kHz (PRNG) with a partial at ×2.4 (−10 dB), `exp(150 ms)`, Poisson 0.3 per second, random pan, −10 dB; room tone: brown noise `lowpass 200`, −12 dB |
| `night-wind` | "Wind across an empty street." | Brown noise `bandpass <f> 0.7q` where f follows 300 + 150 × sin(2π × 0.08 × t) Hz, rendered as 1 s segments spliced (`splice -q`, 0.05 s), then `tremolo 0.05 40`, 0 dB (glass §9.4.2's Wind bed, reused) |
| `low-drone` | "A deep, even hum." | Sines 55 Hz and 82.41 Hz (A1 + E2) at 0 dB and 110 Hz at −12 dB, `chorus 0.6 0.9 55 0.4 0.25 2 -s`; pink noise `lowpass 300`, −10 dB |
| `afternoon-park` | "Birds and far-off voices." | Bed: pink noise `lowpass 2000`, 0 dB; birds: groups of 2–4 chirps 80 ms apart, each a sine sweep `2500:4500` of 60–120 ms (PRNG) with `swell`, groups Poisson 0.25 per second, random pan, −6 dB; far voices: pink noise `sinc 300-2500` `tremolo 4 50`, −10 dB |
| `temple-bells` | "Slow bells over a quiet courtyard." | Bed: pink noise `lowpass 1000`, 0 dB; a bell every 7–11 s (PRNG): partials 1, 2.76, 5.40, 8.93 × f0 at 0, −6, −12, −18 dB with f0 from {196.00, 261.63, 293.66} Hz (PRNG), `exp(6 s)`, `reverb 60 50 100`, +6 dB, random pan |

`backend/media/soundscapes/SOURCES.md`: one section per id with its origin ("Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material"), the PRNG seed, every sox and ffmpeg command line in order, the measured integrated loudness and true peak, both file sizes and SHA-256s, and the `sox --version` and `ffmpeg -version` lines. The About → Licenses page lists this file (cinematic §9.4.2).

### 6. Glass recorded layers: the intake (glass §9.4.2, §12.7)

- Folder `backend/media/soundscapes/glass/`, files `{scene}-{layer}.{ogg,m4a}` for `scene` ∈ `rain, wind, ocean, hearth, stream, deep` and `layer` ∈ `bed, detail, tone` (18 layers, 36 files), which backend/07 serves at the glass §15.5 id URL `/app/soundscapes/glass-{scene}-{layer}.{ext}` (the one web/44 and mobile/44 request) and at the alias `/app/soundscapes/glass/{scene}-{layer}.{ext}`.
- Deep's three layers are synthesised now by `render.mjs` (glass §9.4.2: "Deep's layers synthesized with sox"), 90 s seamless, 48 kHz stereo: `deep-bed` sines 55 Hz and 82.41 Hz with `chorus 0.7 0.9 50 0.4 0.03 2 -s` (the slow 0.03 Hz chorus) plus pink noise `lowpass 300` at −10 dB; `deep-detail` slow shimmer: sines 1760 and 2637.02 Hz (A6, E7) at −6 dB each, `tremolo 0.1 80`, `reverb 70 50 100`; `deep-tone` soft pulses: sine 110 Hz, 400 ms `swell`, one every 4 s, 16 pulses spaced evenly over the 90 s loop (the last one wraps).
- The other fifteen come from the owner: CC0 1.0 field recordings from freesound.org only (no CC-BY, no sampling-plus, nothing imitating a named work). The owner drops each original, named `{scene}-{layer}.<any audio extension>`, into `design/sounds/incoming/glass/` (git-ignored through `design/sounds/incoming/.gitignore` containing `*` and `!.gitignore`, so raw downloads never enter the repo or the backend image) and fills its row in `SOURCES.md`.
- `design/sounds/trim-loop.mjs` (Node 22 + sox + ffmpeg):
  - `node design/sounds/trim-loop.mjs` processes every incoming file whose `SOURCES.md` row has a URL and `CC0 1.0` as licence (a file without them is skipped with a message naming it): decode to 48 kHz stereo WAV; take 96 s starting at the row's `Start (s)` column, or, when that is empty, the 96 s window with the lowest variance of 1 s RMS (searched in 1 s steps); make the 90 s equal-power loop of item 5; normalise to −26 LUFS for `bed`, −30 for `detail`, −32 for `tone` (true peak ≤ −3 dBTP); encode `ffmpeg … -c:a libopus -b:a 96k <id>.ogg` and `ffmpeg … -c:a aac -b:a 96k -movflags +faststart <id>.m4a` into `backend/media/soundscapes/glass/`; write the row's `Processing`, `LUFS`, `Size` and `SHA-256` columns.
  - `node design/sounds/trim-loop.mjs --check` lists every expected file that is missing by name (today: the 30 files of the fifteen recorded layers, for example `rain-bed.ogg`, `rain-bed.m4a`) and every row missing a URL or a CC0 licence, then exits 0 with a one-line warning; `--strict` exits 1 when anything is missing. Nothing in CI or in a later step calls `--strict`: web/44 and mobile/44 ship with the procedural layers playing whenever a recording is absent (glass §9.4.2 "Starting"), so the missing list is the owner's to-do, and the report of this step and `levels.txt` carry it.
- `backend/media/soundscapes/glass/SOURCES.md`: a table with one row per layer: `Id`, `Scene`, `Layer`, `What to look for` (from §9.4.2: rain `bed` steady rain on a roof, `detail` drips on a window pane, `tone` low room tone; wind: wind through trees, leaves and a creaking branch, far drone; ocean: waves on sand, shingle drawback, distant gulls; hearth: fire bed, crackles and embers, night wind; stream: running water, pebbles and a small fall, birds far off), `Freesound URL`, `Author`, `Licence` (must read `CC0 1.0`), `Original file`, `Start (s)`, `Processing`, `LUFS`, `Size`, `SHA-256`; the three Deep rows pre-filled as synthesised with their commands. A short intro says what the owner does: pick, download, drop into `design/sounds/incoming/glass/`, fill the row, run `node design/sounds/trim-loop.mjs`, commit the two outputs and the row.

### 7. `design/sounds/check.mjs` (stdlib, added to `design/build.mjs --check`)

Reads the committed files only (no sox or ffmpeg needed, so it runs in CI) and asserts:
- every cue stem in each token file's `sounds` has `mobile/assets/sounds/<skin>/<stem>.wav`, `frontend/public/sounds/<skin>/<stem>.ogg` and `.m4a`; no extra files;
- every WAV is 48,000 Hz, 16-bit, mono; its length equals the recipe length ± 1 ms; its sample peak equals the recipe peak ± 0.5 dB;
- the Cinematic WAV set totals ≤ 393,216 bytes (384 KB);
- the eight Cinematic loops and Deep's three layers exist as `.ogg` and `.m4a`, and each has a `SOURCES.md` section or row;
- it prints the Glass intake's missing list (the `--check` output of `trim-loop.mjs`, computed in-process) as a warning, never a failure.
Add one call to it at the end of `design/build.mjs --check`. The render-time checks that need tools (decoded web length within 2 ms of the master; loop seam RMS within 1.5 dB and jump < 0.02; loudness −26 ± 1 LUFS; true peak ≤ −3 dBTP) run inside `render.mjs` and `trim-loop.mjs` and fail the render.

### 8. Proof

`node design/sounds/render.mjs --proof` writes, from the WAVs with `wav.mjs` (no browser):
- `docs/redesign/proof/shared-03/cues.svg`: one row per cue of both skins, the waveform envelope (peak per 0.5 ms bin) drawn at a common time scale, labelled with stem, length, peak and the events that use it;
- `docs/redesign/proof/shared-03/soundscapes.svg`: for each loop and Deep layer, 1 s RMS over the 90 s, with the seam region (last 6 s and first 6 s) marked;
- `docs/redesign/proof/shared-03/levels.txt`: a table of every file with length, peak dBFS or LUFS and true peak, size and SHA-256, the Cinematic and Glass WAV totals, and the tool versions.

## File layout

Create:
```
design/sounds/recipes.json
design/sounds/render.mjs
design/sounds/wav.mjs
design/sounds/trim-loop.mjs
design/sounds/check.mjs
design/sounds/test/wav.test.mjs
design/sounds/incoming/.gitignore
mobile/assets/sounds/cinematic/{tick,set,impress,turn,wipe,done,bell,pass,error,toggle-on,toggle-off,sheet,reel}.wav
mobile/assets/sounds/glass/{tap,tick,toggle-on,toggle-off,sheet-up,sheet-down,push-1,push-2,push-3,push-4,back,root,fan,dive,droplet,throw,catch,add,download-done,error,unlock,shimmer,pop,chapter,flip,send,melt,logo}.wav
frontend/public/sounds/cinematic/*.{ogg,m4a}        (13 × 2)
frontend/public/sounds/glass/*.{ogg,m4a}            (28 × 2)
backend/media/soundscapes/{projector-room,rain-on-glass,night-city,cafe,night-wind,low-drone,afternoon-park,temple-bells}.{ogg,m4a}
backend/media/soundscapes/SOURCES.md
backend/media/soundscapes/glass/deep-{bed,detail,tone}.{ogg,m4a}
backend/media/soundscapes/glass/SOURCES.md
docs/redesign/proof/shared-03/{cues.svg, soundscapes.svg, levels.txt, cues-1440.png, cues-390.png, soundscapes-1440.png, soundscapes-390.png}
```
Change: `design/build.mjs` (one call to `design/sounds/check.mjs` in `--check`). If the apt fallback was needed: also `design/sounds/synth.mjs` and `design/sounds/.gitignore` (`.tools/`).

## Acceptance criteria

- [ ] `sox --version` and `ffmpeg -version` are recorded in both `SOURCES.md` files and `levels.txt`.
- [ ] 13 Cinematic and 28 Glass WAV masters exist, each 48 kHz 16-bit mono, each at its table length (± 1 ms) and peak (± 0.5 dB), each with 5 ms (or length / 2) fades; the Cinematic set is ≤ 384 KB; the Glass total is reported against its 320 KB figure.
- [ ] Every cue has `.ogg` (Opus) and `.m4a` (AAC-LC) web files whose decoded length is within 2 ms of the master.
- [ ] Eight Cinematic loops exist as `.ogg` (Vorbis 96 kb/s) and `.m4a` (AAC 96 kb/s), 90.000 s each, −26 ± 1 LUFS, true peak ≤ −3 dBTP, seams within the item-5 limits, about 1.1 MB per file; `SOURCES.md` holds every command line and seed.
- [ ] Deep's three Glass layers exist as `.ogg` (Opus) and `.m4a`; `backend/media/soundscapes/glass/SOURCES.md` has 18 rows (3 filled, 15 waiting for the owner).
- [ ] `node design/sounds/trim-loop.mjs --check` names the 30 missing files of the fifteen recorded layers and exits 0; `--strict` exits 1.
- [ ] Rendering twice gives byte-identical WAV masters (determinism: fixed seeds, no dither; sox runs with `-D` to disable dither and `-R` for repeatable output).
- [ ] `node design/build.mjs --check` exits 0 and now includes the sounds check; `node --test design/sounds/test/` passes.
- [ ] Reduced motion: sounds are not motion and do not change under it (cinematic §14.1 "what does not change", glass §4.11 "UI sounds: per setting"); nothing in this step plays anything, and the runtime rules (UI sounds off by default, per profile in cinematic §6 and per device in glass §6; suppressed while narration or a soundscape plays; never for the typing or letter reveals) are listed as hand-offs in the report.
- [ ] Keyboard and hit targets: not applicable in this step (no UI); stated in the report.
- [ ] Per-skin difference: Cinematic cues are warm (every file low-passed at 5 kHz, small-room reverb) and Glass cues are bright struck glass on the A-major pentatonic scale; the proof sheet shows both sets side by side.
- [ ] `frontend`: `npm run lint` 0 errors 0 warnings, `npm run typecheck` passes, `npm run test` count not lower than before, `npm run build` passes (the new files under `public/` must not break it).
- [ ] `mobile`: `flutter analyze` no issues; `flutter test` passes, 0 failed.
- [ ] `docs/redesign/proof/shared-03/` holds `cues.svg`, `soundscapes.svg`, `levels.txt` and the four PNG captures (1440 × 900 and 390 × 844 per sheet), and you looked at them.
- [ ] No raw download is committed (`git status --short design/sounds/incoming` shows nothing).
- [ ] Every commit touches only this step's paths, carries no AI attribution, and was pushed.

## Verification commands

From the repo root, one heavy command at a time, `free -m` first (stop under 1024 MB available).

```bash
df -h / && free -m
sudo apt-get install -y sox libsox-fmt-all ffmpeg
sox --version && ffmpeg -version | head -1
node --test design/sounds/test/
node design/sounds/render.mjs cues
free -m
node design/sounds/render.mjs loops
node design/sounds/render.mjs --proof
node design/sounds/trim-loop.mjs --check; echo "intake exit $?"
node design/sounds/trim-loop.mjs --strict; echo "strict exit $? (expect 1)"
node design/sounds/check.mjs
node design/build.mjs --check; echo "check exit $?"
for f in mobile/assets/sounds/glass/tap.wav frontend/public/sounds/glass/tap.ogg frontend/public/sounds/glass/tap.m4a; do ffprobe -v error -show_entries format=duration -of csv=p=0 "$f"; done
ffmpeg -hide_banner -i backend/media/soundscapes/cafe.ogg -af ebur128=peak=true -f null - 2>&1 | grep -E "I:|Peak:" | tail -2
free -m
cd frontend && npm run lint && cd ..
free -m
cd frontend && npm run typecheck && cd ..
free -m
cd frontend && npm run test && cd ..
free -m
cd frontend && npm run build && cd ..
free -m
cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze && cd ..
free -m
cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test && cd ..
git status --short
```

Backend: no backend code changes (only files under `backend/media/`). If `backend/.venv` exists (backend/00 creates it), run `cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -3` after the loop files are committed and quote the summary line; the CI `backend` job (`cd backend && pytest -q --no-header`) must stay green on your pushed commits either way.

**Visual proof.** No web screen changes. The proof is `docs/redesign/proof/shared-03/cues.svg`, `soundscapes.svg` and `levels.txt`; capture both SVGs in headless Chromium at 1440 × 900 and 390 × 844 (full page) into `docs/redesign/proof/shared-03/{cues,soundscapes}-{1440,390}.png` with the command block of shared/00 "Visual proof" (same script, one page per SVG; install Chromium first exactly as that block says if `~/.cache/ms-playwright` has no `chromium-*` folder), and look at them.

## Commit plan

1. `feat(sounds): WAV helpers and recipe renderer` — `design/sounds/wav.mjs`, `design/sounds/test/wav.test.mjs`, `design/sounds/render.mjs`, `design/sounds/recipes.json`.
2. `feat(sounds): Cinematic Press Room cues` — the 13 WAVs and 26 web files.
3. `feat(sounds): Glass Meniscus cues` — the 28 WAVs and 56 web files.
4. `feat(sounds): Cinematic soundscape loops` — the 16 loop files and `backend/media/soundscapes/SOURCES.md`.
5. `feat(sounds): Glass layer intake with Deep synthesised` — `design/sounds/trim-loop.mjs`, `design/sounds/incoming/.gitignore`, `backend/media/soundscapes/glass/**`.
6. `feat(design): sound files in the contract check` — `design/sounds/check.mjs`, `design/build.mjs`.
7. `docs(redesign): sound proof sheets and levels` — `docs/redesign/proof/shared-03/**`.

Push after each; `git add <explicit paths>` every time.

## Report back

- The checklist with every box ticked or explained.
- The `levels.txt` table (or its summary): per cue length and peak; per loop LUFS, true peak, seam figures and sizes; the Cinematic and Glass WAV totals.
- Tool versions (`sox`, `ffmpeg`) and whether the fallback path was used.
- Outputs of `node design/sounds/check.mjs`, `trim-loop.mjs --check` (the missing list), `node design/build.mjs --check`, `node --test design/sounds/test/`, `npm run lint`, `npm run typecheck`, `npm run test` (count), `npm run build`, `flutter analyze`, `flutter test` (count), and the lowest `free -m` available figure.
- Proof paths: `docs/redesign/proof/shared-03/cues.svg`, `soundscapes.svg`, `levels.txt` and the four PNG captures.
- A short listening note per cue set (listen on headphones through `ffplay -nodisp -autoexit <file>` if a sound device exists; otherwise say so): anything harsh, clipped, clicky at the seam, or off-scale.
- Pushed commit hashes.
- Open issues and hand-offs: the Glass 320 KB budget versus its 5,682 ms of cues (545 KB at the specified format); the owner's fifteen CC0 picks (the `trim-loop.mjs --check` list); mobile/02 declares `assets/sounds/cinematic/` and `assets/sounds/glass/` in `pubspec.yaml`; web/02 probes `audio/ogg; codecs="opus"` for cues and `audio/ogg; codecs="vorbis"` for Cinematic loops, and pitches `back`, `tick` and `throw` with `playbackRate` as glass §6 describes; backend/07 serves both soundscape folders; the five Cinematic loops the design had planned as recordings are synthesised and replaceable.

**Next prompt file:** in the series order the next file is `docs/redesign/prompts/web/02-foundation-restart-haptics-sound.md`; the next file on the shared track is `docs/redesign/prompts/shared/04-brand-cinematic-and-platform-icons.md`.
