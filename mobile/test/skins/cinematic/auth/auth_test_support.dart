// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/core/storage/secure_storage.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart' show cineLocationOf;
import 'package:manhwamaniacs/skins/cinematic/router_gate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/login_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/setup_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/picker_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profile_form_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_manage_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../primitives/cine_harness.dart' show TestHaptics;

/// Secure storage that keeps the address and token in memory.
class FakeSecureStorage extends SecureStorageService {
  String? url;
  String? token;
  @override
  Future<String?> getApiUrl() async => url;
  @override
  Future<void> setApiUrl(String v) async => url = v;
  @override
  Future<String?> getAuthToken() async => token;
  @override
  Future<void> setAuthToken(String v) async => token = v;
  @override
  Future<void> clearAuthToken() async => token = null;
}

final testUser = AuthUser(id: 1, username: 'tester', isAdmin: false, createdAt: DateTime.utc(2024));

/// An auth controller that never touches the network: login and register answer as told.
class FakeAuth extends AuthController {
  FakeAuth({this.initial = const AuthUnauthenticated()});
  final AuthState initial;
  AppError? loginError;
  AppError? registerError;
  final List<({String user, String pass, bool remember})> logins = [];
  final List<String> registers = [];
  int logouts = 0;

  @override
  AuthState build() => initial;

  @override
  Future<AppError?> login({required String username, required String password, required bool remember}) async {
    logins.add((user: username, pass: password, remember: remember));
    if (loginError != null) return loginError;
    state = AuthAuthenticated(testUser);
    return null;
  }

  @override
  Future<AppError?> register({
    required String username,
    required String password,
    required bool remember,
    String? email,
    String? displayName,
    String? inviteCode,
  }) async {
    registers.add(username);
    if (registerError != null) return registerError;
    state = AuthAuthenticated(testUser);
    return null;
  }

  @override
  Future<void> logout() async {
    logouts++;
    state = const AuthUnauthenticated();
  }
}

Profile profile(int id, String name, {bool mature = false, String? step = 'done', Mood mood = Mood.neutral, int? sort, String? avatar}) => Profile(
      id: id,
      name: name,
      avatarKey: avatar ?? 'violet',
      mood: mood,
      sortOrder: sort ?? id,
      matureContentEnabled: mature,
      createdAt: DateTime.utc(2026),
      onboardingStep: step,
    );

class FakeProfiles implements ProfilesRepository {
  FakeProfiles(List<Profile> items) : items = [...items];
  List<Profile> items;
  Object? failList;
  AppError? failWrite;
  final List<String> calls = [];

  @override
  Future<Result<List<Profile>>> list() async {
    if (failList != null) return const Err(NetworkError(message: 'offline'));
    return Ok([...items]);
  }

  @override
  Future<Result<Profile>> create({required String name, required String avatarKey, required Mood mood, int? sortOrder, bool? matureContentEnabled, String? skin}) async {
    calls.add('create:$name:${mood.wire}:${matureContentEnabled ?? false}:${skin ?? ''}');
    if (failWrite != null) return Err(failWrite!);
    final p = profile(items.length + 10, name, mature: matureContentEnabled ?? false, mood: mood, avatar: avatarKey, step: null);
    items.add(p);
    return Ok(p);
  }

  @override
  Future<Result<Profile>> update(int id, {String? name, String? avatarKey, Mood? mood, int? sortOrder, bool? matureContentEnabled, String? skin}) async {
    calls.add('update:$id:${name ?? ''}:${sortOrder ?? ''}:${matureContentEnabled ?? ''}');
    if (failWrite != null) return Err(failWrite!);
    final i = items.indexWhere((p) => p.id == id);
    final o = items[i];
    items[i] = Profile(
      id: id,
      name: name ?? o.name,
      avatarKey: avatarKey ?? o.avatarKey,
      mood: mood ?? o.mood,
      sortOrder: sortOrder ?? o.sortOrder,
      matureContentEnabled: matureContentEnabled ?? o.matureContentEnabled,
      createdAt: o.createdAt,
      onboardingStep: o.onboardingStep,
    );
    return Ok(items[i]);
  }

  @override
  Future<Result<void>> remove(int id) async {
    calls.add('remove:$id');
    if (failWrite != null) return Err(failWrite!);
    items.removeWhere((p) => p.id == id);
    return const Ok(null);
  }
}

