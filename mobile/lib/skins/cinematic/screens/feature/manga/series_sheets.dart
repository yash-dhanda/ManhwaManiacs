import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/series_shelves_provider.dart';
import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';

/// This series' own tags: the optimistic overlay, else what the follow row
/// carried.
List<Tag> ownTagsOf(WidgetRef ref, FeatureData d) =>
    ref.watch(seriesTagOverlayProvider)[(sourceId: d.sourceId, seriesKey: d.seriesKey)] ??
    d.followed?.tags ??
    const [];

Future<String?> _askName(BuildContext context, String title) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

/// The tag sheet: the profile's tags, checked when applied, with a last row
/// `New tag…`. TODO(mobile/09): replaced by `parts/tag_sheet.dart`.
Future<void> showSeriesTagSheet(BuildContext context, FeatureData d) {
  final t = cineOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.colorPaper2,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final all = ref.watch(profileTagsProvider);
        final own = ownTagsOf(ref, d);
        final key = (sourceId: d.sourceId, seriesKey: d.seriesKey);
        final ctl = ref.read(tagsControllerProvider);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('TAGS', style: kickerStyle(ctx)),
                ),
                ...all.when(
                  data: (tags) => [
                    for (final tag in tags)
                      CheckboxListTile(
                        title: Text(tag.name),
                        value: own.any((x) => x.id == tag.id),
                        onChanged: (on) => unawaited(
                          (on ?? false)
                              ? ctl.tagSeries(key, tag, current: own)
                              : ctl.untagSeries(key, tag, current: own),
                        ),
                      ),
                  ],
                  loading: () => const [Padding(padding: EdgeInsets.all(16), child: Text('Loading…'))],
                  error: (e, _) => const [Padding(padding: EdgeInsets.all(16), child: Text("Couldn't load tags."))],
                ),
                ListTile(
                  minVerticalPadding: 12,
                  leading: const Icon(PhosphorRegular.plus),
                  title: const Text('New tag…'),
                  onTap: () async {
                    final name = await _askName(ctx, 'New tag');
                    if (name == null || name.isEmpty) return;
                    await ctl.createAndTag(key, name, current: own);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Add the series to a shelf (collection). TODO(mobile/09): `add_to_shelf_sheet.dart`.
Future<void> showAddToShelfSheet(BuildContext context, FeatureData d) {
  final t = cineOf(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.colorPaper2,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final key = (sourceId: d.sourceId, seriesKey: d.seriesKey);
        final shelves = ref.watch(seriesShelvesProvider(key)).valueOrNull ?? const <CollectionRef>[];
        final repo = ref.read(libraryRepositoryProvider);
        return SafeArea(
          child: FutureBuilder(
            future: repo.listCollections(),
            builder: (ctx, snap) {
              final list = snap.data?.isOk ?? false ? snap.data!.value : const <Collection>[];
              return ListView(
                shrinkWrap: true,
                children: [
                  Padding(padding: const EdgeInsets.all(16), child: Text('ADD TO SHELF', style: kickerStyle(ctx))),
                  if (snap.connectionState != ConnectionState.done)
                    const Padding(padding: EdgeInsets.all(16), child: Text('Loading…'))
                  else if (list.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('No shelves yet.')),
                  for (final c in list)
                    ListTile(
                      minVerticalPadding: 12,
                      title: Text(c.name),
                      trailing: shelves.any((s) => s.id == c.id) ? const Icon(PhosphorRegular.check) : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final r = await repo.addSeriesToCollection(c.id,
                            sourceId: d.sourceId, seriesKey: d.seriesKey,);
                        ref.invalidate(seriesShelvesProvider(key));
                        if (context.mounted) {
                          featureToast(context,
                              r.isErr ? "Couldn't add it to ${c.name}." : 'Added to ${c.name}.',);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
