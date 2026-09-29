# Cinematic soundscapes: sources

The eight Cinematic ambient loops (cinematic/DESIGN.md §9.4.2), served as `/app/soundscapes/{id}.{ogg,m4a}`. Every file is synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material. The owner may replace a loop with a CC0 1.0 recording later (see `design/sounds/trim-loop.mjs`), updating its section here.

Format: 90.000 s seamless loops, 48 kHz stereo, −26 LUFS integrated, true peak ≤ −3 dBTP; Ogg Vorbis 96 kb/s and AAC-LC 96 kb/s `.m4a`.

- sox: not installed (no sudo on the render box, so apt/pacman could not run); fallback: node design/sounds/synth.mjs (Node v22.14.0)
- ffmpeg: ffmpeg version n9.0.2 Copyright (c) 2000-2026 the FFmpeg developers

Synthesis runs `node design/sounds/synth.mjs loop/<id> <wav> --gain <dB>`: the sox-style chains below (from `design/sounds/recipes.json`) rendered by the pure-Node interpreter at the top of `synth.mjs`; beds 96 s per channel, then the 90 s equal-power loop (last 6 s cross-faded into the first 6 s), then events on the 90 s timeline modulo 90 s. `ffmpeg … ebur128` lines are the loudness measurements.

## projector-room

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: A soft hum with distant reel ticks.
- PRNG seed: mulberry32(FNV-1a("projector-room")) = 3808423049 (0xe2ffec89)
- Bed 1 (0 dB): `synth 96 brownnoise sinc 60-400 tremolo 0.2 20`
- Bed 2 (-18 dB): `synth 96 sine 50 sine 100 remix 1v1,2v0.251`
- Events `reel-tick` (-20 dB, schedule {"type":"periodic","period":0.041666666666666664,"jitter":0.03}): six variants `synth 0.004 whitenoise lowpass 2000`, `synth 0.004 whitenoise lowpass 2000`, `synth 0.004 whitenoise lowpass 2000`, `synth 0.004 whitenoise lowpass 2000`, `synth 0.004 whitenoise lowpass 2000`, `synth 0.004 whitenoise lowpass 2000`
- Integrated loudness -26.0 LUFS (target -26), true peak -13.9 dBTP, gain -10.06 dB
- Seam: L: last -26.1 / first -26.2 dB RMS (diff 0.09), jump 0.0002; R: last -27.7 / first -26.4 dB RMS (diff 1.30), jump 0.0013
- `backend/media/soundscapes/projector-room.ogg`: 1275057 bytes, SHA-256 cdb31ceebd7f132da0c24cac60c82b82b73756cd37ee8fa9bd7734952c22de04
- `backend/media/soundscapes/projector-room.m4a`: 1374450 bytes, SHA-256 54da5196455265b766e1a9de3071aa55b22fb5744d588a315ea8dec4f19daa60

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/projector-room.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/projector-room design/sounds/.build/projector-room.wav --gain -10.06
ffmpeg -hide_banner -nostats -i design/sounds/.build/projector-room.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/projector-room.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/projector-room.ogg
ffmpeg -y -v error -i design/sounds/.build/projector-room.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/projector-room.m4a
ffmpeg -y -v error -i design/sounds/.build/projector-room.wav -c:a aac -b:a 112k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/projector-room.m4a
```

## rain-on-glass

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Steady rain on a window.
- PRNG seed: mulberry32(FNV-1a("rain-on-glass")) = 3502227454 (0xd0bfbffe)
- Bed 1 (0 dB): `synth 96 pinknoise highpass 400 lowpass 6000`
- Bed 2 (-12 dB): `synth 96 brownnoise lowpass 200`
- Events `droplet` (-8 dB, random pan ±0.8, schedule {"type":"poisson","rate":[8,20],"drift":5}): six variants `synth 0.004 sine 2277.708 exp 0.004`, `synth 0.004 sine 2171.33 exp 0.004`, `synth 0.004 sine 3437.696 exp 0.004`, `synth 0.004 sine 3454.428 exp 0.004`, `synth 0.004 sine 2148.288 exp 0.004`, `synth 0.004 sine 3307.696 exp 0.004`
- Integrated loudness -26.0 LUFS (target -26), true peak -17.2 dBTP, gain -11.24 dB
- Seam: L: last -30.3 / first -30.2 dB RMS (diff 0.03), jump 0.0006; R: last -30.6 / first -30.2 dB RMS (diff 0.31), jump 0.0055
- `backend/media/soundscapes/rain-on-glass.ogg`: 1074310 bytes, SHA-256 e7ff0b458c7c6b1adc855939dc6136e4811f22f04ac31fe01dbe199884d2be6a
- `backend/media/soundscapes/rain-on-glass.m4a`: 1101133 bytes, SHA-256 a0de85e6505a52facfe0e0d41aa8bdbc85786ae133c30fc8f7930fd1dafc7ed7

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/rain-on-glass.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/rain-on-glass design/sounds/.build/rain-on-glass.wav --gain -11.24
ffmpeg -hide_banner -nostats -i design/sounds/.build/rain-on-glass.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/rain-on-glass.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/rain-on-glass.ogg
ffmpeg -y -v error -i design/sounds/.build/rain-on-glass.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/rain-on-glass.m4a
```

