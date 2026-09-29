// ignore_for_file: directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/index_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/index_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/install_now_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/update_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../downloads/downloads_rig.dart' show HapticLog, rigTheme, settle;
import 'package:manhwamaniacs/skins/skin_haptics.dart';

class _Unread extends UnreadCountNotifier {
  @override
  int build() => 14;
}

class _Member extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 2, username: 'guest', isAdmin: false, createdAt: DateTime.utc(2024)));
}

const _update = AppVersionInfo(
  localVersion: '3.5.0',
  localBuild: 57,
  remoteVersion: '3.5.1',
  remoteBuild: 58,
  downloadUrl: 'http://example.test/app/download',
  channel: AppUpdateChannel.apk,
);

const _upToDate = AppVersionInfo(
  localVersion: '3.5.0',
  localBuild: 57,
  remoteVersion: '3.5.0',
  remoteBuild: 57,
  downloadUrl: 'http://example.test/app/download',
  channel: AppUpdateChannel.apk,
);

class IndexRig {
  IndexRig({this.admin = true, this.update, this.ocr = true, this.online = true, this.streak = 12});
  final bool admin;
  final AppVersionInfo? update;
  final bool ocr;
  final bool online;
  final int streak;
  final List<String> haptics = [];
}

/// Every provider the Index reads, fixed to [r] (the shots reuse it).
List<Override> indexOverrides(IndexRig r) => [

  apiBaseUrlOverride('http://example.test'),
  if (r.admin) authenticatedAuthOverride() else authControllerProvider.overrideWith(_Member.new),
  activeProfileOverride(),
  ...contentModeOverrides(),
  statisticsProvider.overrideWith(
    (ref) async => LibraryStatistics(
      followedTotal: 0,
      favorites: 0,
      byReadingStatus: const {},
      chaptersCompleted: 0,
      streak: ReadingStreak(currentDays: r.streak),
    ),
  ),
  suggestAvailabilityProvider.overrideWith((ref) async => const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 8)),
  collectionsProvider.overrideWith(_Collections.new),
  bookmarksProvider.overrideWith(_Bookmarks.new),
  unreadNotificationCountProvider.overrideWith(_Unread.new),
  totalDeviceDownloadBytesProvider.overrideWith((ref) async => (4.1 * 1024 * 1024 * 1024).round()),
  sourceHealthSummaryProvider.overrideWith((ref) async => const SourceHealthSummary(total: 89, ok: 84)),
  appChangelogProvider.overrideWith(
    (ref) async => const [ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-28', highlights: ['One thing changed.'])],
  ),
  appUpdateProvider.overrideWith((ref) async => r.update ?? _upToDate),
  packageInfoProvider.overrideWith(
    (ref) async => PackageInfo(appName: 'MM', packageName: 'x', version: '3.5.0', buildNumber: '57'),
  ),
  ocrFeatureVisibleProvider.overrideWithValue(r.ocr),
  deviceOnlineProvider.overrideWith((ref) => Stream.value(r.online)),
  skinHapticsProvider.overrideWithValue(HapticLog(r.haptics)),
];

Future<ProviderContainer> pumpIndex(
  WidgetTester tester, {
  IndexRig? rig,
  Size size = const Size(390, 844),
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.android,
  ProviderContainer? reuse,
  List<Override> extra = const [],
}) async {
  final r = rig ?? IndexRig();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  final container = reuse ?? ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), ...indexOverrides(r), ...extra]);
  if (reuse == null) addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/more',
    routes: [
      GoRoute(path: '/more', builder: (context, state) => const IndexScreen()),
      GoRoute(path: '/:rest(.*)', builder: (context, state) => Scaffold(body: Text('at ${state.uri}'))),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: rigTheme(platform),
        builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: c!),
      ),
    ),
  );
  await settle(tester);
  return container;
}

class _Collections extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => const [];
}

class _Bookmarks extends BookmarksNotifier {
  @override
  Future<BookmarksState> build() async => const BookmarksState(bookmarks: []);
}

Finder row(String label) => find.byWidgetPredicate((w) => w is IndexRow && w.label == label);

