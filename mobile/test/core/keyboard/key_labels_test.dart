import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/keyboard/key_labels.dart';

void main() {
  const ios = TargetPlatform.iOS, and = TargetPlatform.android;
  const k = LogicalKeyboardKey.keyK;
  test('iOS uses Mac glyphs with no space', () {
    expect(formatKeyCombo([LogicalKeyboardKey.meta, k], ios), '⌘K');
    expect(formatKeyCombo([LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, k], ios), '⌥⇧K');
    expect(formatKeyCombo([LogicalKeyboardKey.control, k], ios), '⌃K');
    expect(formatKeyCombo([LogicalKeyboardKey.delete], ios), '⌫');
    expect(formatKeyCombo([LogicalKeyboardKey.backspace], ios), '⌫');
  });
  test('Android uses words joined by a space', () {
    expect(formatKeyCombo([LogicalKeyboardKey.control, k], and), 'Ctrl K');
    expect(formatKeyCombo([LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, k], and), 'Alt Shift K');
    expect(formatKeyCombo([LogicalKeyboardKey.delete], and), 'Del');
    expect(formatKeyCombo([LogicalKeyboardKey.backspace], and), 'Del');
  });
  test('named keys', () {
    expect(formatKeyCombo([LogicalKeyboardKey.escape], and), 'Esc');
    expect(formatKeyCombo([LogicalKeyboardKey.enter], ios), '↵');
    expect(formatKeyCombo([LogicalKeyboardKey.arrowUp], ios), '↑');
    expect(formatKeyCombo([LogicalKeyboardKey.arrowRight], and), '→');
    expect(formatKeyCombo([LogicalKeyboardKey.keyB], and), 'B');
  });
}