## night-city

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Distant traffic after dark.
- PRNG seed: mulberry32(FNV-1a("night-city")) = 2125038539 (0x7ea983cb)
- Bed 1 (0 dB): `synth 96 brownnoise lowpass 500 tremolo 0.05 40`
- Bed 2 (-22 dB): `synth 96 pinknoise highpass 3000`
- Events `horn` (-14 dB, random pan ±0.8, schedule {"type":"count","n":3}): six variants `synth 0.4 sine 392 sine 440 remix 1v0.5,2v0.5 swell 0.4 lowpass 1000 reverb 50 50 100`, `synth 0.4 sine 392 sine 440 remix 1v0.5,2v0.5 swell 0.4 lowpass 1000 reverb 50 50 100`, `synth 0.4 sine 392 sine 440 remix 1v0.5,2v0.5 swell 0.4 lowpass 1000 reverb 50 50 100`, `synth 0.4 sine 392 sine 440 remix 1v0.5,2v0.5 swell 0.4 lowpass 1000 reverb 50 50 100`, `synth 0.4 sine 392 sine 440 remix 1v0.5,2v0.5 swell 0.4 lowpass 1000 reverb 50 50 100`, `synth 0.4 sine 392 sine 440 remix 1v0.5,2v0.5 swell 0.4 lowpass 1000 reverb 50 50 100`
- Integrated loudness -26.0 LUFS (target -26), true peak -11.7 dBTP, gain -9.88 dB
- Seam: L: last -25.9 / first -26.6 dB RMS (diff 0.65), jump 0.0001; R: last -26.4 / first -26.8 dB RMS (diff 0.39), jump 0.0031
- `backend/media/soundscapes/night-city.ogg`: 1103525 bytes, SHA-256 17acd1d242a4fbffdfa918dbae0b13578be37926297e9cf2a05d87bf0932e3f3
- `backend/media/soundscapes/night-city.m4a`: 1100881 bytes, SHA-256 c2e8adcd72ee9e7f82fbd41229c7be7672c98659f5f86658aae8b58931d44afb

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/night-city.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/night-city design/sounds/.build/night-city.wav --gain -9.88
ffmpeg -hide_banner -nostats -i design/sounds/.build/night-city.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/night-city.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/night-city.ogg
ffmpeg -y -v error -i design/sounds/.build/night-city.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/night-city.m4a
```

## cafe

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Low voices and cups.
- PRNG seed: mulberry32(FNV-1a("cafe")) = 3070856776 (0xb7098e48)
- Bed 1 (0 dB): `synth 96 pinknoise sinc 300-3000 tremolo 3 30 tremolo 5.3 20`
- Bed 2 (-12 dB): `synth 96 brownnoise lowpass 200`
- Events `cup` (-10 dB, random pan ±0.8, schedule {"type":"poisson","rate":0.3}): six variants `synth 0.15 sine 3690.363 sine 8856.871 remix 1v1,2v0.316 exp 0.15`, `synth 0.15 sine 4875.364 sine 11700.875 remix 1v1,2v0.316 exp 0.15`, `synth 0.15 sine 3105.631 sine 7453.514 remix 1v1,2v0.316 exp 0.15`, `synth 0.15 sine 3488.564 sine 8372.553 remix 1v1,2v0.316 exp 0.15`, `synth 0.15 sine 3383.117 sine 8119.482 remix 1v1,2v0.316 exp 0.15`, `synth 0.15 sine 4558.918 sine 10941.403 remix 1v1,2v0.316 exp 0.15`
- Integrated loudness -26.0 LUFS (target -26), true peak -12.1 dBTP, gain -6.64 dB
- Seam: L: last -29.1 / first -28.8 dB RMS (diff 0.36), jump 0.0004; R: last -29.4 / first -28.6 dB RMS (diff 0.76), jump 0.0028
- `backend/media/soundscapes/cafe.ogg`: 1024075 bytes, SHA-256 2c3d8ee6b097fcb8fd2a247d1de711de73b6014de63fee6bbfefcd1dff4f5f44
- `backend/media/soundscapes/cafe.m4a`: 1101635 bytes, SHA-256 092e74b56baf1d84a8f7790882ea20821cd93f7bdb17a6aedba629cf773c9ac3

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/cafe.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/cafe design/sounds/.build/cafe.wav --gain -6.64
ffmpeg -hide_banner -nostats -i design/sounds/.build/cafe.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/cafe.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/cafe.ogg
ffmpeg -y -v error -i design/sounds/.build/cafe.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/cafe.m4a
```

