import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/add_to_shelf_sheet.dart' as parts;
import 'package:manhwamaniacs/skins/cinematic/parts/tag_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// This series' own tags: the optimistic overlay, else what the follow row
/// carried.
List<Tag> ownTagsOf(WidgetRef ref, FeatureData d) =>
    ref.watch(seriesTagOverlayProvider)[(sourceId: d.sourceId, seriesKey: d.seriesKey)] ??
    d.followed?.tags ??
    const [];

/// The tag sheet of the series page (cinematic 8.9): the profile's tags, checked when applied,
/// with `New tag` and `Manage tags…` opening the shared tag sheet (`parts/tag_sheet.dart`).
Future<void> showSeriesTagSheet(BuildContext context, FeatureData d) => showCineSheet<void>(
      context,
      kicker: 'TAGS',
      title: d.title,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final c = ctx.cine;
          final all = ref.watch(profileTagsProvider);
          final own = ownTagsOf(ref, d);
          final key = (sourceId: d.sourceId, seriesKey: d.seriesKey);
          final ctl = ref.read(tagsControllerProvider);
          return Padding(
            padding: EdgeInsets.only(bottom: c.space4), // the sheet body sets the gutter
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ...all.when(
                data: (tags) => [
                  for (final tag in tags)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: CineCheckbox(
                        value: own.any((x) => x.id == tag.id),
                        label: tag.name,
                        onChanged: (on) => unawaited(on ? ctl.tagSeries(key, tag, current: own) : ctl.untagSeries(key, tag, current: own)),
                      ),
                    ),
                ],
                loading: () => [Padding(padding: EdgeInsets.symmetric(vertical: c.space3), child: CineRoleText('Loading…', c.typeCaption, color: c.colorInk60))],
                error: (e, _) => [Padding(padding: EdgeInsets.symmetric(vertical: c.space3), child: CineRoleText("Couldn't load tags.", c.typeCaption, color: c.colorProof))],
              ),
              SizedBox(height: c.space2),
              Wrap(spacing: c.space2, children: [
                CineButton(label: 'New tag…', variant: CineButtonVariant.quiet, leadingGlyph: CineGlyph.plus, onPressed: () => unawaited(showTagSheet(context))),
                CineButton(label: 'Manage tags…', variant: CineButtonVariant.quiet, onPressed: () => unawaited(showTagSheet(context))),
              ],),
            ],),
          );
        },
      ),
    );

/// Add the series to a shelf (collection): the shared `ADD TO SHELF` sheet.
Future<void> showAddToShelfSheet(BuildContext context, FeatureData d) =>
    parts.showAddToShelfSheet(context, sourceId: d.sourceId, seriesKey: d.seriesKey, title: d.title);
