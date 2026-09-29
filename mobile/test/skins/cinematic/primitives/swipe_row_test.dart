import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';

import 'cine_harness.dart';

void main() {
  testWidgets('Mark read springs back and dims', (t) async {
    var n = 0;
    await pumpCine(t, CineSwipeRow(id: 'a', kind: CineSwipeKind.markRead, onCommit: () => n++, child: const CineRow(title: 'Chapter 4')));
    await t.drag(find.text('Chapter 4'), const Offset(-300, 0));
    await t.pumpAndSettle();
    expect(n, 1);
    expect(find.text('Chapter 4'), findsOneWidget);
    expect(t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, lessThan(1));
  });

  testWidgets('Remove leaves the list and commits', (t) async {
    var n = 0;
    await pumpCine(t, StatefulBuilder(builder: (context, set) {
      return Column(children: [
        if (n == 0) CineSwipeRow(id: 'a', kind: CineSwipeKind.remove, onCommit: () => set(() => n++), child: const CineRow(title: 'Chapter 4')),
        const CineRow(title: 'Chapter 5'),
      ],);
    },),);
    await t.drag(find.text('Chapter 4'), const Offset(-300, 0));
    await t.pumpAndSettle();
    expect(n, 1);
    expect(find.text('Chapter 4'), findsNothing);
    expect(find.text('Chapter 5'), findsOneWidget);
  });
}
