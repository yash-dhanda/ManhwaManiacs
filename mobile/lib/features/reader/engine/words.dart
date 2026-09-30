import 'dart:ui' show Offset, Rect;

/// One OCR text box in page fractions.
class OcrWordBox {
  const OcrWordBox(this.rect, this.text);
  final Rect rect;
  final String text;
}

int wordCount(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

/// Words in boxes whose centre lies inside [rect] (same space as the boxes).
int wordsInRect(Iterable<OcrWordBox> boxes, Rect rect) =>
    boxes.where((b) => rect.contains(b.rect.center)).fold(0, (n, b) => n + wordCount(b.text));

/// Words in boxes whose centre, mapped through [toViewport] (page, fraction offset -> viewport px),
/// falls inside [viewport].
int wordsInViewport(Map<int, List<OcrWordBox>> boxesByPage, Offset Function(int page, Offset fraction) toViewport, Rect viewport) {
  var n = 0;
  boxesByPage.forEach((page, boxes) {
    for (final b in boxes) {
      if (viewport.contains(toViewport(page, b.rect.center))) n += wordCount(b.text);
    }
  });
  return n;
}
