import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/providers/tags_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/radio_list.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `?sheet=filters` (glass 8.17, "Library and collections"): shelf status as a radio list, the tags as multi-select chips and "Clear
/// filters". Every change writes the shared query at once; the shelf behind the sheet refetches.
final GlassSheetSpec glassFiltersSheetSpec = GlassSheetSpec(
  title: 'Filters',
  builder: (_) => const GlassFiltersBody(),
  detents: const [GlassDetent.medium, GlassDetent.large],
  opening: GlassDetent.medium,
);

const List<GlassRadioOption<ShelfStatus>> kShelfStatusOptions = [
  GlassRadioOption(value: ShelfStatus.all, label: 'Any'),
  GlassRadioOption(value: ShelfStatus.unread, label: 'Unread'),
  GlassRadioOption(value: ShelfStatus.reading, label: 'Reading'),
  GlassRadioOption(value: ShelfStatus.completed, label: 'Completed'),
  GlassRadioOption(value: ShelfStatus.onHold, label: 'On hold'),
  GlassRadioOption(value: ShelfStatus.planToRead, label: 'Plan to read'),
  GlassRadioOption(value: ShelfStatus.dropped, label: 'Dropped'),
];

class GlassFiltersBody extends ConsumerWidget {
  const GlassFiltersBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(shelfQueryProvider);
    final tags = ref.watch(tagsProvider);
    final on = sheetOnGlass(context);
    final notifier = ref.read(shelfQueryProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        GlassText('Shelf status', role: gt.typeHeadline, onGlass: on),
        const SizedBox(height: 8),
        GlassRadioList<ShelfStatus>(
          options: kShelfStatusOptions,
          value: q.effectiveStatus,
          onChanged: (v) => notifier.patch((x) => v == ShelfStatus.all ? x.copyWith(status: ShelfStatus.all, clearReadingStatus: true) : x.copyWith(readingStatus: v)),
        ),
        const SizedBox(height: 20),
        GlassText('Tags', role: gt.typeHeadline, onGlass: on),
        const SizedBox(height: 8),
        tags.when(
          loading: () => GlassText('Loading tags…', role: gt.typeFootnote, onGlass: on),
          error: (_, __) => GlassText("Couldn't load your tags", role: gt.typeFootnote, onGlass: on),
          data: (list) => list.isEmpty
              ? GlassText('No tags yet. Add tags from a series’ ⋯ menu.', role: gt.typeFootnote, onGlass: on)
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in list)
                    GlassChip(
                      label: t.name,
                      selected: q.tagIds.contains(t.id),
                      dot: t.color,
                      semanticsLabel: '${t.name}, tag',
                      onPressed: () => notifier.patch((x) => x.copyWith(tagIds: q.tagIds.contains(t.id) ? [for (final i in q.tagIds) if (i != t.id) i] : [...q.tagIds, t.id])),
                    ),
                ],),
        ),
        const SizedBox(height: 24),
        GlassButton(
          label: 'Clear filters',
          variant: GlassButtonVariant.plain,
          onPressed: q.activeFilterCount == 0 ? null : () => notifier.patch((x) => x.cleared()),
          disabledReason: 'No filters are on',
        ),
      ],
    );
  }
}
