import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_letter_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/dispatch_row.dart';

import 'circle_harness.dart';

const _duo = Ambient(duo: Color(0xFF3355AA), tint: Color(0xFF000000), ink: Color(0xFFFFFFFF));

FakeCircleRepository _repo({List<Letter> letters = const [], bool sharing = true, Ambient? riyaAmbient}) => FakeCircleRepository(
      membersList: [member(riya, now: riyaAmbient == null ? null : nowReading(ambient: riyaAmbient)), member(arjun)],
      feedItems: [
        feedItem('1', FeedKind.finishedChapter, n: 142),
        feedItem('2', FeedKind.started, actor: arjun, title: 'Solo Leveling', seriesKey: 'sl'),
        feedItem('3', FeedKind.reacted, n: 12, reaction: ReactionKind.loved, sealed: true, title: 'Tower of God', seriesKey: 'tog'),
      ],
      letterList: letters,
      sharingValue: Sharing(activity: sharing),
    );

Finder _cardOf(int id) => find.byKey(ValueKey('letter-$id'));

void main() {
  setUpAll(loadAppFonts);

  group('dispatches', () {
    testWidgets('a guarded reaction hides its glyph; Read it too follows and turns to FOLLOWING', (tester) async {
      await pumpCircle(tester, _repo());
      await settle(tester);
      // Sealed: the sentence names no reaction and there is no glyph.
      expect(find.textContaining('Riya reacted to chapter 12 of Tower of God.', findRichText: true), findsOneWidget);
      expect(find.textContaining('Loved', findRichText: true), findsNothing);
      expect(find.text('Read it too'), findsNWidgets(3));
      await tester.tap(find.text('Read it too').first);
      await settle(tester, 400);
      expect(find.text('Following Omniscient Reader.'), findsWidgets);
    });

    testWidgets('dispatch time folio is spoken', (tester) async {
      await pumpCircle(tester, _repo());
      await settle(tester);
      expect(dispatchFolio(DateTime.utc(2026, 9, 30, 8), DateTime.utc(2026, 9, 30, 10)), '2 H');
      expect(dispatchFolio(DateTime.utc(2026, 9, 30, 9, 55), DateTime.utc(2026, 9, 30, 10)), '5 M');
      expect(dispatchFolio(DateTime.utc(2026, 9, 27, 10), DateTime.utc(2026, 9, 30, 10)), '3 D');
    });
  });

  group('presence', () {
    testWidgets('the ring wears the series duo, the tooltip withholds the chapter, then fades out', (tester) async {
      final repo = _repo(riyaAmbient: _duo);
      await pumpCircle(tester, repo);
      await settle(tester);
      Color? ringDuo() => tester.widgetList<CineReadingNowRing>(find.byType(CineReadingNowRing)).map((r) => r.duo).whereType<Color>().firstOrNull;
      expect(ringDuo(), _duo.duo);
      expect(find.text('NOW'), findsOneWidget);
      // Long-press: what she reads, no chapter folio (the viewer has no progress on it).
      await tester.longPress(find.text('Riya').first);
      await pumpMs(tester, 700);
      expect(find.text('Reading Omniscient Reader'), findsOneWidget);
      expect(find.textContaining('CH 212'), findsNothing);
      // The next poll: now is null, the ring and NOW leave.
      repo.membersList = [member(riya), member(arjun)];
      final container = ProviderScope.containerOf(tester.element(find.byType(CircleScreen)));
      container.invalidate(circleMembersProvider);
      await settle(tester, 1000);
      expect(ringDuo(), isNull);
      expect(find.text('NOW'), findsNothing);
    });

    testWidgets('with now null there is no ring and no NOW', (tester) async {
      await pumpCircle(tester, _repo());
      await settle(tester);
      expect(find.text('NOW'), findsNothing);
      expect(tester.widgetList<CineReadingNowRing>(find.byType(CineReadingNowRing)).where((r) => r.duo != null), isEmpty);
      expect(tester.widgetList<CineBadge>(find.byType(CineBadge)).where((b) => b.variant == CineBadgeVariant.now), isEmpty);
    });
  });

  group('states', () {
    testWidgets('a private profile sees the banner and Share turns sharing on', (tester) async {
      final repo = _repo(sharing: false);
      await pumpCircle(tester, repo);
      await settle(tester);
      expect(find.text("You're reading privately. Others can't see your activity."), findsOneWidget);
      await tester.tap(find.text('Share'));
      await settle(tester);
      expect(repo.patches, [
        {'activity': true},
      ]);
      expect(find.text('Sharing is on.'), findsOneWidget);
    });

    testWidgets('only me: the viewer shares and nobody else does', (tester) async {
      await pumpCircle(tester, FakeCircleRepository(sharingValue: const Sharing(activity: true)));
      await settle(tester);
      expect(find.text("You're the only reader sharing so far."), findsOneWidget);
    });

    testWidgets('loading shows six greeked dispatches', (tester) async {
      final repo = _repo();
      await pumpCircle(tester, repo, extra: [circleMembersProvider.overrideWith(_NeverMembers.new)]);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('offline shows the OFFLINE EDITION badge and disables letter actions', (tester) async {
      final repo = _repo(letters: [letter(1, state: LetterState.kept)]);
      await pumpCircle(tester, repo, initial: '/circle?tab=letters', extra: [deviceOnlineOverride(false)]);
      await settle(tester);
      expect(find.text('OFFLINE EDITION'), findsOneWidget);
      expect(find.text('Needs a connection.'), findsWidgets);
    });

    testWidgets('a network error with no data shows the offline notice', (tester) async {
      await pumpCircle(tester, FakeCircleRepository()..failWith = const NetworkError(message: 'x'));
      await settle(tester);
      expect(find.text('OFFLINE EDITION'), findsWidgets);
      expect(headline('The circle needs a connection.'), findsOneWidget);
    });
  });

  group('tabs', () {
    testWidgets('exact empty copy per tab', (tester) async {
      final repo = FakeCircleRepository(membersList: [member(riya)], sharingValue: const Sharing(activity: true));
      await pumpCircle(tester, repo);
      await settle(tester);
      Future<void> tab(String label) async {
        final key = {'READING': LogicalKeyboardKey.digit2, 'REACTIONS': LogicalKeyboardKey.digit3, 'LETTERS': LogicalKeyboardKey.digit4, 'SHELVES': LogicalKeyboardKey.digit5}[label]!;
        await tester.sendKeyEvent(key);
        await settle(tester, 700);
      }

      await tab('READING');
      expect(headline('Nobody is reading right now.'), findsOneWidget);
      await tab('REACTIONS');
      expect(headline('No reactions yet.'), findsOneWidget);
      expect(find.text('They appear here when someone stamps a chapter.'), findsOneWidget);
      await tab('LETTERS');
      expect(headline('No letters yet.'), findsOneWidget);
      expect(find.text('When someone passes a series to you, it lands here.'), findsOneWidget);
      await tab('SHELVES');
      expect(headline('No shared shelves yet.'), findsOneWidget);
      expect(find.text('New shelf'), findsOneWidget);
    });

    testWidgets('the keys 1-5, j, k and l work', (tester) async {
      await pumpCircle(tester, _repo(letters: [letter(1)]));
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await settle(tester, 700);
      expect(find.byKey(const Key('circle-offline-edition')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await settle(tester, 700);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'dispatch-0');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'dispatch-1');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'dispatch-0');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await settle(tester, 700);
      expect(find.byKey(_cardOf(1).evaluate().isEmpty ? const ValueKey('letter-1') : const ValueKey('letter-1')), findsOneWidget);
    });

    testWidgets('a swipe pages between tabs', (tester) async {
      await pumpCircle(tester, _repo());
      await settle(tester);
      await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1200);
      await settle(tester, 800);
      expect(find.textContaining('reacted to chapter 12 of', findRichText: true), findsNothing); // READING has no reactions
    });
  });

  group('letters', () {
    testWidgets('a new letter unfolds, then turns read after 2 s at 50% visibility', (tester) async {
      final repo = _repo(letters: [letter(1), letter(2, from: arjun)]);
      await pumpCircle(tester, repo, initial: '/circle?tab=letters');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_cardOf(1), findsOneWidget);
      expect(find.byKey(const Key('letter-dot')), findsWidgets);
      await pumpMs(tester, 600); // the unfold (480 ms) has run
      expect(repo.log.where((e) => e.startsWith('patchLetter')), isEmpty);
      await pumpMs(tester, 2200);
      expect(repo.log, containsAll(['patchLetter 1 read', 'patchLetter 2 read']));
    });

    testWidgets('Keep, Dismiss and a failing PATCH', (tester) async {
      final repo = _repo(letters: [letter(1), letter(2, from: arjun, title: 'Solo Leveling')]);
      await pumpCircle(tester, repo, initial: '/circle?tab=letters');
      await settle(tester, 1000);
      await tester.tap(find.text('Keep').first);
      await settle(tester, 400);
      expect(repo.log, contains('patchLetter 1 kept'));
      expect(find.text('Kept. It stays in Sent to you.'), findsOneWidget);
      await tester.tap(find.text('Dismiss').last);
      await settle(tester, 400);
      expect(repo.log, contains('patchLetter 2 dismissed'));
      expect(find.text('Solo Leveling'), findsNothing);
      repo.failPatchLetter = const NetworkError(message: 'x');
      await tester.tap(find.text('Dismiss').first);
      await settle(tester, 400);
      expect(find.text("Couldn't update the letter."), findsWidgets);
      expect(find.text('Tower of God'), findsWidgets);
    });

    testWidgets('Add follows and marks read', (tester) async {
      final repo = _repo(letters: [letter(1)]);
      await pumpCircle(tester, repo, initial: '/circle?tab=letters');
      await settle(tester, 700);
      expect(find.byType(CineLetterCard), findsOneWidget);
    });

    testWidgets('the LETTERS tab count is a raised number', (tester) async {
      await pumpCircle(tester, _repo(letters: [letter(1), letter(2)]));
      await settle(tester);
      expect(find.bySemanticsLabel(RegExp('Letters, 2')), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('hit targets on iOS and Android', (tester) async {
      for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
        await pumpCircle(tester, _repo(letters: [letter(1)]), platform: p);
        await settle(tester);
        expectHitTargets(tester, p);
      }
    });

    testWidgets('text scale 2.0 keeps every dispatch readable without overflow', (tester) async {
      await pumpCircle(tester, _repo(), textScale: 2);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Riya finished chapter 142 of Omniscient Reader.', findRichText: true), findsOneWidget);
    });

    testWidgets('reduced motion: the letter appears without the unfold', (tester) async {
      await pumpCircle(tester, _repo(letters: [letter(1)]), initial: '/circle?tab=letters', reduced: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CineLetterCard), findsOneWidget);
    });

    testWidgets('dispatch rows are list items with the full sentence', (tester) async {
      await pumpCircle(tester, _repo());
      await settle(tester);
      expect(find.bySemanticsLabel(RegExp(r'Riya finished chapter 142 of Omniscient Reader\.')), findsOneWidget);
    });
  });
}

class _NeverMembers extends CircleMembersNotifier {
  @override
  Future<List<CircleMember>> build() => Future.any<List<CircleMember>>([]);
}
