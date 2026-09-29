import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/series_block.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `ON THIS PHONE — BIGGEST FIRST` and one block per series, largest first (two columns from
/// 900 dp). [nodeFor] hands each block its focus node so `j` / `k` can walk them.
class SavedLibrary extends StatelessWidget {
  const SavedLibrary({
    super.key,
    required this.groups,
    required this.pendingKeys,
    required this.nodeFor,
    required this.noun,
    this.blockKeys,
    this.onRemoveRequest,
  });

  final List<DownloadedSeriesGroup> groups;
  final Set<String> pendingKeys;
  final FocusNode Function(String key) nodeFor;
  final String noun;

  /// The screen reads each block's state through these (Enter expands, Delete removes).
  final Map<String, GlobalKey<DownloadSeriesBlockState>>? blockKeys;
  final void Function(DownloadedSeriesGroup group)? onRemoveRequest;

  static String keyOf(DownloadedSeriesGroup g) => '${g.sourceId} ${g.seriesKey}';

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (groups.isEmpty) return const SizedBox.shrink();
    Widget block(DownloadedSeriesGroup g) => DownloadSeriesBlock(
          key: blockKeys?.putIfAbsent(keyOf(g), GlobalKey<DownloadSeriesBlockState>.new),
          group: g,
          pendingKeys: pendingKeys,
          focusNode: nodeFor(keyOf(g)),
          onRemoveRequest: onRemoveRequest == null ? null : () => onRemoveRequest!(g),
        );
    return LayoutBuilder(
      builder: (context, box) {
        final two = box.maxWidth >= 900 - 2 * c.space8;
        final header = Padding(
          padding: EdgeInsets.only(bottom: c.space2),
          child: CineRoleText('ON THIS $noun — BIGGEST FIRST', c.typeKicker, color: c.colorInk60),
        );
        if (!two) {
          return Column(
            key: const Key('saved-library'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, for (final g in groups) block(g)],
          );
        }
        return Column(
          key: const Key('saved-library'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: [for (var i = 0; i < groups.length; i += 2) block(groups[i])])),
                SizedBox(width: c.space6),
                Expanded(child: Column(children: [for (var i = 1; i < groups.length; i += 2) block(groups[i])])),
              ],
            ),
          ],
        );
      },
    );
  }
}
