import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/glass_density_provider.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/add_series_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/collection_form_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/filters_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/manage_tags_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/note_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/updates/run_sheet.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `?sheet=density`: the column slider, List then 2 to 5 columns (glass 7.21, `detent.tick` per step).
final GlassSheetSpec glassDensitySheetSpec = GlassSheetSpec(
  title: 'Density',
  builder: (_) => const GlassDensityBody(),
  detents: const [GlassDetent.medium],
  opening: GlassDetent.medium,
);

class GlassDensityBody extends ConsumerWidget {
  const GlassDensityBody({super.key});

  static const _steps = [GlassPhoneDensity.list, GlassPhoneDensity.c5, GlassPhoneDensity.c4, GlassPhoneDensity.c3, GlassPhoneDensity.c2];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(glassDensityProvider).phone;
    final idx = _steps.indexOf(d).clamp(0, _steps.length - 1);
    final on = sheetOnGlass(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassText('Items per row', role: gt.typeHeadline, onGlass: on),
        const SizedBox(height: 16),
        GlassSlider(
          label: 'Columns',
          value: idx.toDouble(),
          max: (_steps.length - 1).toDouble(),
          divisions: _steps.length - 1,
          format: (v) => _steps[v.round()].isList ? 'List' : '${_steps[v.round()].columns}',
          onChanged: (v) => ref.read(glassDensityProvider.notifier).setPhone(_steps[v.round()]),
        ),
        const SizedBox(height: 8),
        GlassText('Pinch the grid for the same thing.', role: gt.typeFootnote, onGlass: on, color: gt.colorLabel2),
      ],),
    );
  }
}

/// Registers the Library family's `?sheet=` ids (glass 8.0.3 "Library and collections"); the other families add theirs as they land.
void registerLibrarySheets() {
  registerGlobalSheet('filters', glassFiltersSheetSpec);
  registerGlobalSheet('manage-tags', glassManageTagsSheetSpec);
  registerGlobalSheet('density', glassDensitySheetSpec);
  registerGlobalSheet('collection-new', glassCollectionNewSheetSpec);
  registerGlobalSheet('collection-edit', glassCollectionEditSheetSpec);
  registerGlobalSheet('add-series', glassAddSeriesSheetSpec);
  registerGlobalSheet('note', glassNoteSheetSpec);
  registerGlobalSheet('run', glassRunSheetSpec);
}
