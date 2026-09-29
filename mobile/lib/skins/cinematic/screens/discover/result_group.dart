import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One source group: subhead row (logo, name, count badge, health mark) and a
/// rail of posters, or the failed-group correction with a per-source Retry.
class ResultGroup extends ConsumerWidget {
  const ResultGroup({
    super.key,
    required this.group,
    required this.retrying,
    required this.onRetry,
    this.headerFocus,
  });

  final SourceSearchGroup group;
  final bool retrying;
  final VoidCallback onRetry;
  final FocusNode? headerFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final base = ref.watch(apiBaseUrlProvider);
    final health = describeHealth(group.health, DateTime.now());
    final tablet = isTablet(context);
    final scaled = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final visible = tablet ? 5.2 : (scaled ? 2.3 : 3.2);
    final gap = tablet ? 12.0 : 8.0;
    final width = MediaQuery.sizeOf(context).width;
    final posterW = (width - CineSpace.s4 - gap * (visible - 1)) / visible;
    return Padding(
      padding: const EdgeInsets.only(bottom: CineSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            focusNode: headerFocus,
            child: Semantics(
            header: true,
            label: '${group.sourceName}, ${group.items.length} results, ${health.label}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: CineSpace.s2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: group.isLocal
                        ? Icon(CineGlyphs.mmMarkRegular, size: 24, color: t.colorInk100)
                        : CineCover(
                            url: group.iconUrl == null
                                ? null
                                : resolveApiResourceUrl(base, group.iconUrl!),
                            displayWidth: 24,
                          ),
                  ),
                  const SizedBox(width: CineSpace.s3),
                  Flexible(
                    child: Text(
                      group.isLocal ? 'IN YOUR LIBRARY' : group.sourceName,
                      overflow: TextOverflow.ellipsis,
                      style: cineText(context, t.typeTitle),
                    ),
                  ),
                  const SizedBox(width: CineSpace.s3),
                  if (!group.hasError && group.items.isNotEmpty)
                    ColoredBox(
                      color: t.colorSpot,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          '${group.total > group.items.length ? group.total : group.items.length}',
                          style: cineText(context, t.typeMicro, color: const Color(0xFF000000)),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!group.isLocal) HealthMark(health.state),
                ],
              ),
            ),
          ),
          ),
          if (group.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
              child: retrying
                  ? Row(
                      children: [
                        Expanded(child: FlickerPlate(height: posterW * 1.5)),
                        const SizedBox(width: 8),
                        Expanded(child: FlickerPlate(height: posterW * 1.5)),
                      ],
                    )
                  : Row(
                      children: [
                        Flexible(
                          child: Text(
                            "This source didn't answer.",
                            style: cineText(context, t.typeCaption, color: t.colorProof),
                          ),
                        ),
                        const SizedBox(width: CineSpace.s3),
                        QuietButton('Retry', onPressed: onRetry),
                      ],
                    ),
            )
          else
            SizedBox(
              height: posterW * 1.5 + 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: 8),
                itemCount: group.items.length,
                separatorBuilder: (_, __) => SizedBox(width: gap),
                itemBuilder: (context, i) {
                  final item = group.items[i];
                  final chapters = item.extra?['chapter_count'];
                  final path = item.isLocal
                      ? Routes.featureByFollow(item.seriesId)
                      : Routes.feature(item.source ?? group.key, item.seriesId);
                  final cover = searchResultCoverUrl(base, item.coverUrl);
                  final caption = chapters is num && chapters > 0 ? 'CHAPTERS ${chapters.toInt()}' : null;
                  return CinePoster(
                    title: item.title,
                    coverUrl: cover,
                    caption: caption,
                    width: posterW,
                    heroTag: (item.source ?? '@local', item.seriesId),
                    onTap: () => context.push(path),
                    onLongPress: () => showQuickLook(
                      context,
                      ref,
                      title: item.title,
                      coverUrl: cover,
                      kicker: group.isLocal ? 'IN YOUR LIBRARY' : group.sourceName,
                      caption: caption,
                      onOpen: () => context.push(path),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
