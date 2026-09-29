import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/utils/series_time.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/series_enrichment_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:url_launcher/url_launcher.dart';

const _statuses = [
  ('reading', 'READING'),
  ('plan_to_read', 'PLAN TO READ'),
  ('on_hold', 'ON HOLD'),
  ('completed', 'DONE'),
  ('dropped', 'DROPPED'),
  ('unread', 'NOT STARTED'),
];

/// DETAILS: At a glance, then the synopsis with its drop cap, genres and the
/// enriched credits.
class DetailsPanel extends ConsumerWidget {
  const DetailsPanel({super.key, required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = cineOf(context);
    final d = data;
    final key = (sourceId: d.sourceId, seriesKey: d.seriesKey);
    final progress =
        ref.watch(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    final read = progress.values.where((p) => p.completed).length;
    final enrichment = ref.watch(seriesEnrichmentProvider(key)).valueOrNull;
    final suggested = ref.watch(suggestedTagsProvider(key)).valueOrNull;
    final coverage = ref.watch(ocrCoverageProvider(key)).valueOrNull;
    final rows = ref.watch(_progressRowsProvider(key)).valueOrNull ?? const <ReadingProgress>[];
    final synopsis = d.series.description?.trim() ?? '';
    final indexed = coverage?.coveredChapterCount ?? 0;

    return CustomScrollView(
      key: const PageStorageKey('details'),
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                decoration:
                    BoxDecoration(border: Border(top: BorderSide(color: t.colorInk100, width: 3))),
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
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                          FontFeature.liningFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (d.followed != null)
                Wrap(
                  spacing: 4,
                  children: [
                    for (final (wire, label) in _statuses)
                      ChoiceChip(
                        label:
                            Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 0.8)),
                        selected: d.followed!.readingStatus == wire,
                        onSelected: (_) async {
                          await ref
                              .read(libraryRepositoryProvider)
                              .patchSeries(d.followed!.id, readingStatus: wire);
                          ref.invalidate(updatesProvider);
                        },
                      ),
                  ],
                ),
              Text('YOUR TIME HERE ${timeHere(rows)}', style: kickerStyle(context)),
              if (suggested != null && suggested.available && suggested.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('SUGGESTED', style: kickerStyle(context)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in suggested.tags.take(5))
                      InputChip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        onDeleted: () async {
                          await rejectSuggestedTag(ref, d.sourceId, d.seriesKey, tag);
                          ref.invalidate(suggestedTagsProvider(key));
                        },
                      ),
                  ],
                ),
              ],
              if (d.chapters.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Dialogue indexed for $indexed of ${d.chapters.length} chapters',
                  style: TextStyle(fontSize: 12, color: t.colorInk60),
                ),
                SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: (indexed / d.chapters.length).clamp(0.0, 1.0),
                    color: t.colorSpot,
                    backgroundColor: t.colorRule1,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (synopsis.isNotEmpty) Text('SYNOPSIS', style: kickerStyle(context)),
              if (synopsis.isNotEmpty)
                DropCapParagraph(
                  text: synopsis,
                  style: TextStyle(fontSize: 16, height: 24 / 16, color: t.colorInk80),
                  capStyle: TextStyle(
                    fontSize: 72,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.44,
                    color: t.colorInk100,
                  ),
                ),
              if (d.series.genres.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final g in d.series.genres)
                      TextButton(
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () => context
                            .push('/sources/${d.sourceId}?genre=${Uri.encodeQueryComponent(g)}'),
                        child: Text(g.toUpperCase(),
                            style: const TextStyle(fontSize: 12, letterSpacing: 1),),
                      ),
                  ],
                ),
              ],
              if (enrichment != null) ...[
                const SizedBox(height: 16),
                if (enrichment.format != null)
                  Text('FORMAT  ${enrichment.format}', style: kickerStyle(context)),
                if (enrichment.score != null)
                  Text('ANILIST ★ ${enrichment.score}', style: kickerStyle(context)),
                for (final o in enrichment.official)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () async {
                      final ok =
                          await launchUrl(Uri.parse(o.url), mode: LaunchMode.externalApplication);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("Couldn't open ${o.url}")));
                      }
                    },
                    child: Text('Read on ${o.site} ↗'),
                  ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

final _progressRowsProvider = FutureProvider.autoDispose
    .family<List<ReadingProgress>, ({String sourceId, String seriesKey})>((ref, k) async {
  final r = await ref
      .watch(readerRepositoryProvider)
      .seriesProgress(sourceId: k.sourceId, seriesKey: k.seriesKey);
  return r.isErr ? const [] : r.value;
});
