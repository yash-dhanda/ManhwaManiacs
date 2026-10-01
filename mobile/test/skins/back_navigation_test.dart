// ignore_for_file: directives_ordering
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/back_parent.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screenshots/support/shot_harness.dart' show loadAppFonts;
import 'cinematic/qa/qa_screens.dart';
import 'glass/qa/glass_qa_screens.dart';

/// Every registered non-root route of both skins, opened cold (a deep link, the skin-switch return
/// route: nothing beneath it), shows a Back (or Close, or Search's Cancel) control, and tapping it, or Android back,
/// lands on the route's parent instead of a dead end. The QA lists hold one entry per `ScreenId`.
void main() {
  // Real fonts: Ahem's square glyphs overflow the Library's content-mode switch the Back lands on.
  setUpAll(loadAppFonts);
  final backLabel = RegExp(r'^(Back|Close|Cancel)\b');

  /// The first on-screen Back, Close or Cancel control's semantics node.
  SemanticsNode? backNode(WidgetTester t) {
    final hits = find.semantics.byPredicate((n) => backLabel.hasMatch(n.label) && n.getSemanticsData().hasAction(SemanticsAction.tap));
    return hits.evaluate().isEmpty ? null : hits.evaluate().first;
  }

  String path(String loc) => Uri.parse(loc).path;

  List<String> labels() => [for (final n in find.semantics.byPredicate((n) => n.label.isNotEmpty).evaluate()) n.label.replaceAll('\n', ' | ')];

  for (final skin in SkinId.values) {
    test('${skin.name}: every parent chain ends on a root, through routes that exist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [skinIdProvider.overrideWithValue(skin), sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      final router = c.read(skinRouterProvider);
      for (final id in ScreenId.values) {
        var loc = id.path.replaceAllMapped(RegExp(r':\w+'), (_) => '7');
        for (var hops = 0;; hops++) {
          expect(hops, lessThan(5), reason: '${id.id}: no root above $loc');
          final up = backParentOf(loc, glass: skin == SkinId.glass);
          if (up == null) break;
          expect(router.configuration.findMatch(Uri.parse(up)).isError, isFalse, reason: '${id.id}: parent $up is not a route');
          loc = up;
        }
      }
    });
  }

  group('Cinematic', () {
    for (final s in kQaScreens) {
      final parent = backParentOf(s.location, glass: false);
      if (parent == null) continue;
      for (final android in [false, true]) {
        testWidgets('${s.id.id} ${android ? 'Android back' : 'Back control'} goes to $parent', (t) async {
          final h = t.ensureSemantics();
          debugDefaultTargetPlatformOverride = android ? TargetPlatform.android : TargetPlatform.iOS;
          try {
            final rig = await pumpQaScreen(t, s, platform: debugDefaultTargetPlatformOverride!);
            expect(path(rig.at), path(s.location), reason: 'mounted cold');
            if (android) {
              await t.binding.handlePopRoute();
            } else {
              final node = backNode(t);
              expect(node, isNotNull, reason: '${s.id.id} has no Back control; it shows ${labels()}');
              t.semantics.tap(find.semantics.byPredicate((n) => n.id == node!.id));
            }
            for (var i = 0; i < 12; i++) {
              await t.pump(const Duration(milliseconds: 100));
            }
            expect(path(rig.at), parent);
            await disposeQa(t, rig);
          } finally {
            debugDefaultTargetPlatformOverride = null;
            h.dispose();
          }
        });
      }
    }
  });

  group('Glass', () {
    for (final s in kGlassQaScreens) {
      final parent = backParentOf(s.location, glass: true);
      if (parent == null) continue;
      for (final android in [false, true]) {
        glassQaWidgets('${s.id.id} ${android ? 'Android back' : 'Back control'} goes to $parent', (t) async {
          final h = t.ensureSemantics();
          try {
            final rig = await pumpGlassQa(t, s, platform: android ? TargetPlatform.android : TargetPlatform.iOS);
            expect(path(rig.at), path(s.location), reason: 'mounted cold');
            if (android) {
              await t.binding.handlePopRoute();
            } else {
              final node = backNode(t);
              expect(node, isNotNull, reason: '${s.id.id} has no Back control; it shows ${labels()}');
              t.semantics.tap(find.semantics.byPredicate((n) => n.id == node!.id));
            }
            for (var i = 0; i < 12; i++) {
              await t.pump(const Duration(milliseconds: 100));
            }
            // A followed series' Back goes to the library (glass 8.12, `seriesBack`); Android back to its parent.
            expect(path(rig.at), s.id == ScreenId.feature && !android ? anyOf(parent, '/library') : parent);
            await disposeGlassQa(t, rig);
          } finally {
            h.dispose();
          }
        });
      }
    }
  });
}