void main() {
  testWidgets('member: profile block, four sections with their values, no admin rows', (tester) async {
    await pumpIndex(tester, rig: IndexRig(admin: false));
    expect(find.text('THE INDEX'), findsOneWidget);
    expect(find.text('Tester'), findsOneWidget);
    expect(find.text('@guest'), findsOneWidget);
    expect(find.text('ADMIN'), findsNothing);
    for (final s in ['YOU', 'READING', 'THE HOUSE', 'ABOUT']) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.text('12-DAY STREAK'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('8 ASKS LEFT'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('4.1 GB'), findsOneWidget);
    expect(find.text('3.5.0 (57)'), findsOneWidget);
    expect(row('Backup & restore'), findsNothing);
    expect(row('Members'), findsNothing);
    expect(row('System status'), findsNothing);
    expect(row('Dialogue search'), findsOneWidget);
  });

  testWidgets('admin rows appear, with the source health count', (tester) async {
    await pumpIndex(tester);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(row('Backup & restore'), findsOneWidget);
    expect(row('Members'), findsOneWidget);
    expect(row('System status'), findsOneWidget);
    expect(find.text('84/89 OK'), findsOneWidget);
  });

  testWidgets('Dialogue search is absent when OCR is unavailable', (tester) async {
    await pumpIndex(tester, rig: IndexRig(ocr: false));
    expect(row('Dialogue search'), findsNothing);
  });

  testWidgets('no streak value at zero', (tester) async {
    await pumpIndex(tester, rig: IndexRig(streak: 0));
    expect(find.textContaining('-DAY STREAK'), findsNothing);
    expect(row('The Numbers'), findsOneWidget);
  });

  testWidgets('APK update banner, its download failure toast and the Install now steps', (tester) async {
    final launched = <Uri>[];
    var fail = true;
    final container = await pumpIndex(
      tester,
      rig: IndexRig(update: _update),
      extra: [
        updateLauncherProvider.overrideWithValue((u) async {
          launched.add(u);
          return !fail;
        }),
      ],
    );
    expect(find.text('UPDATE AVAILABLE · 3.5.1 (58)'), findsOneWidget);
    expect(find.text('INSTALLED 3.5.0 (57)'), findsOneWidget);
    expect(find.text("Downloading doesn't install it automatically."), findsOneWidget);
    expect(find.text('Updating from 1.2.x? Uninstall the old app first.'), findsOneWidget);
    expect(find.text('AVAILABLE'), findsOneWidget);
    expect(launched, isEmpty);
    // A launcher that fails: the failure is a toast naming the URL.
    await tester.tap(find.text('Download update'));
    await settle(tester, ms: 300);
    expect(launched.single.toString(), 'http://example.test/app/download');
    expect(container.read(cineToastsProvider).any((t) => t.text == "Couldn't open http://example.test/app/download"), isTrue);
    // A launcher that works: the Install now steps follow.
    fail = false;
    await tester.tap(find.text('Download update'));
    await settle(tester, ms: 800);
    expect(find.text('Install now'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('Install now dialog lists three steps', (tester) async {
    await pumpIndex(tester, rig: IndexRig(update: _update));
    // Reach the dialog through the banner's launcher hook.
    unawaited(showInstallNowDialog(tester.element(find.byType(IndexScreen))));
    await settle(tester, ms: 600);
    expect(find.text('Install now'), findsOneWidget);
    expect(find.text('The new version is downloading to your device.'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Open the downloaded APK from your notification shade or Downloads.'), findsOneWidget);
    expect(find.text('Tap Install and confirm any prompt.'), findsOneWidget);
    expect(find.text('Return here: the version updates and this banner clears on its own.'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('no banner on an up-to-date build', (tester) async {
    await pumpIndex(tester);
    expect(find.byKey(const Key('update-banner')), findsNothing);
    expect(find.text('AVAILABLE'), findsNothing);
  });

  testWidgets('no banner on iOS, where SideStore owns updates', (tester) async {
    await pumpIndex(tester, rig: IndexRig(update: _update), platform: TargetPlatform.iOS);
    expect(find.byKey(const Key('update-banner')), findsNothing);
  });

  testWidgets('tablet from 900 dp: two columns with a column rule', (tester) async {
    await pumpIndex(tester, size: const Size(1024, 1366));
    expect(find.byKey(const Key('index-column-rule')), findsOneWidget);
    final left = tester.getTopLeft(find.text('YOU')).dx;
    final right = tester.getTopLeft(find.text('THE HOUSE')).dx;
    expect(right, greaterThan(left + 300));
  });

  testWidgets('below 900 dp one column', (tester) async {
    await pumpIndex(tester, size: const Size(834, 1194));
    expect(find.byKey(const Key('index-column-rule')), findsNothing);
  });

  testWidgets('the leaders draw once per session and sit at rest under reduced motion', (tester) async {
    final c = await pumpIndex(tester);
    expect(c.read(indexLeadersDrawnProvider), isTrue);
    final draws = tester.widgetList<LeaderDraw>(find.byType(LeaderDraw)).toList();
    expect(draws, isNotEmpty);
    expect(draws.every((d) => d.play), isTrue);
  });

  testWidgets('a second visit in the same session: leaders at rest', (tester) async {
    await pumpIndex(tester, extra: [indexLeadersDrawnProvider.overrideWith((ref) => true)]);
    expect(tester.widgetList<LeaderDraw>(find.byType(LeaderDraw)).every((d) => !d.play), isTrue);
  });

  testWidgets('reduced motion: leaders present at rest at once', (tester) async {
    await pumpIndex(tester, reduced: true);
    final leader = find.byKey(const Key('cine-dot-leader')).first;
    expect(tester.getSize(leader).width, greaterThan(20));
  });

  testWidgets('offline shows the OFFLINE EDITION badge', (tester) async {
    await pumpIndex(tester, rig: IndexRig(online: false));
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
  });

  testWidgets('What\'s new rises as a sheet from the Index', (tester) async {
    await pumpIndex(tester);
    await tester.ensureVisible(row("What's new"));
    await tester.pump();
    await tester.tap(row("What's new"));
    await settle(tester, ms: 800);
    expect(find.text('Release notes'), findsOneWidget);
    expect(find.text('3.5.0 · BUILD 57 · 28 SEP 2026'), findsOneWidget);
    expect(find.text('LATEST'), findsOneWidget);
  });

  group('a11y', () {
    testWidgets('Android tap targets, labels and contrast', (tester) async {
      final h = tester.ensureSemantics();
      await pumpIndex(tester, rig: IndexRig(update: _update));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });

    testWidgets('iOS tap targets', (tester) async {
      final h = tester.ensureSemantics();
      await pumpIndex(tester, platform: TargetPlatform.iOS);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      h.dispose();
    });
  });
}
