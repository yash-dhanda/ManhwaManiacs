// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart' show CinePressable;
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/login_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/setup_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/picker_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profile_form_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_manage_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../skins/cinematic/auth/auth_test_support.dart';
import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// Screenshot group `mobile-07`: every screen and state of the Cinematic setup, sign-in and
/// profile cluster at phone 390 x 844 and tablet 834 x 1194 (the picker also at 1024 x 1366), plus
/// `-reduced` and `-scale2` variants of Login and the picker. States that need time or a tap are
/// scripted with fixture providers (no network); the gate switch and the rating card are the
/// gallery's `auth` section.
///
/// Files land as `docs/redesign/proof/mobile-07/<screen>-<state>[-reduced|-scale2]-<size>.png`.
void mobile07Shots() {
  const yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);
  final five = [
    profile(1, 'Yash', mature: true, avatar: 'violet', mood: Mood.romantic),
    profile(2, 'Guest', step: null, avatar: 'ember'),
    profile(3, 'Mira', avatar: 'lunar'),
    profile(4, 'Kit', avatar: 'reader'),
    profile(5, 'Dana', avatar: 'blade'),
  ];
  final three = five.take(3).toList();

  Future<void> tick(WidgetTester t, int ms) async {
    for (var i = 0; i < ms ~/ 50; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> full(WidgetTester t) async {
    await t.pump();
    await tick(t, 3000);
  }

  Future<void> shot(
    WidgetTester t, {
    required String name,
    required SkinShotSize size,
    required String start,
    bool signedIn = true,
    ActiveProfile? active = yash,
    List<Profile>? profiles,
    bool listFails = false,
    BootstrapStatus status = const BootstrapStatus(needsBootstrap: false, registrationEnabled: true),
    Object? statusError,
    FakeAuth? auth,
    ServerCheck? check,
    Completer<ServerCheck>? checkHold,
    bool reduced = false,
    double scale = 1,
    bool splashDone = true,
    DateTime? clock,
    List<Override> extra = const [],
    Future<void> Function(WidgetTester t)? script,
    Future<void> Function(WidgetTester t)? settle,
  }) async {
    final fakeAuth = auth ?? FakeAuth(initial: signedIn ? AuthAuthenticated(testUser) : const AuthUnauthenticated());
    final fakeProfiles = FakeProfiles(profiles ?? three);
    if (listFails) fakeProfiles.failList = true;
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const ColoredBox(color: Colors.black)),
        GoRoute(path: '/welcome', builder: (_, __) => const ColoredBox(color: Colors.black)),
        GoRoute(path: '/setup', builder: (_, __) => const SetupScreen(releaseBuild: true)),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/profiles', builder: (_, s) => ProfilePickerScreen(switchMode: s.extra is Map && (s.extra! as Map)['mode'] == 'switch', clock: clock == null ? null : () => clock)),
        GoRoute(path: '/profiles/new', builder: (_, __) => const ProfileFormScreen()),
        GoRoute(path: '/profiles/manage', builder: (_, __) => const ProfilesManageScreen()),
        GoRoute(path: '/profiles/:id/edit', builder: (_, s) => ProfileFormScreen(profileId: int.tryParse(s.pathParameters['id']!))),
      ],
    );
    await captureSkinWidget(
      t,
      name: name,
      size: size,
      disableAnimations: reduced,
      textScale: scale,
      overrides: [
        skinIdProvider.overrideWithValue(SkinId.cinematic),
        secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        authControllerProvider.overrideWith(() => fakeAuth),
        bootstrapStatusProvider.overrideWith((ref) async {
          if (statusError != null) throw statusError;
          return status;
        }),
        profilesRepositoryProvider.overrideWithValue(fakeProfiles),
        activeProfileProvider.overrideWith(() => SeededActive(active)),
        splashDoneProvider.overrideWith((ref) => splashDone),
        if (check != null || checkHold != null)
          serverCheckProvider.overrideWithValue((_) => checkHold?.future ?? Future.value(check!)),
        ...extra,
      ],
      settle: (t) async {
        await t.pump();
        await tick(t, 300);
        await script?.call(t);
        await (settle ?? full)(t);
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: CinematicSkin.baseTheme,
        routerConfig: router,
        builder: (c, child) => CineShutterLayer(child: CineToastHost(child: child!)),
      ),
    );
    router.dispose();
    await drainCacheTimers(t);
  }

  Future<void> fillLogin(WidgetTester t, {String user = 'yash', String pass = 'a-long-password'}) async {
    await t.enterText(find.byType(TextField).at(0), user);
    await t.enterText(find.byType(TextField).at(1), pass);
    await t.pump();
  }

  Future<void> fillRegister(WidgetTester t) async {
    await t.enterText(find.byType(TextField).at(0), 'yash.d');
    await t.enterText(find.byType(TextField).at(1), 'a-long-password');
    await t.enterText(find.byType(TextField).at(2), 'a-long-password');
    await t.pump();
  }

  Future<void> submitSetup(WidgetTester t) async {
    await t.enterText(find.byType(TextField), 'https://library.example.org');
    await t.pump();
    await t.tap(find.text('Connect'));
    await t.pump();
  }

  ApiError api(String code, {int status = 400, Duration? retry}) => ApiError(statusCode: status, code: code, message: 'm', retryAfter: retry);

  for (final size in kSkinShotSizes) {
    // ── Setup ──
    testWidgets('mobile-07 setup-default ${size.name}', (t) => shot(t, name: 'setup-default', size: size, start: '/setup', signedIn: false, active: null));
    testWidgets('mobile-07 setup-validating ${size.name}', (t) async {
      final hold = Completer<ServerCheck>();
      await shot(t, name: 'setup-validating', size: size, start: '/setup', signedIn: false, active: null, checkHold: hold, script: submitSetup, settle: (t) => tick(t, 700));
      hold.complete(const ServerCheck.offline());
    });
    final errors = <String, ServerCheck>{
      'offline': const ServerCheck.offline(),
      'not-a-server': const ServerCheck.notManhwaManiacs(),
      'tls': const ServerCheck.tls(),
      'http': const ServerCheck.httpInRelease(),
      'timeout': const ServerCheck.timeout(),
      'unreachable': const ServerCheck.unreachable('x'),
    };
    for (final e in errors.entries) {
      testWidgets('mobile-07 setup-error-${e.key} ${size.name}', (t) => shot(t, name: 'setup-error-${e.key}', size: size, start: '/setup', signedIn: false, active: null, check: e.value, script: submitSetup, settle: (t) => tick(t, 600)));
    }
    testWidgets('mobile-07 setup-success ${size.name}', (t) => shot(t, name: 'setup-success', size: size, start: '/setup', signedIn: false, active: null, check: const ServerCheck.ok('https://library.example.org'), script: submitSetup, settle: (t) => tick(t, 250)));
    testWidgets('mobile-07 setup-rule-mid ${size.name}', (t) => shot(t, name: 'setup-rule-mid', size: size, start: '/setup', signedIn: false, active: null, check: const ServerCheck.ok('https://library.example.org'), script: submitSetup, settle: (t) => tick(t, 650)));

    // ── Login ──
    testWidgets('mobile-07 login-normal ${size.name}', (t) => shot(t, name: 'login-normal', size: size, start: '/login', signedIn: false, active: null));
    testWidgets('mobile-07 login-normal-reduced ${size.name}', (t) => shot(t, name: 'login-normal-reduced', size: size, start: '/login', signedIn: false, active: null, reduced: true));
    testWidgets('mobile-07 login-normal-scale2 ${size.name}', (t) => shot(t, name: 'login-normal-scale2', size: size, start: '/login', signedIn: false, active: null, scale: 2));
    testWidgets('mobile-07 login-bootstrap ${size.name}', (t) => shot(t, name: 'login-bootstrap', size: size, start: '/login', signedIn: false, active: null, status: const BootstrapStatus(needsBootstrap: true, registrationEnabled: true)));
    testWidgets('mobile-07 login-unreachable ${size.name}', (t) => shot(t, name: 'login-unreachable', size: size, start: '/login', signedIn: false, active: null, statusError: const NetworkError(message: 'x')));
    testWidgets('mobile-07 login-pending ${size.name}', (t) async {
      final auth = _HoldAuth();
      await shot(t, name: 'login-pending', size: size, start: '/login', signedIn: false, active: null, auth: auth, script: (t) async {
        await fillLogin(t);
        await t.tap(find.text('Sign in'));
        await t.pump();
      }, settle: (t) => tick(t, 700));
      auth.hold.complete();
    });
    testWidgets('mobile-07 login-invalid ${size.name}', (t) => shot(t, name: 'login-invalid', size: size, start: '/login', signedIn: false, active: null, auth: FakeAuth()..loginError = api('invalid_credentials', status: 401), script: (t) async {
          await fillLogin(t);
          await t.tap(find.text('Sign in'));
          await t.pump();
        }, settle: (t) => tick(t, 600)));
    testWidgets('mobile-07 login-ratelimit ${size.name}', (t) => shot(t, name: 'login-ratelimit', size: size, start: '/login', signedIn: false, active: null, auth: FakeAuth()..loginError = api('rate_limited', status: 429, retry: const Duration(seconds: 12)), script: (t) async {
          await fillLogin(t);
          await t.tap(find.text('Sign in'));
          await t.pump();
        }, settle: (t) => tick(t, 2200)));
    testWidgets('mobile-07 login-toast ${size.name}', (t) => shot(t, name: 'login-toast', size: size, start: '/login', signedIn: false, active: null, extra: [sessionEndReasonProvider.overrideWith((ref) => SessionEndReason.signedOut)], settle: (t) => tick(t, 1200)));

    // ── Register ──
    testWidgets('mobile-07 register-open ${size.name}', (t) => shot(t, name: 'register-open', size: size, start: '/register', signedIn: false, active: null));
    testWidgets('mobile-07 register-bootstrap ${size.name}', (t) => shot(t, name: 'register-bootstrap', size: size, start: '/register', signedIn: false, active: null, status: const BootstrapStatus(needsBootstrap: true, registrationEnabled: true)));
    testWidgets('mobile-07 register-invite ${size.name}', (t) => shot(t, name: 'register-invite', size: size, start: '/register', signedIn: false, active: null, status: const BootstrapStatus(needsBootstrap: false, registrationEnabled: true, inviteCodeRequired: true)));
    testWidgets('mobile-07 register-closed ${size.name}', (t) => shot(t, name: 'register-closed', size: size, start: '/register', signedIn: false, active: null, status: const BootstrapStatus(needsBootstrap: false, registrationEnabled: false)));
    testWidgets('mobile-07 register-error-username ${size.name}', (t) => shot(t, name: 'register-error-username', size: size, start: '/register', signedIn: false, active: null, script: (t) async {
          await t.enterText(find.byType(TextField).at(0), 'ab');
          await t.enterText(find.byType(TextField).at(1), 'one-password');
          await t.enterText(find.byType(TextField).at(2), 'two-password');
          await t.pump();
        }));
    testWidgets('mobile-07 register-error-taken ${size.name}', (t) => shot(t, name: 'register-error-taken', size: size, start: '/register', signedIn: false, active: null, auth: FakeAuth()..registerError = api('username_taken', status: 409), script: (t) async {
          await fillRegister(t);
          final b = find.text('Create account');
          await t.ensureVisible(b);
          await t.tap(b);
          await t.pump();
        }, settle: (t) => tick(t, 600)));

    // ── Picker ──
    testWidgets('mobile-07 picker-three ${size.name}', (t) => shot(t, name: 'picker-three', size: size, start: '/profiles', clock: DateTime(2026, 9, 29, 21)));
    testWidgets('mobile-07 picker-five ${size.name}', (t) => shot(t, name: 'picker-five', size: size, start: '/profiles', profiles: five, clock: DateTime(2026, 9, 29, 8)));
    testWidgets('mobile-07 picker-one ${size.name}', (t) => shot(t, name: 'picker-one', size: size, start: '/profiles', profiles: [five.first], clock: DateTime(2026, 9, 29, 14)));
    testWidgets('mobile-07 picker-empty ${size.name}', (t) => shot(t, name: 'picker-empty', size: size, start: '/profiles', profiles: const [], active: null));
    testWidgets('mobile-07 picker-error ${size.name}', (t) => shot(t, name: 'picker-error', size: size, start: '/profiles', active: null, listFails: true));
    testWidgets('mobile-07 picker-unreachable ${size.name}', (t) => shot(t, name: 'picker-unreachable', size: size, start: '/profiles', listFails: true));
    testWidgets('mobile-07 picker-loading ${size.name}', (t) => shot(t, name: 'picker-loading', size: size, start: '/profiles', extra: [profilesRepositoryProvider.overrideWithValue(_NeverProfiles())], settle: (t) => tick(t, 900)));
    testWidgets('mobile-07 picker-manage ${size.name}', (t) => shot(t, name: 'picker-manage', size: size, start: '/profiles', script: (t) async {
          await t.tap(find.text('Manage'));
          await t.pump();
        }));
    testWidgets('mobile-07 picker-iris-mid ${size.name}', (t) => shot(t, name: 'picker-iris-mid', size: size, start: '/profiles', script: (t) async {
          await tick(t, 900);
          await t.tap(find.bySemanticsLabel('Read as Mira'));
          await t.pump();
        }, settle: (t) => tick(t, 560)));
    testWidgets('mobile-07 picker-three-reduced ${size.name}', (t) => shot(t, name: 'picker-three-reduced', size: size, start: '/profiles', reduced: true, clock: DateTime(2026, 9, 29, 21)));
    testWidgets('mobile-07 picker-three-scale2 ${size.name}', (t) => shot(t, name: 'picker-three-scale2', size: size, start: '/profiles', scale: 2, clock: DateTime(2026, 9, 29, 21)));

    // ── Profile form ──
    testWidgets('mobile-07 form-new ${size.name}', (t) => shot(t, name: 'form-new', size: size, start: '/profiles/new'));
    testWidgets('mobile-07 form-edit ${size.name}', (t) => shot(t, name: 'form-edit', size: size, start: '/profiles/1/edit'));
    testWidgets('mobile-07 form-certificate ${size.name}', (t) => shot(t, name: 'form-certificate', size: size, start: '/profiles/new', script: (t) async {
          await t.enterText(find.byType(TextField).first, 'Yash');
          await t.pump();
          await t.ensureVisible(find.byType(CineSwitch));
          await t.tap(find.descendant(of: find.byType(CineSwitch), matching: find.byType(CinePressable)), warnIfMissed: false);
          await t.pump();
        }));
    testWidgets('mobile-07 form-stamp ${size.name}', (t) => shot(t, name: 'form-stamp', size: size, start: '/profiles/new', script: (t) async {
          await t.enterText(find.byType(TextField).first, 'Yash');
          await t.pump();
          await t.ensureVisible(find.byType(CineSwitch));
          await t.tap(find.descendant(of: find.byType(CineSwitch), matching: find.byType(CinePressable)), warnIfMissed: false);
          await tick(t, 900);
          await t.tap(find.byKey(const Key('cert-check')));
          await t.pump();
          await t.tap(find.byKey(const Key('cert-enable')));
          await t.pump();
        }, settle: (t) => tick(t, 150)));

    // ── Manage profiles ──
    testWidgets('mobile-07 manage-loaded ${size.name}', (t) => shot(t, name: 'manage-loaded', size: size, start: '/profiles/manage', profiles: five));
    testWidgets('mobile-07 manage-loading ${size.name}', (t) => shot(t, name: 'manage-loading', size: size, start: '/profiles/manage', extra: [profilesRepositoryProvider.overrideWithValue(_NeverProfiles())], settle: (t) => tick(t, 900)));
    testWidgets('mobile-07 manage-empty ${size.name}', (t) => shot(t, name: 'manage-empty', size: size, start: '/profiles/manage', profiles: const []));
  }

  // The picker at 1024: one row of 144 px avatars.
  testWidgets('mobile-07 picker-five tablet-wide', (t) => shot(t, name: 'picker-five', size: kSkinShotTabletWide, start: '/profiles', profiles: five, clock: DateTime(2026, 9, 29, 8)));
  testWidgets('mobile-07 picker-three tablet-wide', (t) => shot(t, name: 'picker-three', size: kSkinShotTabletWide, start: '/profiles', clock: DateTime(2026, 9, 29, 21)));

  // The gallery's auth section: the masthead lockups, the 18+ switch and the rating card.
  for (final size in kSkinShotSizes) {
    testWidgets('mobile-07 auth-gallery ${size.name}', (t) async {
      final tall = SkinShotSize(size.name, Size(size.logical.width, 2400), size.pixelRatio, size.padding);
      await captureSkinWidget(
        t,
        name: 'auth-gallery',
        size: tall,
        child: const MaterialApp(debugShowCheckedModeBanner: false, home: CinePrimitivesGalleryPage(section: 'auth')),
      );
      await drainCacheTimers(t);
    });
  }
}

/// A sign-in that never answers, to hold the pending frame.
class _HoldAuth extends FakeAuth {
  final hold = Completer<void>();

  @override
  Future<AppError?> login({required String username, required String password, required bool remember}) async {
    await hold.future;
    return null;
  }
}

/// A profile list that never loads.
class _NeverProfiles extends FakeProfiles {
  _NeverProfiles() : super(const []);
  final _c = Completer<void>();

  @override
  Future<Result<List<Profile>>> list() async {
    await _c.future;
    return super.list();
  }
}
