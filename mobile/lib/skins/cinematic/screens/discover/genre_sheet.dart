import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_index.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Opens [genre]: straight into the catalogue when one pinned source has it,
/// else the genre sheet (one row per pinned source exposing it).
Future<void> openGenre(BuildContext context, GenreEntry genre, List<SourcePin> pinned) async {
  final rows = [for (final p in pinned) if (genre.sourceIds.contains(p.sourceId)) p];
  if (rows.length == 1) {
    unawaited(context.push(Routes.source(rows.first.sourceId, {'genre': genre.label})));
    return;
  }
  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.cine.colorPaper2,
    barrierColor: CineScrim.modal,
    shape: const RoundedRectangleBorder(),
    builder: (context) {
      final t = context.cine;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: CineSpace.s4),
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: CineSpace.s2),
                width: 32,
                height: 3,
                color: t.colorInk30,
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: CineSpace.s4), child: Kicker('Genre')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: CineSpace.s2),
              child: Semantics(
                header: true,
                child: Text(genre.label, style: cineText(context, t.typeSubhead)),
              ),
            ),
            for (final p in rows)
              InkWell(
                onTap: () => Navigator.of(context).pop(p.sourceId),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                    child: Row(
                      children: [Text(p.name, style: cineText(context, t.typeTitle))],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
  if (picked != null && context.mounted) {
    unawaited(context.push(Routes.source(picked, {'genre': genre.label})));
  }
}
