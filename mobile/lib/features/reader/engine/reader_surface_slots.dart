import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';

/// The decorations drawn *inside* the page strip, injected by the skin so the
/// engine holds no visuals of its own.
class ReaderSurfaceSlots {
  const ReaderSurfaceSlots({
    required this.chapterSeam,
    required this.brokenPage,
    required this.pagedCornerRadius,
  });

  /// The divider above the first page of every chapter after the first,
  /// sized by the engine to exactly `kChapterSeamExtent`.
  final Widget Function(BuildContext context, ReaderChapter chapter, Axis axis)
      chapterSeam;

  /// What a page that failed to load shows, inside its reserved box.
  final Widget Function(BuildContext context, VoidCallback retry) brokenPage;

  /// Corner radius of a page card in left-to-right / right-to-left paging.
  final double pagedCornerRadius;
}
