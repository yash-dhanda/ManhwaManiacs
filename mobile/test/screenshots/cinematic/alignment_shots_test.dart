// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_screen.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../skins/cinematic/downloads/downloads_rig.dart' show rigTheme;
import '../../skins/cinematic/qa/qa_screens.dart';
import '../../skins/cinematic/settings/settings_rig.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The alignment pass: every Cinematic screen at both iPhone widths and two text scales, plus each
/// Settings section at full length. Only writes when `MM_PROOF_DIR` is set:
///
///   MM_PROOF_DIR=/tmp/align flutter test test/screenshots/cinematic/alignment_shots_test.dart
const _sizes = {'390': Size(390, 844), '430': Size(430, 932)};
const _scales = [1.0, 1.3];

class _Configurator implements SessionConfigurator {
  @override
  Future<void> configure(AudioSessionConfiguration c) async {}
  @override
  Future<void> setActive(bool a) async {}
}

class _Engine implements CueEngine {
  @override
  Future<void> init() async {}
  @override
  Future<dynamic> loadAsset(String path) async => path;
  @override
  Future<dynamic> play(dynamic source, {required double volume}) async => 1;
  @override
  void setRelativePlaySpeed(dynamic handle, double rate) {}
}

Widget _settings(String slug) => MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: rigTheme(TargetPlatform.iOS),
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (c, s) => SettingsScreen(slug: slug == 'contents' ? null : slug, location: '/settings/$slug')),
        GoRoute(path: '/:rest(.*)', builder: (c, s) => const SizedBox()),
      ]),
      builder: (context, child) => CineToastHost(child: child!),
    );

void main() {
  setUpAll(loadAppFonts);

  group('screens', () {
    for (final s in kQaScreens) {
      for (final size in _sizes.entries) {
        for (final scale in _scales) {
          testWidgets('${s.id.id} ${size.key} x$scale', (t) async {
            final rig = await pumpQaScreen(t, s, size: size.value, textScale: scale, boundaryKey: kSkinShotKey);
            final dir = proofDir;
            if (dir != null) await writeShot(t, find.byKey(kSkinShotKey), '$dir/screens/${s.id.id}-${size.key}-x$scale.png', pixelRatio: 1.5);
            await disposeQa(t, rig);
          });
        }
      }
    }
  });

  const slugs = ['contents', 'profile', 'appearance', 'reading-manga', 'reading-novels', 'listen', 'ambient', 'storage', 'content', 'feedback', 'notifications', 'server', 'admin', 'diagnostics', 'about', 'security', 'members', 'backup'];
  group('settings', () {
    for (final slug in slugs) {
      for (final w in const [390.0, 430.0]) {
        for (final scale in _scales) {
          testWidgets('settings $slug $w x$scale', (t) async {
            final r = SettingsRig();
            const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
            t.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async => Directory.systemTemp.path);
            addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
            SharedPreferences.setMockInitialValues(r.prefs);
            final prefs = await SharedPreferences.getInstance();
            final audio = SkinAudio.forTest(_Configurator(), _Engine())..bind(skin: SkinId.cinematic, userId: 1, profileId: 1, prefs: prefs);
            // Tall: the whole section in one frame.
            await captureSkinWidget(
              t,
              name: 'settings-$slug-${w.round()}-x$scale',
              size: SkinShotSize('tall', Size(w, 2600), 1.5, EdgeInsets.only(top: 47, bottom: 34)),
              child: _settings(slug),
              overrides: settingsOverrides(r, prefs, audio),
              textScale: scale,
              settle: (t) async {
                for (var i = 0; i < 2200; i += 100) {
                  await t.pump(const Duration(milliseconds: 100));
                }
              },
            );
          });
        }
      }
    }
  });

  // The shared overlays and rows, through the primitives gallery (as mobile-05 drives it).
  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f, warnIfMissed: false);
    for (var i = 0; i < 24; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  final overlays = <(String, String, double, String?)>[
    ('rows', 'rows', 4200, null),
    ('tabs', 'tabs', 900, null),
    ('sheet', 'sheets', 900, 'g-sheet-basic'),
    ('dialog', 'dialogs', 1000, 'g-dialog-destructive'),
    ('dialog-username', 'dialogs', 1000, 'g-dialog-heavy-username'),
    ('dialog-ack', 'dialogs', 1000, 'g-dialog-heavy-ack'),
  ];
  group('overlays', () {
    for (final (name, section, height, key) in overlays) {
      for (final w in const [390.0, 430.0]) {
        for (final scale in _scales) {
          testWidgets('overlay $name $w x$scale', (t) async {
            await captureSkinWidget(
              t,
              name: 'overlay-$name-${w.round()}-x$scale',
              size: SkinShotSize('tall', Size(w, height), 1.5, EdgeInsets.only(top: 47, bottom: 34)),
              textScale: scale,
              settle: (t) async {
                await settleShot(t);
                if (key != null) await tap(t, key);
              },
              child: MaterialApp(debugShowCheckedModeBanner: false, home: CinePrimitivesGalleryPage(section: section)),
            );
            await t.pumpWidget(const SizedBox());
            await t.pump(const Duration(seconds: 12));
          });
        }
      }
    }
  });
}
