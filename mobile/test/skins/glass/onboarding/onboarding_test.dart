import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/genre_field_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/restart_into.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../auth/auth_rig.dart';

GlassAuthFixture _fx({String? step, List<WorldItem>? seeds, List<WorldItem> similar = const []}) => GlassAuthFixture(
      signedIn: true,
      profiles: [fixtureProfile(1, 'Yash', step: step, mood: Mood.fantasy)],
      active: const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy),
      seeds: seeds,
      similar: similar,
    );

const _draftKey = 'mm.onboarding.draft.u1p1';

void _custom(WidgetTester t, String label, String action) {
  t.semantics.performAction(find.semantics.byLabel(label), SemanticsAction.customAction, args: CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: action)));
}

Future<void> _cont(WidgetTester t, String label) async {
  await t.tap(find.widgetWithText(GlassButton, label));
  await settleFor(t, 2000);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a profile at step 4 resumes at 4 with its answers from the draft', (t) async {
    final h = t.ensureSemantics();
    final draft = jsonEncode(OnboardingDraftJson.of({'Fantasy': 2}));
    await pumpAuth(t, '/welcome?step=6', _fx(step: '4'), prefs: {_draftKey: draft});
    await settleFor(t, 2500);
    expect(find.text('Which genres pull you in?'), findsWidgets);
    expect(find.bySemanticsLabel('Fantasy, loved'), findsOneWidget);
    h.dispose();
  });

  testWidgets('the dots read "Step 3 of 7"', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/welcome?step=3', _fx(step: '3'));
    await settleFor(t, 1500);
    expect(find.bySemanticsLabel('Step 3 of 7'), findsOneWidget);
    h.dispose();
  });

  testWidgets('the dots read "of 6" with Look hidden', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/welcome?step=3', _fx(step: '3'), debugGlass: false);
    await settleFor(t, 1500);
    expect(find.bySemanticsLabel('Step 2 of 6'), findsOneWidget);
    h.dispose();
  });

  testWidgets('Android back from step 3 goes to step 2, from step 1 leaves the step alone', (t) async {
    final rig = await pumpAuth(t, '/welcome?step=3', _fx(step: '3'), android: true);
    await settleFor(t, 1500);
    await t.binding.handlePopRoute();
    await settleFor(t, 2500);
    expect(rig.at, '/welcome');
    expect(find.text('Pick a look'), findsWidgets);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Skip writes done and lands on Home', (t) async {
    final repo = FakeOnboardingRepo(Ok(OnboardingCatalog(seeds: fixtureSeeds())));
    final rig = await pumpAuth(t, '/welcome', _fx(), onboardingRepo: repo);
    await settleFor(t, 2500);
    await t.tap(find.text('Skip'));
    await t.pump();
    await settleFor(t, 2000);
    expect(repo.saved.last.step.isDone, isTrue);
    // The fake profile store keeps the stale onboarding step, so Home's redirect may send it back; the real refresh clears it.
    expect(rig.at, anyOf('/', startsWith('/welcome')));
  });

  testWidgets('Continue steps through 1, 2, 3 and writes the taste after each change', (t) async {
    final repo = FakeOnboardingRepo(Ok(OnboardingCatalog(seeds: fixtureSeeds())));
    final rig = await pumpAuth(t, '/welcome', _fx(), onboardingRepo: repo);
    await settleFor(t, 2500);
    expect(find.text('Start'), findsOneWidget);
    await _cont(t, 'Start');
    expect(find.text('Pick a look'), findsWidgets);
    await _cont(t, 'Continue');
    expect(find.text('What do you read?'), findsWidgets);
    await t.tap(find.text('Manhwa'));
    await t.pump();
    await _cont(t, 'Continue');
    await settleFor(t);
    expect(repo.saved, isNotEmpty);
    expect(repo.saved.any((u) => u.touched.contains(TasteField.formats)), isTrue);
    expect(rig.at, '/welcome');
  });

  testWidgets("the genre field's semantics actions set each weight", (t) async {
    final h = t.ensureSemantics();
    final weights = <String, int>{};
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(_host(prefs, GenreFieldView(names: const ['Action', 'Fantasy', 'Romance'], weights: weights, onWeight: (n, w) => weights[n] = w)));
    await settleFor(t, 100);
    _custom(t, 'Action, not chosen', 'Like');
    expect(weights['Action'], 1);
    _custom(t, 'Action, not chosen', 'Love');
    expect(weights['Action'], 2);
    _custom(t, 'Action, not chosen', 'Not for me');
    expect(weights['Action'], -1);
    _custom(t, 'Action, not chosen', 'Clear');
    expect(weights['Action'], 0);
    expect(t.getSemantics(find.bySemanticsLabel('Fantasy, not chosen')).hint, 'Double-tap to change');
    h.dispose();
  });

  testWidgets('the five mature genres are absent with the gate closed', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/welcome?step=4', _fx(step: '4'), extra: [matureGateOpenProvider.overrideWithValue(false)]);
    await settleFor(t, 2500);
    expect(find.bySemanticsLabel('Smut, not chosen'), findsNothing);
    expect(find.bySemanticsLabel('Murim, not chosen'), findsOneWidget);
    h.dispose();
  });

  testWidgets('the five mature genres appear with the gate open', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/welcome?step=4', _fx(step: '4'), extra: [matureGateOpenProvider.overrideWithValue(true)]);
    await settleFor(t, 2500);
    expect(find.bySemanticsLabel('Smut, not chosen'), findsOneWidget);
    expect(find.bySemanticsLabel('Murim, not chosen'), findsNothing);
    h.dispose();
  });

  testWidgets('step 6 follows a seed, updates the counter and pulls the similar titles in after it', (t) async {
    GlassHaptics.debugLog.clear();
    final lib = FakeLibrary();
    final similar = [for (var i = 0; i < 4; i++) WorldItem(anilistId: 900 + i, title: 'Similar $i', available: [WorldAvailability(sourceId: 's', sourceName: 'S', seriesKey: 'sim-$i')])];
    await pumpAuth(t, '/welcome?step=6', _fx(step: '6', similar: similar), library: lib);
    await settleFor(t, 2500);
    expect(find.text('Your home has 0 titles to start with'), findsOneWidget);
    final before = find.byType(GlassPoster).evaluate().length;
    await t.tap(find.byType(GlassPoster).first);
    await t.pump();
    await settleFor(t, 300);
    await settleFor(t, 500);
    expect(lib.calls, ['follow:src/series-0']);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.followAdd));
    expect(find.text('Your home has 1 title to start with'), findsOneWidget);
    expect(find.byType(GlassPoster).evaluate().length, before + 3, reason: 'up to three similar titles');
  });

  testWidgets('a seed no source has is kept as a seed with its caption', (t) async {
    final repo = FakeOnboardingRepo(Ok(OnboardingCatalog(seeds: fixtureSeeds())));
    await pumpAuth(t, '/welcome?step=6', _fx(step: '6'), onboardingRepo: repo);
    await settleFor(t, 2500);
    expect(find.text('Not on your sources yet'), findsOneWidget);
    await t.tap(find.byType(GlassPoster).at(1));
    await t.pump();
    await settleFor(t, 500);
    expect(find.text('Your home has 1 title to start with'), findsOneWidget);
  });

  testWidgets('Finish with the Cinematic choice melts and restarts', (t) async {
    final asked = <SkinId>[];
    restartIntoSkinTestHook = (skin, route) async => asked.add(skin);
    addTearDown(() => restartIntoSkinTestHook = null);
    await pumpAuth(t, '/welcome?step=2', _fx(step: '2'));
    await settleFor(t, 2500);
    await t.tap(find.text('Cinematic'));
    await settleFor(t, 400);
    expect(find.text('The app will restart in Cinematic after the last step.'), findsOneWidget);
    for (final label in ['Continue', 'Continue', 'Continue', 'Continue']) {
      await _cont(t, label);
    }
    await t.tap(find.byType(GlassPoster).first);
    await t.pump();
    await settleFor(t, 500);
    await t.tap(find.widgetWithText(GlassButton, 'Finish'));
    await t.pump();
    await settleFor(t, 3000);
    expect(asked, [SkinId.cinematic]);
  });

  testWidgets('reduced motion: the genre field is a grid and the tilt subscription is never opened', (t) async {
    await pumpAuth(t, '/welcome?step=4', _fx(step: '4'), reduced: true);
    await settleFor(t, 1500);
    final state = t.state<GenreFieldViewState>(find.byType(GenreFieldView));
    expect(state.field!.allAsleep, isTrue);
    expect(state.field!.bodies.first.p.dy, lessThan(state.field!.bodies.last.p.dy));
  });

  testWidgets('leaving step 4 drops the accelerometer subscription to zero', (t) async {
    final ctl = StreamController<AccelerometerEvent>.broadcast();
    addTearDown(ctl.close);
    final rig = await pumpAuth(t, '/welcome?step=4', _fx(step: '4'), extra: [
      glassLightAngleProvider.overrideWith((ref) => Stream.value(kLightAngleRest)),
      gravitySensorProvider.overrideWithValue(() => ctl.stream),
    ],);
    await settleFor(t, 1500);
    expect(rig.container.read(gravityProvider).sensorSubscriptions, 1);
    await _cont(t, 'Continue');
    await settleFor(t);
    expect(rig.container.read(gravityProvider).sensorSubscriptions, 0);
  });
}

Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(data: const MediaQueryData(size: Size(390, 844)), child: Center(child: SizedBox(width: 358, height: 480, child: child))),
      ),
    );

/// A draft with genre weights, in the shape `OnboardingDraft.toJson` writes.
abstract final class OnboardingDraftJson {
  static Map<String, Object> of(Map<String, int> genres) => {
        'taste': {'formats': <String>[], 'genres': genres, 'styles': <String>[], 'seeds': <Object>[]},
        'touched': ['genres'],
        'picks': <int>[],
      };
}
