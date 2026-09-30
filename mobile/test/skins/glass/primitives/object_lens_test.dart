import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/state_view.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/view_state.dart';

import 'support.dart';

void main() {
  testWidgets('the lens is 96 px with a 44 px Light glyph, a header title and one description', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(const SizedBox(width: 390, child: GlassObjectLens(situation: LensSituation.nothingDownloaded, title: 'Nothing saved yet', description: 'Downloaded chapters open with no connection.'))));
    await pumpFor(tester, 300);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byWidgetPredicate((w) => w is Icon && w.size == 44));
    expect(icon.icon, lensGlyph(LensSituation.nothingDownloaded));
    expect(tester.getSize(find.byWidgetPredicate((w) => w is SizedBox && w.width == 96 && w.height == 96).first), const Size(96, 96));
    expect(tester.getSemantics(find.text('Nothing saved yet')).getSemanticsData().flagsCollection.isHeader, isTrue);
    h.dispose();
  });

  testWidgets('the lens bobs 2 px and stands still under reduced motion', (tester) async {
    Future<double> top() async => tester.getTopLeft(find.byWidgetPredicate((w) => w is Icon && w.size == 44)).dy;
    await tester.pumpWidget(primHost(const SizedBox(width: 390, child: GlassObjectLens(situation: LensSituation.library, title: 'Empty'))));
    final a = await top();
    await pumpFor(tester, 1500);
    final b = await top();
    expect((a - b).abs(), inInclusiveRange(0.1, 2.001));
  });

  testWidgets('under reduced motion the lens stands still', (tester) async {
    Future<double> top() async => tester.getTopLeft(find.byWidgetPredicate((w) => w is Icon && w.size == 44)).dy;
    await tester.pumpWidget(primHost(const SizedBox(width: 390, child: GlassObjectLens(situation: LensSituation.library, title: 'Empty')), reduced: true));
    final c = await top();
    await pumpFor(tester, 1500);
    expect(await top(), c);
  });

  testWidgets('an offline lens retries when the connection returns, at most every 3 s, and hops once on success', (tester) async {
    final online = StreamController<bool>.broadcast();
    addTearDown(online.close);
    var now = DateTime(2026);
    var calls = 0;
    await tester.pumpWidget(primHost(SizedBox(
      width: 390,
      child: GlassObjectLens(
        situation: LensSituation.offline,
        tone: GlassLensTone.offline,
        title: "You're offline",
        clock: () => now,
        forceOnline: online.stream,
        onRetry: () async {
          calls++;
          return calls >= 2;
        },
      ),
    ),),);
    Future<double> top() async => tester.getTopLeft(find.byWidgetPredicate((w) => w is Icon && w.size == 44)).dy;
    online.add(true);
    await pumpFor(tester, 50);
    expect(calls, 1);
    online.add(true); // inside the cooldown
    await pumpFor(tester, 50);
    expect(calls, 1);
    now = now.add(const Duration(seconds: 4));
    final before = await top();
    online.add(true);
    await pumpFor(tester, 120);
    expect(calls, 2);
    expect(await top(), lessThan(before - 3), reason: 'hopped');
    await pumpFor(tester, 1200);
  });

  testWidgets('the state view shows the skeleton after 180 ms, the lens for empty, and the content', (tester) async {
    Widget view(GlassViewState s) => primHost(SizedBox(width: 390, height: 600, child: GlassStateView(state: s, emptyTitle: 'No series yet', child: const Text('content'))));
    await tester.pumpWidget(view(GlassViewState.loading));
    await pumpFor(tester, 100);
    expect(find.byType(GlassSkeleton), findsNothing);
    await pumpFor(tester, 120);
    expect(find.byType(GlassSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink()); // the overlay keeps its first entry, so rebuild the host
    await tester.pumpWidget(view(GlassViewState.empty));
    await pumpFor(tester, 100);
    expect(find.text('No series yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(view(GlassViewState.content));
    expect(find.text('content'), findsOneWidget);
  });
}
