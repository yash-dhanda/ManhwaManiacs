import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';

/// What a plate shows: up to four cover URLs, the duotone colour and the scrim's tint.
typedef PlateArt = ({List<String> covers, Color? duo, Color? tint, int count});

/// The four covers, duotone and tint of [c]. A manual shelf uses the server's `preview_covers` and
/// `preview_ambient_duo`; a smart shelf's are empty on the server, so its mosaic is computed here
/// from [evaluateShelf] over [followed] (the first computed member's `ambient` gives the colours).
PlateArt plateArt(
  Collection c,
  List<FollowedSeries> followed,
  String apiBase, {
  String? Function(FollowedSeries)? contentKindOf,
}) {
  final rules = c.rules;
  if (rules != null) {
    final rows = evaluateShelf(rules, followed, contentKindOf: contentKindOf);
    final first = rows.isEmpty ? null : rows.first.ambient;
    return (
      covers: [for (final s in rows.take(4)) if (followedSeriesCoverUrl(apiBase, s) case final u?) u],
      duo: first?.duo,
      tint: first?.tint,
      count: rows.length,
    );
  }
  return (
    covers: [for (final u in c.previewCovers) if (historyCoverUrl(apiBase, u) case final r?) r],
    duo: c.previewAmbientDuo,
    tint: null,
    count: c.seriesCount,
  );
}

/// `24 SERIES`, `24 SERIES · SMART`.
String plateCredit(Collection c, int count) => '$count SERIES${c.smart ? ' · SMART' : ''}';

/// A collection plate (cinematic 7.6, 8.11): [CineCollectionPlate] with the collection's art. The
/// mosaic is the `Hero` of the match cut into the detail header.
class CollectionPlate extends StatelessWidget {
  const CollectionPlate({
    super.key,
    required this.collection,
    required this.art,
    this.onTap,
    this.selected = false,
    this.dragHandle,
    this.moveEntries,
    this.semanticActions,
    this.focusNode,
    this.menuOnLongPress = true,
    this.sharedWith = const [],
    this.badges = const [],
  });

  final Collection collection;

  /// The members' avatar keys, bottom-right, and the badges, top-left (shared shelves).
  final List<String> sharedWith;
  final List<Widget> badges;
  final PlateArt art;
  final VoidCallback? onTap;
  final bool selected, menuOnLongPress;
  final Widget? dragHandle;
  final List<CineMenuEntry<Object?>>? moveEntries;
  final Map<CustomSemanticsAction, VoidCallback>? semanticActions;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => CineCollectionPlate(
        name: collection.name,
        credit: plateCredit(collection, art.count),
        coverUrls: art.covers,
        duo: art.duo,
        tint: art.tint,
        heroTag: ('collection', collection.id),
        heroOnGestures: defaultTargetPlatform == TargetPlatform.iOS,
        selected: selected,
        onTap: onTap,
        dragHandle: dragHandle,
        moveEntries: moveEntries,
        semanticActions: semanticActions,
        focusNode: focusNode,
        menuOnLongPress: menuOnLongPress,
        sharedWith: sharedWith,
        badges: badges,
      );
}
