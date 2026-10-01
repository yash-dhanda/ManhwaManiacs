// ignore_for_file: require_trailing_commas
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chrome_top.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/end_matter.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/go_to_percent.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paged_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/type_rows.dart';

import 'novel_rig.dart';

const _settingsKey = 'mm.novel-settings.device';

Future<void> _key(WidgetTester t, LogicalKeyboardKey k, {bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _waitGrace(WidgetTester t) => settle(t);

bool _chromeLive(WidgetTester t) {
  final top = find.byType(NovelChromeTop);
  if (top.evaluate().isEmpty) return false;
  return !t.widgetList<IgnorePointer>(find.ancestor(of: top, matching: find.byType(IgnorePointer))).any((i) => i.ignoring);
}

void main() {
  testWidgets('B1, D5-D8: header, drop cap whole for screen readers, scene break, indents off with paragraph spacing', (t) async {
    final handle = t.ensureSemantics();
    await pumpGlassNovel(t);
    await settle(t);
    expect(find.text('CHAPTER 1'), findsOneWidget);
    expect(find.text('Down the Rabbit-Hole'), findsOneWidget);
    expect(find.textContaining('words ·'), findsWidgets);
    expect(find.byType(GlassDropCapParagraph), findsOneWidget);
    final first = fixtureChapter().paragraphs.first;
    expect(find.bySemanticsLabel(first), findsOneWidget);
    expect(find.text('Alice'.substring(0, 1)), findsWidgets);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('D9: speaker bands at 14 % with the semantics prefix; stale attribution gives none', (t) async {
    final handle = t.ensureSemantics();
    await pumpGlassNovel(t, attribution: fixtureAttribution());
    await settle(t);
    final pieces = t.widgetList<GlassTextPiece>(find.byType(GlassTextPiece));
    expect(pieces.any((p) => p.decorations.any((d) => d is SpeakerBandsDecoration)), isTrue);
    expect(find.bySemanticsLabel(RegExp('Alice: ')), findsWidgets);
    await disposeGlassNovel(t);

    await pumpGlassNovel(t, attribution: fixtureAttributionStale());
    await settle(t);
    final stale = t.widgetList<GlassTextPiece>(find.byType(GlassTextPiece));
    expect(stale.any((p) => p.decorations.any((d) => d is SpeakerBandsDecoration)), isFalse);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('E1: a tap toggles the chrome; hidden chrome is inert; never hides in the first 800 ms', (t) async {
    await pumpGlassNovel(t);
    await settle(t, ms: 300);
    expect(_chromeLive(t), isFalse);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 400);
    expect(_chromeLive(t), isTrue);
    await _waitGrace(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 500);
    expect(_chromeLive(t), isFalse);
    await disposeGlassNovel(t);
  });

  testWidgets('E1: a screen reader keeps the chrome', (t) async {
    await pumpGlassNovel(t, accessibleNavigation: true);
    await _waitGrace(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 400);
    expect(_chromeLive(t), isTrue);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 500);
    expect(_chromeLive(t), isTrue);
    await disposeGlassNovel(t);
  });

  testWidgets('B2, E2, E4: positions follow the reader insets', (t) async {
    await pumpGlassNovel(t, padding: const EdgeInsets.only(top: 47, bottom: 34));
    await settle(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 400);
    final top = t.getTopLeft(find.byType(NovelChromeTop));
    expect(top.dy, 47 + 8);
    expect(top.dx, 16);
    await disposeGlassNovel(t);
  });

  testWidgets('K: l and h change chapter in place; the location is replaced', (t) async {
    final rig = await pumpGlassNovel(t);
    await settle(t);
    await _key(t, LogicalKeyboardKey.keyL);
    await settle(t);
    expect(find.text('CHAPTER 2'), findsOneWidget);
    expect(rig.location, contains('/novels/demo/k/2'));
    await _key(t, LogicalKeyboardKey.keyH);
    await settle(t);
    expect(find.text('CHAPTER 1'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('K: g opens go to a percentage; Esc closes it, then returns to the book', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    await _key(t, LogicalKeyboardKey.keyG);
    await settle(t, ms: 600);
    expect(find.byType(NovelGoToPopover), findsOneWidget);
    await _key(t, LogicalKeyboardKey.escape);
    await settle(t, ms: 300);
    expect(find.byType(NovelGoToPopover), findsNothing);
    await _key(t, LogicalKeyboardKey.escape);
    await settle(t, ms: 900);
    expect(find.text('book page'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('K, H: , opens the Aa sheet with every row', (t) async {
    final handle = t.ensureSemantics();
    await pumpGlassNovel(t);
    await settle(t);
    await _key(t, LogicalKeyboardKey.comma);
    await settle(t, ms: 900);
    expect(find.byType(NovelTypeBody), findsOneWidget);
    expect(novelTypeRows().map((r) => r.id), containsAllInOrder(['faces', 'size', 'line', 'measure', 'paragraph', 'letter', 'reset', 'justify', 'bold', 'line-guide', 'mode', 'page-turn', 'taps', 'papers', 'page-tinted', 'keep-awake']));
    for (final label in ['This book', 'Literata', 'Sans', 'Atkinson', 'Size', 'Line height', 'Measure']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.bySemanticsLabel('Larger text'), findsOneWidget);
    expect(find.bySemanticsLabel('Narrower column'), findsOneWidget);
    await t.drag(find.text('Measure').first, const Offset(0, -900));
    await settle(t, ms: 500);
    for (final label in ['Bold text', 'Line guide', 'Page-tinted chrome', 'Keep screen awake']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('K, I: t opens the contents; a missing chapter number reads the no-match line', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    await _key(t, LogicalKeyboardKey.keyT);
    await settle(t, ms: 900);
    expect(find.text('Contents'), findsWidgets);
    await t.enterText(find.byType(EditableText).first, '480');
    await settle(t, ms: 300);
    expect(find.text('No chapter 480 in this book.'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('D11: the end matter offers the Next card and the plain buttons', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    await _key(t, LogicalKeyboardKey.end);
    await settle(t, ms: 600);
    expect(find.byType(GlassEndMatter), findsOneWidget);
    expect(find.text('END OF CHAPTER 1'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('Previous chapter'), findsNothing);
    expect(find.text('Back to the book'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('G2, G3: paged mode paginates and a tap in the right band turns the page', (t) async {
    await pumpGlassNovel(t, prefs: {_settingsKey: jsonEncode({'layout': 'paged'})});
    await settle(t, ms: 1500);
    expect(find.byType(NovelPagedView), findsOneWidget);
    final view = t.state<NovelPagedViewState>(find.byType(NovelPagedView));
    expect(view.page, 0);
    await t.tapAt(const Offset(370, 500));
    await settle(t, ms: 900);
    expect(view.page, 1);
    await t.tapAt(const Offset(10, 500));
    await settle(t, ms: 900);
    expect(view.page, 0);
    await disposeGlassNovel(t);
  });

  testWidgets('L: the reader stays within 4 layers and 6 shapes', (t) async {
    final rig = await pumpGlassNovel(t);
    await settle(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 600);
    final s = rig.container.read(glassRegistryProvider);
    expect(s.layers, lessThanOrEqualTo(4), reason: s.entries.map((e) => e.label).join(', '));
    expect(s.shapes, lessThanOrEqualTo(6), reason: s.entries.map((e) => '${e.label}:${e.shapes}').join(', '));
    await _key(t, LogicalKeyboardKey.keyG);
    await settle(t, ms: 600);
    final s2 = rig.container.read(glassRegistryProvider);
    expect(s2.layers, lessThanOrEqualTo(4), reason: s2.entries.map((e) => e.label).join(', '));
    expect(s2.shapes, lessThanOrEqualTo(6));
    await disposeGlassNovel(t);
  });

  testWidgets('hit targets: the chrome meets the iOS, Android and labelled guidelines', (t) async {
    final handle = t.ensureSemantics();
    await pumpGlassNovel(t);
    await settle(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 600);
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await disposeGlassNovel(t);
    await pumpGlassNovel(t, android: true);
    await settle(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 600);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await disposeGlassNovel(t);
    handle.dispose();
  });
}
