// ignore_for_file: require_trailing_commas
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scroll_edge.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';

import '../../../screenshots/support/shot_harness.dart' show loadAppFonts;
import '../../cinematic/feature/feature_test_support.dart' show Recorder;
import '../home/home_rig.dart' show FakeHomeRepo, homeOverrides;
import '../novel/novel_rig.dart' show pumpGlassNovel;
import '../reader/glass_reader_rig.dart' show GlassReaderOrigin, pumpGlassReader;
import 'glass_qa_screens.dart';

/// The Glass layout guard: every Glass route on the smallest phone (375 x 667) at text scale 1.3 and 2.0 must lay out with no
/// RenderFlex overflow and no button whose label is ellipsized (a button wraps to two lines before it hides what it does). The
/// owner's Home cases ride along: rail titles cap at two lines with "See all" on the first, the content-mode pill never sits under
/// the bar icons, the accessory never shows without a title, and the scroll edges are a tint no taller than their bars + 16 px.
const _size = Size(375, 667);
const _padding = EdgeInsets.only(top: 20);
const _readers = {ScreenId.reader, ScreenId.readAll, ScreenId.novel};

/// Flutter errors (overflow) collected while [body] runs.
Future<List<String>> _errors(Future<void> Function() body) async {
  final errors = <String>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    final w = RegExp(r'relevant error-causing widget was:\n\s+(.*)\n?\s*(.*)').firstMatch(d.toString());
    errors.add('${d.exception.toString().split('\n').first} <- ${w?.group(1) ?? ''} ${w?.group(2) ?? ''}');
  };
  try {
    await body();
  } finally {
    FlutterError.onError = old;
  }
  return errors;
}

/// Labels of on-screen buttons that were cut with an ellipsis.
List<String> _ellipsizedButtons(WidgetTester t) => [
      for (final e in find.descendant(of: find.byType(GlassButton), matching: find.byType(RichText)).evaluate())
        if (e.renderObject case final RenderParagraph p when p.attached && p.hasSize && p.didExceedMaxLines) 'button "${p.text.toPlainText()}" ellipsized',
    ];

Rect _rect(WidgetTester t, Finder f) => t.getRect(f);

FakeHomeRepo _richHome() {
  final raw = File('test/fixtures/home/ready.json').readAsStringSync().replaceAll('Sword of the Ninth Spring', 'Surviving as a Genius on Borrowed Time');
  return FakeHomeRepo(() async => Ok(HomeFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>)));
}

void main() {
  // Real fonts: a label's wrap depends on its glyph widths.
  setUpAll(() async {
    await loadAppFonts();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity_status'), (_) async => null);
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => <String>['wifi']);
  });

  for (final scale in const [1.3, 2.0]) {
    for (final s in kGlassQaScreens) {
      glassQaWidgets('${s.id.id} at 375 wide, text scale $scale: no overflow, no ellipsized button', (t) async {
        GlassQaRig? rig;
        final errors = await _errors(() async {
          if (s.id == ScreenId.novel) {
            await pumpGlassNovel(t, size: _size, padding: _padding, textScale: scale);
          } else if (_readers.contains(s.id)) {
            await pumpGlassReader(t,
                size: _size,
                padding: _padding,
                origin: s.id == ScreenId.readAll ? GlassReaderOrigin.readAll : GlassReaderOrigin.manifest,
                extra: [readerRepositoryProvider.overrideWithValue(GlassQaReader(Recorder()))]);
          } else {
            rig = await pumpGlassQa(t, s, size: _size, padding: _padding, textScale: scale);
          }
          if (rig == null) await t.pump(const Duration(milliseconds: 1500));
        });
        expect([...errors, ..._ellipsizedButtons(t)], isEmpty);
        if (rig != null) {
          await disposeGlassQa(t, rig!);
        } else {
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 11));
        }
      });
    }
  }

  for (final scale in const [1.0, 1.3, 2.0]) {
    glassQaWidgets('Home at 375 wide, text scale $scale: two-line rail titles, See all on the first line, the pill clear of the icons, '
        'tint-only edges', (t) async {
      late GlassQaRig rig;
      final errors = await _errors(() async {
        rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.tonight, Routes.tonight(), novels: true, extra: homeOverrides(_richHome())),
            size: _size, padding: _padding, textScale: scale);
      });
      expect([...errors, ..._ellipsizedButtons(t)], isEmpty);

      // The content-mode pill sits beside the bar icons, never under them.
      final pill = _rect(t, find.byType(GlassContentModeSwitch));
      for (final e in find.byType(GlassBarIcon).evaluate()) {
        final r = t.getRect(find.byWidget(e.widget));
        expect(pill.overlaps(r), isFalse, reason: 'the Manga pill $pill overlaps a bar icon $r');
      }

      // The scroll edges: no blur band, each no taller than its bars + the 16 px fade.
      expect(find.descendant(of: find.byType(GlassScrollEdge), matching: find.byType(BackdropFilter)), findsNothing);
      final edges = find.byType(GlassScrollEdge).evaluate().map((e) => (e.widget as GlassScrollEdge, t.getSize(find.byWidget(e.widget)).height));
      for (final (w, h) in edges) {
        expect(h, lessThanOrEqualTo(w.edge == GlassEdge.top ? 20 + 52 + 16 : 85 + 56 + 16), reason: '${w.edge} edge $h px');
      }

      // Scroll the long "Because you read" rail into view: two lines at most, "See all" centred on its first line.
      final title = find.byWidgetPredicate((w) => w is LetterReveal && w.text.startsWith('Because you read'));
      await t.scrollUntilVisible(title, 300, scrollable: find.byType(Scrollable).first);
      await t.pump(const Duration(seconds: 2));
      final para = t.renderObject<RenderParagraph>(find.descendant(of: title, matching: find.byType(RichText)).first);
      final lines = para.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: para.text.toPlainText().length)).map((b) => b.top.round()).toSet();
      expect(lines.length, lessThanOrEqualTo(2), reason: 'the rail title runs to ${lines.length} lines');
      final seeAll = find.byWidgetPredicate((w) => w is GlassButton && (w.semanticsLabel ?? '').startsWith('See all, Because you read'));
      expect(seeAll, findsOneWidget);
      final titleTop = t.getTopLeft(title).dy;
      final firstLineH = para.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1)).first.toRect().height;
      expect(t.getCenter(seeAll).dy, closeTo(titleTop + firstLineH / 2, 3));

      // A continue item with no cover still reads as one: a title beside the glyph, minimised or not.
      rig.shell.container.read(glassAccessoryProvider.notifier).setContinue(GlassContinueAccessory(title: 'Continue The Lantern Courier', subtitle: 'Ch 143', coverUrl: '', onOpen: (_) {}));
      await t.pump(const Duration(seconds: 1));
      final acc = find.byType(GlassAccessoryBody);
      expect(acc, findsOneWidget);
      expect(find.descendant(of: acc, matching: find.textContaining('Continue The Lantern Courier')), findsOneWidget);

      await disposeGlassQa(t, rig);
      await t.pump(const Duration(minutes: 11));
    });
  }
}
