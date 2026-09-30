import 'package:flutter/widgets.dart';

/// How the chapter is laid out: the continuous strip, one page per screen, or a two-page spread
/// per screen (glass 15.4).
enum ReaderLayout { strip, single, double }

/// How a page fits the paged stage.
enum ReaderPageFit { width, height, original }

/// What [ReaderEngine.setLayout] set: the layout, the reading direction and the skin's finger
/// physics for a paged layout (null is `PageScrollPhysics`). The engine holds no skin value.
@immutable
class ReaderLayoutSpec {
  const ReaderLayoutSpec({this.layout = ReaderLayout.strip, this.rtl = false, this.pagePhysics});

  final ReaderLayout layout;
  final bool rtl;
  final ScrollPhysics? pagePhysics;

  bool get paged => layout != ReaderLayout.strip;

  @override
  bool operator ==(Object other) =>
      other is ReaderLayoutSpec && other.layout == layout && other.rtl == rtl && other.pagePhysics == pagePhysics;

  @override
  int get hashCode => Object.hash(layout, rtl, pagePhysics);
}