## night-wind

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Wind across an empty street.
- PRNG seed: mulberry32(FNV-1a("night-wind")) = 2734812810 (0xa301ee8a)
- Bed 1 (0 dB): `synth 96 brownnoise windbp 300 150 0.08 0.7q 1 0.05 tremolo 0.05 40`
- Integrated loudness -26.0 LUFS (target -26), true peak -13.4 dBTP, gain -7.85 dB
- Seam: L: last -29.1 / first -28.8 dB RMS (diff 0.35), jump 0.0007; R: last -28.9 / first -28.8 dB RMS (diff 0.12), jump 0.0001
- `backend/media/soundscapes/night-wind.ogg`: 1028398 bytes, SHA-256 879f4c40bbcd5f590245a0584ae7d9e809ab7dd36c3157fa909fc5f99c30cfc3
- `backend/media/soundscapes/night-wind.m4a`: 1100923 bytes, SHA-256 c7ae6f0793321781df0f3ce183fdd99799f2e1cb0783d1fa730187bba0ad051d

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/night-wind.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/night-wind design/sounds/.build/night-wind.wav --gain -7.85
ffmpeg -hide_banner -nostats -i design/sounds/.build/night-wind.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/night-wind.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/night-wind.ogg
ffmpeg -y -v error -i design/sounds/.build/night-wind.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/night-wind.m4a
```

## low-drone

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: A deep, even hum.
- PRNG seed: mulberry32(FNV-1a("low-drone")) = 2840939422 (0xa9554b9e)
- Bed 1 (0 dB): `synth 96 sine 55 sine 82.41 sine 110 remix 1v1,2v1,3v0.251 chorus 0.6 0.9 55 0.4 0.25 2 -s`
- Bed 2 (-10 dB): `synth 96 pinknoise lowpass 300`
- Integrated loudness -26.0 LUFS (target -26), true peak -16.9 dBTP, gain -22.31 dB
- Seam: L: last -25.6 / first -25.5 dB RMS (diff 0.12), jump 0.0009; R: last -25.7 / first -25.5 dB RMS (diff 0.19), jump 0.0010
- `backend/media/soundscapes/low-drone.ogg`: 663787 bytes, SHA-256 ee43e15ad91982335a489182b4b7d6db2b0166bb41940f85596fb643e4ff0908
- `backend/media/soundscapes/low-drone.m4a`: 1106398 bytes, SHA-256 3454efe5a907589661daf084b3b3ba471ab3d1783f6d046db6b7512bcb90de32

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/low-drone.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/low-drone design/sounds/.build/low-drone.wav --gain -22.31
ffmpeg -hide_banner -nostats -i design/sounds/.build/low-drone.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/low-drone.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/low-drone.ogg
ffmpeg -y -v error -i design/sounds/.build/low-drone.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/low-drone.m4a
```

