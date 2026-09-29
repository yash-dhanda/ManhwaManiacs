import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_labels.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_tooltip.dart';

/// A Library wall poster (cinematic 7.7, 8.9): [CinePoster] with the shelf's caption, badges and
/// hover icons. WALL shows the caption below and every badge; COMPACT shows no caption, only the
/// `NEW` badge and, for a mouse, a tooltip with the title. Reused by the collection member wall.
class LibraryPoster extends StatelessWidget {
  const LibraryPoster({
    super.key,
    required this.series,
    required this.coverUrl,
    this.density = ShelfDensity.wall,
    this.gateOpen = false,
    this.saved = false,
    this.selectMode = false,
    this.selected = false,
    this.groupIndex,
    this.flickerIndex = 0,
    this.onTap,
    this.onQuickLook,
    this.onFavourite,
    this.onNotify,
    this.dragHandle,
    this.focusNode,
    this.disabled = false,
    this.heroTag = true,
  });

  final FollowedSeries series;
  final String? coverUrl;
  final ShelfDensity density;

  /// The 18+ certificate shows only with the gate open and a series that resolves mature.
  final bool gateOpen;

  /// A chapter of it is saved on this device.
  final bool saved;
  final bool selectMode, selected, disabled, heroTag;
  final int? groupIndex;
  final int flickerIndex;
  final VoidCallback? onTap, onQuickLook, onFavourite, onNotify;
  final Widget? dragHandle;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final s = series;
    final compact = density == ShelfDensity.compact;
    final fresh = s.readState?.newCount ?? 0;
    final badges = <Widget>[
      if (fresh > 0) CineBadge.newCount(fresh, onArt: true),
      if (!compact && s.readingStatus != 'unread') CineBadge.reading(s.readingStatus, onArt: true),
      if (!compact && gateOpen && s.rating == 'mature') CineBadge.certificate(onArt: true),
      if (!compact && saved) const CineBadge('SAVED', variant: CineBadgeVariant.saved, onArt: true),
    ];
    Widget poster = CinePoster(
      title: s.title,
      url: coverUrl,
      caption: compact ? CinePosterCaption.wall : CinePosterCaption.below,
      folio: shelfFolio(s),
      badges: badges,
      heroTag: heroTag ? (s.sourceId, s.seriesKey) : null,
      favourited: s.isFavorite && !compact,
      selectMode: selectMode,
      selected: selected,
      groupIndex: groupIndex,
      flickerIndex: flickerIndex,
      focusNode: focusNode,
      disabled: disabled,
      onTap: onTap,
      onQuickLook: onQuickLook,
      dragHandle: dragHandle,
      duo: s.ambient?.duo,
      hoverIcons: compact || (onFavourite == null && onNotify == null)
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (onNotify != null)
                CineIconButton(
                  label: s.notify ? 'Turn off notifications' : 'Notify me of new chapters',
                  role: CineIconRole.notify,
                  variant: CineIconButtonVariant.onArt,
                  selected: s.notify,
                  onPressed: onNotify,
                ),
              if (onNotify != null && onFavourite != null) const SizedBox(width: 8),
              if (onFavourite != null)
                CineIconButton(
                  label: s.isFavorite ? 'Remove from favourites' : 'Favourite',
                  role: CineIconRole.favourite,
                  variant: CineIconButtonVariant.onArt,
                  selected: s.isFavorite,
                  onPressed: onFavourite,
                ),
            ],),
    );
    if (compact) poster = CineTooltip(message: s.title, excludeFromSemantics: true, child: poster);
    return poster;
  }
}
