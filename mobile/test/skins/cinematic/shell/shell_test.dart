import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/nav_map.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/shell.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/thumb_index.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

class _Unread extends UnreadCountNotifier {
  _Unread(this.n);
  final int n;
  @override
  int build() => n;
}

class _Rig {
  _Rig(this.router, this.container);
  final GoRouter router;
  final ProviderContainer container;
  String get at => cineLocationOf(router);
}

Future<_Rig> _pump(WidgetTester t, {int unread = 0, int downloads = 0, String start = '/'}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    skinIdProvider.overrideWithValue(SkinId.cinematic),
    authenticatedAuthOverride(),
    activeProfileOverride(),
    profileSessionReadyOverride(),
    unreadNotificationCountProvider.overrideWith(() => _Unread(unread)),
    activeDownloadCountProvider.overrideWithValue(downloads),
    setupCompletedProvider.overrideWithValue(true),
    tonightIdleOverride(),
  ],);
  addTearDown(c.dispose);
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = c.read(skinRouterProvider);
  if (start != '/') router.go(start);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      theme: CinematicSkin.baseTheme,
      routerConfig: router,
      builder: (context, child) => CineAppFrame(splash: false, child: child!),
    ),
  ),);
  await t.pumpAndSettle();
  return _Rig(router, c);
}

Finder _tab(String label) => find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          (w.properties.button ?? false) &&
          w.properties.selected != null &&
          (w.properties.label ?? '').toLowerCase().startsWith(label.toLowerCase()),
    );

