// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_hero.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

import 'feature_test_support.dart';

Future<void> _page(WidgetTester tester) => pumpFeature(
      tester,
      rig: FeatureRig(followed: followedRow()),
      child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())),
    );

Future<void> _open(WidgetTester tester) async {
  await _page(tester);
  await tester.longPress(find.byType(FeatureCover));
  await frames(tester, 700);
}

Finder get _caption => find.text('COVER · 720 × 1080');

void main() {
  testWidgets('long-press on the cover opens the Lightbox with its caption', (tester) async {
    await _open(tester);
    expect(_caption, findsOneWidget);
    expect(find.text('Tower of Dawn'), findsWidgets);
  });

  testWidgets('the V key opens it', (tester) async {
    await _page(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await frames(tester, 700);
    expect(_caption, findsOneWidget);
  });

  testWidgets('View cover in the overflow menu opens it', (tester) async {
    await _page(tester);
    await tester.tap(find.byTooltip('More'));
    await frames(tester, 500);
    await tester.tap(find.text('View cover'));
    await frames(tester, 900);
    expect(_caption, findsOneWidget);
  });

  testWidgets('x closes it', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('lightbox-close')));
    await frames(tester, 600);
    expect(_caption, findsNothing);
  });

  testWidgets('Esc closes it', (tester) async {
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(tester, 600);
    expect(_caption, findsNothing);
  });

  testWidgets('Android back closes it', (tester) async {
    await _open(tester);
    await tester.binding.handlePopRoute();
    await frames(tester, 600);
    expect(_caption, findsNothing);
  });

  testWidgets('a drag down past 120 px dismisses it; a short drag springs back', (tester) async {
    await _open(tester);
    // Slow drags (timed), so the fling speed never reaches 800 px/s.
    Future<void> slow(double dy) async {
      await tester.timedDrag(find.byType(InteractiveViewer), Offset(0, dy), const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
    }

    await slow(60);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await slow(160);
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('a double tap zooms to 250% with a chip that goes away', (tester) async {
    await _open(tester);
    final c = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(c);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(c);
    await frames(tester, 300);
    expect(find.byKey(const Key('lightbox-chip')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const Key('lightbox-chip')), findsNothing);
  });
}
