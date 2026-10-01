import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';

/// The 4.10 table rows of `glass/DESIGN.md`: name, duration cell, spec cell, last cell (Reduce Motion).
List<({String name, String duration, String reduced})> motionTableRows() {
  final lines = File('../docs/redesign/glass/DESIGN.md').readAsLinesSync();
  final start = lines.indexWhere((l) => l.startsWith('### 4.10 '));
  if (start < 0) throw StateError('no 4.10 heading in glass/DESIGN.md');
  final rows = <({String name, String duration, String reduced})>[];
  for (var i = start + 1; i < lines.length && !lines[i].startsWith('### '); i++) {
    final l = lines[i];
    if (!l.startsWith('| **')) continue;
    final cells = l.split('|').map((c) => c.trim()).toList(); // ['', name, duration, spring, spec, where, reduced, '']
    rows.add((name: cells[1].replaceAll('*', ''), duration: cells[2], reduced: cells[cells.length - 2]));
  }
  return rows;
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

void main() {
  test('MotionName.values is exactly the 116 bold names of the 4.10 table', () {
    final rows = motionTableRows();
    expect(rows.length, 116);
    expect({for (final r in rows) _norm(r.name)}.length, 116, reason: 'names are unique');
    expect(MotionName.values.map((m) => _norm(m.label)).toSet(), rows.map((r) => _norm(r.name)).toSet());
    expect(MotionName.values.length, 116);
  });

  test('an unknown motion label is not a MotionName (the enum makes it a compile error)', () {
    expect(MotionName.values.where((m) => m.label == 'NOT A MOVE'), isEmpty);
  });
}
