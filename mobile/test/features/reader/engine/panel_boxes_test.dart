import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/panel_boxes.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';

void main() {
  test('mapping', () {
    const r = Rect.fromLTWH(0, 0, 1, 0.5);
    expect(panelBoxesOf(const PanelsFound([r])), [r]);
    expect(panelBoxesOf(const PanelsNone()), isNull);
    expect(panelBoxesOf(const PanelsFinding()), isNull);
    expect(panelBoxesOf(null), isNull);
  });
}
