import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';

const _size = Size(390, 844);

Future<ProviderContainer> pumpField(WidgetTester tester, {bool reduced = false, GlobalKey? key}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [glassMotionPrefsProvider.overrideWith((ref) => GlassMotionPrefs(reduced: reduced))],
      child: MediaQuery(
        data: const MediaQueryData(size: _size),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(key: key, child: ColoredBox(color: Colors.black, child: GlassAmbientField(random: math.Random(7)))),
        ),
      ),
    ),
  );
  return ProviderScope.containerOf(tester.element(find.byType(GlassAmbientField)));
}

GlassAmbientFieldState stateOf(WidgetTester tester) => tester.state<GlassAmbientFieldState>(find.byType(GlassAmbientField));

void main() {
  testWidgets('the field is one CustomPaint with no BackdropFilter and no ImageFiltered', (tester) async {
    await pumpField(tester);
    final inField = find.descendant(of: find.byType(GlassAmbientField), matching: find.byType(CustomPaint));
    expect(inField, findsOneWidget);
    expect(find.descendant(of: find.byType(GlassAmbientField), matching: find.byType(BackdropFilter)), findsNothing);
    expect(find.descendant(of: find.byType(GlassAmbientField), matching: find.byType(ImageFiltered)), findsNothing);
    expect(tester.widget<CustomPaint>(inField).painter, isA<GlassFieldPainter>());
  });

  testWidgets('anchors are unchanged over 15 s of fake time under reduced motion, and drift otherwise', (tester) async {
    await pumpField(tester, reduced: true);
    final before = stateOf(tester).anchors;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 2));
    expect(stateOf(tester).anchors, before);
    await tester.pumpWidget(const SizedBox());

    await pumpField(tester);
    final start = stateOf(tester).anchors;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 3));
    final moved = stateOf(tester).anchors;
    expect(moved, isNot(start));
    for (final a in moved) {
      expect(a.dx.abs(), lessThanOrEqualTo(kDriftRange + 1e-9));
      expect(a.dy.abs(), lessThanOrEqualTo(kDriftRange + 1e-9));
    }
  });

  testWidgets('colours cross-fade over 900 ms', (tester) async {
    final c = await pumpField(tester);
    c.read(glassAmbientProvider.notifier).state = const GlassAmbientSpec.mood(Mood.romantic);
    await tester.pump();
    final target = GlassBlobs.of(const GlassAmbientSpec.mood(Mood.romantic)).colors.first;
    await tester.pump(const Duration(milliseconds: 100));
    expect(stateOf(tester).currentColours.first, isNot(target));
    await tester.pump(const Duration(milliseconds: 500));
    expect(stateOf(tester).currentColours.first, isNot(target));
    await tester.pump(const Duration(milliseconds: 320));
    expect(stateOf(tester).currentColours.first, target);
  });

  testWidgets('under reduced motion the cross-fade is 200 ms', (tester) async {
    final c = await pumpField(tester, reduced: true);
    c.read(glassAmbientProvider.notifier).state = const GlassAmbientSpec.mood(Mood.horror);
    await tester.pump();
    final target = GlassBlobs.of(const GlassAmbientSpec.mood(Mood.horror)).colors.first;
    await tester.pump(const Duration(milliseconds: 100));
    expect(stateOf(tester).currentColours.first, isNot(target));
    await tester.pump(const Duration(milliseconds: 110));
    expect(stateOf(tester).currentColours.first, target);
  });

  testWidgets('the lower screen is true black and the top carries the blobs', (tester) async {
    final key = GlobalKey();
    final c = await pumpField(tester, key: key);
    c.read(glassAmbientProvider.notifier).state = const GlassAmbientSpec.aurora(opacity: 0.4);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final data = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData())!;
      image.dispose();
      return bytes;
    });
    int px(int x, int y) => (y * _size.width.toInt() + x) * 4;
    final top = px((0.18 * _size.width).round(), (0.08 * _size.height).round());
    expect(data!.getUint8(top) + data.getUint8(top + 1) + data.getUint8(top + 2), greaterThan(60), reason: 'a blob centre is lit');
    for (final y in [0.72, 0.85, 0.98]) {
      final i = px(200, (y * _size.height).round());
      expect([data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2)], [0, 0, 0], reason: 'y $y is true black');
    }
  });

  testWidgets('a GlassAmbientScope declares its field and clears it on leaving', (tester) async {
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app(bool on) => ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: on ? const GlassAmbientScope(spec: GlassAmbientSpec.aurora(), child: SizedBox()) : const SizedBox(),
          ),
        );
    await tester.pumpWidget(app(true));
    await tester.pump();
    final c = ProviderScope.containerOf(tester.element(find.byType(GlassAmbientScope)));
    expect(c.read(glassAmbientProvider), const GlassAmbientSpec.aurora());
    await tester.pumpWidget(app(false));
    await tester.pump();
    // A different scope tree, a different container: the declaration cleared with its owner.
    expect(c.read(glassAmbientProvider), isNull);
  });

  test('mood table: opacities and the default pair of colours', () {
    expect(kMoodOpacity[Mood.romantic], 0.20);
    expect(kMoodOpacity[Mood.horror], 0.26);
    expect(kMoodOpacity[Mood.neutral], 0.30);
    final d = GlassBlobs.of(const GlassAmbientSpec.mood(Mood.neutral));
    expect(d.colors[0], const Color(0xFF4336A3));
    expect(d.colors[1], kMoodDefaultDeep);
    expect(d.alpha, 0.30);
    final aurora = GlassBlobs.of(const GlassAmbientSpec.aurora());
    expect(aurora.alpha, 0.20);
    expect(aurora.colors, [const Color(0xFF8FD8FF), const Color(0xFFA99BFF), const Color(0xFFFF9ED8)]);
  });
}
