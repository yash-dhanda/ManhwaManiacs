import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/followed_series_meta.dart';
import 'package:manhwamaniacs/features/library/providers/local_read_marks_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_subtitle.dart';
import 'package:manhwamaniacs/features/library/utils/read_state_label.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/widgets/pressable.dart';
import 'package:manhwamaniacs/shared/widgets/series_cover_image.dart';

/// A cover-first Library grid card for one followed series.
///
/// Matches the sources/search cards: cover, title, and a single muted meta
/// line — which is omitted entirely when nothing true is known, rather than
/// claiming "0 chapters".
class FollowedSeriesCard extends ConsumerWidget {
  const FollowedSeriesCard({
    super.key,
    required this.series,
    required this.coverWidth,
    required this.meta,
    required this.onTap,
    this.onLongPress,
  });

  final FollowedSeries series;

  /// Logical width of one grid tile — the card fills its cell, so only the
  /// grid that laid it out knows how wide the cover will actually be.
  final double coverWidth;

  final FollowedSeriesMeta meta;
  final VoidCallback onTap;

  /// Opens the per-series menu (favourite, remove). Null on a surface that
  /// has no menu to open — a multi-select, say — rather than a no-op, so the
  /// press has no haptic to answer with either.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final coverUrl = followedSeriesCoverUrl(baseUrl, series);
    // Only this series' answer, so a page turned in the reader rebuilds the
    // one card it moved rather than the whole shelf.
    final local = ref.watch(
      localReadMarksProvider.select((marks) => marks.forFollow(series)),
    );
    final subtitle = followedSeriesCardSubtitle(series, meta, local: local);
    final newCount = libraryCardNewCount(
      readStateWithLocal(series.readState, local),
      unreadNotifications: meta.unreadCount,
    );

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.radii.xl),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl == null)
                    ColoredBox(color: context.colors.surface2)
                  else
                    SeriesCoverImage(
                      url: coverUrl,
                      displayWidth: coverWidth,
                      borderRadius: context.radii.xl,
                    ),
                  if (newCount > 0)
                    Positioned(
                      top: context.space.sm,
                      right: context.space.sm,
                      child: _NewBadge(count: newCount),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.space.sm),
          Text(
            series.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.label.copyWith(
              color: context.colors.fg,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: context.space.xxs),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.copyWith(color: context.colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Warm amber "N NEW" pill: chapters past the furthest one read (or, for a
/// row with no read state, unread new-chapter notifications).
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.sm,
        vertical: context.space.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Text(
        newCountBadgeText(count),
        style: context.text.caption.copyWith(
          color: context.colors.primaryFg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
