import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart' show GlassDensityWide;
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';

/// What the toolbar shows and calls; the page owns the query (`shelfQueryProvider`).
class ShelfToolbarSpec {
  const ShelfToolbarSpec({
    required this.query,
    required this.searchController,
    required this.searchFocus,
    required this.onQuery,
    required this.onStatus,
    required this.onFavourites,
    required this.onFilters,
    required this.onSort,
    this.onBrowseAll,
    this.sortLabel = 'Sort',
    this.density,
    this.onDensity,
  });
  final ShelfQuery query;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onQuery;
  final ValueChanged<ShelfStatus> onStatus;
  final VoidCallback onFavourites;
  final VoidCallback onFilters;
  final VoidCallback onSort;

  /// Null on Browse all itself.
  final VoidCallback? onBrowseAll;
  final String sortLabel;

  /// Tablet and desktop frames: the Comfortable · Compact · List segmented control (the non-gesture density path).
  final GlassDensityWide? density;
  final ValueChanged<GlassDensityWide>? onDensity;
}

/// The Shelf toolbar (glass 8.17), pinned under the nav row with `edgeHard`: the search well "Search your library", the progress chips
/// All, Reading, Not started, Completed and Favourites, "Filters" with its count, Sort and "Browse all".
class ShelfToolbarDelegate extends SliverPersistentHeaderDelegate {
  ShelfToolbarDelegate(this.spec, {required this.extent});
  final ShelfToolbarSpec spec;
  final double extent;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  bool shouldRebuild(ShelfToolbarDelegate old) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => _Toolbar(spec: spec, stuck: overlapsContent || shrinkOffset > 0);
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.spec, required this.stuck});
  final ShelfToolbarSpec spec;
  final bool stuck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = spec.query;
    final margin = GlassFrame.screenMargin(context);
    final filters = q.activeFilterCount;
    final s = q.effectiveStatus;
    Widget chip(String label, bool selected, VoidCallback onTap) => GlassChip(label: label, selected: selected, onPressed: onTap);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (stuck)
          Positioned(
            left: -margin,
            right: -margin,
            top: 0,
            bottom: 0,
            child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xEB000000), border: Border(bottom: BorderSide(color: Color(0x38FFFFFF), width: 0.5)))),
          ),
        Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          GlassSearchField(
            variant: GlassSearchVariant.filter,
            controller: spec.searchController,
            focusNode: spec.searchFocus,
            placeholder: 'Search your library',
            onQuery: spec.onQuery,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: GlassChipRow(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                chip('All', s == ShelfStatus.all && !q.fav, () => spec.onStatus(ShelfStatus.all)),
                chip('Reading', s == ShelfStatus.reading, () => spec.onStatus(ShelfStatus.reading)),
                chip('Not started', s == ShelfStatus.unread, () => spec.onStatus(ShelfStatus.unread)),
                chip('Completed', s == ShelfStatus.completed, () => spec.onStatus(ShelfStatus.completed)),
                chip('★ Favourites', q.fav, spec.onFavourites),
                GlassChip(label: 'Filters', kind: GlassChipKind.count, count: filters == 0 ? null : filters, selected: filters > 0, onPressed: spec.onFilters),
                GlassChip(label: spec.sortLabel, onPressed: spec.onSort),
                if (spec.density != null && spec.onDensity != null && GlassFrame.of(context) != GlassFrameKind.phone)
                  SizedBox(
                    width: 300,
                    child: GlassSegmented<GlassDensityWide>(
                      compact: true,
                      segments: const [
                        GlassSegment(value: GlassDensityWide.comfortable, label: 'Comfortable'),
                        GlassSegment(value: GlassDensityWide.compact, label: 'Compact'),
                        GlassSegment(value: GlassDensityWide.list, label: 'List'),
                      ],
                      selected: spec.density!,
                      onSelected: spec.onDensity!,
                    ),
                  ),
                if (spec.onBrowseAll != null) GlassButton(label: 'Browse all', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: spec.onBrowseAll),
              ],
            ),
          ),
        ],),
      ),
      ],
    );
  }
}
