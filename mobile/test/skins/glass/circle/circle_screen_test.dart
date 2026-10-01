import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroine/heroine.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/copy/reactions.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/presence_arc.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart' show glassNavigatorsProvider;

import '../../../screenshots/support/shot_harness.dart';
import 'circle_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('presence: reading, today, away; now null is never reading; streak only where shared; labels carry the state', (t) async {
    final h = t.ensureSemantics();
    await pumpCircle(t, circleFake());
    expect(find.text('Reading '), findsNothing);
    expect(find.textContaining('Omniscient Reader'), findsWidgets);
    expect(find.bySemanticsLabel('Aarav, reading Omniscient Reader now'), findsOneWidget);
    expect(find.bySemanticsLabel('Mira, active today'), findsOneWidget);
    expect(find.bySemanticsLabel('Noor, active today'), findsOneWidget, reason: 'now: null is never reading');
    expect(find.bySemanticsLabel('Kai, away, 12-day streak'), findsOneWidget);
    // The reading orb is 64 px at the front (the arc's lowest, centred point).
    final arc = t.getRect(find.byType(PresenceArc));
    final aarav = t.getRect(find.bySemanticsLabel('Aarav, reading Omniscient Reader now'));
    expect(aarav.center.dx, closeTo(arc.center.dx, 2));
    final others = ['Mira, active today', 'Noor, active today', 'Kai, away, 12-day streak'].map((l) => t.getRect(find.bySemanticsLabel(l)).center.dy);
    expect(others.every((y) => y <= aarav.center.dy + 0.5), isTrue);
    expect(find.text('12'), findsOneWidget, reason: 'the streak count on Kai only');
    h.dispose();
    await unmount(t);
  });

  testWidgets('activity: day headers, collapsed reads, Fill glyph reactions, guarded "reacted to Ch 212", Read it too follows', (t) async {
    final lib = FollowRecorder();
    await pumpCircle(t, circleFake(), extra: [libraryRepositoryProvider.overrideWithValue(lib)]);
    final text = visibleText();
    expect(text, contains('Today'));
    expect(text, contains('Aarav read chapters 140–152 of Solo Leveling'));
    expect(text, contains('Mira reacted Hype to chapter 88'));
    expect(find.byIcon(glassReaction(ReactionKind.hype).fill), findsWidgets);
    expect(text, contains('Kai reacted to Ch 212'));
    expect(text, isNot(contains('Kai reacted Wrecked')));
    final read = find.text('Read it too', skipOffstage: false);
    await t.ensureVisible(read);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(read);
    await settle(t, 400);
    expect(lib.followed, ['s:ob']);
    expect(visibleText(), contains('Yesterday'));
    await unmount(t);
  });

  testWidgets("a row's orb opens the friend sheet with one flying Heroine tag", (t) async {
    final rig = await pumpCircle(t, circleFake());
    Iterable<Heroine> tags() => find.byType(Heroine, skipOffstage: false).evaluate().map((e) => e.widget as Heroine).where((h) => h.tag == 'circle-orb-2');
    expect(tags(), isEmpty, reason: 'no orb carries the tag until it is tapped');
    await t.tap(find.bySemanticsLabel('Aarav, reading Omniscient Reader now'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(rig.at, '/circle/2');
    expect(tags().length, lessThanOrEqualTo(2), reason: 'the tapped orb and the header orb only');
    await settle(t);
    expect(find.text('Aarav · @aarav'), findsOneWidget);
    expect(find.text('Recommend something to Aarav'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing, reason: 'no progress lines under Reading');
    // Android back / Esc closes it.
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t, 800);
    expect(rig.at, '/circle');
    await unmount(t);
  });

  testWidgets('letters: tap sends read, Not now dismisses, kept renders as read, Sent shows only opened state', (t) async {
    final repo = circleFake();
    await pumpCircle(t, repo, start: '/circle?tab=letters');
    expect(find.text('Tower of God'), findsOneWidget);
    expect(find.text('Blue Hour'), findsOneWidget);
    await t.ensureVisible(find.text('Not now').last);
    await t.pump();
    await t.tap(find.text('Not now').last);
    await settle(t, 900);
    expect(repo.log, contains('patchLetter 2 dismissed'));
    expect(find.text('Blue Hour'), findsNothing);
    await t.ensureVisible(find.text('Tower of God'));
    await t.pump();
    await t.tap(find.text('Tower of God'));
    await settle(t, 600);
    expect(repo.log, contains('patchLetter 1 read'));
    await unmount(t);

    await pumpCircle(t, circleFake(), start: '/circle?tab=letters');
    await t.tap(find.text('Sent'));
    await settle(t, 400);
    expect(find.text('Not opened yet'), findsOneWidget);
    expect(find.text('Opened'), findsOneWidget);
    expect(visibleText(), isNot(contains('Added')));
    await unmount(t);
  });

  testWidgets('states: not sharing (others still below), quiet, error, offline', (t) async {
    await pumpCircle(t, circleFake(sharing: false));
    expect(find.text('Read together'), findsOneWidget);
    expect(visibleText(), contains('Aarav read chapters 140–152 of Solo Leveling'));
    await unmount(t);

    await pumpCircle(t, circleFake(members: const [], feed: const []));
    expect(find.text('Your Circle is quiet'), findsOneWidget);
    await unmount(t);

    await pumpCircle(t, circleFake(fail: const ApiError(statusCode: 500, code: 'server_error', message: 'x')));
    expect(find.text("Couldn't load your Circle"), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
    await unmount(t);

    await pumpCircle(t, circleFake(fail: const NetworkError(message: 'x')), extra: [glassOfflineProvider.overrideWithValue(true)]);
    expect(find.text('The Circle needs a connection'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('keys: [ and ] switch tabs, the Circle group is registered', (t) async {
    final rig = await pumpCircle(t, circleFake());
    final groups = rig.container.read(shortcutRegistryProvider.notifier).registeredGroups().map((g) => g.name).toSet();
    expect(groups, contains('Circle'));
    focusRow(t, 'a3');
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await settle(t, 400);
    expect(rig.router.routerDelegate.currentConfiguration.uri.queryParameters['tab'], 'letters');
    await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await settle(t, 400);
    expect(rig.router.routerDelegate.currentConfiguration.uri.queryParameters['tab'], 'activity');
    await unmount(t);
  });

  testWidgets('activity keeps paging: every new page asks again for the next', (t) async {
    final repo = _Pages(circleFake());
    await pumpCircle(t, repo);
    await settle(t);
    expect(repo.cursors, containsAllInOrder(['p2', 'p3']));
    await unmount(t);
  });

  testWidgets('friend sheet: no Recommend button when they take no recommendations', (t) async {
    final page = aaravPage();
    final repo = circleFake(page: MemberPage(profile: page.profile, now: page.now, reading: page.reading));
    await pumpCircle(t, repo, start: '/circle/2');
    await settle(t);
    expect(find.text('Recommend something to Aarav'), findsNothing);
    await unmount(t);
  });

  testWidgets('friend sheet: 404 says they stopped sharing; a cold deep link renders a full page', (t) async {
    final repo = circleFake()..memberPage = null;
    final rig = await pumpCircle(t, repo, start: '/circle/2');
    await settle(t);
    expect(find.text("Aarav isn't sharing right now."), findsOneWidget);
    expect(rig.container.read(glassNavigatorsProvider), isNotNull);
    await unmount(t);
  });

  testWidgets('18+ gate closed: nothing mentions hidden, 18+ or mature in the Circle or the friend sheet', (t) async {
    await pumpCircle(t, circleFake());
    final bad = RegExp(r'hidden|18\+|mature', caseSensitive: false);
    expect(bad.hasMatch(visibleText()), isFalse);
    await unmount(t);
    await pumpCircle(t, circleFake(), start: '/circle/2');
    await settle(t);
    expect(bad.hasMatch(visibleText()), isFalse);
    await unmount(t);
  });

  testWidgets('hit targets on Circle at 390 x 844', (t) async {
    final h = t.ensureSemantics();
    await pumpCircle(t, circleFake());
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
    await unmount(t);
  });

  test('presenceStates follows the arc order', () {
    expect(presenceStates(circleMembers(), circleNow).map((s) => s.name), ['reading', 'today', 'today', 'away']);
    expect(circleTabOf('letters'), CircleTab.letters);
    expect(circleTabOf('nope'), CircleTab.activity);
    expect(presenceLabel(const CircleMember(profileId: 1, name: 'Kai', streak: CircleStreak(currentDays: 12)), PresenceState.away), 'Kai, away, 12-day streak');
  });
}

/// Pages p2 then p3, then the end.
class _Pages extends CircleFake {
  _Pages(CircleFake base) : super(membersList: base.membersList, feedItems: base.feedItems, letterList: base.letterList, memberPage: base.memberPage, sharingValue: base.sharingValue, shared: base.shared);
  final cursors = <String>[];

  @override
  Future<Result<FeedPage>> feed({String? cursor, int limit = 50, String? kind, int? profileId}) async {
    if (profileId != null) return super.feed(profileId: profileId);
    if (cursor == null) return Ok(FeedPage(items: feedItems, nextCursor: 'p2'));
    cursors.add(cursor);
    return Ok(FeedPage(nextCursor: cursor == 'p2' ? 'p3' : null));
  }
}