class SeededActive extends ActiveProfileNotifier {
  SeededActive(this.seed);
  final ActiveProfile? seed;
  @override
  ActiveProfile? build() => seed;
}

/// Everything a screen test drives.
class Rig {
  Rig(this.router, this.container, this.auth, this.profiles, this.haptics);
  final GoRouter router;
  final ProviderContainer container;
  final FakeAuth auth;
  final FakeProfiles profiles;
  final List<HapticEvent> haptics;
  String get at => cineLocationOf(router);
}

Future<Rig> pumpAuth(
  WidgetTester t, {
  String start = '/login',
  FakeAuth? auth,
  List<Profile>? profiles,
  ActiveProfile? active,
  BootstrapStatus status = const BootstrapStatus(needsBootstrap: false, registrationEnabled: true),
  Object? statusError,
  bool setupDone = true,
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.iOS,
  Size size = const Size(390, 844),
  double scale = 1,
  bool splashDone = true,
  bool gated = false,
  bool listFails = false,
  DateTime Function()? clock,
  List<Override> extra = const [],
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(setupDone ? testPrefsDefaults(prefs) : prefs);
  final sp = await SharedPreferences.getInstance();
  final fakeAuth = auth ?? FakeAuth();
  final fakeProfiles = FakeProfiles(profiles ?? [profile(1, 'Yash'), profile(2, 'Guest', step: null)]);
  if (listFails) fakeProfiles.failList = true;
  final haptics = <HapticEvent>[];
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(sp),
    secureStorageProvider.overrideWithValue(FakeSecureStorage()),
    skinIdProvider.overrideWithValue(SkinId.cinematic),
    authControllerProvider.overrideWith(() => fakeAuth),
    bootstrapStatusProvider.overrideWith((ref) async {
      if (statusError != null) throw statusError;
      return status;
    }),
    profilesRepositoryProvider.overrideWithValue(fakeProfiles),
    activeProfileProvider.overrideWith(() => SeededActive(active)),
    splashDoneProvider.overrideWith((ref) => splashDone),
    skinHapticsProvider.overrideWithValue(TestHaptics(haptics)),
    ...noDownloadsStoreOverrides(),
    ...extra,
  ],);
  addTearDown(c.dispose);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);

  final bridge = ValueNotifier<int>(0);
  addTearDown(bridge.dispose);
  if (gated) {
    c
      ..listen(setupCompletedProvider, (_, __) => bridge.value++)
      ..listen(authControllerProvider, (_, __) => bridge.value++)
      ..listen(activeProfileProvider, (_, __) => bridge.value++);
  }
  final router = GoRouter(
    initialLocation: start,
    refreshListenable: bridge,
    redirect: !gated
        ? null
        : (context, state) => cineRedirect(
              CineGateState(
                setupCompleted: c.read(setupCompletedProvider),
                auth: switch (c.read(authControllerProvider)) {
                  AuthUnknown() => CineAuth.unknown,
                  AuthUnauthenticated() => CineAuth.unauthenticated,
                  AuthAuthenticated() => CineAuth.authenticated,
                },
                hasActiveProfile: c.read(activeProfileProvider) != null,
              ),
              state.uri,
            ),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Center(child: Text('TONIGHT')))),
      GoRoute(path: '/welcome', builder: (_, __) => const Scaffold(body: Center(child: Text('ONBOARDING')))),
      GoRoute(path: '/setup', builder: (_, __) => const SetupScreen(releaseBuild: true)),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/profiles',
        builder: (_, s) => ProfilePickerScreen(switchMode: s.extra is Map && (s.extra! as Map)['mode'] == 'switch', clock: clock),
      ),
      GoRoute(path: '/profiles/new', builder: (_, __) => const ProfileFormScreen()),
      GoRoute(path: '/profiles/manage', builder: (_, __) => const ProfilesManageScreen()),
      GoRoute(path: '/profiles/:id/edit', builder: (_, s) => ProfileFormScreen(profileId: int.tryParse(s.pathParameters['id']!))),
    ],
  );
  addTearDown(router.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      theme: CinematicSkin.baseTheme.copyWith(platform: platform),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
        child: CineShutterLayer(child: CineToastHost(child: child!)),
      ),
    ),
  ),);
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  return Rig(router, c, fakeAuth, fakeProfiles, haptics);
}

/// Lets timers and route animations run out.
Future<void> settle(WidgetTester t, [int ms = 3000]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}
