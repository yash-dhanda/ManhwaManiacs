import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/utils/ocr_boxes.dart';

void main() {
  test('x/y/width/height stay as fractions', () {
    final b = parseApiBox({'text': 'hi', 'x': 0.1, 'y': 0.2, 'width': 0.3, 'height': 0.1})!;
    expect(boxFraction(b), const Rect.fromLTWH(0.1, 0.2, 0.3, 0.1));
  });
  test('left/top/right/bottom when x/y are null', () {
    final b = parseApiBox({'text': 'hi', 'left': 0.1, 'top': 0.2, 'right': 0.4, 'bottom': 0.5})!;
    final r = boxFraction(b)!;
    expect(r.left, closeTo(0.1, 1e-9));
    expect(r.width, closeTo(0.3, 1e-9));
    expect(r.height, closeTo(0.3, 1e-9));
  });
  test('no geometry, empty and clamped boxes', () {
    expect(parseApiBox({'text': 'x'}), isNull);
    expect(boxFraction(parseApiBox({'x': 0.5, 'y': 0.5, 'width': 0, 'height': 0.1})!), isNull);
    expect(boxFraction(parseApiBox({'x': 0.9, 'y': 0.9, 'width': 0.5, 'height': 0.5})!), const Rect.fromLTRB(0.9, 0.9, 1, 1));
  });
  test('placed in a page box', () {
    final b = parseApiBox({'x': 0.5, 'y': 0.25, 'width': 0.25, 'height': 0.5})!;
    expect(boxInPage(b, const Size(400, 800)), const Rect.fromLTRB(200, 200, 300, 600));
  });
}
