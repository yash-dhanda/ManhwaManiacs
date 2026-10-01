// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';

import '../primitives/support.dart';

/// mobile/45 I6 (14.8, 11): the non-gesture alternative does the same thing as the gesture. Reorder is proven here (the drag has four
/// semantics actions and the Alt+arrow keys); the other rows of the gesture matrix are proven in the test each row of `qa.md` names, or
/// are device-only (marked "awaiting owner").
void main() {
  Widget list(List<String> order, void Function(int, int) onReorder) => SizedBox(
        width: 390,
        height: 600,
        child: GlassReorderList<String>(
          items: order,
          nameOf: (s) => s,
          onReorder: onReorder,
          itemBuilder: (context, item, i, info) => GlassListRow(title: item, trailing: info.handle()),
        ),
      );

  testWidgets('Move up, Move down, Move to top and Move to bottom are semantics actions that reorder like the drag does', (t) async {
    final h = t.ensureSemantics();
    final moves = <(int, int)>[];
    await t.pumpWidget(primHost(list(['A', 'B', 'C', 'D'], (a, b) => moves.add((a, b)))));
    await t.pump(const Duration(milliseconds: 400));
    // The row whose actions include all four moves: the third row, C.
    SemanticsNode? row;
    void walk(SemanticsNode n) {
      final d = n.getSemanticsData();
      final labels = [for (final id in d.customSemanticsActionIds ?? <int>[]) CustomSemanticsAction.getAction(id)?.label];
      if (['Move up', 'Move down', 'Move to top', 'Move to bottom'].every(labels.contains)) row ??= n;
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }
    walk(t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
    expect(row, isNotNull, reason: 'a row carries Move up, Move down, Move to top and Move to bottom');
    t.binding.renderViews.first.owner!.semanticsOwner!.performAction(row!.id, SemanticsAction.customAction, CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: 'Move to top')));
    await t.pump(const Duration(milliseconds: 600));
    expect(moves, [(1, 0)], reason: 'the first row with all four actions is the second item (the first has no Move up)');
    h.dispose();
  });

  testWidgets('Alt+Arrow moves the focused row', (t) async {
    final moves = <(int, int)>[];
    await t.pumpWidget(primHost(list(['A', 'B', 'C'], (a, b) => moves.add((a, b)))));
    await t.pump(const Duration(milliseconds: 400));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    for (var i = 0; i < 6 && moves.isEmpty; i++) {
      await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await t.pump(const Duration(milliseconds: 500));
      if (moves.isEmpty) await t.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    expect(moves, isNotEmpty, reason: 'Alt+ArrowDown on a focused row reorders it');
  });
}
