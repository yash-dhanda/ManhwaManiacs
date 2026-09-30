import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/up_next_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `More like this` (caught up) or `Up next` (the end): a poster rail (cinematic 7.8, 8.14.6)
/// from `upNextProvider`. Absent when its chain yields nothing; a `NOTE` line with the 9.1.8
/// reason when the AI desk is unavailable.
class UpNextRail extends ConsumerWidget {
  const UpNextRail({super.key, required this.sourceId, required this.seriesKey, required this.mode});

  final String sourceId, seriesKey;
  final UpNextMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final next = ref.watch(upNextProvider((sourceId: sourceId, seriesKey: seriesKey, mode: mode)));
    return next.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (r) {
        if (r.items.isEmpty) return const SizedBox.shrink();
        final note = r.reason == null ? null : cineAiUnavailableCopy(_reason(r.reason), retryAfterSeconds: 10);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note != null)
              Padding(
                padding: EdgeInsets.only(bottom: c.space2),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${note.kicker}  ', style: CineText.style(context, c.typeKicker).copyWith(color: c.colorInk60)),
                      TextSpan(text: note.copy, style: CineText.style(context, c.typeCaption).copyWith(color: c.colorInk60)),
                    ],
                  ),
                ),
              ),
            CineRail(
              headingId: 'reader.upnext.${mode.name}',
              heading: mode == UpNextMode.caughtUp ? 'More like this' : 'Up next',
              itemCount: r.items.length,
              itemBuilder: (context, i, w, node) {
                final item = r.items[i];
                final world = item.world;
                return CinePoster(
                  title: item.title,
                  url: coverAbs(ref, world?.coverUrl ?? item.source?.coverUrl),
                  folio: r.source == UpNextSource.sameGenres ? 'SAME GENRES' : (item.why ?? (world?.badgeLine)),
                  duo: item.ambient?.duo,
                  focusNode: node,
                  flickerIndex: i,
                  onTap: () => openPick(context, item),
                );
              },
            ),
          ],
        );
      },
    );
  }

  CineAiReason _reason(String? code) => switch (code) {
        'budget_exhausted' || 'ai_budget_exhausted' => CineAiReason.budget,
        'not_configured' || 'ai_not_configured' => CineAiReason.notConfigured,
        'rate_limited' => CineAiReason.rateLimited,
        _ => CineAiReason.failed,
      };
}
