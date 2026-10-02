import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart' show aiRepositoryProvider;
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';
import 'package:manhwamaniacs/skins/glass/primitives/revealed_headings.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/ai_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/greeting_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_chrome.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_menus.dart';
import 'package:manhwamaniacs/skins/glass/shell/error_surface.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:sensors_plus/sensors_plus.dart' show AccelerometerEvent;

import '../../../screenshots/support/shot_harness.dart';
import '../../cinematic/picks/picks_test_support.dart' show FakeAi;
import '../primitives/support.dart' show glassHapticsTestOverride;
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
  setUp(glassRevealSlots.reset);

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
    t.semantics.performAction(find.semantics.byLabel(RegExp('^Spotlight')), SemanticsAction.increase);
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

  // -- states -----------------------------------------------------------------------------------------------------------

  Finder skeletons() => find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SkeletonPainter');

  homeTest('loading: the greeting at once, skeletons after 180 ms, no spotlight yet', (t) async {
    final repo = homeRepoOf('ready');
    pendingFeed(repo);
    await pumpHome(t, repo, settle: false);
    await pumpFor(t, 100);
    expect(find.byType(HomeLoadingSkeleton), findsOneWidget);
    expect(find.byType(GreetingHeader), findsOneWidget);
    expect(skeletons(), findsNothing);
    await pumpFor(t, 250);
    expect(skeletons(), findsWidgets);
    expect(find.byType(Spotlight), findsNothing);
  });

  homeTest('new profile: the Start here spotlight, the popular rail and the nothing-followed lens', (t) async {
    await pumpHome(t, homeRepoOf('new-profile'));
    expect(find.byType(Spotlight), findsOneWidget);
    expect(find.byType(HomeNewProfileLens), findsOneWidget);
    await t.ensureVisible(find.byType(HomeNewProfileLens));
    await pumpFor(t, 400);
    expect(find.text('Nothing followed yet'), findsOneWidget);
    expect(find.text('Browse sources'), findsOneWidget);
  });

  homeTest('AI unavailable: the notice carries the reason short line, the rest works', (t) async {
    await pumpHome(t, homeRepoOf('ai-unavailable'));
    final rail = find.byWidgetPredicate((w) => w is HomeAiRail && w.rail.id == 'picked');
    await t.ensureVisible(rail);
    await pumpFor(t, 400);
    expect(find.text("Today's AI asks are used up"), findsOneWidget);
    expect(find.byType(HomeContinueRail), findsOneWidget);
  });

  homeTest('caught up: the spotlight opens with You\'re caught up and Updated for you is omitted', (t) async {
    await pumpHome(t, homeRepoOf('caught-up'));
    expect(find.bySemanticsLabel(RegExp("^1 of \\d: You're caught up")), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is HomePosterRail && w.rail.id == 'new-this-week'), findsNothing);
  });

  homeTest('stale AI rails wear the Picked N days ago stamp', (t) async {
    await pumpHome(t, homeRepoOf('stale'), now: DateTime(2026, 10, 4, 12));
    final rail = find.byWidgetPredicate((w) => w is HomeAiRail && w.rail.id == 'picked');
    await t.ensureVisible(rail);
    await pumpFor(t, 400);
    expect(find.textContaining('Picked '), findsWidgets);
    expect(find.textContaining(' days ago'), findsWidgets);
  });

  homeTest('error: a server failure with every local source failing is the full lens', (t) async {
    final repo = FakeHomeRepo(() async => const Err(ApiError(statusCode: 500, code: 'boom', message: 'x')));
    await pumpHome(t, repo, libraryDown: true, extra: [sourcePinsProvider.overrideWith(_FailingPins.new)]);
    expect(find.byType(HomeErrorLens), findsOneWidget);
    expect(find.text("Couldn't load your home"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(Spotlight), findsNothing);
  });

  homeTest('rate limited: the warning capsule says Sources are busy and retries after Retry-After', (t) async {
    final repo = FakeHomeRepo(() async => const Err(ApiError(statusCode: 429, code: 'rate_limited', message: 'x', retryAfter: Duration(seconds: 12))));
    final rig = await pumpHome(t, repo, libraryDown: true, extra: [sourcePinsProvider.overrideWith(_FailingPins.new)]);
    final limit = rig.container.read(glassRateLimitProvider);
    expect(limit?.copy, 'Sources are busy. Retrying in 12 s');
    final before = repo.calls.length;
    await t.pump(const Duration(seconds: 13));
    expect(repo.calls.length, greaterThan(before));
  });

  homeTest('offline: one spotlight card and only Ready offline and Continue reading', (t) async {
    final repo = homeRepoOf('ready');
    final rig = await pumpHome(t, repo, extra: [downloadedSeriesProvider.overrideWith((ref) async => [_savedGroup()])]);
    repo.answer = () async => const Err(NetworkError(message: 'down'));
    await rig.container.read(homeFeedProvider.notifier).refresh();
    await pumpFor(t, 1500);
    expect(rig.container.read(homeFeedProvider).value!.offline, isTrue);
    final ids = find.byType(HomeContinueRail).evaluate().length + find.byWidgetPredicate((w) => w is HomePosterRail && w.rail.id == 'ready-offline').evaluate().length;
    expect(ids, 2);
    expect(find.byType(HomeAiRail), findsNothing);
    expect(find.byType(Spotlight), findsOneWidget);
    expect(t.state<SpotlightState>(find.byType(Spotlight)).widget.specs.length, 1);
  });

  // -- dock menu, orbs, accessory ---------------------------------------------------------------------------------------

  homeTest('the dock Home menu lists Updates, Mark all read and Continue last read', (t) async {
    await pumpHome(t, homeRepoOf('ready'));
    final ref = t.element(find.byType(GlassHomeScreen)) as WidgetRef;
    final labels = [for (final e in dockMenuEntries(GlassTab.home, ref, t.element(find.byType(GlassHomeScreen)), const Rect.fromLTWH(0, 0, 10, 10))) e.label];
    expect(labels, ['Home', 'Updates', 'Mark all read', 'Continue last read']);
  });

  homeTest('the dock Home menu hides Continue last read when there is nothing to continue', (t) async {
    await pumpHome(t, homeRepoOf('new-profile'));
    final ref = t.element(find.byType(GlassHomeScreen)) as WidgetRef;
    final labels = [for (final e in dockMenuEntries(GlassTab.home, ref, t.element(find.byType(GlassHomeScreen)), const Rect.fromLTWH(0, 0, 10, 10))) e.label];
    expect(labels, isNot(contains('Continue last read')));
    expect(labels, contains('Mark all read'));
  });

  homeTest('with a friend eligible a lift shows the orb row and a drop recommends with Undo', (t) async {
    GlassHaptics.debugLog.clear();
    final circle = _FakeCircle();
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [
      circleRepositoryProvider.overrideWithValue(circle),
      sharingProvider.overrideWith(_Sharing.new),
      recipientsProvider.overrideWith((ref, key) async => const [CircleMember(profileId: 2, name: 'Mira', canReceive: true)]),
      glassHapticsTestOverride,
    ],);
    final rail = find.byType(HomePosterRail).first;
    await t.ensureVisible(rail);
    await pumpFor(t, 500);
    final poster = find.descendant(of: rail, matching: find.byType(GlassPoster)).first;
    final g = await t.startGesture(t.getCenter(poster));
    await pumpFor(t, 520);
    final friendOrbs = find.byWidgetPredicate((w) => w is GlassProfileOrb && w.friend);
    expect(friendOrbs, findsOneWidget);
    final orb = t.getCenter(friendOrbs);
    final from = t.getCenter(poster);
    for (var i = 1; i <= 20; i++) {
      await g.moveTo(Offset.lerp(from, orb, i / 20)!, timeStamp: Duration(milliseconds: 520 + 40 * i));
      await t.pump(const Duration(milliseconds: 40));
    }
    await g.up(timeStamp: const Duration(milliseconds: 1400));
    await pumpFor(t, 500);
    final toasts = rig.container.read(glassToastProvider);
    expect(toasts.map((e) => e.spec.message), contains('Recommended to Mira'));
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.magnetDrop));
    // Undo cancels the letter.
    expect(rig.container.read(glassToastProvider.notifier).undoLast(), isTrue);
    await t.pump(const Duration(seconds: 12));
    expect(circle.sent, isEmpty);
  });

  homeTest('no friend orbs appear when nobody can receive', (t) async {
    await pumpHome(t, homeRepoOf('ready'), extra: [
      sharingProvider.overrideWith(_Sharing.new),
      recipientsProvider.overrideWith((ref, key) async => const []),
    ],);
    final rail = find.byType(HomePosterRail).first;
    await t.ensureVisible(rail);
    await pumpFor(t, 500);
    final g = await t.startGesture(t.getCenter(find.descendant(of: rail, matching: find.byType(GlassPoster)).first));
    await pumpFor(t, 520);
    expect(find.byWidgetPredicate((w) => w is GlassProfileOrb && w.friend), findsNothing);
    await g.up();
    await pumpFor(t, 600);
  });

  homeTest('the accessory publishes Continue once the spotlight scrolls out and clears on return', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    GlassAccessoryState acc() => rig.container.read(glassAccessoryProvider);
    expect(acc().continueItem, isNull);
    await t.fling(find.byType(Scrollable).first, const Offset(0, -900), 2500);
    await pumpFor(t, 1200);
    expect(acc().continueItem, isNotNull);
    expect(acc().continueItem!.title, startsWith('Continue '));
    await t.fling(find.byType(Scrollable).first, const Offset(0, 1800), 4000);
    await pumpFor(t, 1500);
    expect(acc().continueItem, isNull);
  });

  // -- sensors ----------------------------------------------------------------------------------------------------------

  homeTest('sensors: one accelerometer subscription while Home is visible and allowed, none after leaving', (t) async {
    final sensor = StreamController<AccelerometerEvent>.broadcast();
    addTearDown(sensor.close);
    final rig = await pumpHome(t, homeRepoOf('ready'), extra: [
      gravitySensorProvider.overrideWithValue(() => sensor.stream),
      glassLightAngleProvider.overrideWith((ref) => Stream<double>.value(kLightAngleRest)),
    ],);
    int subs() => rig.container.read(gravityProvider).sensorSubscriptions;
    expect(subs(), 1);
    // A tab switch.
    await t.tap(find.bySemanticsLabel(RegExp('^Library, tab')));
    await pumpFor(t, 900);
    expect(subs(), 0);
    await t.tap(find.bySemanticsLabel(RegExp('^Home, tab')));
    await pumpFor(t, 900);
    expect(subs(), 1);
    // A route pushed over Home.
    unawaited(rig.container.read(skinRouterProvider).push<void>('/updates'));
    await pumpFor(t, 900);
    expect(subs(), 0);
    rig.container.read(skinRouterProvider).pop();
    await pumpFor(t, 900);
    expect(subs(), 1);
    // Backgrounding.
    // The real order (any live text field holds an AppLifecycleListener, which asserts on a skipped step).
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await pumpFor(t, 300);
    expect(subs(), 0);
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await pumpFor(t, 300);
    expect(subs(), 1);
    // Reduced motion.
    rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await pumpFor(t, 400);
    expect(subs(), 0);
  });

  // -- Signature animations actually play (glass 15.8) -------------------------------------------------------------------

  homeTest('the greeting types, a rail header below the fold waits, and a second visit is remembered', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), settle: false);
    await t.pump();
    await pumpFor(t, 200);
    final greeting = find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText)).first;
    TextSpan root() => t.widget<RichText>(greeting).text as TextSpan;
    Color? colour(int i) => (root().children![i] as TextSpan).style?.color;
    expect(colour(9), const Color(0x00000000));
    expect(colour(0), isNot(const Color(0x00000000)));
    await pumpFor(t, 3000);
    final n = root().children!.length;
    for (var i = 0; i < n; i++) {
      expect(colour(i), isNot(const Color(0x00000000)), reason: 'grapheme $i');
    }
    final genres = find.byWidgetPredicate((w) => w is LetterReveal && w.text == 'Your genres', skipOffstage: false);
    double headerLetter() => (find.descendant(of: genres, matching: find.byType(Opacity), skipOffstage: false).evaluate().first.widget as Opacity).opacity;
    expect(headerLetter(), 0);
    expect(rig.container.read(revealedHeadingsProvider).any((k) => k.endsWith(':tonight:genres')), isFalse);
    await t.ensureVisible(genres);
    await pumpFor(t, 2500);
    expect(rig.container.read(revealedHeadingsProvider).any((k) => k.endsWith(':tonight:genres')), isTrue);
    // A second visit in the same session: the set of revealed headings remembers both.
    final revealed = rig.container.read(revealedHeadingsProvider);
    expect(revealed.any((k) => k.endsWith(':home.greeting')), isTrue);
    expect(revealed.any((k) => k.endsWith(':tonight:genres')), isTrue);
  });

  homeTest('a 429 answered by another 429 keeps retrying', (t) async {
    final repo = FakeHomeRepo(() async => const Err(ApiError(statusCode: 429, code: 'rate_limited', message: 'busy', retryAfter: Duration(seconds: 2))));
    await pumpHome(t, repo);
    final first = repo.calls.length;
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(repo.calls.length, greaterThanOrEqualTo(first + 2));
    await t.pumpWidget(const SizedBox());
  });
}

class _Sharing extends SharingNotifier {
  @override
  Future<Sharing> build(int arg) async => const Sharing(activity: true);
}

class _FakeCircle implements CircleRepository {
  final sent = <List<int>>[];

  @override
  Future<Result<void>> sendLetter({required List<int> toProfileIds, required String sourceId, required String seriesKey, String? note}) async {
    sent.add(toProfileIds);
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _FailingPins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => throw const NetworkError(message: 'down');
}

DownloadedSeriesGroup _savedGroup() => DownloadedSeriesGroup(
      sourceId: 'shelf',
      seriesKey: 'the-lantern-courier',
      seriesTitle: 'The Lantern Courier',
      chapters: [
        SavedChapter(
          rowId: 1,
          scopeId: 'u1p1',
          sourceId: 'shelf',
          seriesKey: 'the-lantern-courier',
          chapterKey: 'c142',
          chapterNumber: 142,
          title: null,
          seriesTitle: 'The Lantern Courier',
          pageCount: 40,
          bytes: 100,
          state: DownloadChapterState.complete,
          pinned: false,
          readAt: null,
          createdAt: DateTime(2026, 9),
          retryCount: 0,
          error: null,
        ),
      ],
    );
