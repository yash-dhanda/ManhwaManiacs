import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/router/routes.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/shared/widgets/glass_card.dart';
import 'package:manhwamaniacs/shared/widgets/series_cover_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// One title from the worldwide catalog, drawn by the contract's card rules.
///
/// A title one of the reader's sources carries opens that source's series
/// page. One nobody here carries does NOT pretend to: it says so, offers the
/// app's own search for the title (a source may carry it under another name),
/// and, when there is one, a link to an official place to read it. What to
/// show is decided by the getters on [WorldItem]; this only lays it out.
class WorldTitleCard extends ConsumerWidget {
  const WorldTitleCard({super.key, required this.item});

  final WorldItem item;

  void _search(BuildContext context, WidgetRef ref) {
    ref.read(searchQueryProvider.notifier).state = item.title;
    context.go(Routes.search);
  }

  Future<void> _readElsewhere(BuildContext context, WorldPlatform platform) async {
    final uri = Uri.tryParse(platform.url);
    // Server-supplied, so only ever a web page — never a scheme that makes
    // the phone dial, mail or open some other app.
    final launched = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: ${platform.url}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = item.openTarget;
    final elsewhere = item.readElsewhere;
    final badge = item.badgeLine;
    final stats =
        [item.chaptersLabel, item.ratingLabel].whereType<String>().join(' · ');
    final genres = item.cardGenres;
    final why = item.why;
    final muted = context.text.caption.copyWith(color: context.colors.muted);

    return GlassCard(
      onTap: target == null
          ? null
          : () => context.push(
                RoutePaths.sourceSeriesDetail(
                  target.sourceId,
                  target.seriesKey,
                ),
              ),
      padding: EdgeInsets.all(context.space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeriesCoverImage(
            url: item.coverUrl ?? '',
            width: 72,
            height: 108,
            withCredentials: false,
          ),
          SizedBox(width: context.space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 2),
                  Text(badge, maxLines: 1, style: muted),
                ],
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(stats, maxLines: 1, style: context.text.caption),
                ],
                if (genres.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    genres.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ],
                SizedBox(height: context.space.sm),
                if (target != null)
                  Text(
                    item.availabilityLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.caption.copyWith(
                      color: context.colors.cyan400,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else ...[
                  Text('Not on your sources', style: muted),
                  Wrap(
                    spacing: context.space.xs,
                    children: [
                      TextButton.icon(
                        onPressed: () => _search(context, ref),
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Search'),
                      ),
                      if (elsewhere != null)
                        TextButton.icon(
                          onPressed: () => _readElsewhere(context, elsewhere),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text('Read on ${elsewhere.site}'),
                        ),
                    ],
                  ),
                ],
                if (why != null) ...[
                  SizedBox(height: context.space.xs),
                  Text(why, style: muted.copyWith(height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
