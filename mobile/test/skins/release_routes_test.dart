// ignore_for_file: directives_ordering
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/utils/route_guard.dart' show kSplashHoldPath;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_screen.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

import 'cinematic/qa/qa_screens.dart';
import 'glass/qa/glass_qa_screens.dart';
import 'glass/shell/shell_rig.dart';

/// What a release build must never show: the mobile/29 shell demo, the dev gallery, fixtures and probes, pending stand-ins.
const _harnessText = ['Shell', 'Push a level', 'Clear accessory', 'Dive into a chapter', 'Row 0', 'Row 1', 'PENDING', 'This section arrives in the next update.'];
final _harnessType = RegExp(r'Demo|Gallery|DevIndex|DevPage|CalibrationPage|EngineProbePage|AuthFixture|^_Fixture$');

void expectNoHarness(String where) {
  for (final s in _harnessText) {
    expect(find.text(s, findRichText: true, skipOffstage: false), findsNothing, reason: '"$s" on $where');
  }
  expect(find.textContaining('PENDING', findRichText: true, skipOffstage: false), findsNothing, reason: 'PENDING on $where');
  expect(find.byWidgetPredicate((w) => w is Placeholder || _harnessType.hasMatch(w.runtimeType.toString()), skipOffstage: false), findsNothing, reason: 'a harness widget on $where');
}

/// Every route must be a real `ScreenId` screen, a known alias of one, or a redirect; every branch must open on a real screen.
void expectReleaseRouteTable(GoRouter router, String skin) {
  final aliases = {
    kSplashHoldPath,
    ...Routes.readerAliases,
    ...Routes.novelAliases,
    ...Routes.libraryAliases,
    ...Routes.settingsAliases,
    ...Routes.profileNewAliases,
    ...Routes.profileEditAliases,
  };
  final ids = {for (final id in ScreenId.values) id.id: id};
  final all = RouteBase.routesRecursively(router.configuration.routes).toList();
  for (final r in all.whereType<GoRoute>()) {
    expect(r.path.startsWith('/dev'), isFalse, reason: '$skin registers ${r.path}');
    if (r.redirect != null) continue;
    final named = ids[r.name];
    expect(named != null || aliases.contains(r.path), isTrue, reason: '$skin registers ${r.path}, which is no ScreenId screen');
  }
  for (final shell in all.whereType<StatefulShellRoute>()) {
    for (final b in shell.branches) {
      final first = b.initialLocation ?? b.defaultRoute?.path;
      expect(ScreenId.values.any((id) => id.path == first), isTrue, reason: '$skin has a branch that opens on $first');
    }
  }
}

/// Unmounts and lets every pending screen timer fire, so the test ends with none pending.
Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 120));
}

final _settingsSlugs = [for (final s in SettingsSection.values) if (s != SettingsSection.storage) s.slug];

void main() {
  group('Glass in a release build', () {
    final off = [glassDevRoutesProvider.overrideWithValue(false)];

    testWidgets('the route table holds real screens only, and every dock tab opens its real root', (t) async {
      final rig = await pumpGlassShell(t, extra: off);
      expectReleaseRouteTable(rig.router, 'Glass');
      for (final (tab, root) in [('Library', '/library'), ('Sources', '/sources'), ('You', '/more'), ('Home', '/')]) {
        await t.tap(dockTab(tab));
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(rig.at, root, reason: 'the $tab tab');
        expectNoHarness('the $tab tab');
      }
      await _end(t);
    });

    testWidgets('the You tab opens the You screen, also on a re-tap from a pushed level', (t) async {
      final rig = await pumpGlassShell(t, extra: off);
      await t.tap(dockTab('You'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(YouScreen), findsOneWidget);
      unawaited(rig.router.push(Routes.settings()));
      await t.pump(const Duration(milliseconds: 600));
      expect(rig.at, '/settings');
      await t.tap(dockTab('You'));
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 600));
      expect(rig.at, '/more');
      expect(find.byType(YouScreen), findsOneWidget);
      expectNoHarness('You');
      await _end(t);
    });

    testWidgets('a debug build still keeps the demo out of the You tab', (t) async {
      final rig = await pumpGlassShell(t);
      await t.tap(dockTab('You'));
      await t.pump(const Duration(milliseconds: 600));
      expect(rig.at, '/more');
      expect(find.byType(YouScreen), findsOneWidget);
      await _end(t);
    });

    final screens = [
      ...kGlassQaScreens,
      for (final slug in _settingsSlugs) GlassQaScreen(ScreenId.settings, '/settings/$slug'),
    ];
    for (final s in screens) {
      glassQaWidgets('no harness on ${s.location}', (t) async {
        final rig = await pumpGlassQa(t, s, extra: off);
        expectNoHarness(s.location);
        await disposeGlassQa(t, rig);
      });
    }
  });

  group('Cinematic in a release build', () {
    testWidgets('the route table holds real screens only', (t) async {
      final rig = await pumpQaScreen(t, kQaScreens.firstWhere((s) => s.id == ScreenId.tonight));
      expectReleaseRouteTable(rig.router, 'Cinematic');
      await disposeQa(t, rig);
    });

    final screens = [
      ...kQaScreens,
      for (final slug in _settingsSlugs) QaScreen(ScreenId.settings, '/settings/$slug'),
    ];
    for (final s in screens) {
      testWidgets('no harness on ${s.location}', (t) async {
        try {
          final rig = await pumpQaScreen(t, s);
          expectNoHarness(s.location);
          await disposeQa(t, rig);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  });
}
