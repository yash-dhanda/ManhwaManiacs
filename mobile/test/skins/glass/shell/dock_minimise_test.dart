import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_state.dart';

void main() {
  test('minimises after 20 px down and restores after 12 px up', () {
    final l = DockMinimiseLogic();
    expect(l.onScroll(10, atTop: false), isFalse);
    expect(l.onScroll(9, atTop: false), isFalse);
    expect(l.onScroll(1, atTop: false), isTrue);
    expect(l.onScroll(-11, atTop: false), isTrue);
    expect(l.onScroll(-1, atTop: false), isFalse);
  });

  test('reversing resets the other accumulator', () {
    final l = DockMinimiseLogic();
    l.onScroll(15, atTop: false);
    l.onScroll(-1, atTop: false);
    expect(l.onScroll(15, atTop: false), isFalse);
  });

  test('the top of a list restores it', () {
    final l = DockMinimiseLogic()..onScroll(30, atTop: false);
    expect(l.minimised, isTrue);
    expect(l.onScroll(-1, atTop: true), isFalse);
  });

  test('never while a screen reader is on', () {
    final l = DockMinimiseLogic();
    expect(l.onScroll(200, atTop: false, assistive: true), isFalse);
  });
}