void main() {
  testWidgets('five tabs, each at least 44 x 44 (iOS) / 48 x 48 (Android)', (t) async {
    await _pump(t);
    final min = defaultTargetPlatform == TargetPlatform.android ? 48.0 : 44.0;
    for (final label in ['Tonight', 'Library', 'Discover', 'Downloads', 'Index']) {
      final size = t.getSize(_tab(label));
      expect(size.width, greaterThanOrEqualTo(min), reason: label);
      expect(size.height, greaterThanOrEqualTo(min), reason: label);
    }
    expect(t.getSize(find.byType(CineThumbIndex)).height, 56);
  }, variant: TargetPlatformVariant.all(),);

  testWidgets('the notch sits at the top edge of the active tab and slides to the next', (t) async {
    final rig = await _pump(t);
    Rect notch() {
      final n = find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 24 && w.constraints?.maxHeight == 2);
      return t.getRect(n.first);
    }

    final tonight = t.getRect(_tab('Tonight'));
    expect(notch().center.dx, closeTo(tonight.center.dx, 1));
    await t.tap(_tab('Downloads'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 160));
    // Mid-slide: between the two cells.
    expect(notch().center.dx, greaterThan(tonight.center.dx));
    await t.pumpAndSettle();
    expect(notch().center.dx, closeTo(t.getRect(_tab('Downloads')).center.dx, 1));
    expect(rig.at, '/downloads');
  });

  testWidgets('the Library badge shows the unread count', (t) async {
    await _pump(t, unread: 3);
    expect(find.descendant(of: find.byType(CineThumbIndex), matching: find.text('3')), findsOneWidget);
    expect(_tab('Library, 3 new'), findsOneWidget);
  });

  testWidgets('a count past 99 reads 99+', (t) async {
    await _pump(t, downloads: 120);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('the second tap on the active tab pops the branch to its root', (t) async {
    final rig = await _pump(t);
    await t.tap(_tab('Discover'));
    await t.pumpAndSettle();
    unawaited(rig.router.push<void>('/sources'));
    await t.pumpAndSettle();
    expect(rig.at, '/sources');
    await t.tap(_tab('Discover')); // first tap: scroll to top (nothing to scroll)
    await t.pumpAndSettle();
    expect(rig.at, '/sources');
    await t.tap(_tab('Discover')); // second: pop to the branch root
    await t.pumpAndSettle();
    expect(rig.at, '/search');
  });

  testWidgets('long-press: Library to /updates, Downloads to /downloads, Index to the picker', (t) async {
    final rig = await _pump(t);
    await t.longPress(_tab('Library'));
    await t.pumpAndSettle();
    expect(rig.at, '/updates');
    await t.longPress(_tab('Downloads'));
    await t.pumpAndSettle();
    expect(rig.at, '/downloads');
    await t.longPress(_tab('Index'));
    await t.pumpAndSettle();
    expect(rig.at, '/profiles');
  });

  testWidgets('Android back from /downloads goes to /', (t) async {
    final rig = await _pump(t);
    await t.tap(_tab('Downloads'));
    await t.pumpAndSettle();
    expect(rig.at, '/downloads');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(rig.at, '/');
  });

  testWidgets('Android back from /updates goes to /library, and a second back to /', (t) async {
    final rig = await _pump(t);
    rig.router.go('/updates');
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(rig.at, '/library');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(rig.at, '/');
  });

  testWidgets('the thumb index is hidden on root-navigator routes', (t) async {
    final rig = await _pump(t);
    expect(find.byType(CineThumbIndex), findsOneWidget);
    unawaited(rig.router.push<void>('/reader/a/b/c'));
    await t.pumpAndSettle();
    // The reader route is a root-navigator page above the shell; the shell's index sits beneath it.
    expect(find.byType(CineThumbIndex).hitTestable(), findsNothing);
  });

  test('Android back rule', () {
    expect(cineBranchBack(navInfoFor('/')), CineBranchBack.system);
    expect(cineBranchBack(navInfoFor('/downloads')), CineBranchBack.toTonight);
    expect(cineBranchBack(navInfoFor('/library')), CineBranchBack.toTonight);
    expect(cineBranchBack(navInfoFor('/updates')), CineBranchBack.toShelf);
    expect(cineBranchBack(navInfoFor('/library/history')), CineBranchBack.toShelf);
    expect(cineBranchBack(navInfoFor('/settings')), CineBranchBack.toTonight);
  });

  testWidgets('the running title appears only after the masthead scrolls under the bar', (t) async {
    final key = GlobalKey();
    await t.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(await (() async {
          SharedPreferences.setMockInitialValues({});
          return SharedPreferences.getInstance();
        })(),),
      ],
      child: MaterialApp(
        theme: CinematicSkin.baseTheme,
        home: CineScaffold(
          location: '/library/history',
          firstRunNote: false,
          mastheadKey: key,
          body: ListView(children: [
            SizedBox(key: key, height: 160, child: const Text('MASTHEAD')),
            for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('row $i')),
          ],),
        ),
      ),
    ),);
    await t.pump();
    double titleOpacity() => t.widget<AnimatedOpacity>(find.ancestor(of: find.text('LIBRARY · HISTORY'), matching: find.byType(AnimatedOpacity)).first).opacity;
    expect(titleOpacity(), 0);
    await t.drag(find.byType(ListView), const Offset(0, -260));
    await t.pump();
    await t.pump();
    expect(titleOpacity(), 1);
    // Once past 24 px the head is #000 with the rule.
    final head = t.widget<CineRunningHead>(find.byType(CineRunningHead));
    expect(head.solid, isTrue);
  });

  testWidgets('the running head is at least 44 / 48 plus the top inset', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.viewPadding = const FakeViewPadding(top: 47);
    t.view.padding = const FakeViewPadding(top: 47);
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(await (() async {
          SharedPreferences.setMockInitialValues({});
          return SharedPreferences.getInstance();
        })(),),
      ],
      child: MaterialApp(
        theme: CinematicSkin.baseTheme,
        home: const CineScaffold(location: '/downloads', firstRunNote: false, body: SizedBox()),
      ),
    ),);
    await t.pump();
    final min = defaultTargetPlatform == TargetPlatform.android ? 48.0 : 44.0;
    expect(t.getSize(find.byType(CineRunningHead)).height, greaterThanOrEqualTo(min + 47));
  }, variant: TargetPlatformVariant.all(),);

  testWidgets('a route change moves focus to the new screen masthead heading', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final k2 = GlobalKey();
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: CinematicSkin.baseTheme,
        home: Builder(
          builder: (context) => CineScaffold(
            location: '/downloads',
            firstRunNote: false,
            body: Center(child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CineScaffold(key: k2, location: '/library/history', firstRunNote: false, body: const SizedBox()),
              ),),
              child: const Text('go'),
            ),),
          ),
        ),
      ),
    ),);
    await t.pumpAndSettle();
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    final focus = FocusManager.instance.primaryFocus;
    expect(focus?.debugLabel, 'cine-masthead');
    var inside = false;
    focus!.context!.visitAncestorElements((a) {
      if (a.widget is CineScaffold) inside = a.widget.key == k2;
      return a.widget is! CineScaffold;
    });
    expect(inside, isTrue);
  });
}
