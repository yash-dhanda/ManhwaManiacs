import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/contrast.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_tint.dart';

import '../feature/feature_test_support.dart' show featureTheme;

Future<ValueNotifier<PageTintSource?>> _pump(WidgetTester tester, {bool enabled = true, bool reduced = false, required void Function(ReaderTint) seen}) async {
  final source = ValueNotifier<PageTintSource?>(null);
  addTearDown(source.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: featureTheme(TargetPlatform.android),
      builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: c!),
      home: ReaderTintHost(
        source: source,
        enabled: enabled,
        coverDuo: const Color(0xFF3060C0),
        child: Builder(
          builder: (context) {
            seen(ReaderTintScope.of(context));
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return source;
}

void main() {
  test('page.tint is L 0.06 and page.light clears 4.5:1 on black', () {
    final t = readerTintFor(const PageTintSource.page('#C82828'), const Color(0xFFB8B2A4));
    expect(HSLColor.fromColor(t.tint!).lightness, closeTo(0.06, 0.02));
    expect(contrastRatio(t.light!, Colors.black), greaterThanOrEqualTo(4.5));
    final cover = readerTintFor(PageTintSource.cover, const Color(0xFF3060C0));
    expect(HSLColor.fromColor(cover.tint!).hue, closeTo(HSLColor.fromColor(const Color(0xFF3060C0)).hue, 4));
  });

  testWidgets('a page seed dissolves over 800 ms; a second one retargets from where it is', (tester) async {
    ReaderTint? now;
    final source = await _pump(tester, seen: (t) => now = t);
    expect(now!.tint, isNull, reason: 'nothing sampled: untinted');
    source.value = const PageTintSource.page('#C82828');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final mid = now!.light!;
    await tester.pump(const Duration(milliseconds: 500));
    final end = now!.light!;
    expect(end, isNot(mid));
    expect(end, readerTintFor(const PageTintSource.page('#C82828'), const Color(0xFF3060C0)).light);
    source.value = PageTintSource.cover;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(now!.light, isNot(end));
    await tester.pump(const Duration(milliseconds: 900));
    expect(now!.light, readerTintFor(PageTintSource.cover, const Color(0xFF3060C0)).light);
  });

  testWidgets('the toggle off leaves the chrome untinted', (tester) async {
    ReaderTint? now;
    final source = await _pump(tester, enabled: false, seen: (t) => now = t);
    source.value = const PageTintSource.page('#C82828');
    await tester.pump(const Duration(seconds: 1));
    expect(now!.tint, isNull);
    expect(now!.light, isNull);
  });

  testWidgets('reduced motion swaps without a fade, at most once every 2 s', (tester) async {
    ReaderTint? now;
    final source = await _pump(tester, reduced: true, seen: (t) => now = t);
    source.value = const PageTintSource.page('#C82828');
    await tester.pump();
    final first = readerTintFor(const PageTintSource.page('#C82828'), const Color(0xFF3060C0));
    expect(now!.light, first.light, reason: 'no fade');
    source.value = const PageTintSource.page('#28C828');
    await tester.pump(const Duration(milliseconds: 500));
    expect(now!.light, first.light, reason: 'held: a swap already happened inside 2 s');
    await tester.pump(const Duration(milliseconds: 1600));
    expect(now!.light, readerTintFor(const PageTintSource.page('#28C828'), const Color(0xFF3060C0)).light);
  });
}
