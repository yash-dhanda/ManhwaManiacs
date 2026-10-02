// ignore_for_file: avoid_dynamic_calls
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/skin_preview.dart';

import '../screenshots/support/shot_harness.dart' show loadAppFonts;

Future<void> pumpPreview(WidgetTester t, {String skin = 'cinematic', Size box = kSkinPreviewSize, bool play = true, double textScale = 1, bool ticking = true}) async {
  t.view.physicalSize = const Size(390, 844) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), textScaler: TextScaler.linear(textScale)),
        child: TickerMode(
          enabled: ticking,
          child: Align(alignment: Alignment.topLeft, child: SizedBox.fromSize(size: box, child: SkinPreview(skin: skin, play: play))),
        ),
      ),
    ),
  );
}

AnimationController controllerOf(WidgetTester t) => (t.state(find.byType(SkinPreview)) as dynamic).controller as AnimationController;

Finder _private(String name) => find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

/// The scrolled content's top, in miniature px.
double contentTop(WidgetTester t, String skin) => t.getTopLeft(_private(skin == 'glass' ? '_PvGlassBody' : '_CineBody')).dy;

List<Rect> paragraphs(WidgetTester t, Finder under) => [
      for (final e in find.descendant(of: under, matching: find.byType(RichText)).evaluate())
        if ((e.renderObject! as RenderParagraph).text.toPlainText().trim().isNotEmpty) t.getRect(find.byWidget(e.widget)),
    ];

void main() {
  setUpAll(loadAppFonts);

  test('the preview is a live tree on one controller: no Timer, no snapshots, no frames, no heavy effects', () {
    final files = [
      'lib/skins/skin_preview.dart',
      'lib/skins/glass/screens/onboarding/skin_preview_loop.dart',
      'lib/skins/cinematic/screens/settings/edition/edition_card.dart',
    ];
    for (final f in files) {
      final src = File(f).readAsStringSync();
      for (final banned in ['Timer', 'toImage', 'Image.asset', 'precacheImage', 'BackdropFilter', 'ImageFilter', 'FragmentShader']) {
        expect(src.contains(banned), isFalse, reason: '$f uses $banned');
      }
    }
    expect(File(files.first).readAsStringSync(), contains('AnimationController(vsync: this'));
  });

  for (final skin in ['cinematic', 'glass']) {
    group(skin, () {
      testWidgets('a vsync ticker moves the content on every frame of a second, in small steps', (t) async {
        await pumpPreview(t, skin: skin);
        expect(controllerOf(t).isAnimating, isTrue);
        expect(t.binding.transientCallbackCount, greaterThan(0), reason: 'a Ticker is registered');
        await t.pump(const Duration(microseconds: 16667)); // the ticker's first tick is t = 0
        final tops = <double>[contentTop(t, skin)];
        for (var i = 0; i < 60; i++) {
          await t.pump(const Duration(microseconds: 16667));
          tops.add(contentTop(t, skin));
        }
        final steps = [for (var i = 1; i < tops.length; i++) tops[i - 1] - tops[i]];
        expect(steps.every((d) => d > 0), isTrue, reason: 'every one of the 60 frames scrolls a little further: $steps');
        expect(steps.reduce((a, b) => a > b ? a : b), lessThan(6), reason: 'no jumps');
        expect(tops.first - tops.last, greaterThan(20), reason: 'it visibly moves within a second');
      });

      testWidgets('still under reduced motion: the top, no frames scheduled', (t) async {
        await pumpPreview(t, skin: skin, play: false);
        final top = contentTop(t, skin);
        await t.pump(const Duration(seconds: 1));
        expect(contentTop(t, skin), top);
        expect(controllerOf(t).value, 0);
        expect(t.binding.hasScheduledFrame, isFalse);
      });

      testWidgets('pauses with TickerMode off and keeps its phase', (t) async {
        await pumpPreview(t, skin: skin);
        await t.pump(const Duration(seconds: 1));
        final v = controllerOf(t).value;
        await pumpPreview(t, skin: skin, ticking: false);
        await t.pump(const Duration(seconds: 1));
        expect(controllerOf(t).value, v);
        expect(t.binding.hasScheduledFrame, isFalse);
        await pumpPreview(t, skin: skin);
        await t.pump(const Duration(milliseconds: 100));
        expect(controllerOf(t).value, greaterThan(v));
      });

      testWidgets('nothing overflows, clips or overlaps inside the miniature at every host size and text scale', (t) async {
        for (final (box, scale) in const [
          (kSkinPreviewSize, 1.0),
          (Size(209, 453), 1.0),
          (Size(240, 520), 1.0),
          (Size(160, 347), 2.0),
          (Size(120, 260), 1.0),
          (Size(104, 225), 3.0),
        ]) {
          await pumpPreview(t, skin: skin, box: box, textScale: scale);
          for (final v in [0.0, 0.25, 0.5]) {
            controllerOf(t).value = v;
            await t.pump();
            expect(t.takeException(), isNull, reason: '$box @ $v');
          }
          final fit = (t.getSize(find.byType(SkinPreview)).width / 390).clamp(0.0, 1.0);
          for (final p in find.descendant(of: find.byType(SkinPreview), matching: find.byType(RichText)).evaluate()) {
            final r = p.renderObject! as RenderParagraph;
            expect(r.didExceedMaxLines, isFalse, reason: '${r.text.toPlainText()} at $box');
            expect(r.size.width, lessThanOrEqualTo(390 - 32), reason: '${r.text.toPlainText()} is wider than the page');
            expect(r.textSize.width, lessThanOrEqualTo(r.size.width + 0.5), reason: '${r.text.toPlainText()} is clipped');
          }
          for (final section in [_private(skin == 'glass' ? '_PvGlassBody' : '_CineBody'), _private(skin == 'glass' ? '_PvGlassTop' : '_CineTop'), _private(skin == 'glass' ? '_PvGlassDock' : '_CineTabs')]) {
            final rects = paragraphs(t, section);
            for (var i = 0; i < rects.length; i++) {
              for (var j = i + 1; j < rects.length; j++) {
                final o = rects[i].intersect(rects[j]);
                expect(o.width > 0.5 * fit && o.height > 0.5 * fit, isFalse, reason: 'text $i overlaps text $j at $box');
              }
            }
          }
        }
      });
    });
  }
}
