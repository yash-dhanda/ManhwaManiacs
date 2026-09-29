# Phosphor sources

- Archive: https://pub.dev/api/archives/phosphor_flutter-2.1.0.tar.gz
- SHA-256: `8a14f238f28a0b54842c5a4dc20676598dd4811fcba284ed828bd5a262c11fde`
- Copied: `lib/fonts/{Phosphor,Phosphor-Thin,Phosphor-Light,Phosphor-Bold,Phosphor-Fill,Phosphor-Duotone}.ttf` to `mobile/assets/fonts/phosphor/` (byte-identical); `codepoints.json` extracted from `lib/src/phosphor_icons_{regular,thin,light,bold,fill,duotone}.dart` (1,512 icons per weight). `cell-signal-none` and `wifi-none` have no duotone secondary in the archive, so their `duotone` array holds only the primary.
- Custom-glyph references: `@phosphor-icons/core@2.1.1` (`npm pack`, SHA-256 `313332be6190b724da24107addd781799b48bf76b13963f24501112ffe1baadd`), `assets/{light,regular,fill,duotone}/user-sound*.svg` and `assets/{regular,duotone,fill}/sparkle*.svg`.
- Why `phosphor_flutter` is not a dependency: Flutter 3.44 declares `final class IconData` and `phosphor_flutter` 2.1.0 declares `class PhosphorIconData extends IconData`, so the package cannot compile; generated plain `IconData` constants replace it.

## Licence (from the archive's `LICENSE`)

```
MIT License

Copyright (c) 2020-2021 Phosphor Icons

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
