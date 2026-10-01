// ignore_for_file: directives_ordering
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/app_update_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/sidestore_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../downloads/downloads_rig.dart' show rigTheme, settle, typed;

const _entries = [
  ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-28', highlights: ['First thing.', 'Second thing.']),
  ChangelogRelease(version: '3.4.2', build: 55, date: '2026-09-24', highlights: ['Older thing.']),
];

Future<ProviderContainer> pumpHost(
  WidgetTester tester, {
  required Widget Function(BuildContext, WidgetRef) home,
  List<Override> extra = const [],
  Map<String, Object> prefsSeed = const {},
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(testPrefsDefaults(prefsSeed));
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      apiBaseUrlOverride('http://example.test'),
      packageInfoProvider.overrideWith((ref) async => PackageInfo(appName: 'MM', packageName: 'x', version: '3.5.0', buildNumber: '57')),
      ...extra,
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: rigTheme(TargetPlatform.android),
        home: Consumer(builder: (context, ref, _) => Scaffold(body: home(context, ref))),
      ),
    ),
  );
  await settle(tester, ms: 200);
  return c;
}

void main() {
  testWidgets('the sheet lists every entry, LATEST on the first only, with dashes', (tester) async {
    await pumpHost(
      tester,
      extra: [appChangelogProvider.overrideWith((ref) async => _entries)],
      home: (context, ref) => TextButton(onPressed: () => unawaited(showWhatsNewSheet(context, ref)), child: const Text('open')),
    );
    await tester.tap(find.text('open'));
    await settle(tester, ms: 900);
    expect(find.text("WHAT'S NEW"), findsOneWidget);
    expect(find.text('Release notes'), findsOneWidget);
    expect(find.text('3.5.0 · BUILD 57 · 28 SEP 2026'), findsOneWidget);
    expect(find.text('3.4.2 · BUILD 55 · 24 SEP 2026'), findsOneWidget);
    expect(find.text('LATEST'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('First thing.'), findsOneWidget);
  });

  testWidgets('closing the sheet stores the running build', (tester) async {
    final c = await pumpHost(
      tester,
      extra: [appChangelogProvider.overrideWith((ref) async => _entries)],
      home: (context, ref) => TextButton(onPressed: () => unawaited(showWhatsNewSheet(context, ref)), child: const Text('open')),
    );
    await tester.tap(find.text('open'));
    await settle(tester, ms: 900);
    expect(c.read(preferencesProvider).lastSeenChangelogBuild, 0);
    await tester.tap(find.byKey(const Key('cine-sheet-done')));
    await settle(tester, ms: 900);
    expect(c.read(preferencesProvider).lastSeenChangelogBuild, 57);
  });

  testWidgets('loading: a leader dial and LOADING after 400 ms', (tester) async {
    await pumpHost(
      tester,
      extra: [appChangelogProvider.overrideWith((ref) => Completer<List<ChangelogRelease>>().future)],
      home: (context, ref) => const SizedBox(height: 300, child: SingleChildScrollView(child: WhatsNewBody())),
    );
    expect(find.text('LOADING'), findsOneWidget);
  });

  testWidgets('unavailable: the notice', (tester) async {
    await pumpHost(
      tester,
      extra: [appChangelogProvider.overrideWith((ref) async => const <ChangelogRelease>[])],
      home: (context, ref) => const SingleChildScrollView(child: WhatsNewBody()),
    );
    expect(typed("Release notes aren't available right now."), findsOneWidget);
    await settle(tester, ms: 3000);
  });

  group('whatsNewDue', () {
    testWidgets('a first run stores the build and does not open', (tester) async {
      final c = await pumpHost(tester, home: (context, ref) => const SizedBox());
      // Reading through a widget ref is needed; use a consumer to run it.
      late bool due;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: Consumer(builder: (context, ref, _) {
            unawaited(whatsNewDue(ref).then((v) => due = v));
            return const SizedBox();
          },),
        ),
      );
      await settle(tester, ms: 200);
      expect(due, isFalse);
      expect(c.read(preferencesProvider).lastSeenChangelogBuild, 57);
    });

    testWidgets('a lower stored build opens it', (tester) async {
      final c = await pumpHost(tester, prefsSeed: {'settings_last_seen_changelog_build': 55}, home: (context, ref) => const SizedBox());
      late bool due;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: Consumer(builder: (context, ref, _) {
            unawaited(whatsNewDue(ref).then((v) => due = v));
            return const SizedBox();
          },),
        ),
      );
      await settle(tester, ms: 200);
      expect(due, isTrue);
    });
  });

  group('update cards', () {
    const behind = AppVersionInfo(
      localVersion: '3.5.0',
      localBuild: 57,
      remoteVersion: '3.5.1',
      remoteBuild: 58,
      downloadUrl: 'http://example.test/app/download',
      channel: AppUpdateChannel.apk,
    );

    testWidgets('up to date', (tester) async {
      await pumpHost(
        tester,
        home: (context, ref) => const AppUpdateCard(
          preview: AsyncValue.data(AppVersionInfo(localVersion: '3.5.0', localBuild: 57, remoteVersion: '3.5.0', remoteBuild: 57, downloadUrl: '', channel: AppUpdateChannel.apk)),
        ),
      );
      expect(find.text('UP TO DATE — 3.5.0'), findsOneWidget);
    });

    testWidgets('available', (tester) async {
      await pumpHost(tester, home: (context, ref) => const AppUpdateCard(preview: AsyncValue.data(behind)));
      expect(find.text('3.5.0 → 3.5.1'), findsOneWidget);
      expect(find.text('Download update'), findsOneWidget);
    });

    testWidgets('unreachable and loading', (tester) async {
      await pumpHost(tester, home: (context, ref) => const AppUpdateCard(preview: AsyncValue.data(null)));
      expect(find.text("Couldn't check for updates."), findsOneWidget);
      await pumpHost(tester, home: (context, ref) => const AppUpdateCard(preview: AsyncValue.loading()));
      expect(find.byKey(const Key('update-greek')), findsOneWidget);
    });

    testWidgets('SideStore card: explanation, source URL, copy and the weekly note', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final c = await pumpHost(tester, home: (context, ref) => const SideStoreCard());
      expect(find.text('MANAGED BY SIDESTORE'), findsOneWidget);
      expect(find.text('http://example.test/app/source.json'), findsOneWidget);
      expect(find.textContaining('SideStore re-signs the app every 7 days'), findsOneWidget);
      await tester.tap(find.text('Copy source URL'));
      await settle(tester, ms: 200);
      expect(copied, 'http://example.test/app/source.json');
      expect(c.read(cineToastsProvider).any((t) => t.text == 'Source URL copied'), isTrue);
    });
  });

  testWidgets('the sheet meets the tap target, label and contrast guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpHost(
      tester,
      extra: [appChangelogProvider.overrideWith((ref) async => _entries)],
      home: (context, ref) => TextButton(onPressed: () => unawaited(showWhatsNewSheet(context, ref)), child: const Text('open')),
    );
    await tester.tap(find.text('open'));
    await settle(tester, ms: 900);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('the sheet meets the iOS 44 pt tap target guideline', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final h = tester.ensureSemantics();
    try {
      await pumpHost(
        tester,
        extra: [appChangelogProvider.overrideWith((ref) async => _entries)],
        home: (context, ref) => TextButton(onPressed: () => unawaited(showWhatsNewSheet(context, ref)), child: const Text('open')),
      );
      await tester.tap(find.text('open'));
      await settle(tester, ms: 900);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    } finally {
      h.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

