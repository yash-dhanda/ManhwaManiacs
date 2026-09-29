# Glass soundscape layers: sources

Glass's six scenes (glass/DESIGN.md §9.4.2) each have three recorded layers, `bed`, `detail` and `tone`: 90 s seamless loops served as `/app/soundscapes/glass-{scene}-{layer}.{ogg,m4a}` (alias `/app/soundscapes/glass/{scene}-{layer}.{ext}`). Until a layer's two files exist, the apps play Glass's procedural layer for it (web/44, mobile/44).

**Deep** is synthesised by `design/sounds/render.mjs` (no third-party material). The other fifteen layers are **CC0 1.0 field recordings from freesound.org only**: no CC-BY, no Sampling+, nothing imitating a named work. For each one:

1. Pick a recording on freesound.org whose licence reads "Creative Commons 0" and that matches "What to look for". It must be at least 96 s long.
2. Download the original and save it as `design/sounds/incoming/glass/{scene}-{layer}.<its extension>` (for example `rain-bed.wav`). That folder is git-ignored: raw downloads never enter the repo.
3. Fill the row below: Freesound URL, Author, Licence (`CC0 1.0`), Original file name, and optionally Start (s) to choose where the 96 s window begins (empty: the steadiest 96 s is found automatically).
4. Run `node design/sounds/trim-loop.mjs`. It trims, loops, normalises (bed −26, detail −30, tone −32 LUFS, true peak ≤ −3 dBTP) and encodes the two files into `backend/media/soundscapes/glass/`, and fills Processing, LUFS, Size and SHA-256.
5. Commit the two new files and this file. `node design/sounds/trim-loop.mjs --check` lists what is still missing.

| Id | Scene | Layer | What to look for | Freesound URL | Author | Licence | Original file | Start (s) | Processing | LUFS | Size | SHA-256 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| glass-rain-bed | rain | bed | steady rain on a roof |  |  |  |  |  |  |  |  |  |
| glass-rain-detail | rain | detail | drips on a window pane |  |  |  |  |  |  |  |  |  |
| glass-rain-tone | rain | tone | low room tone |  |  |  |  |  |  |  |  |  |
| glass-wind-bed | wind | bed | wind through trees |  |  |  |  |  |  |  |  |  |
| glass-wind-detail | wind | detail | leaves and a creaking branch |  |  |  |  |  |  |  |  |  |
| glass-wind-tone | wind | tone | far drone |  |  |  |  |  |  |  |  |  |
| glass-ocean-bed | ocean | bed | waves on sand |  |  |  |  |  |  |  |  |  |
| glass-ocean-detail | ocean | detail | shingle drawback |  |  |  |  |  |  |  |  |  |
| glass-ocean-tone | ocean | tone | distant gulls |  |  |  |  |  |  |  |  |  |
| glass-hearth-bed | hearth | bed | fire bed |  |  |  |  |  |  |  |  |  |
| glass-hearth-detail | hearth | detail | crackles and embers |  |  |  |  |  |  |  |  |  |
| glass-hearth-tone | hearth | tone | night wind |  |  |  |  |  |  |  |  |  |
| glass-stream-bed | stream | bed | running water |  |  |  |  |  |  |  |  |  |
| glass-stream-detail | stream | detail | pebbles and a small fall |  |  |  |  |  |  |  |  |  |
| glass-stream-tone | stream | tone | birds far off |  |  |  |  |  |  |  |  |  |
| glass-deep-bed | deep | bed | synthesised drone in A (sines 55 + 82.41 Hz, 0.03 Hz chorus, pink noise under 300 Hz) | none (synthesised) | ManhwaManiacs (synthesised by design/sounds/render.mjs) | no third-party material | none |  | Synthesised: node design/sounds/synth.mjs loop/glass-deep-bed … --gain -24.26, then Opus + AAC 96k (commands below) | -26.0 (TP -16.9 dBTP) | ogg 968365 B, m4a 1103054 B | ogg 30dd21de4073def13c49ca6973d1a439b2050019d88afe7145a49f3d56b00392, m4a d640eaab561ef3c36f432c941816214264e85de8e5110e03cae23d8d6ca9f609 |
| glass-deep-detail | deep | detail | synthesised slow shimmer (A6 + E7, tremolo, reverb) | none (synthesised) | ManhwaManiacs (synthesised by design/sounds/render.mjs) | no third-party material | none |  | Synthesised: node design/sounds/synth.mjs loop/glass-deep-detail … --gain -30.05, then Opus + AAC 96k (commands below) | -30.0 (TP -25.1 dBTP) | ogg 1388145 B, m4a 1101156 B | ogg 2dd8ce1e3bc10e1726110d740b46e220a35915259b70276fa15016900e3ceea5, m4a b06aff0c742c7ba2aeb7041a3207cd45c1373b4cabff67641884728eaa04d78e |
| glass-deep-tone | deep | tone | synthesised soft pulses (110 Hz, 16 per loop) | none (synthesised) | ManhwaManiacs (synthesised by design/sounds/render.mjs) | no third-party material | none |  | Synthesised: node design/sounds/synth.mjs loop/glass-deep-tone … --gain -24.4, then Opus + AAC 96k (commands below) | -32.0 (TP -24.4 dBTP) | ogg 103670 B, m4a 131198 B | ogg e2d0a7ad8cae06eabd458a979f7b7e87771df77f1034eb2fbb38c7c66cbc633e, m4a 9594ef6c651c12db643ba26e7e3aee28b380ea89a3c2ced3659faeec67042f2a |

