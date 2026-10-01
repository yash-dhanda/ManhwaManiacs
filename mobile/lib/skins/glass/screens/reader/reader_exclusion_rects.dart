import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Android system-gesture exclusion for the reader (glass 8.0.5, 8.14.3), logical px `[left, top, width, height]`: a 200 dp band
/// on the trailing edge centred on the scrub thumb (the rail's hit-strip width) and, in portrait on phones, the brightness band's
/// middle 200 dp on the leading edge. The rest of both edges stays system back (the OS caps exclusion at 200 dp per edge).
List<List<double>> readerExclusionRects({
  required Size size,
  required double thumbY,
  required double railWidth,
  required bool portraitPhone,
  required bool railShown,
}) {
  final out = <List<double>>[];
  if (railShown) {
    final top = (thumbY - 100).clamp(0.0, (size.height - 200).clamp(0.0, double.infinity));
    out.add([size.width - railWidth, top.toDouble(), railWidth, 200]);
  }
  if (portraitPhone) out.add([0, size.height / 2 - 100, 0.12 * size.width, 200]);
  return out;
}

/// Sends exclusion rects only on Android and only when they changed.
class ReaderExclusionSync {
  ReaderExclusionSync(this._send);
  final Future<void> Function(List<List<double>> rects) _send;
  List<List<double>>? _last;

  void apply(List<List<double>> rects) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_last != null && listEquals(_flat(_last!), _flat(rects))) return;
    _last = rects;
    _send(rects);
  }

  void clear() => apply(const []);

  static List<double> _flat(List<List<double>> r) => [for (final x in r) ...x];
}