## afternoon-park

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Birds and far-off voices.
- PRNG seed: mulberry32(FNV-1a("afternoon-park")) = 4083754598 (0xf3692666)
- Bed 1 (0 dB): `synth 96 pinknoise lowpass 2000`
- Bed 2 (-10 dB): `synth 96 pinknoise sinc 300-2500 tremolo 4 50`
- Events `chirp` (-6 dB, random pan ±0.8, schedule {"type":"poisson","rate":0.25,"group":{"size":[2,4],"gap":0.08}}): six variants `synth 0.087 sine 2500:4500 swell 0.087`, `synth 0.11 sine 2500:4500 swell 0.11`, `synth 0.106 sine 2500:4500 swell 0.106`, `synth 0.062 sine 2500:4500 swell 0.062`, `synth 0.096 sine 2500:4500 swell 0.096`, `synth 0.093 sine 2500:4500 swell 0.093`
- Integrated loudness -26.0 LUFS (target -26), true peak -10.6 dBTP, gain -11.31 dB
- Seam: L: last -27.2 / first -27.1 dB RMS (diff 0.02), jump 0.0042; R: last -27.2 / first -26.7 dB RMS (diff 0.48), jump 0.0045
- `backend/media/soundscapes/afternoon-park.ogg`: 1059919 bytes, SHA-256 c225039246f5b0cfa00ec601a8d7a0727827d162769c9e4a22c5efb9bb012aee
- `backend/media/soundscapes/afternoon-park.m4a`: 1100929 bytes, SHA-256 77b2428c193d5b82b16ebd0c6ad29f76e1b51e08a63cb505d59b00382c22a5d0

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/afternoon-park.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/afternoon-park design/sounds/.build/afternoon-park.wav --gain -11.31
ffmpeg -hide_banner -nostats -i design/sounds/.build/afternoon-park.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/afternoon-park.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/afternoon-park.ogg
ffmpeg -y -v error -i design/sounds/.build/afternoon-park.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/afternoon-park.m4a
```

## temple-bells

- Origin: Synthesised for ManhwaManiacs by `design/sounds/render.mjs`; no third-party material.
- Description: Slow bells over a quiet courtyard.
- PRNG seed: mulberry32(FNV-1a("temple-bells")) = 1472009587 (0x57bd1573)
- Bed 1 (0 dB): `synth 96 pinknoise lowpass 1000`
- Events `bell` (6 dB, random pan ±0.8, schedule {"type":"interval","min":7,"max":11}): six variants `synth 6 sine 261.63 sine 722.099 sine 1412.802 sine 2336.356 remix 1v1,2v0.501,3v0.251,4v0.126 exp 6 reverb 60 50 100`, `synth 6 sine 261.63 sine 722.099 sine 1412.802 sine 2336.356 remix 1v1,2v0.501,3v0.251,4v0.126 exp 6 reverb 60 50 100`, `synth 6 sine 261.63 sine 722.099 sine 1412.802 sine 2336.356 remix 1v1,2v0.501,3v0.251,4v0.126 exp 6 reverb 60 50 100`, `synth 6 sine 261.63 sine 722.099 sine 1412.802 sine 2336.356 remix 1v1,2v0.501,3v0.251,4v0.126 exp 6 reverb 60 50 100`, `synth 6 sine 196 sine 540.96 sine 1058.4 sine 1750.28 remix 1v1,2v0.501,3v0.251,4v0.126 exp 6 reverb 60 50 100`, `synth 6 sine 293.66 sine 810.502 sine 1585.764 sine 2622.384 remix 1v1,2v0.501,3v0.251,4v0.126 exp 6 reverb 60 50 100`
- Integrated loudness -26.0 LUFS (target -26), true peak -4.2 dBTP, gain -15.94 dB
- Seam: L: last -32.4 / first -32.7 dB RMS (diff 0.36), jump 0.0021; R: last -32.6 / first -33.0 dB RMS (diff 0.41), jump 0.0017
- `backend/media/soundscapes/temple-bells.ogg`: 1008832 bytes, SHA-256 77da140cac1b4e167ddad5cb36236ec207496166aa202639145d8e69723b42e6
- `backend/media/soundscapes/temple-bells.m4a`: 1100754 bytes, SHA-256 447ad366e7f5f17d8d22bef383b9b400fe8084685197ba63e5ee841452db447a

Commands, in order:

```
ffmpeg -hide_banner -nostats -i design/sounds/.build/temple-bells.wav -af ebur128=peak=true -f null -
node design/sounds/synth.mjs loop/temple-bells design/sounds/.build/temple-bells.wav --gain -15.94
ffmpeg -hide_banner -nostats -i design/sounds/.build/temple-bells.wav -af ebur128=peak=true -f null -
ffmpeg -y -v error -i design/sounds/.build/temple-bells.wav -c:a libvorbis -b:a 96k -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/temple-bells.ogg
ffmpeg -y -v error -i design/sounds/.build/temple-bells.wav -c:a aac -b:a 96k -movflags +faststart -fflags +bitexact -flags:a +bitexact -map_metadata -1 backend/media/soundscapes/temple-bells.m4a
```
