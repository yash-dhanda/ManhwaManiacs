# Glass alternate icon: registration (applied by release/01, not before)

Everything below is written down and deliberately NOT applied while `flags.glass_available` is `false`
(`design/contract.json`). Apply all three parts in the same change that sets it to `true`;
`node brand/check.mjs` fails on a half-applied state in either direction.

The resources these edits point at already exist and are inert: `mipmap-*/ic_launcher_glass.png`,
`mipmap-anydpi-v26/ic_launcher_glass.xml`, `drawable-*/ic_launcher_glass_{foreground,background,monochrome}.png`,
`mobile/ios/Runner/AppIcon-Glass.icon`, `mobile/ios/Runner/Assets.xcassets/AppIcon-Glass.appiconset`.

## Android: `mobile/android/app/src/main/AndroidManifest.xml`

1. In `.MainActivity` keep the activity, `android:exported="true"` and its NormalTheme `<meta-data>`; remove its MAIN/LAUNCHER `<intent-filter>`.
2. After `.MainActivity`, inside `<application>`, add:

```xml
<activity-alias android:name=".CinematicIcon" android:targetActivity=".MainActivity"
    android:label="Maniacs" android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher"
    android:enabled="true" android:exported="true">
    <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity-alias>
<activity-alias android:name=".GlassIcon" android:targetActivity=".MainActivity"
    android:label="Maniacs" android:icon="@mipmap/ic_launcher_glass" android:roundIcon="@mipmap/ic_launcher_glass"
    android:enabled="false" android:exported="true">
    <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity-alias>
<service android:name="com.solusibejo.flutter_dynamic_icon_plus.FlutterDynamicIconPlusService"
    android:stopWithTask="false" />
```

3. Dart (`flutter_dynamic_icon_plus` 1.4.1). The plugin compares fully qualified class names; `namespace` and `applicationId` are both `com.manhwamaniacs.reader`:
   - Glass: `setAlternateIconName(iconName: 'com.manhwamaniacs.reader.GlassIcon', blacklistBrands: [], blacklistManufactures: [], blacklistModels: [])`
   - Cinematic: `setAlternateIconName(iconName: 'com.manhwamaniacs.reader.CinematicIcon', blacklistBrands: [], blacklistManufactures: [], blacklistModels: [])`
   - The plugin's service applies the alias when the task is removed; glass §8.25.2 step 4 queues the call until `AppLifecycleState.paused`.
4. Release-note line (required): "Moving the launcher to an activity alias makes existing home-screen shortcuts to `.MainActivity` stop working once; re-add the icon."

## iOS: `mobile/ios/Runner.xcodeproj/project.pbxproj`

- Add a `PBXFileReference` for the bundle, as a child of the Runner group:
  `<ID1> /* AppIcon-Glass.icon */ = {isa = PBXFileReference; lastKnownFileType = folder.iconcomposer.icon; path = "AppIcon-Glass.icon"; sourceTree = "<group>"; };`
- Add a `PBXBuildFile` `<ID2> /* AppIcon-Glass.icon in Resources */ = {isa = PBXBuildFile; fileRef = <ID1> /* AppIcon-Glass.icon */; };` and list it in the Runner target's Resources build phase. `<ID1>` and `<ID2>` are 24-character uppercase hex ids that do not already occur in the file.
- In the Runner target's Debug, Release and Profile configurations, next to `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` add:
  `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "AppIcon-Glass";`
- `actool` then writes `CFBundleAlternateIcons` into the built `Info.plist`; no hand-written plist entry. The `.icon` bundle and `AppIcon-Glass.appiconset` share the name `AppIcon-Glass`: Xcode 26 uses the bundle, older systems the asset set.
- Dart: Glass `setAlternateIconName(iconName: 'AppIcon-Glass')`; Cinematic `setAlternateIconName(iconName: null)` (the primary `AppIcon`).

## CI (glass §12.2, Xcode 26 pin)

- `.github/workflows/ios-build.yml`: before the build step, on a runner image that carries Xcode 26, add
  `- uses: maxim-lobanov/setup-xcode@v1` with `with: { xcode-version: '26.0' }`.
- `codemagic.yaml`: set `xcode: 26.0`.
- The iOS dry run must show `actool` compiling `AppIcon-Glass.icon`.

## Gate

`brand/check.mjs` ("registration gate"): while `glass_available` is `false` it fails if `AndroidManifest.xml` contains
`activity-alias` or `FlutterDynamicIconPlusService`, or `project.pbxproj` contains `AppIcon-Glass` or
`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`; while `true` it fails if any is missing.
