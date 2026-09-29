import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// One notification per series (glass 7.7): cover 44 x 66, the series title `headline`, "3 new - Ch 141-143"
/// `footnote` `iris400`, the time `caption1` `label3`, and chapter chips that each open the reader (its swipe
/// actions are `mobile/28`).
class GlassNotificationCard extends StatelessWidget {
  const GlassNotificationCard({super.key, required this.cover, required this.title, required this.summary, required this.time, required this.chapters, this.onOpenSeries, this.onOpenChapter});
  final Widget cover;
  final String title;

  /// "3 new · Ch 141–143".
  final String summary;
  final String time;
  final List<int> chapters;
  final VoidCallback? onOpenSeries;
  final ValueChanged<int>? onOpenChapter;

  @override
  Widget build(BuildContext context) => GlassSlab(
        onTap: onOpenSeries,
        semanticsLabel: '$title, $summary, $time',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 44, height: 66, child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusXs + 2), child: cover)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: GlassLabel(title, role: gt.typeHeadline, maxLines: 2)),
                      const SizedBox(width: 8),
                      GlassLabel(time, role: gt.typeCaption1, color: gt.colorLabel3),
                    ],
                  ),
                  GlassLabel(summary, role: gt.typeFootnote, color: gt.colorIris400),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, children: [for (final c in chapters) GlassChip(label: 'Ch $c', onPressed: onOpenChapter == null ? null : () => onOpenChapter!(c))]),
                ],
              ),
            ),
          ],
        ),
      );
}
