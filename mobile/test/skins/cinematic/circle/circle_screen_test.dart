import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';

import 'circle_harness.dart';

FakeCircleRepository _repo({bool riyaReading = false}) => FakeCircleRepository(
      membersList: [member(riya, now: riyaReading ? nowReading() : null), member(arjun)],
      feedItems: [
        feedItem('1', FeedKind.finishedChapter, n: 142),
        feedItem('2', FeedKind.started, actor: arjun, title: 'Solo Leveling', seriesKey: 'sl', followed: true),
      ],
      sharingValue: const Sharing(activity: true),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the readers strip and the dispatches with their sentences', (tester) async {
    await pumpCircle(tester, _repo());
    await settle(tester);
    expect(find.text('NO. 11 — THE CIRCLE'), findsOneWidget);
    expect(find.text('Riya'), findsWidgets);
    expect(find.text('Arjun'), findsWidgets);
    expect(find.textContaining('Riya finished chapter 142 of Omniscient Reader.', findRichText: true), findsOneWidget);
    expect(find.text('Read it too'), findsOneWidget); // Arjun's series is already followed
    expect(find.text('FOLLOWING'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.byType(CineBadge).evaluate().where((e) => (e.widget as CineBadge).variant == CineBadgeVariant.now), isEmpty);
  });

  testWidgets('a member reading now wears the NOW badge', (tester) async {
    await pumpCircle(tester, _repo(riyaReading: true));
    await settle(tester);
    expect(find.text('NOW'), findsOneWidget);
    expect(find.bySemanticsLabel('Riya, reading now'), findsOneWidget);
  });

  testWidgets('nobody shares: the circle is quiet', (tester) async {
    await pumpCircle(tester, FakeCircleRepository());
    await settle(tester);
    expect(find.text('THE CIRCLE IS QUIET'), findsOneWidget);
    expect(headline('Nobody has shared their reading yet.'), findsOneWidget);
    expect(find.text('Sharing settings'), findsOneWidget);
  });

  testWidgets('nobody shares but a letter came: the LETTERS tab is there', (tester) async {
    await pumpCircle(tester, FakeCircleRepository().._letters([letter(1)]));
    await settle(tester);
    expect(find.text('LETTERS'), findsOneWidget);
  });

  testWidgets('an error shows the correction', (tester) async {
    await pumpCircle(tester, FakeCircleRepository()..failWith = const ApiError(statusCode: 500, code: 'x', message: 'x'));
    await settle(tester);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(headline("The circle didn't load."), findsOneWidget);
  });

  testWidgets('tabs: the letters count is raised and tab empties read exactly', (tester) async {
    await pumpCircle(tester, _repo().._letters([letter(1), letter(2)]), initial: '/circle?tab=reading');
    await settle(tester);
    expect(find.text('LETTERS'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('wide aside: only letters on screen turn read', (tester) async {
    final repo = _repo().._letters([for (var i = 1; i <= 8; i++) letter(i)]);
    await pumpCircle(tester, repo, size: const Size(1200, 800));
    await settle(tester, 4000);
    final read = repo.log.where((l) => l.startsWith('patchLetter') && l.endsWith(' read')).length;
    expect(read, lessThan(8));
  });
}

extension on FakeCircleRepository {
  void _letters(List<Letter> l) => letterList = l;
}
