import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart' show searchResultCoverUrl;
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/result_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_common.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// One result section: a header (28 px logo or monogram, the name in `headline`, a count badge) and a rail of 112 x 168 result cards.
/// A failed source shows "This source didn't answer" with Retry (4 skeletons while retrying).
class SearchGroupSection extends ConsumerWidget {
  const SearchGroupSection({super.key, required this.group, required this.retrying, required this.onRetry, this.grid = false, this.headerFocus});
  final SourceSearchGroup group;
  final bool retrying;
  final VoidCallback onRetry;
  final bool grid;
  final FocusNode? headerFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(apiBaseUrlProvider);
    final count = group.total > group.items.length ? group.total : group.items.length;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            headingLevel: 2,
            focusable: true,
            child: Focus(
              focusNode: headerFocus,
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: group.isLocal
                        ? Icon(GlassGlyph28.books.regular, size: 22, color: gt.colorInfo)
                        : (group.iconUrl != null && group.iconUrl!.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(7), child: HomeCoverImage(url: group.iconUrl, width: 28))
                            : GlassSourceMonogram(name: group.sourceName, sourceId: group.key, size: 28)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(child: GlassLabel(group.isLocal ? 'In your library' : group.sourceName, role: gt.typeHeadline)),
                  if (!group.hasError && group.items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(10)),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), child: GlassLabel('$count', role: gt.typeCaption1, color: gt.colorLabel2)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (group.hasError)
            retrying
                ? GlassSkeletonGroup(child: Row(children: [for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(right: 10), child: GlassSkeleton(width: 80, height: 120, index: i))]))
                : Row(
                    children: [
                      Icon(GlassGlyph28.cloudSlash.regular, size: 18, color: gt.colorDanger),
                      const SizedBox(width: 8),
                      Flexible(child: GlassLabel("This source didn't answer", role: gt.typeFootnote, color: gt.colorLabel2)),
                      const SizedBox(width: 8),
                      GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onRetry),
                    ],
                  )
          else if (grid)
            Wrap(spacing: 12, runSpacing: 12, children: [for (final i in group.items) _card(context, ref, i, base)])
          else
            SizedBox(
              height: 208,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: group.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _card(context, ref, group.items[i], base),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, GlobalSearchItem item, String base) {
    final cover = searchResultCoverUrl(base, item.coverUrl);
    final sourceId = item.source ?? group.source;
    void open() {
      if (item.isLocal || sourceId == null) {
        unawaited(ref.read(skinRouterProvider).push<void>(Routes.featureByFollow(item.seriesId)));
      } else {
        unawaited(openSeries(ref, sourceId, item.seriesId));
      }
    }

    return SizedBox(
      width: 112,
      child: GlassResultCard(
        cover: cover == null ? ColoredBox(color: gt.colorSurface2) : GlassCoverImage(url: cover, width: 112),
        title: item.title,
        hideSource: true,
        onTap: open,
      ),
    );
  }
}

/// "Show 12 sources with no matches" disclosure row.
class QuietSourcesRow extends StatelessWidget {
  const QuietSourcesRow({super.key, required this.count, required this.open, required this.onToggle});
  final int count;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => GlassTap(
        label: open ? 'Hide $count sources with no matches' : 'Show $count sources with no matches',
        onTap: onToggle,
        child: GlassLabel(open ? 'Hide $count sources with no matches' : 'Show $count sources with no matches', role: gt.typeSubhead, color: gt.colorIris500),
      );
}
