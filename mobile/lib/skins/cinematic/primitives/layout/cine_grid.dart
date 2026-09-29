import 'package:flutter/widgets.dart';

/// The resolved column grid (cinematic 2.2.2): 4 columns / margin 16 / gutter 12 below 600 px,
/// 8 / 32 / 16 from 600 px. Horizontal margins grow to clear a notch: `max(margin, inset + 8)`.
class CineGridSpec {
  const CineGridSpec({required this.columns, required this.left, required this.right, required this.gutter, required this.width});
  final int columns;
  final double left, right, gutter, width;

  double get contentWidth => width - left - right;
  double get colWidth => (contentWidth - gutter * (columns - 1)) / columns;

  /// The width of [n] columns and the gutters between them.
  double span(int n) => n * colWidth + (n - 1) * gutter;

  /// The x offset of column [i] (0-based).
  double col(int i) => left + i * (colWidth + gutter);
}

abstract final class CineGrid {
  static CineGridSpec of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return resolve(mq.size.width, viewLeft: mq.viewPadding.left, viewRight: mq.viewPadding.right);
  }

  static CineGridSpec resolve(double width, {double viewLeft = 0, double viewRight = 0}) {
    final tablet = width >= 600;
    final margin = tablet ? 32.0 : 16.0;
    return CineGridSpec(
      columns: tablet ? 8 : 4,
      gutter: tablet ? 16 : 12,
      left: margin > viewLeft + 8 ? margin : viewLeft + 8,
      right: margin > viewRight + 8 ? margin : viewRight + 8,
      width: width,
    );
  }
}
