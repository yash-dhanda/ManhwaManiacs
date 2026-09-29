import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/sources/providers/series_enrichment_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/at_a_glance.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final enrichment = ref.watch(seriesEnrichmentProvider(key)).valueOrNull;
    final synopsis = d.series.description?.trim() ?? '';

    return CustomScrollView(
      key: const PageStorageKey('details'),
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AtAGlance(data: d),
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
