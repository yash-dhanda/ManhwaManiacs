import 'dart:ui' show Rect, Size;

import 'package:manhwamaniacs/features/ocr/models/page_text.dart';

/// One `GET /ocr/chapter` box as the API sends it: fractions 0-1 with a top-left origin, as
/// `x`, `y`, `width`, `height`, or `left`, `top`, `right`, `bottom` when `x` / `y` are null.
/// Returns null when there is no usable geometry.
OcrTextBox? parseApiBox(Map<Object?, Object?> raw) {
  double? n(Object? v) => v is num ? v.toDouble() : null;
  final text = raw['text'] is String ? raw['text']! as String : '';
  var x = n(raw['x']), y = n(raw['y']), w = n(raw['width']), h = n(raw['height']);
  if (x == null || y == null) {
    final l = n(raw['left']), t = n(raw['top']), r = n(raw['right']), b = n(raw['bottom']);
    if (l == null || t == null || r == null || b == null) return null;
    x = l;
    y = t;
    w = r - l;
    h = b - t;
  }
  if (w == null || h == null) return null;
  return OcrTextBox(text: text, x: x, y: y, width: w, height: h, confidence: n(raw['confidence']));
}

/// The box as a rect of fractions, clamped to the page and never empty; null without geometry.
Rect? boxFraction(OcrTextBox b) {
  if (b.x == null || b.y == null || b.width == null || b.height == null) return null;
  final l = b.x!.clamp(0.0, 1.0), t = b.y!.clamp(0.0, 1.0);
  final r = (b.x! + b.width!).clamp(0.0, 1.0), bo = (b.y! + b.height!).clamp(0.0, 1.0);
  if (r <= l || bo <= t) return null;
  return Rect.fromLTRB(l, t, r, bo);
}

/// The box placed in a page box of [size] (top-left origin).
Rect? boxInPage(OcrTextBox b, Size size) {
  final f = boxFraction(b);
  if (f == null) return null;
  return Rect.fromLTRB(f.left * size.width, f.top * size.height, f.right * size.width, f.bottom * size.height);
}