## Tools

- sox: not installed (no sudo on the render box, so apt/pacman could not run); fallback: node design/sounds/synth.mjs (Node v22.14.0)
- ffmpeg: ffmpeg version n9.0.2 Copyright (c) 2000-2026 the FFmpeg developers

## Deep: synthesised layers

### glass-deep-bed

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Deep: synthesised drone in A
- PRNG seed: mulberry32(FNV-1a("glass-deep-bed")) = 2268419550 (0x873555de)
- Bed 1 (0 dB): `synth 96 sine 55 sine 82.41 remix 1v1,2v1 chorus 0.7 0.9 50 0.4 0.03 2 -s`
- Bed 2 (-10 dB): `synth 96 pinknoise lowpass 300`
- Integrated loudness -26.0 LUFS (target -26), true peak -16.9 dBTP, gain -24.26 dB
- Seam: L: last -25.9 / first -25.6 dB RMS (diff 0.26), jump 0.0007; R: last -25.9 / first -25.6 dB RMS (diff 0.32), jump 0.0007
- `backend/media/soundscapes/glass/deep-bed.ogg`: 968365 bytes, SHA-256 30dd21de4073def13c49ca6973d1a439b2050019d88afe7145a49f3d56b00392
- `backend/media/soundscapes/glass/deep-bed.m4a`: 1103054 bytes, SHA-256 d640eaab561ef3c36f432c941816214264e85de8e5110e03cae23d8d6ca9f609

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/glass-deep-bed.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/glass-deep-bed design/sounds/.build/glass-deep-bed.wav --gain -24.26
ffmpeg -hide_banner -nostats -i design/sounds/.build/glass-deep-bed.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/glass-deep-bed.wav -c:a libopus -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/glass/deep-bed.ogg
ffmpeg -y -v error -i design/sounds/.build/glass-deep-bed.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/glass/deep-bed.m4a
```

### glass-deep-detail

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Deep: slow shimmer
- PRNG seed: mulberry32(FNV-1a("glass-deep-detail")) = 1190252550 (0x46f1d006)
- Bed 1 (0 dB): `synth 96 sine 1760 sine 2637.02 remix 1v0.501,2v0.501 tremolo 0.1 80 reverb 70 50 100`
- Integrated loudness -30.0 LUFS (target -30), true peak -25.1 dBTP, gain -30.05 dB
- Seam: L: last -37.6 / first -36.6 dB RMS (diff 1.04), jump 0.0022; R: last -37.6 / first -36.6 dB RMS (diff 1.04), jump 0.0022
- `backend/media/soundscapes/glass/deep-detail.ogg`: 1388145 bytes, SHA-256 2dd8ce1e3bc10e1726110d740b46e220a35915259b70276fa15016900e3ceea5
- `backend/media/soundscapes/glass/deep-detail.m4a`: 1101156 bytes, SHA-256 b06aff0c742c7ba2aeb7041a3207cd45c1373b4cabff67641884728eaa04d78e

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/glass-deep-detail.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/glass-deep-detail design/sounds/.build/glass-deep-detail.wav --gain -30.05
ffmpeg -hide_banner -nostats -i design/sounds/.build/glass-deep-detail.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/glass-deep-detail.wav -c:a libopus -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/glass/deep-detail.ogg
ffmpeg -y -v error -i design/sounds/.build/glass-deep-detail.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/glass/deep-detail.m4a
```

### glass-deep-tone

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Deep: soft pulses
- PRNG seed: mulberry32(FNV-1a("glass-deep-tone")) = 1309021091 (0x4e0613a3)
- Events `pulse` (0 dB, schedule {"type":"even","n":16,"offset":-0.2}): six variants `synth 0.4 sine 110 swell 0.4`, `synth 0.4 sine 110 swell 0.4`, `synth 0.4 sine 110 swell 0.4`, `synth 0.4 sine 110 swell 0.4`, `synth 0.4 sine 110 swell 0.4`, `synth 0.4 sine 110 swell 0.4`
- Integrated loudness -32.0 LUFS (target -32), true peak -24.4 dBTP, gain -24.4 dB
- Seam: L: last -32.6 / first -32.6 dB RMS (diff 0.00), jump 0.0009; R: last -32.6 / first -32.6 dB RMS (diff 0.00), jump 0.0009
- `backend/media/soundscapes/glass/deep-tone.ogg`: 103670 bytes, SHA-256 e2d0a7ad8cae06eabd458a979f7b7e87771df77f1034eb2fbb38c7c66cbc633e
- `backend/media/soundscapes/glass/deep-tone.m4a`: 131198 bytes, SHA-256 9594ef6c651c12db643ba26e7e3aee28b380ea89a3c2ced3659faeec67042f2a

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/glass-deep-tone.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/glass-deep-tone design/sounds/.build/glass-deep-tone.wav --gain -24.4
ffmpeg -hide_banner -nostats -i design/sounds/.build/glass-deep-tone.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/glass-deep-tone.wav -c:a libopus -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/glass/deep-tone.ogg
ffmpeg -y -v error -i design/sounds/.build/glass-deep-tone.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/glass/deep-tone.m4a
```
