import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_stamp.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/world_card.dart';

import 'support.dart';

void main() {
  test('orbit dots: 8 / 6 / 4 px at 64 and 4 / 3 / 2 px at 28, one revolution per 1,400 ms', () {
    expect(orbitDotSizes(64), [8, 6, 4]);
    expect(orbitDotSizes(28), [4, 3, 2]);
    expect(kOrbitPeriod, const Duration(milliseconds: 1400));
  });

  test('the near dot is full brightness at 1.2, the far dot 0.4 at 0.8', () {
    // a = pi/2 is the front of the ellipse
    final near = OrbitPainter.dot(0, 0.25, 64);
    expect(near.opacity, closeTo(1, 1e-9));
    expect(near.scale, closeTo(1.2, 1e-9));
    final far = OrbitPainter.dot(0, 0.75, 64);
    expect(far.opacity, closeTo(0.4, 1e-9));
    expect(far.scale, closeTo(0.8, 1e-9));
    // the ellipse is rx 24, ry 9 at 64 px and scales down
    expect(OrbitPainter.dot(0, 0, 64).at.dx, closeTo(24, 1e-9));
    expect(OrbitPainter.dot(0, 0.25, 64).at.dy, closeTo(9, 1e-9));
    expect(OrbitPainter.dot(0, 0, 28).at.dx, closeTo(24 * 28 / 64, 1e-9));
  });

  test('reduced motion pulses the dots in place, in sequence', () {
    final a = OrbitPainter.dot(0, 0.1, 64, reduced: true);
    final b = OrbitPainter.dot(0, 0.5, 64, reduced: true);
    expect(a.at, OrbitPainter.dot(0, 0.9, 64, reduced: true).at, reason: 'the dot does not travel');
    expect(a.opacity, isNot(closeTo(b.opacity, 0.05)));
    for (final t in [0.0, 0.2, 0.4, 0.6, 0.8]) {
      final o = OrbitPainter.dot(1, t, 28, reduced: true).opacity;
      expect(o, inInclusiveRange(0.4, 1.0));
    }
  });

  testWidgets('the orbit is labelled Thinking', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(const ThinkingOrbit(size: 64)));
    await pumpFor(tester, 300);
    expect(find.bySemanticsLabel('Thinking'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('glass-thinking-orbit'))), const Size(64, 64));
    h.dispose();
  });

  testWidgets('AiNotice: the exact lines, long or short, admin hint under not_configured, never danger', (tester) async {
    await tester.pumpWidget(primHost(const SizedBox(width: 390, child: AiNotice(reason: 'not_configured', long: true, admin: true, alternative: Text('Try world picks')))));
    await pumpFor(tester, 100);
    expect(find.text("AI isn't set up on this server. Everything else works as usual."), findsOneWidget);
    expect(find.text('Add an AI API key on the server to turn it on.'), findsOneWidget);
    expect(find.text('Try world picks'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(primHost(const SizedBox(width: 390, child: AiNotice(reason: 'rate_limited', retrySeconds: 9))));
    await pumpFor(tester, 100);
    expect(find.text('AI is busy, retrying in 9 s'), findsOneWidget);
    expect(find.text('Add an AI API key on the server to turn it on.'), findsNothing);
  });

  testWidgets('the stale stamp appears after 24 h with the exact wording', (tester) async {
    final now = DateTime(2026, 9, 30, 12);
    await tester.pumpWidget(primHost(AiStamp(generatedAt: now.subtract(const Duration(hours: 23)), now: now)));
    expect(find.textContaining('Picked'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(primHost(AiStamp(generatedAt: now.subtract(const Duration(hours: 73)), now: now)));
    expect(find.text('Picked 3 days ago'), findsOneWidget);
  });

  testWidgets('a long world-card title wraps before the source badge instead of running under it', (tester) async {
    await tester.pumpWidget(primHost(const GlassWorldCard.available(
      cover: SizedBox(),
      title: 'The Extraordinarily Long Title Of A Series That Never Ends',
      kind: 'Manhwa · Ongoing',
      stats: '120 ch · 8.4',
      why: 'Because you read Solo Leveling',
      source: 'MangaSource',
      extraSources: 2,
    ), size: const Size(834, 1194),),);
    await tester.pump(const Duration(milliseconds: 300));
    final title = tester.getRect(find.textContaining('Extraordinarily'));
    final badge = tester.getRect(find.byType(GlassBadge).first);
    expect(title.right, lessThanOrEqualTo(badge.left));
    expect(tester.takeException(), isNull);
  });
}
