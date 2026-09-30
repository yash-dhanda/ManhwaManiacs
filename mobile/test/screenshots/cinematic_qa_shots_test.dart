import 'dart:async';

// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import '../skins/cinematic/library/library_test_support.dart' show ShelfLibrary, shelfSeries;
import '../skins/cinematic/qa/qa_screens.dart';
import 'support/shot_harness.dart';
import 'support/skin_shots.dart' show kSkinShotKey, proofDir;

/// E: mobile/24 proof captures of every `ScreenId`, written only when `MM_PROOF_DIR` is set (each
/// group has its own folder; the verification runs them one at a time with `--plain-name`).
/// The harness renders with the test renderer: motion and 120 Hz are the device pass.
class _Legible extends A11yPrefsNotifier {
  @override
  A11yPrefs build() => const A11yPrefs(legible: true);
}

Future<void> _shot(WidgetTester t, String file, {double ratio = 1}) async {
  final dir = proofDir;
  if (dir == null) return;
  await writeShot(t, find.byKey(kSkinShotKey), '$dir/$file', pixelRatio: ratio);
}

void main() {
  setUpAll(loadAppFonts);

  group('mobile-24 screens', () {
    for (final s in kQaScreens) {
      for (final e in kQaSizes.entries) {
        for (final grid in const [false, true]) {
          testWidgets('${s.id.id} ${e.key}${grid ? ' grid' : ''}', (t) async {
            final rig = await pumpQaScreen(t, s,
                size: e.value,
                boundaryKey: kSkinShotKey,
                extra: [if (grid) layoutGridOverlayProvider.overrideWith((ref) => true)]);
            final w = e.value.width.round(), h = e.value.height.round();
            await _shot(t, grid ? 'cinematic-${s.id.id}-grid-${e.key}.png' : 'cinematic-${s.id.id}-${w}x$h.png', ratio: e.key == 'phone' ? 2 : 1);
            await disposeQa(t, rig);
          });
        }
      }
    }
  });

  group('mobile-24 states', () {
    // The loading, empty, error and offline states the fixtures can produce. Screens whose
    // states need the network (feature, reader, novel) keep their own proof in mobile-1x/2x.
    final states = <String, Map<ScreenId, ShelfLibrary Function()>>{
      'loading': {
        ScreenId.library: () => ShelfLibrary(all: [shelfSeries(1)], listGate: Completer<void>()),
      },
      'empty': {
        ScreenId.library: () => ShelfLibrary(all: const []),
      },
      'error': {
        ScreenId.library: () => ShelfLibrary(all: [shelfSeries(1)], listError: null)..failList = true,
      },
    };
    for (final st in states.entries) {
      for (final e in st.value.entries) {
        for (final size in const ['phone', 'tablet']) {
          testWidgets('${e.key.id} ${st.key} $size', (t) async {
            final s = kQaScreens.firstWhere((x) => x.id == e.key);
            final lib = e.value();
            final rig = await pumpQaScreen(t, s, size: kQaSizes[size]!, boundaryKey: kSkinShotKey, lib: lib);
            await _shot(t, '${e.key.id}-${st.key}-$size.png', ratio: size == 'phone' ? 2 : 1);
            await disposeQa(t, rig);
          });
        }
      }
    }
    for (final id in const [ScreenId.history, ScreenId.bookmarks, ScreenId.updates, ScreenId.collections, ScreenId.downloads, ScreenId.discover, ScreenId.numbers, ScreenId.circle]) {
      for (final size in const ['phone', 'tablet']) {
        testWidgets('${id.id} offline-or-empty $size', (t) async {
          final s = kQaScreens.firstWhere((x) => x.id == id);
          // No `more`: the data layer answers offline or empty, the state the contract defines.
          final rig = await pumpQaScreen(t, QaScreen(s.id, s.location), size: kQaSizes[size]!, boundaryKey: kSkinShotKey);
          await _shot(t, '${id.id}-empty-$size.png', ratio: size == 'phone' ? 2 : 1);
          await disposeQa(t, rig);
        });
      }
    }
  });

  group('mobile-24 a11y', () {
    for (final s in kQaScreens) {
      testWidgets('${s.id.id} scale2', (t) async {
        final rig = await pumpQaScreen(t, s, textScale: 2.0, boundaryKey: kSkinShotKey);
        await _shot(t, '${s.id.id}-scale2-phone.png', ratio: 2);
        await disposeQa(t, rig);
      });
      testWidgets('${s.id.id} bold', (t) async {
        t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(boldText: true);
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        final rig = await pumpQaScreen(t, s, boundaryKey: kSkinShotKey);
        await _shot(t, '${s.id.id}-bold-phone.png', ratio: 2);
        await disposeQa(t, rig);
      });
      testWidgets('${s.id.id} contrast', (t) async {
        t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(highContrast: true);
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        final rig = await pumpQaScreen(t, s, boundaryKey: kSkinShotKey);
        await _shot(t, '${s.id.id}-contrast-phone.png', ratio: 2);
        await disposeQa(t, rig);
      });
      testWidgets('${s.id.id} legible', (t) async {
        final rig = await pumpQaScreen(t, s, boundaryKey: kSkinShotKey, extra: [a11yPrefsProvider.overrideWith(_Legible.new)]);
        await _shot(t, '${s.id.id}-legible-phone.png', ratio: 2);
        await disposeQa(t, rig);
      });
    }
  });
}
