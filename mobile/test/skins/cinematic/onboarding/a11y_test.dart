// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values, unnecessary_import
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';

import 'onboarding_test_support.dart';

void main() {
  for (final step in [1, 2, 3, 4, 5]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('step $step renders at text scale $scale without overflow', (t) async {
        await pumpOnboarding(t, step: step, profileStep: step, scale: scale);
        await settleFor(t, 1200);
        expect(t.takeException(), isNull);
      });
    }

    for (final (name, size) in [('tablet', const Size(834, 1194)), ('landscape phone', const Size(844, 390))]) {
      testWidgets('step $step on a $name renders without overflow', (t) async {
        await pumpOnboarding(t, step: step, profileStep: step, size: size);
        await settleFor(t, 1200);
        expect(t.takeException(), isNull);
      });
    }

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets('step $step: every control is at least ${platform == TargetPlatform.android ? 48 : 44} and clear of its neighbours ($platform)', (t) async {
        await pumpOnboarding(t, step: step, profileStep: step, platform: platform);
        await settleFor(t, 1200);
        final min = platform == TargetPlatform.android ? 48.0 : 44.0;
        final rects = <Rect>[];
        // Only what the pager shows: rows scrolled out of the viewport are clipped, not tappable.
        final pager = t.getRect(find.byType(PageView));
        final screen = Offset.zero & t.view.physicalSize;
        for (final e in find.byType(CinePressable).evaluate()) {
          final box = e.renderObject! as RenderBox;
          if (!box.attached || !box.hasSize) continue;
          final r = box.localToGlobal(Offset.zero) & box.size;
          if (!r.overlaps(screen)) continue;
          final inPager = e.findAncestorWidgetOfExactType<PageView>() != null;
          if (inPager && !pager.contains(r.center)) continue;
          expect(r.width, greaterThanOrEqualTo(min - 0.01), reason: '${e.widget} width');
          expect(r.height, greaterThanOrEqualTo(min - 0.01), reason: '${e.widget} height');
          rects.add(inPager ? r.intersect(pager) : r);
        }
        expect(rects, isNotEmpty);
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final a = rects[i], b = rects[j];
            final nested = a.contains(b.topLeft) && a.contains(b.bottomRight) || b.contains(a.topLeft) && b.contains(a.bottomRight);
            expect(a.deflate(0.5).overlaps(b.deflate(0.5)) && !nested, isFalse, reason: 'controls overlap: $a $b');
          }
        }
      });
    }
  }

  group('loading states', () {
    for (final step in [2, 3, 5]) {
      testWidgets('step $step shows its galley after 120 ms and the content once the catalog answers', (t) async {
        final repo = FakeOnboardingRepo()..hold = Completer<void>();
        await pumpOnboarding(t, step: step, profileStep: step, repo: repo);
        await t.pump(const Duration(milliseconds: 200));
        expect(t.takeException(), isNull);
        repo.hold!.complete();
        await settleFor(t, 1500);
        expect(t.takeException(), isNull);
      });
    }
  });

  testWidgets('reduced motion: the love band shows at once and the words need no animation', (t) async {
    await pumpOnboarding(t, step: 3, profileStep: 3, reduced: true);
    await settleFor(t, 300);
    await t.tap(find.bySemanticsLabel('Romance, not chosen'));
    await t.pump();
    await t.tap(find.bySemanticsLabel('Romance, liked'));
    await t.pump();
    expect(find.bySemanticsLabel('Romance, loved'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a NetworkError from the catalog reads as offline, an ApiError as unreachable', (t) async {
    final repo = FakeOnboardingRepo()..error = const ApiError(statusCode: 500, code: 'x', message: 'x');
    await pumpOnboarding(t, step: 2, repo: repo);
    await settleFor(t, 800);
    expect(find.text('OFFLINE EDITION'), findsNothing);
    expect(find.text('Next'), findsOneWidget, reason: 'unreachable formats stay selectable plates');
  });
}
