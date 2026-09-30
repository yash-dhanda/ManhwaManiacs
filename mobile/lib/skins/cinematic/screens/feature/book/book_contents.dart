import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/contents_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

/// The contents under the 1 px section rule: toolbar (`FIRST → LAST`,
/// `Pick chapters`, `Narrated only`, go-to), the windowed rows with `Show
/// earlier chapters` / `Show more chapters`, and the list states.
class BookContentsToolbar extends StatelessWidget {
  const BookContentsToolbar({
    super.key,
    required this.order,
    required this.onOrder,
    required this.selecting,
    required this.onPick,
    required this.narratedOnly,
    required this.onNarrated,
    required this.onGoTo,
    required this.wide,
    this.goToController,
    this.goToFocus,
    this.onGoToSubmitted,
    this.goToMatches = const [],
    this.goToCaption,
    this.onPickMatch,
    this.showNarrated = true,
  });

  final String order;
  final ValueChanged<String> onOrder;
  final bool selecting;
  final VoidCallback onPick;
  final bool narratedOnly;
  final ValueChanged<bool> onNarrated;
  final VoidCallback onGoTo;
  final bool wide;
  final TextEditingController? goToController;
  final FocusNode? goToFocus;
  final ValueChanged<String>? onGoToSubmitted;
  final List<SourceChapterSummary> goToMatches;
  final String? goToCaption;
  final ValueChanged<SourceChapterSummary>? onPickMatch;
  final bool showNarrated;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: t.colorRule1, height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 300,
                  child: CineSegmentedControl(
                    key: const Key('book-order'),
                    labels: const ['FIRST → LAST', 'LAST → FIRST'],
                    index: order == 'oldest' ? 0 : 1,
                    onChanged: (i) => onOrder(i == 0 ? 'oldest' : 'newest'),
                  ),
                ),
              ),
            ),
            if (!wide)
              IconButton(
                key: const Key('book-go-to'),
                tooltip: 'Go to chapter',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(PhosphorRegular.magnifyingGlass),
                onPressed: onGoTo,
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onPick,
              child: Text(selecting ? 'Done' : 'Pick chapters'),
            ),
            if (showNarrated)
              Semantics(
                button: true,
                toggled: narratedOnly,
                child: FilterChip(
                  label: const Text('Narrated only'),
                  selected: narratedOnly,
                  onSelected: onNarrated,
                ),
              ),
            if (wide)
              SizedBox(
                width: 180,
                child: TextField(
                  key: const Key('inline-go-to'),
                  controller: goToController,
                  focusNode: goToFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.go,
                  decoration: const InputDecoration(labelText: 'Chapter number', isDense: true),
                  onChanged: onGoToSubmitted,
                  onSubmitted: onGoToSubmitted,
                ),
              ),
          ],
        ),
        if (wide) ...[
          Text(goToCaption ?? 'Type a chapter number.',
              style: TextStyle(fontSize: 12, color: t.colorInk60),),
          for (final c in goToMatches.take(12))
            TextButton(
              key: Key('inline-match-${c.id}'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => onPickMatch?.call(c),
              child: Text(c.title),
            ),
          if (goToMatches.length > 12) Text('and ${goToMatches.length - 12} more'),
        ],
      ],
    );
  }
}

/// The windowed list of contents rows as slivers, so only the rows on screen
/// are built. [shown] is the whole ordered list; [window] the rows in play
/// (`tocWindowAround` / `extendTocWindow`).
List<Widget> bookContentsSlivers({
  required List<SourceChapterSummary> shown,
  required ({int start, int end}) window,
  required ValueChanged<({int start, int end})> onWindow,
  required Widget Function(SourceChapterSummary c) rowBuilder,
  ContentsNoticeKind? notice,
  GlobalKey? startKey,
}) {
  if (notice != null) return [SliverToBoxAdapter(child: ContentsNotice(kind: notice))];
  final visible =
      shown.isEmpty ? const <SourceChapterSummary>[] : shown.sublist(window.start, window.end);
  return [
    SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (window.start > 0)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => onWindow(extendTocWindow(window, shown.length, earlier: true)),
              child: Text('Show earlier chapters (${window.start})'),
            ),
          SizedBox(key: startKey, height: 0),
        ],
      ),
    ),
    SliverFixedExtentList(
      itemExtent: kContentsRowExtent,
      delegate: SliverChildBuilderDelegate(
        childCount: visible.length,
        (context, i) => rowBuilder(visible[i]),
      ),
    ),
    if (window.end < shown.length)
      SliverToBoxAdapter(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => onWindow(extendTocWindow(window, shown.length, earlier: false)),
          child: Text('Show more chapters (${shown.length - window.end})'),
        ),
      ),
  ];
}
