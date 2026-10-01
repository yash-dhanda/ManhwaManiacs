import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_counts.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_vocab.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The shelf toolbar (cinematic 8.9). Below 768 px: the status slug line, `Filters`, a search
/// glass that expands in place, and `Select`. From 768 px: the slug line, `FAVOURITES` and `NEW
/// ONLY` toggles, `TAGS`, `Clear filters`, and on the right search, Sort, density and `Select`.
/// Active tags show as removable tokens after the slug line. Offline every control is disabled.
class ShelfToolbar extends StatelessWidget {
  const ShelfToolbar({
    super.key,
    required this.query,
    required this.counts,
    required this.tags,
    required this.novels,
    required this.offline,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocus,
    required this.onQuery,
    required this.onSearchChanged,
    required this.onSearchSubmit,
    required this.onToggleSearch,
    required this.onSelect,
    required this.onFilters,
    required this.onManageTags,
  });

  final ShelfQuery query;
  final ShelfCounts? counts;
  final List<Tag> tags;
  final bool novels, offline, searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<ShelfQuery> onQuery;
  final ValueChanged<String> onSearchChanged, onSearchSubmit;
  final VoidCallback onToggleSearch, onSelect, onFilters, onManageTags;

  static const String needsConnection = 'Needs a connection.';

  Widget _slugs() => CineSlugLines(
        items: shelfStatusSlugs(counts),
        selected: {query.status.name},
        loading: counts == null,
        onChanged: (id) => onQuery(query.copyWith(status: shelfStatusByName(id))),
      );

  Widget _tokens(BuildContext context) {
    final active = [for (final t in tags) if (query.tagIds.contains(t.id)) t];
    if (active.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: context.cine.space2),
      child: CineSlugLines(
        items: [for (final t in active) CineSlug('tag-${t.id}', t.name, removable: true)],
        selected: const {},
        multi: true,
        onChanged: (_) {},
        onRemove: (id) {
          final n = int.tryParse(id.replaceFirst('tag-', ''));
          onQuery(query.copyWith(tagIds: [for (final i in query.tagIds) if (i != n) i]));
        },
      ),
    );
  }

  Widget _clear() => CineButton(
        label: 'Clear filters',
        variant: CineButtonVariant.quiet,
        disabledReason: offline ? needsConnection : null,
        onPressed: offline ? null : () => onQuery(query.cleared().copyWith(q: '')),
      );

  Widget _search(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
        child: CineSearchField(
          semanticLabel: 'Search your shelf',
          placeholder: 'Search your shelf',
          variant: CineSearchVariant.compact,
          controller: searchController,
          focusNode: searchFocus,
          onChanged: onSearchChanged,
          onSubmitNow: onSearchSubmit,
        ),
      );

  Future<void> _sortMenu(BuildContext context) => showCineMenu<ShelfSort>(
        context,
        anchor: cineAnchorRect(context),
        entries: [
          for (final e in kShelfSortLabels.entries)
            CineMenuEntry<ShelfSort>(
              label: e.value,
              value: e.key,
              checked: query.sort == e.key,
              disabledReason: e.key == ShelfSort.manual && query.filtering ? 'Clear filters to reorder.' : null,
              onSelected: () => onQuery(query.copyWith(sort: e.key)),
            ),
        ],
      );

  Future<void> _tagsMenu(BuildContext context) => showCineMenu<int>(
        context,
        anchor: cineAnchorRect(context),
        entries: [
          for (final t in tags)
            CineMenuEntry<int>(
              label: t.name,
              value: t.id,
              checked: query.tagIds.contains(t.id),
              onSelected: () => onQuery(query.copyWith(
                tagIds: query.tagIds.contains(t.id) ? [for (final i in query.tagIds) if (i != t.id) i] : [...query.tagIds, t.id],
              ),),
            ),
          CineMenuEntry<int>(label: 'Manage tags…', separatorBefore: true, onSelected: onManageTags),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final wide = MediaQuery.sizeOf(context).width >= 768;
    final body = wide ? _wide(context, c) : _phone(context, c);
    return Semantics(
      container: true,
      hint: offline ? needsConnection : null,
      child: AbsorbPointer(absorbing: offline, child: Opacity(opacity: offline ? 0.4 : 1, child: body)),
    );
  }

  Widget _phone(BuildContext context, CineTokens c) {
    final n = query.activeFilterCount;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _slugs(),
      _tokens(context),
      SizedBox(height: c.space2),
      if (searchOpen)
        Row(children: [
          Expanded(child: CineSearchField(
            semanticLabel: 'Search your shelf',
            placeholder: 'Search your shelf',
            variant: CineSearchVariant.compact,
            controller: searchController,
            focusNode: searchFocus,
            autofocus: true,
            onChanged: onSearchChanged,
            onSubmitNow: onSearchSubmit,
          ),),
          CineButton(label: 'Close', variant: CineButtonVariant.quiet, onPressed: onToggleSearch),
        ],)
      else
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            _FiltersButton(count: n, onPressed: onFilters),
            SizedBox(width: c.space2),
            CineIconButton(label: 'Search your shelf', role: CineIconRole.search, onPressed: onToggleSearch),
          ],),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (query.filtering) ...[_clear(), SizedBox(width: c.space2)],
            CineButton(label: 'Select', variant: CineButtonVariant.quiet, icon: CineIconRole.select, onPressed: onSelect),
          ],),
        ],),
    ],);
  }

  Widget _wide(BuildContext context, CineTokens c) {
    final flags = {if (query.fav) 'fav', if (query.newOnly) 'new'};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: c.space4, runSpacing: c.space1, children: [
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: _slugs()),
        CineSlugLines(
          items: [
            CineSlug('fav', 'FAVOURITES', leading: CineGlyphIcon(CineGlyph.star, size: 12, weight: CineIconWeight.fill, color: c.colorSpot)),
            const CineSlug('new', 'NEW ONLY'),
          ],
          selected: flags,
          multi: true,
          onChanged: (id) => onQuery(id == 'fav' ? query.copyWith(fav: !query.fav) : query.copyWith(newOnly: !query.newOnly)),
        ),
        if (tags.isNotEmpty) Builder(builder: (b) => _MenuTrigger(label: 'TAGS', onPressed: () => _tagsMenu(b))),
        if (query.filtering) _clear(),
      ],),
      _tokens(context),
      Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, spacing: c.space4, children: [
        _search(context),
        Builder(builder: (b) => _MenuTrigger(label: kShelfSortLabels[query.sort]!, glyph: CineGlyph.arrowLineDown, onPressed: () => _sortMenu(b))),
        if (!novels)
          SizedBox(
            width: 264,
            child: CineSegmentedControl(
              labels: [for (final l in kShelfDensityLabels.values) l],
              index: query.density.index,
              onChanged: (i) => onQuery(query.copyWith(density: ShelfDensity.values[i])),
            ),
          ),
        CineButton(label: 'Select', variant: CineButtonVariant.quiet, icon: CineIconRole.select, onPressed: onSelect),
      ],),
    ],);
  }
}

