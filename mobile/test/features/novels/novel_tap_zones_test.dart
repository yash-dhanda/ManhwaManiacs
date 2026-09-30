import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_tap_zones.dart';

void main() {
  const size = Size(400, 800);
  NovelTapAction at(String p, double x, double y) => novelTapAction(p, Offset(x, y), size);

  test('standard 25 / 50 / 25', () {
    expect(at('standard', 50, 400), NovelTapAction.back);
    expect(at('standard', 200, 400), NovelTapAction.menu);
    expect(at('standard', 350, 400), NovelTapAction.forward);
    expect(at('standard', 60, 10), NovelTapAction.back, reason: 'the top band is not special in standard');
  });

  test('both margins advance, centre is the menu', () {
    expect(at('bothMargins', 50, 400), NovelTapAction.forward);
    expect(at('bothMargins', 350, 400), NovelTapAction.forward);
    expect(at('bothMargins', 200, 400), NovelTapAction.menu);
  });

  test('one hand: left back, top 12 % menu, the rest forward', () {
    expect(at('oneHand', 50, 400), NovelTapAction.back);
    expect(at('oneHand', 50, 40), NovelTapAction.menu);
    expect(at('oneHand', 350, 90), NovelTapAction.menu);
    expect(at('oneHand', 350, 100), NovelTapAction.forward);
    expect(at('oneHand', 200, 400), NovelTapAction.forward);
  });
}
