import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/series_shelves_provider.dart';
import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';
import 'package:manhwamaniacs/features/library/utils/series_time.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dashed_token.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/series_sheets.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

const statusOptions = [
  ('reading', 'READING'),
  ('plan_to_read', 'PLAN TO READ'),
  ('on_hold', 'ON HOLD'),
  ('completed', 'DONE'),
  ('dropped', 'DROPPED'),
  ('unread', 'NOT STARTED'),
];

final atAGlanceRowsProvider = FutureProvider.autoDispose
    .family<List<ReadingProgress>, ({String sourceId, String seriesKey})>((ref, k) async {
  final r = await ref
      .watch(readerRepositoryProvider)
      .seriesProgress(sourceId: k.sourceId, seriesKey: k.seriesKey);
  return r.isErr ? const [] : r.value;
});

/// At a glance (top of DETAILS): the Stat block, reading status, time, tags,
/// suggested tags, shelves and OCR coverage.
class AtAGlance extends ConsumerWidget {
  const AtAGlance({super.key, required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = cineOf(context);
    final d = data;
    final online = isOnline(ref);
    final key = (sourceId: d.sourceId, seriesKey: d.seriesKey);
    final progress =
        ref.watch(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    final read = progress.values.where((p) => p.completed).length;
    final suggested = ref.watch(suggestedTagsProvider(key)).valueOrNull;
    final coverage = ref.watch(ocrCoverageProvider(key)).valueOrNull;
    final rows = ref.watch(atAGlanceRowsProvider(key)).valueOrNull ?? const <ReadingProgress>[];
    final shelves = ref.watch(seriesShelvesProvider(key)).valueOrNull ?? const [];
    final own = ownTagsOf(ref, d);
    final indexed = coverage?.coveredChapterCount ?? 0;
    final f = d.followed;
    final ctl = ref.read(tagsControllerProvider);

    final suggestions = [
      for (final s in suggested?.tags ?? const <String>[])
        if (!own.any((o) => o.name.toLowerCase() == s.toLowerCase())) s,
    ].take(5).toList();

    Future<void> accept(String name) async {
      final all = ref.read(profileTagsProvider).valueOrNull ?? const <Tag>[];
      final match = all.where((x) => x.name.toLowerCase() == name.toLowerCase()).toList();
      if (match.isNotEmpty) {
        await ctl.tagSeries(key, match.first, current: own);
      } else {
        await ctl.createAndTag(key, name, current: own);
      }
      feedback(ref, HapticEvent.select);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.colorInk100, width: 3))),
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHAPTERS READ', style: kickerStyle(context)),
              Text(
                '$read / ${d.chapters.length}',
                key: const Key('at-a-glance-read'),
                style: TextStyle(
                  fontSize: 32,
                  height: 36 / 32,
                  color: t.colorInk100,
                  fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
                ),
              ),
            ],
          ),
        ),
        if (f != null) ...[
          const SizedBox(height: 12),
          Tooltip(
            message: online ? '' : kNeedsConnection,
            child: Wrap(
              key: const Key('reading-status'),
              children: [
                for (final (wire, label) in statusOptions)
                  Semantics(
                    button: true,
                    selected: f.readingStatus == wire,
                    child: InkWell(
                      onTap: !online
                          ? null
                          : () async {
                              feedback(ref, HapticEvent.select);
                              await ref
                                  .read(libraryRepositoryProvider)
                                  .patchSeries(f.id, readingStatus: wire);
                              ref.invalidate(updatesProvider);
                            },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            widthFactor: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: f.readingStatus == wire ? t.colorSpot : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  color: f.readingStatus == wire ? t.colorInk100 : t.colorInk60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text('YOUR TIME HERE ${timeHere(rows)}', style: kickerStyle(context)),
        const SizedBox(height: 12),
        Text('TAGS', style: kickerStyle(context)),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in own)
              InputChip(
                key: Key('own-tag-${tag.id}'),
                label: Text(tag.name.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1)),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteButtonTooltipMessage: 'Remove tag ${tag.name}',
                onDeleted: () => unawaited(ctl.untagSeries(key, tag, current: own)),
              ),
            TextButton(
              key: const Key('add-tag'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => unawaited(showSeriesTagSheet(context, d)),
              child: const Text('Add tag'),
            ),
          ],
        ),
        if (suggested != null && suggested.available && suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('SUGGESTED', style: kickerStyle(context)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in suggestions)
                DashedToken(
                  key: Key('suggested-$tag'),
                  label: tag,
                  onAccept: () => unawaited(accept(tag)),
                  onReject: () async {
                    feedback(ref, HapticEvent.select);
                    await rejectSuggestedTag(ref, d.sourceId, d.seriesKey, tag);
                    ref.invalidate(suggestedTagsProvider(key));
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text('SHELVES', style: kickerStyle(context)),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final s in shelves)
              TextButton(
                key: Key('shelf-${s.id}'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => context.push(Routes.collection(s.id)),
                child: Text(s.name),
              ),
            TextButton(
              key: const Key('add-to-shelf'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => unawaited(showAddToShelfSheet(context, d)),
              child: const Text('Add to shelf'),
            ),
          ],
        ),
        if (d.chapters.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Dialogue indexed for $indexed of ${d.chapters.length} chapters',
            style: TextStyle(fontSize: 12, color: t.colorInk60),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: (indexed / d.chapters.length).clamp(0.0, 1.0),
              color: t.colorSpot,
              backgroundColor: t.colorRule1,
            ),
          ),
        ],
      ],
    );
  }
}