/// `Filters ⁽2⁾`: a quiet button whose active-filter count is a raised folio, spoken "Filters, 2".
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      button: true,
      label: count > 0 ? 'Filters, $count' : 'Filters',
      excludeSemantics: true,
      onTap: onPressed,
      child: CinePressable(
        hit: false,
        onTap: onPressed,
        builder: (context, st) => ConstrainedBox(
          constraints: BoxConstraints(minHeight: cineHitMin(context), minWidth: cineHitMin(context)),
          child: Padding(
            // The row's first word: on the gutter, not 12 px in.
            padding: EdgeInsets.only(right: c.space3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CineRoleText('Filters', c.typeLabel, color: st.hovered ? c.colorInk100 : c.colorInk60),
              if (count > 0)
                Transform.translate(offset: const Offset(0, -5), child: Padding(padding: const EdgeInsets.only(left: 2), child: CineLit('$count', CineFace.plexMono, 10, 12, color: c.colorInk60))),
            ],),
          ),
        ),
      ),
    );
  }
}

/// A `LABEL ▾` menu trigger.
class _MenuTrigger extends StatelessWidget {
  const _MenuTrigger({required this.label, required this.onPressed, this.glyph});
  final String label;
  final int? glyph;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: CinePressable(
        hit: false,
        onTap: onPressed,
        builder: (context, st) => ConstrainedBox(
          constraints: BoxConstraints(minHeight: cineHitMin(context), minWidth: cineHitMin(context)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (glyph != null) ...[CineGlyphIcon(glyph!, size: 16, color: c.colorInk60), const SizedBox(width: 6)],
            CineRoleText(label, c.typeNav, color: st.hovered ? c.colorInk100 : c.colorInk60, upper: true),
            const SizedBox(width: 4),
            CineGlyphIcon(CineGlyph.caretDown, size: 12, color: c.colorInk60),
          ],),
        ),
      ),
    );
  }
}
