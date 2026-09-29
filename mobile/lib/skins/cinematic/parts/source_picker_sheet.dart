import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';

/// `OPEN ON`: a world title several of the reader's sources carry (cinematic 8.8). One row per
/// source with its logo at 24 px, its name and `Open`; [onOpen] runs after the sheet closes.
Future<void> showSourcePickerSheet(
  BuildContext context, {
  required String title,
  required List<WorldAvailability> sources,
  required void Function(WorldAvailability source) onOpen,
}) {
  WorldAvailability? chosen;
  return showCineSheet<void>(
    context,
    kicker: 'OPEN ON',
    title: title,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final icons = {
          for (final s in ref.watch(sourcesListProvider).valueOrNull ?? const <SourceSummary>[]) s.id: s.iconUrl,
        };
        final base = ref.watch(apiBaseUrlProvider);
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final s in sources)
            CineRow(
              key: Key('source-pick-${s.sourceId}'),
              title: s.sourceName,
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CineImage(url: icons[s.sourceId] == null ? null : resolveApiResourceUrl(base, icons[s.sourceId]!), title: s.sourceName),
              ),
              trailing: CineButton(
                label: 'Open',
                variant: CineButtonVariant.quiet,
                size: CineButtonSize.sm,
                onPressed: () {
                  chosen = s;
                  Navigator.of(ctx).pop();
                },
              ),
              onTap: () {
                chosen = s;
                Navigator.of(ctx).pop();
              },
            ),
        ],);
      },
    ),
  ).whenComplete(() {
    final s = chosen;
    if (s != null) onOpen(s);
  });
}
