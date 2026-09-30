import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';

import 'circle_harness.dart';

MemberPage _page({CircleNow? now, CircleShares shares = const CircleShares(activity: true, reactions: true, shelves: true)}) => MemberPage(
      profile: riya,
      shares: shares,
      now: now,
      reading: const [
        MemberSeries(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader', chapterNumber: 212),
        MemberSeries(sourceId: 's', seriesKey: 'tog', title: 'Tower of God'),
      ],
      finished: const [MemberSeries(sourceId: 's', seriesKey: 'sl', title: 'Solo Leveling')],
      reactions: const [
        MemberSeries(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', title: 'Omniscient Reader', chapterNumber: 212, reaction: ReactionKind.loved, sealed: true),
        MemberSeries(sourceId: 's', seriesKey: 'sl', chapterKey: 'c1', title: 'Solo Leveling', chapterNumber: 1, reaction: ReactionKind.tears, sealed: false),
      ],
      shelves: const [SharedShelf(id: 4, name: 'Riya picks', seriesCount: 2, owner: riya, role: 'view_only')],
    );

Future<void> _pump(WidgetTester t, FakeCircleRepository repo, {Size size = const Size(390, 1800)}) async {
  await pumpCircle(t, repo, initial: '/circle/2', size: size);
  await settle(t, 2500);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('masthead, deck and rails; guarded reactions read "reacted to Ch. N"', (t) async {
    await _pump(t, FakeCircleRepository(memberPage: _page(), membersList: [member(riya, canReceive: true)]));
    expect(find.text('NO. 11 · CIRCLE / RIYA'), findsOneWidget);
    expect(headline('Riya'), findsOneWidget);
    expect(find.text('Reading 2 series · shares activity, reactions and shelves'), findsOneWidget);
    for (final h in ['Now reading', 'Recently finished', 'Their reactions', 'Shared shelves']) {
      expect(headline(h), findsOneWidget, reason: h);
    }
    expect(find.text('reacted to Ch. 212'), findsOneWidget);
    expect(find.text('Tears · Ch. 1'), findsOneWidget);
  });

  testWidgets('the ring shows while she is reading', (t) async {
    const duo = Ambient(duo: Color(0xFF3355AA), tint: Color(0xFF000000), ink: Color(0xFFFFFFFF));
    await _pump(t, FakeCircleRepository(memberPage: _page(now: nowReading(ambient: duo)), membersList: [member(riya, canReceive: true)]));
    expect(find.bySemanticsLabel('Riya, reading now'), findsOneWidget);
  });

  testWidgets('Recommend something to Riya preselects her in the sheet', (t) async {
    await _pump(t, FakeCircleRepository(memberPage: _page(shares: const CircleShares(activity: true, reactions: true, shelves: true, recommendations: true)), membersList: [member(riya, canReceive: true)]));
    await t.tap(find.text('Recommend something to Riya'));
    await settle(t, 800);
    expect(find.text('YOUR LIBRARY').evaluate().isNotEmpty || find.text('PASS IT ON').evaluate().isNotEmpty, isTrue);
    await t.tap(find.byKey(const ValueKey('pick-1')));
    await settle(t, 900);
    expect(find.text('PASS IT ON'), findsWidgets);
    expect(find.bySemanticsLabel('Riya'), findsWidgets);
  });

  testWidgets('a member who stopped sharing: 404 circle_member_not_sharing', (t) async {
    await _pump(t, FakeCircleRepository(membersList: [member(riya)]));
    expect(find.text('NOTE'), findsOneWidget);
    expect(headline("Riya isn't sharing right now."), findsOneWidget);
    expect(find.text('Back to the Circle'), findsOneWidget);
  });

  testWidgets('hit targets', (t) async {
    for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
      await pumpCircle(t, FakeCircleRepository(memberPage: _page(), membersList: [member(riya, canReceive: true)]), initial: '/circle/2', platform: p);
      await settle(t, 2000);
      expectHitTargets(t, p);
    }
  });
}
