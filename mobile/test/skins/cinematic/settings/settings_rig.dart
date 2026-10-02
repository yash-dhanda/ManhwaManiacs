// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/admin/models/account.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/providers/members_provider.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/user_session.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/sessions_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_display_mode.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/backup_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/source_cache_ttl_provider.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_screen.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/circle/fakes.dart' show FakeCircleRepository;
import '../../../support/test_overrides.dart';
import '../downloads/downloads_rig.dart' show HapticLog, rigTheme, settle;

class _Member extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 2, username: 'guest', isAdmin: false, createdAt: DateTime.utc(2024)));
}

class _Profiles extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => [];
}

class _Ttl extends SourceCacheTtlNotifier {
  int? saved;
  @override
  Future<int> build() async => 360;

  @override
  Future<Never?> save(int minutes) async => null;
}

class _FakeDisplay implements ReaderDisplayMode {
  @override
  Future<void> apply(ReaderRefreshRate rate) async {}
  @override
  Future<void> reset() async {}
  @override
  Future<DisplayModeInfo> describe() async => const DisplayModeInfo(supported: true, activeRefreshRate: 120, activeWidth: 1440, activeHeight: 3120, maxRefreshRate: 120);
}

class _Configurator implements SessionConfigurator {
  @override
  Future<void> configure(AudioSessionConfiguration c) async {}
  @override
  Future<void> setActive(bool a) async {}
}

class _Engine implements CueEngine {
  final played = <String>[];
  @override
  Future<void> init() async {}
  @override
  Future<dynamic> loadAsset(String path) async => path;
  @override
  Future<dynamic> play(dynamic source, {required double volume}) async {
    played.add(source as String);
    return 1;
  }

  @override
  void setRelativePlaySpeed(dynamic handle, double rate) {}
}

class SettingsRig {
  SettingsRig({
    this.admin = true,
    this.profile = true,
    this.novels = true,
    this.clientDownloads = true,
    this.online = true,
    this.sessionsError = false,
    this.members,
    this.backup = const BackupStatus(restorePending: false),
    this.checkInterval = 30,
    Map<String, Object> prefs = const {},
  }) : prefs = testPrefsDefaults(prefs);

  final bool admin, profile, novels, clientDownloads, online, sessionsError;
  final List<Account>? members;
  final BackupStatus backup;
  final int checkInterval;
  final Map<String, Object> prefs;
  final List<String> haptics = [];
  final _Engine engine = _Engine();
}

const kFixtureSessions = [];

