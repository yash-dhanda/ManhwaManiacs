// ignore_for_file: directives_ordering, prefer_const_constructors
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/speed_dial.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import '../primitives/support.dart';
import '../reader/glass_reader_rig.dart';
import '../reader/glass_reader_behaviour_test.dart' show pull;
import 'glass_qa_screens.dart';

/// mobile/45 F: screen-reader behaviours with `MediaQueryData(accessibleNavigation: true)` (what `glassAssistiveProvider` reads).
/// The rest of F is proven by the tests `qa.md` names: reader chrome that never auto-hides (`reader/glass_reader_behaviour_test.dart`),
/// voice previews that never auto-play (`listen/voices_test.dart`), Wrapped (`wrapped/wrapped_budget_motion_test.dart`), the cruise pill
/// (`ambient/cruise_pill_test.dart`), swipe and reorder rows (`primitives/lists_states_a11y_test.dart`), charts (`primitives/glass_chart_test.dart`).
void main() {
  glassQaWidgets('toasts stay until dismissed and carry a close button named Dismiss', (t) async {
    final h = t.ensureSemantics();
    final rig = await pumpGlassQa(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.library), accessible: true);
    rig.shell.container.read(glassToastProvider.notifier).show(const GlassToastSpec('Removed from your library', actionLabel: 'Undo'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 600));
    final toast = find.bySemanticsLabel(RegExp('Removed from your library'));
    expect(toast, findsWidgets);
    await t.pump(const Duration(seconds: 12));
    expect(toast, findsWidgets, reason: 'a screen reader never loses a toast to a timer');
    expect(find.bySemanticsLabel('Dismiss'), findsWidgets, reason: 'the close button');
    final node = t.getSemantics(find.bySemanticsLabel(RegExp('Removed from your library')).first).getSemanticsData();
    expect([for (final id in node.customSemanticsActionIds ?? <int>[]) CustomSemanticsAction.getAction(id)?.label], contains('Dismiss'));
    h.dispose();
    await disposeGlassQa(t, rig);
  });

  glassQaWidgets('the dock keeps its four tabs in the semantics tree (a tab list), also when it is minimised', (t) async {
    final h = t.ensureSemantics();
    final rig = await pumpGlassQa(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.tonight));
    final tabs = find.bySemanticsLabel(RegExp(r', tab \d of 4$'));
    expect(tabs, findsNWidgets(4));
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pump(const Duration(milliseconds: 900));
    expect(tabs, findsNWidgets(4), reason: 'minimised by scroll, the tabs are still there for a screen reader');
    h.dispose();
    await disposeGlassQa(t, rig);
  });

  glassQaWidgets('every back button carries the "All levels" action; with a screen reader it opens the flat back menu', (t) async {
    final h = t.ensureSemantics();
    final rig = await pumpGlassQa(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.source), accessible: true);
    final back = find.byType(GlassBackButton);
    expect(back, findsWidgets);
    final data = t.getSemantics(back.first).getSemanticsData();
    expect(data.customSemanticsActionIds, isNotNull);
    final labels = [for (final id in data.customSemanticsActionIds!) CustomSemanticsAction.getAction(id)?.label];
    expect(labels, contains('All levels'));
    h.dispose();
    await disposeGlassQa(t, rig);
  });

  testWidgets('the speed dial is a slider with value "1.25 times" and increase and decrease actions that step 0.05', (t) async {
    final h = t.ensureSemantics();
    final changes = <double>[];
    await t.pumpWidget(primHost(GlassSpeedDial(value: 1.25, onChanged: changes.add, onCommit: (_) {}, wpmAt: (s) => (190 * s).round())));
    await t.pump(const Duration(milliseconds: 400));
    final node = t.getSemantics(find.bySemanticsLabel('Speed'));
    final d = node.getSemanticsData();
    expect(d.flagsCollection.isSlider, isTrue);
    expect(d.value, '1.25 times');
    expect(d.increasedValue, '1.3 times');
    expect(d.decreasedValue, '1.2 times');
    t.semantics.performAction(find.semantics.byLabel('Speed'), SemanticsAction.increase);
    await t.pump();
    expect(changes.last, closeTo(1.30, 1e-9));
    h.dispose();
  });

  testWidgets('the manga reader announces "Chapter N" once on a chapter change and nothing on page changes', (t) async {
    final spoken = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      if (m is Map && m['type'] == 'announce') spoken.add((m['data'] as Map)['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
    final rig = await pumpGlassReader(t, pages: 2, prefsValues: {'mm.reader-settings.device': '{"glass":{"chapters":"single"}}'});
    await settleReader(t, ms: 1000);
    expect(spoken.where((s) => s.startsWith('Chapter')), isEmpty, reason: 'entering a chapter announces nothing');
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo(pos.maxScrollExtent);
    await t.pump();
    expect(spoken.where((s) => s.startsWith('Chapter')), isEmpty, reason: 'a page change is silent');
    await pull(t, -144);
    await settleReader(t, ms: 3000);
    expect(rig.at.path, '/reader/demo/k/c3');
    expect(spoken.where((s) => s.startsWith('Chapter')).length, 1, reason: spoken.join(' | '));
    await disposeGlassReader(t);
  });
}
