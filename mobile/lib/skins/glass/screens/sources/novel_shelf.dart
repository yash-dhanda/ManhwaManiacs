import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';

/// A novel source's book shelf (glass 8.11): a 48 x 68 plate, the title in Literata 17, "by Author · 120 chapters · Ongoing", a
/// two-line blurb and the genres in `caption1` upper case.
class NovelShelf extends ConsumerWidget {
  const NovelShelf({super.key, required this.items, required this.sourceId});
  final List<SourceSeriesSummary> items;
  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        children: [
          for (final s in items)
            Semantics(
              button: true,
              label: s.title,
              excludeSemantics: true,
              onTap: () => unawaited(openSeries(ref, sourceId, s.id)),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(openSeries(ref, sourceId, s.id)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 68),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 48, height: 68, child: HomeCoverImage(url: s.coverUrl, width: 48))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Literata', fontSize: 17, color: gt.colorLabel1)),
                              GlassLabel([if (s.author != null) 'by ${s.author}', if (s.chapterCount > 0) '${s.chapterCount} chapters', if (s.status != null) s.status!].join(' · '), role: gt.typeFootnote, color: gt.colorLabel2),
                              if ((s.description ?? '').isNotEmpty) GlassLabel(s.description!, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2),
                              if (s.genres.isNotEmpty) GlassLabel(s.genres.take(3).join(' · '), role: gt.typeCaption1, upper: true, color: gt.colorLabel3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}