List<Override> settingsOverrides(SettingsRig r, SharedPreferences prefs, SkinAudio audio) => [
      sharedPrefsProvider.overrideWithValue(prefs),
      apiBaseUrlOverride('https://manhwamaniacs.xyz'),
      circleRepositoryProvider.overrideWithValue(FakeCircleRepository(sharingValue: const Sharing(activity: true))),
      skinIdProvider.overrideWithValue(SkinId.cinematic),
      if (r.admin) authenticatedAuthOverride() else authControllerProvider.overrideWith(_Member.new),
      if (r.profile) activeProfileOverride(),
      ...contentModeOverrides(novelsEnabled: r.novels),
      ...noDownloadsStoreOverrides(),
      profilesProvider.overrideWith(_Profiles.new),
      serverCapabilitiesProvider.overrideWith((ref) async => ServerCapabilities(clientDownloads: r.clientDownloads)),
      settingsApiUrlProvider.overrideWith((ref) async => 'https://manhwamaniacs.xyz'),
      packageInfoProvider.overrideWith((ref) async => PackageInfo(appName: 'MM', packageName: 'x', version: '3.5.0', buildNumber: '57')),
      appUpdateProvider.overrideWith(
        (ref) async => const AppVersionInfo(
          localVersion: '3.5.0',
          localBuild: 57,
          remoteVersion: '3.5.0',
          remoteBuild: 57,
          downloadUrl: 'http://example.test/app/download',
          channel: AppUpdateChannel.apk,
        ),
      ),
      totalDeviceDownloadBytesProvider.overrideWith((ref) async => (4.1 * 1024 * 1024 * 1024).round()),
      deviceSpaceProvider.overrideWith((ref) async => (free: 40 * 1024 * 1024 * 1024, total: 128 * 1024 * 1024 * 1024)),
      seriesStorageBreakdownProvider.overrideWith((ref) async => const []),
      deviceOnlineProvider.overrideWith((ref) => Stream.value(r.online)),
      updateSettingsProvider.overrideWith(
        (ref) async => UpdateSettings(enabled: true, checkIntervalMinutes: r.checkInterval, notifyEnabled: true, checkOnStartup: false, lastRunAt: DateTime.now().subtract(const Duration(minutes: 45))),
      ),
      updateRunsProvider.overrideWith((ref) async => const []),
      sourceCacheTtlProvider.overrideWith(_Ttl.new),
      authSessionsProvider.overrideWith((ref) async {
        if (r.sessionsError) throw Exception('nope');
        return [
          UserSession(id: 1, createdAt: DateTime.now().subtract(const Duration(days: 3)), lastUsedAt: DateTime.now().subtract(const Duration(hours: 3)), expiresAt: DateTime.now().add(const Duration(days: 4)), isCurrent: true, userAgent: 'Dart/3.5 (dart:io)', ipAddress: '10.0.0.2'),
          UserSession(id: 2, createdAt: DateTime.now().subtract(const Duration(days: 9)), lastUsedAt: DateTime.now().subtract(const Duration(days: 1)), expiresAt: DateTime.now().add(const Duration(days: 1)), isCurrent: false, userAgent: 'Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/130.0'),
        ];
      }),
      membersProvider.overrideWith(
        (ref) async =>
            r.members ??
            [
              Account(id: 1, username: 'tester', isAdmin: true, isActive: true, createdAt: DateTime.utc(2026, 7, 27), lastLoginAt: DateTime.now(), sessionCount: 2),
              Account(id: 3, username: 'raghav', isAdmin: false, isActive: true, createdAt: DateTime.utc(2026, 8, 3), lastLoginAt: DateTime.now().subtract(const Duration(days: 2)), sessionCount: 1),
            ],
      ),
      backupStatusProvider.overrideWith((ref) async => r.backup),
      novelVoicesProvider.overrideWith(
        (ref) async => const [
          NovelVoice(voiceId: 'a', name: 'Atlas', character: 'deep, steady', gender: 'male', pitchHz: 100, seconds: 4),
          NovelVoice(voiceId: 'b', name: 'Lucia', character: 'warm, bright', gender: 'female', pitchHz: 200, seconds: 4),
        ],
      ),
      readerDisplayModeProvider.overrideWithValue(_FakeDisplay()),
      skinAudioProvider.overrideWithValue(audio),
      skinHapticsProvider.overrideWithValue(HapticLog(r.haptics)),
    ];

Future<ProviderContainer> pumpSettings(
  WidgetTester tester, {
  SettingsRig? rig,
  String path = '/settings',
  Size size = const Size(390, 844),
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.android,
  ProviderContainer? reuse,
  Object? extra,
  List<Override> more = const [],
  double textScale = 1,
  Key? boundaryKey,
}) async {
  final r = rig ?? SettingsRig();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(r.prefs);
  final prefs = await SharedPreferences.getInstance();
  final audio = SkinAudio.forTest(_Configurator(), r.engine)..bind(skin: SkinId.cinematic, userId: 1, profileId: 1, prefs: prefs);
  final container = reuse ?? ProviderContainer(overrides: [...settingsOverrides(r, prefs, audio), ...more]);
  if (reuse == null) addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: path,
    initialExtra: extra,
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/:section',
        builder: (context, state) => SettingsScreen(
          key: ValueKey(state.pathParameters['section']),
          slug: state.pathParameters['section'],
          jumpRow: state.extra is Map ? (state.extra! as Map)['jump'] as String? : null,
          licenses: state.uri.queryParameters['licenses'] == '1',
        ),
      ),
      GoRoute(path: '/:rest(.*)', builder: (context, state) => Scaffold(body: Text('at ${state.uri}'))),
    ],
  );
  Widget app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    theme: rigTheme(platform),
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(textScale)),
      child: c!,
    ),
  );
  if (boundaryKey != null) app = RepaintBoundary(key: boundaryKey, child: app);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: app));
  await settle(tester);
  return container;
}


/// Pumps [page] alone in a scrollable, under the same fakes as [pumpSettings].
Future<ProviderContainer> pumpPage(
  WidgetTester tester,
  Widget page, {
  SettingsRig? rig,
  Size size = const Size(390, 844),
  TargetPlatform platform = TargetPlatform.android,
  bool reduced = false,
  List<Override> more = const [],
}) async {
  final r = rig ?? SettingsRig();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(r.prefs);
  final prefs = await SharedPreferences.getInstance();
  final audio = SkinAudio.forTest(_Configurator(), r.engine)..bind(skin: SkinId.cinematic, userId: 1, profileId: 1, prefs: prefs);
  final container = ProviderContainer(overrides: [...settingsOverrides(r, prefs, audio), ...more]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: rigTheme(platform),
        builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: c!),
        home: Scaffold(backgroundColor: Colors.black, body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: page))),
      ),
    ),
  );
  await settle(tester);
  return container;
}
