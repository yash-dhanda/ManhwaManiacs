import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/utils/source_latest.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Tablet and desktop frames: the pinned sources as a glass-free shelf of 180 x 96 cards (`surface1`, radius 20: logo 48, name and
/// the update line from [updates] or "No updates yet").
class PinnedShelf extends ConsumerWidget {
  const PinnedShelf({super.key, required this.sources, required this.updates, required this.now});
  final List<SourceSummary> sources;
  final Map<String, DateTime> updates;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sources.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final s = sources[i];
            final line = latestUpdateLine(updates[s.id], now);
            return Semantics(
              button: true,
              label: '${s.name}, $line',
              excludeSemantics: true,
              onTap: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.source(s.id))),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.source(s.id))),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(20)),
                  child: SizedBox(
                    width: 180,
                    height: 96,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 48, height: 48, child: s.iconUrl == null || s.iconUrl!.isEmpty ? GlassSourceMonogram(name: s.name, sourceId: s.id, size: 48) : HomeCoverImage(url: s.iconUrl, width: 48)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [GlassLabel(s.name, role: gt.typeHeadline), GlassLabel(line, role: gt.typeCaption1, color: gt.colorLabel2, maxLines: 2)])),
                      ],),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}
