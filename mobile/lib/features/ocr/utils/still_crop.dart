import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';

/// The 16:9 crop window, in page fractions, for a dialogue still. The box
/// fills 60 % of the still's width; the window is centred on the box and
/// clamped inside the page. [pageAspect] = page width / page height.
Rect stillCropWindow(OcrBox? box, double pageAspect) {
  final ratio =
      9 / 16 * pageAspect; // window height fraction per width fraction
  if (box == null) return Rect.fromLTWH(0, 0, 1, math.min(1, ratio));
  var w = math.min(1.0, box.w / 0.6);
  var h = w * ratio;
  if (h > 1) {
    h = 1;
    w = h / ratio;
  }
  final cx = box.x + box.w / 2, cy = box.y + box.h / 2;
  final left = (cx - w / 2).clamp(0.0, 1 - w);
  final top = (cy - h / 2).clamp(0.0, 1 - h);
  return Rect.fromLTWH(left, top, w, h);
}
