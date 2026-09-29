import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/providers/tags_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/tag_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_vocab.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The Filters sheet of the phone toolbar (cinematic 8.9): favourites and new only as switches,
/// the six sorts as radios, the density control (manga only), the reading-status slug line and the
/// profile's tags. Every change applies at once behind the sheet.
Future<void> showFiltersSheet(BuildContext context, {required bool novels}) => showCineSheet<void>(
      context,
      kicker: 'FILTERS',
      title: 'Your shelf',
      builder: (_) => FiltersSheetBody(novels: novels),
    );

class FiltersSheetBody extends ConsumerWidget {
  const FiltersSheetBody({super.key, required this.novels});
  final bool novels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final q = ref.watch(shelfQueryProvider);
    final n = ref.read(shelfQueryProvider.notifier);
    final counts = ref.watch(shelfCountsProvider).valueOrNull;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const [];

    Widget section(String label) => Padding(
          padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
          child: CineRoleText(label, c.typeKicker, color: c.colorInk45),
        );

    Widget switchRow(String label, bool value, ValueChanged<bool> on) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            Expanded(child: CineRoleText(label, c.typeUi)),
            CineSwitch(value: value, label: label, onChanged: on),
          ],),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space6),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        switchRow('Favourites', q.fav, (v) => n.patch((s) => s.copyWith(fav: v))),
        switchRow('New only', q.newOnly, (v) => n.patch((s) => s.copyWith(newOnly: v))),
        section('SORT'),
        for (final e in kShelfSortLabels.entries)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CineRadio<ShelfSort>(
              value: e.key,
              groupValue: q.sort,
              label: e.value,
              onChanged: (v) => n.patch((s) => s.copyWith(sort: v)),
            ),
          ),
        if (!novels) ...[
          section('DENSITY'),
          CineSegmentedControl(
            labels: [for (final l in kShelfDensityLabels.values) l],
            index: q.density.index,
            onChanged: (i) => n.patch((s) => s.copyWith(density: ShelfDensity.values[i])),
          ),
        ],
        section('READING STATUS'),
        CineSlugLines(
          items: shelfStatusSlugs(counts),
          selected: {q.status.name},
          loading: counts == null,
          onChanged: (id) => n.patch((s) => s.copyWith(status: shelfStatusByName(id))),
        ),
        if (tags.isNotEmpty) ...[
          section('TAGS'),
          for (final t in tags)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: CineCheckbox(
                value: q.tagIds.contains(t.id),
                label: t.name,
                onChanged: (v) => n.patch((s) => s.copyWith(tagIds: v ? [...s.tagIds, t.id] : [for (final i in s.tagIds) if (i != t.id) i])),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: CineButton(label: 'Manage tags…', variant: CineButtonVariant.quiet, onPressed: () => showTagSheet(context)),
          ),
        ],
        if (q.filtering) ...[
          SizedBox(height: c.space4),
          Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Clear filters', variant: CineButtonVariant.quiet, onPressed: () => n.set(q.cleared()))),
        ],
      ],),
    );
  }
}
