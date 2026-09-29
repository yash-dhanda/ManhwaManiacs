import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';

/// A series card (glass 7.7): a [GlassPoster], 8 px, the title `footnote` 13/600 in two lines and the meta
/// `caption1` `label3` in one line. No slab: the poster is the card.
class GlassSeriesCard extends StatelessWidget {
  const GlassSeriesCard({
    super.key,
    required this.poster,
    required this.title,
    this.meta,
    this.width,
  });

  /// Skeleton of the same shape.
  const GlassSeriesCard.loading({super.key, this.width})
      : poster = null,
        title = '',
        meta = null;

  final GlassPoster? poster;
  final String title;
  final String? meta;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final w = width ?? poster?.width;
    if (poster == null) {
      final pw = w ?? 124;
      return GlassSkeletonGroup(
        child: SizedBox(
          width: pw,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassSkeleton(width: pw, height: pw * 1.5, delayed: false),
              const SizedBox(height: 8),
              GlassSkeleton(width: pw * 0.85, height: 12, radius: 6, delayed: false),
              const SizedBox(height: 6),
              GlassSkeleton(width: pw * 0.5, height: 10, radius: 5, delayed: false),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        poster!,
        const SizedBox(height: 8),
        GlassLabel(title, role: gt.typeFootnote, wght: 600, maxLines: 2),
        if (meta != null) GlassLabel(meta!, role: gt.typeCaption1, color: gt.colorLabel3),
      ],
    );
  }
}
