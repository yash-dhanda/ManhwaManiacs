import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart' show aiRepositoryProvider;
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/ai_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_chrome.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart';
import '../../cinematic/picks/picks_test_support.dart' show FakeAi;
import '../primitives/support.dart' show glassHapticsTestOverride;
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../primitives/support.dart' show pumpFor;
import 'home_rig.dart';

class _Profiles extends ProfilesNotifier {
  _Profiles(this.list);
  final List<Profile> list;
  @override
  Future<List<Profile>> build() async => list;
}

Profile profile({String? onboarding}) => Profile(id: 1, name: 'Tester', avatarKey: null, mood: Mood.neutral, sortOrder: 0, matureContentEnabled: false, createdAt: DateTime(2026), onboardingStep: onboarding);

void main() {
  setUpAll(loadAppFonts);

  homeTest('a profile with onboarding pending is redirected to /welcome before any rail paints', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [profilesProvider.overrideWith(() => _Profiles([profile(onboarding: '3')]))]);
    expect(rig.at, startsWith('/welcome'));
    expect(find.byType(GlassHomeScreen), findsNothing);
  });

  homeTest('a finished profile lands on Home with the greeting and the spotlight', (t) async {
    final h = t.ensureSemantics();
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [profilesProvider.overrideWith(() => _Profiles([profile(onboarding: 'done')]))]);
    expect(rig.at, '/');
    expect(find.byType(GlassHomeScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Good afternoon, Tester'), findsOneWidget);
    h.dispose();
  });

  homeTest('the spotlight is a carousel: label, value, increase and decrease, real dot buttons', (t) async {
    final h = t.ensureSemantics();
    await pumpHome(t, homeRepoOf('ready'));
    final node = t.getSemantics(find.bySemanticsLabel(RegExp('^Spotlight')));
    final d = node.getSemanticsData();
    expect(d.value, matches(RegExp(r'^1 of \d$')));
    expect(d.increasedValue, matches(RegExp(r'^2 of \d$')));
    expect(d.decreasedValue, isEmpty);
    final dots = find.bySemanticsLabel(RegExp(r'^Show spotlight \d of \d$'));
    expect(dots, findsAtLeastNWidgets(3));
    expect(find.bySemanticsLabel(RegExp(r'^1 of \d: The Lantern Courier')), findsOneWidget);
    // Increase pages to the second card.
    t.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.increase);
    await pumpFor(t, 600);
    final d2 = t.getSemantics(find.bySemanticsLabel(RegExp('^Spotlight'))).getSemanticsData();
    expect(d2.value, matches(RegExp(r'^2 of \d$')));
    h.dispose();
  });

  homeTest('paging changes the ambient palette (Light follows the story)', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    CoverPalette? pal() => rig.container.read(glassAmbientProvider)?.palette;
    final first = pal();
    expect(first, isNotNull);
    await t.tap(find.bySemanticsLabel('Show spotlight 2 of 4'));
    await pumpFor(t, 1200);
    expect(pal(), isNot(first));
    expect(t.state<SpotlightState>(find.byType(Spotlight)).index, 1);
  });

  homeTest('the primary runs the Dive to the reader route', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    await t.tap(find.text('Start Ch 143'));
    await pumpFor(t, 1500);
    expect(rig.at, contains('/reader/shelf/the-lantern-courier/c143'));
  });

  homeTest('keys page the spotlight and Enter opens the series', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    t.state<SpotlightState>(find.byType(Spotlight)).requestFocus();
    await pumpFor(t, 200);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFor(t, 800);
    expect(t.state<SpotlightState>(find.byType(Spotlight)).index, 1);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await pumpFor(t, 800);
    expect(t.state<SpotlightState>(find.byType(Spotlight)).index, 0);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(t, 900);
    expect(rig.at, startsWith('/sources/shelf/series/the-lantern-courier'));
    expect(find.byType(GlassHomeScreen, skipOffstage: false), findsOneWidget);
  });

  homeTest('tapping a poster opens the feature sheet route with Home still mounted beneath', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    final rail = find.byType(HomePosterRail).first;
    await t.ensureVisible(rail);
    await pumpFor(t, 400);
    await t.tap(find.descendant(of: rail, matching: find.byType(GlassPoster)).first);
    await pumpFor(t, 1200);
    expect(rig.at, startsWith('/sources/'));
    expect(find.byType(GlassHomeScreen, skipOffstage: false), findsOneWidget);
  });

  // -- AI cards ---------------------------------------------------------------------------------------------------------

  Future<void> throwSideways(WidgetTester t, Finder poster) async {
    final g = await t.startGesture(t.getCenter(poster));
    await pumpFor(t, 520);
    for (var i = 1; i <= 8; i++) {
      await g.moveBy(const Offset(45, 0), timeStamp: Duration(milliseconds: 520 + 10 * i));
      await t.pump(const Duration(milliseconds: 10));
    }
    await g.up(timeStamp: const Duration(milliseconds: 620));
    await pumpFor(t, 600);
  }

  homeTest('an AI card thrown sideways sends not_interested, the toast offers Undo and Undo sends undo', (t) async {
    GlassHaptics.debugLog.clear();
    final ai = FakeAi();
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [aiRepositoryProvider.overrideWithValue(ai), glassHapticsTestOverride]);
    final rail = find.byType(HomeAiRail).first;
    await t.ensureVisible(rail);
    await pumpFor(t, 500);
    final card = find.descendant(of: rail, matching: find.byType(AiPickCard)).first;
    final poster = find.descendant(of: card, matching: find.byType(GlassPoster)).first;
    await throwSideways(t, poster);
    expect(ai.sent.map((m) => m['signal']), contains('not_interested'));
    final toasts = rig.container.read(glassToastProvider);
    expect(toasts.map((e) => e.spec.message), contains("We'll show fewer like this"));
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.throwCommit));
    expect(rig.container.read(glassToastProvider.notifier).undoLast(), isTrue);
    await pumpFor(t, 300);
    expect(ai.sent.map((m) => m['signal']), contains('undo'));
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.undo));
  });

  // -- chrome -----------------------------------------------------------------------------------------------------------

  homeTest('the bell shows its count, links to Updates and swings when the count rises', (t) async {
    final h = t.ensureSemantics();
    final unread = MutableUnread()..initial = 3;
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [unreadNotificationCountProvider.overrideWith(() => unread)]);
    expect(find.bySemanticsLabel('Updates, 3 new'), findsOneWidget);
    double angle() {
      final bell = find.byType(HomeBell);
      final tr = t.widget<Transform>(find.descendant(of: bell, matching: find.byType(Transform)).first);
      return tr.transform.storage[1];
    }

    expect(angle(), 0);
    unread.set(5);
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    expect(angle().abs(), greaterThan(0.001));
    await pumpFor(t, 1500);
    expect(angle().abs(), lessThan(0.01));
    await t.tap(find.bySemanticsLabel('Updates, 5 new'));
    await pumpFor(t, 900);
    expect(rig.at, '/updates');
    h.dispose();
  });

  homeTest('the bell does not swing under reduced motion', (t) async {
    final unread = MutableUnread()..initial = 1;
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [unreadNotificationCountProvider.overrideWith(() => unread)]);
    rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await pumpFor(t, 300);
    unread.set(4);
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    final tr = t.widget<Transform>(find.descendant(of: find.byType(HomeBell), matching: find.byType(Transform)).first);
    expect(tr.transform.storage[1], 0);
  });

  // -- refresh ----------------------------------------------------------------------------------------------------------

  homeTest('pull to refresh calls GET /home with refresh=1', (t) async {
    final repo = homeRepoOf('ready');
    await pumpHome(t, repo);
    expect(repo.calls.where((c) => c.refresh), isEmpty);
    await t.fling(find.byType(Scrollable).first, const Offset(0, 420), 1200);
    await pumpFor(t, 2500);
    expect(repo.calls.where((c) => c.refresh).length, 1);
  });

  homeTest('r refreshes through the same call', (t) async {
    final repo = homeRepoOf('ready');
    await pumpHome(t, repo);
    GlassRefreshBus.fire();
    await pumpFor(t, 1500);
    expect(repo.calls.where((c) => c.refresh).length, 1);
  });
}
