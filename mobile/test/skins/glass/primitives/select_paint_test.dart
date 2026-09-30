import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_paint.dart';

void main() {
  test('the paint mode is the new state of the first item', () {
    expect(paintModeFrom(firstWasSelected: false), isTrue);
    expect(paintModeFrom(firstWasSelected: true), isFalse);
  });

  test('a range along a pointer path selects or deselects everything it crosses', () {
    final start = <int>{2};
    expect(paintAlong(start, [3, 4, 5], true), {2, 3, 4, 5});
    expect(paintAlong({1, 2, 3, 4}, [3, 2], false), {1, 4});
    expect(paintAlong(start, [3, 4], true, enabled: (i) => i != 4), {2, 3});
  });

  test('ranges run either direction over the visible order', () {
    final v = [10, 11, 12, 13, 14];
    expect(rangeBetween(v, 11, 13), [11, 12, 13]);
    expect(rangeBetween(v, 13, 11), [11, 12, 13]);
    expect(rangeBetween(v, 11, 99), isEmpty);
  });

  test('Shift+Space extends from the last toggled item', () {
    final c = GlassSelectModeController<int>()..order = () => [1, 2, 3, 4, 5];
    c.toggle(2);
    c.extendTo(5);
    expect(c.selected, {2, 3, 4, 5});
    c.exit();
    expect(c.active, isFalse);
    expect(c.selected, isEmpty);
  });

  test('select all stops at the loaded page of 200 and says so', () {
    final all = List<int>.generate(412, (i) => i);
    expect(selectAllVisible(all).length, 200);
    expect(selectAllVisible(all.sublist(0, 30)).length, 30);
    expect(selectionCapMessage(200, 412), 'Selected 200 of 412 shown');
    expect(selectionCapMessage(30, 30), isNull);
    expect(selectAllLabel(412), 'Select all (412 visible)');
    expect(selectedCountLabel(3), '3 selected');
  });
}
