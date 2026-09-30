import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

class _Unread extends UnreadCountNotifier {
  _Unread(this.n);
  final int n;
  @override
  int build() => n;
}

class _NoLetters extends LettersNotifier {
  @override
  Future<List<Letter>> build() async => const [];
}

class _NoPins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => const SourcePinsState(synced: true);
}

class _NoProfiles extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => const [];
}

class ShellRig {
  ShellRig(this.router, this.container);
  final GoRouter router;
  final ProviderContainer container;
  String get at {
    final cfg = container.read(skinRouterProvider).routerDelegate.currentConfiguration;
    return cfg.isEmpty ? '/' : cfg.last.matchedLocation;
  }
}

/// Pumps the Glass router in the given window, signed in with a profile, no network and no downloads store.
Future<ShellRig> pumpGlassShell(
  WidgetTester t, {
  Size size = const Size(390, 844),
  String start = '/',
  int unread = 0,
  int downloads = 0,
  List<Override> extra = const [],
  bool platformAndroid = false,
  bool settle = true,
  Map<String, Object> prefsExtra = const {},
}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults(prefsExtra));
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      skinIdProvider.overrideWithValue(SkinId.glass),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      profileSessionReadyOverride(),
      unreadNotificationCountProvider.overrideWith(() => _Unread(unread)),
      activeDownloadCountProvider.overrideWithValue(downloads),
      setupCompletedProvider.overrideWithValue(true),
      ...noDownloadsStoreOverrides(),
      ...contentModeOverrides(),
      lettersProvider.overrideWith(_NoLetters.new),
      profilesProvider.overrideWith(_NoProfiles.new),
      sourcePinsProvider.overrideWith(_NoPins.new),
      serverCapabilitiesProvider.overrideWith((ref) async => const ServerCapabilities()),
      ...extra,
    ],
  );
  addTearDown(c.dispose);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  if (platformAndroid) debugDefaultTargetPlatformOverride = TargetPlatform.android;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  final router = c.read(skinRouterProvider);
  if (start != '/') router.go(start);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: GlassSkin.baseTheme.copyWith(platform: defaultTargetPlatform),
          routerConfig: ref.watch(skinRouterProvider),
          builder: (context, child) => const GlassSkin().wrap(context, child ?? const SizedBox.shrink()),
        ),
      ),
    ),
  );
  if (settle) {
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
  } else {
    await t.pump();
  }
  return ShellRig(router, c);
}

/// The semantics node of a dock tab.
Finder dockTab(String label) => find.bySemanticsLabel(RegExp('^$label, tab '));

ProviderContainer containerOf(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(Scaffold).first), listen: false);

GlassTab tabOfRig(ShellRig r) => r.container.read(glassActiveTabProvider);

/// Semantics of the sidebar panel.
Finder sidebarPanel() => find.bySemanticsLabel(RegExp('^Sections'));
