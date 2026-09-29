import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_list.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';

import 'cine_harness.dart';

void main() {
  testWidgets('Alt+Down moves the focused row and the menu Move items are wired', (t) async {
    final moves = <(int, int)>[];
    final names = ['Solo', 'Tower', 'Omniscient'];
    final announced = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      if (m is Map && m['type'] == 'announce') announced.add((m['data'] as Map)['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
    await pumpCine(
      t,
      StatefulBuilder(builder: (context, set) {
        return CineReorderableList<String>(
          items: names,
          idOf: (s) => s,
          titleOf: (s) => s,
          onMove: (f, to) {
            moves.add((f, to));
            set(() => names.insert(to, names.removeAt(f)));
          },
          itemBuilder: (context, s, i, handle, entries, sem) => CineRow(title: s, handle: handle, menu: entries, onTap: () {}),
        );
      },),
    );
    // Focus the first row, then Alt+Down.
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.pumpAndSettle();
    expect(moves, [(0, 1)]);
    expect(names.first, 'Tower');
    expect(announced, contains('Solo moved to position 2 of 3'));
  });
}
