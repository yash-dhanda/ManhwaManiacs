import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_wordmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthController {
  _Auth(this.initial);
  final AuthState initial;
  @override
  AuthState build() => initial;
  void set(AuthState s) => state = s;
}

final _user = AuthUser(id: 1, username: 'u', isAdmin: false, createdAt: DateTime.utc(2024));

Future<ProviderContainer> _pump(
  WidgetTester t, {
  Map<String, Object> prefs = const {},
  AuthState auth = const AuthUnknown(),
  bool reduced = false,
  Size size = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(p),
    authControllerProvider.overrideWith(() => _Auth(auth)),
  ],);
  addTearDown(c.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: CinematicSkin.baseTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: const Stack(children: [ColoredBox(color: Colors.black, child: SizedBox.expand()), Positioned.fill(child: CineSplash())]),
    ),
  ),);
  return c;
}

Finder get _lockup => find.byType(CineWordmark);

void main() {
  testWidgets('the letters land by 1,400 ms and the layer is gone after the hand-off', (t) async {
    final c = await _pump(t, auth: AuthAuthenticated(_user));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.byType(SetHeading), findsNWidgets(2));
    expect(c.read(splashDoneProvider), isFalse);
    await t.pump(const Duration(milliseconds: 600));
    // 1,300 ms: the hand-off (1,180) has begun and the lockup is dissolving.
    expect(c.read(splashDoneProvider), isTrue);
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byType(SetHeading), findsNothing);
    expect(find.byType(CineSplash), findsOneWidget);
    expect(_lockup, findsNothing);
  });

  testWidgets('a pending probe holds after the impression and shows the dial at 2,400 ms', (t) async {
    final c = await _pump(t);
    await t.pump(const Duration(milliseconds: 1500));
    expect(c.read(splashDoneProvider), isFalse);
    expect(find.text('CONNECTING'), findsNothing);
    await t.pump(const Duration(milliseconds: 950));
    expect(find.text('CONNECTING'), findsOneWidget);
    expect(find.byType(CineLeaderDial), findsOneWidget);
    // The probe answers: the hand-off starts and the layer goes.
    (c.read(authControllerProvider.notifier) as _Auth).set(const AuthUnauthenticated());
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
    expect(c.read(splashDoneProvider), isTrue);
    await t.pump(const Duration(milliseconds: 400));
    expect(_lockup, findsNothing);
  });

  testWidgets('a tap skips to the hand-off once the probe has answered', (t) async {
    final c = await _pump(t, auth: AuthAuthenticated(_user));
    await t.pump(const Duration(milliseconds: 300));
    await t.tapAt(const Offset(200, 400));
    await t.pump(const Duration(milliseconds: 50));
    expect(c.read(splashDoneProvider), isTrue);
    await t.pump(const Duration(milliseconds: 400));
    expect(_lockup, findsNothing);
  });

  testWidgets('a warm start plays only the fades: no letters', (t) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final c = await _pump(t, prefs: {kSplashLastKey: now - 3600000}, auth: AuthAuthenticated(_user));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(SetHeading), findsNothing);
    expect(_lockup, findsOneWidget);
    await t.pump(const Duration(milliseconds: 500));
    expect(c.read(splashDoneProvider), isTrue);
    await t.pump(const Duration(milliseconds: 300));
    expect(_lockup, findsNothing);
  });

  testWidgets('a skin restart always plays the full reveal', (t) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _pump(t, prefs: {kSplashLastKey: now - 1000, kSkinT0Key: now - 700}, auth: AuthAuthenticated(_user));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.byType(SetHeading), findsNWidgets(2));
    await t.pump(const Duration(milliseconds: 1000));
  });

  testWidgets('reduced motion: no letter transforms, the lockup fades in over 300 ms', (t) async {
    await _pump(t, auth: AuthAuthenticated(_user), reduced: true);
    await t.pump(const Duration(milliseconds: 150));
    expect(find.byType(SetHeading), findsNothing);
    final o = t.widgetList<Opacity>(find.descendant(of: find.byType(CineSplash), matching: find.byType(Opacity))).map((e) => e.opacity).toList();
    expect(o.any((v) => v > 0 && v < 1), isTrue);
    await t.pump(const Duration(milliseconds: 900));
  });

  testWidgets('SKIN RESTART is logged on the first frame and mm.skin.t0 is cleared', (t) async {
    MotionRecorder.instance.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    final c = await _pump(t, prefs: {kSkinT0Key: now - 900}, auth: AuthAuthenticated(_user));
    await t.pump(const Duration(milliseconds: 20));
    expect(c.read(sharedPrefsProvider).containsKey(kSkinT0Key), isFalse);
    expect(MotionRecorder.instance.entries.any((e) => e.label == 'SKIN RESTART'), isTrue);
    await t.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('the layer is a live region named Loading ManhwaManiacs and never takes focus', (t) async {
    await _pump(t, auth: AuthAuthenticated(_user));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Loading ManhwaManiacs'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<CineSplash>(), isNull);
    await t.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('frozen frames render at any time', (t) async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    for (final ms in [0.0, 300.0, 560.0, 900.0, 1180.0, 1400.0]) {
      await t.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(p)],
        child: MaterialApp(theme: CinematicSkin.baseTheme, home: CineSplash(freezeAtMs: ms)),
      ),);
      await t.pump();
      expect(t.takeException(), isNull, reason: 'at $ms');
    }
  });
}

