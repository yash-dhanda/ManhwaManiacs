# Onboarding art-style crops: brief for the owner

One commission of eleven masters serves both skins: Glass (nine crops, 320 px, glass §12.7) and Cinematic (nine crops, 600 px, cinematic §8.7). Seven styles are shared, so eleven ids cover both.

## Subject (identical in every crop)

A young swordsman looking over his shoulder at a city at dusk. Only the style differs.

## Delivery

- One master per id at `brand/onboarding/styles/masters/{id}.png`: sRGB PNG, square, at least 1200 x 1200 (minimum 600 x 600). A non-square master is centre-cropped.
- One subject, one panel crop. No text, no signature, no watermark, no nudity, no gore.
- Line widths below are at the 320 px crop size (glass §12.7); scale them with the master.
- Nothing may be publisher art, a real series' cover or a real series' name.

## Rights

Drawn by the owner, or commissioned as work for hire and released under CC0 1.0. A generated draft may be used only if its licence allows CC0 release and nothing in it imitates a named artist (no artist names in prompts, no "in the style of" a person). Fill the master's row in `LICENSE.md` (`artist`, `date`, `licence` = `CC0-1.0`, `source` = `own work`, `commission` or `generated draft: <tool>`). A generated draft feeds Glass only; Cinematic accepts drawn art only (cinematic §8.7).

Credit in About > Licences: "Onboarding art (c) ManhwaManiacs contributors, CC0".

## The eleven ids

| id | Glass | Cinematic | Brief |
|---|---|---|---|
| `painted` | 1 | 1 | Full-colour webtoon painting: soft cel base, painted light, saturated teal-orange palette, no line art on the background |
| `cel` | 2 | 2 | Crisp cel shading: 2-tone shadows, 3 px black line, flat bright colours |
| `screentone` | 3 | 3 | Black-and-white screentone: 2 px ink line, dot tone at 20 % and 40 %, pure white paper |
| `manhua-3d` | 4 | 4 | Manhua 3D/CG: rendered figure, rim light, depth-of-field background |
| `watercolour` | 5 | none | Watercolour: wet edges, paper texture, muted blues and ochres, 1 px pencil line |
| `sketch` | 6 | 5 | Sketchy indie: loose 1 to 3 px graphite line, 2 flat spot colours |
| `retro` | 7 | 6 | Retro 1990s: thick 4 px line, airbrushed gradients, pastel sky |
| `pastel` | none | 7 | Soft pastel: 1 px coloured line (never black), flat pale peach `#FAD4C0`, mint `#CDEFE0` and lavender `#DCD0F5`, airbrushed blush, low contrast, no pure black anywhere |
| `noir` | none | 8 | High-contrast noir: pure black and pure white only, no mid greys, at least 60 % of the frame solid black, one hard rim light carving the silhouette, one slash of light across the city |
| `chibi` | 8 | 9 | Chibi comedy: 3-head-tall proportions, 3 px round line, candy palette, a sweat-drop symbol |
| `dark-realism` | 9 | none | Dark realism: heavy blacks, 1 px hatching, desaturated reds |

## Where outputs go

`node brand/onboarding/styles/intake.mjs` writes:

- Glass, 320 x 320 WebP under 40,000 bytes: `brand/onboarding/styles/{nn}-{id}.webp`, `frontend/public/onboarding/styles/glass/{nn}-{id}.webp`, `mobile/assets/onboarding/styles/glass/{nn}-{id}.webp`.
- Cinematic, 600 x 600 WebP at most 60,000 bytes: `frontend/public/onboarding/styles/{nn}-{id}.webp`, `mobile/assets/onboarding/styles/{nn}-{id}.webp`.

Cinematic's onboarding step shows typographic plates until all nine of its files exist (cinematic §8.7); Glass's step 5 needs its nine. `node brand/onboarding/styles/intake.mjs --check` lists what is still missing.
