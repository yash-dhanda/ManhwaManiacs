import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_index.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Opens [genre]: straight into the catalogue when one pinned source has it,
/// else the genre sheet (one row per pinned source exposing it).
Future<void> openGenre(BuildContext context, WidgetRef ref, GenreEntry genre,
    List<SourcePin> pinned,) async {
  final rows = [
    for (final p in pinned)
      if (genre.sourceIds.contains(p.sourceId)) p,
  ];
  if (rows.length == 1) {
    unawaited(context
        .push(Routes.source(rows.first.sourceId, {'genre': genre.label})),);
    return;
  }
  final base = ref.read(apiBaseUrlProvider);
  final live =
      ref.read(sourcesListProvider).valueOrNull ?? const <SourceSummary>[];
  HealthState healthOf(String id) => describeHealth(
          live.where((x) => x.id == id).firstOrNull?.health, DateTime.now(),)
      .state;
  final picked = await showCineSheet<String>(
    context,
    title: genre.label,
    body: (context) {
      final t = context.cine;
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: CineSpace.s4),
        children: [
          for (final p in rows)
            InkWell(
              onTap: () => Navigator.of(context).pop(p.sourceId),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: p.iconUrl == null
                            ? ColoredBox(color: t.colorPaper1)
                            : CineCover(
                                url: resolveApiResourceUrl(base, p.iconUrl!),
                                displayWidth: 24,),
                      ),
                      const SizedBox(width: CineSpace.s3),
                      Expanded(
                          child: Text(p.name,
                              style: cineText(context, t.typeTitle),),),
                      HealthMark(healthOf(p.sourceId)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
  if (picked != null && context.mounted) {
    unawaited(context.push(Routes.source(picked, {'genre': genre.label})));
  }
}
