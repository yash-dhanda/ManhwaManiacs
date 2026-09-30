import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_providers.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_index.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The Novel text scope (glass 8.9): results from the on-device FTS4 index of downloaded chapters. Never shows an offline state.
class NovelTextResults extends ConsumerStatefulWidget {
  const NovelTextResults({super.key, required this.query});
  final String query;

  @override
  ConsumerState<NovelTextResults> createState() => _NovelTextResultsState();
}

class _NovelTextResultsState extends ConsumerState<NovelTextResults> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) unawaited(ref.read(novelTextBackfillProvider.notifier).start());
    });
  }

  void _open(NovelTextHit h) => unawaited(ref.read(skinRouterProvider).push<void>(Routes.novel(h.sourceId, h.seriesKey, h.chapterKey, {'para': h.para})));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(novelTextSearchProvider(widget.query));
    final s = async.valueOrNull;
    if (s == null) return const SizedBox(height: 120);
    switch (s.status) {
      case NovelTextStatus.noDownloads:
        return GlassObjectLens(
          situation: LensSituation.nothingDownloaded,
          title: 'Download a book to search its text here.',
          placement: GlassLensPlacement.inline,
          primary: LensAction('Go to library', () => ref.read(skinRouterProvider).go(Routes.library())),
        );
      case NovelTextStatus.idle:
        return const SizedBox.shrink();
      case NovelTextStatus.indexing:
      case NovelTextStatus.ready:
        break;
    }
    final indexing = s.status == NovelTextStatus.indexing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (indexing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(liveRegion: true, child: GlassLabel('Preparing ${s.indexing} ${s.indexing == 1 ? 'chapter' : 'chapters'} for search…', role: gt.typeFootnote, color: gt.colorLabel2)),
          ),
        if (s.hits.isEmpty && !indexing)
          GlassObjectLens(situation: LensSituation.nothingFound, title: 'No downloaded chapter says “${widget.query}”', placement: GlassLensPlacement.inline),
        for (final h in s.hits.take(50)) _Row(hit: h, onOpen: () => _open(h)),
        if (s.capped) Padding(padding: const EdgeInsets.only(top: 8), child: GlassLabel('Showing the first 50 matches', role: gt.typeFootnote, color: gt.colorLabel2)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.hit, required this.onOpen});
  final NovelTextHit hit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final snip = hit.snippet;
    final style = TextStyle(fontFamily: 'Literata', fontStyle: FontStyle.italic, fontSize: 15, height: 1.35, color: gt.colorLabel1);
    final spans = <TextSpan>[];
    var at = 0;
    for (final r in snip.ranges) {
      if (r.start > at) spans.add(TextSpan(text: snip.text.substring(at, r.start)));
      spans.add(TextSpan(text: snip.text.substring(r.start, r.end), style: TextStyle(backgroundColor: gt.colorIris600.withValues(alpha: 0.3))));
      at = r.end;
    }
    if (at < snip.text.length) spans.add(TextSpan(text: snip.text.substring(at)));
    return Semantics(
      button: true,
      label: '${hit.seriesKey}, chapter ${hit.chapterKey}, paragraph ${hit.para + 1}, ${snip.text}',
      excludeSemantics: true,
      onTap: onOpen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(6)),
                  child: SizedBox(width: 36, height: 52, child: Icon(GlassGlyph28.bookOpenText.regular, size: 20, color: gt.colorLabel2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassLabel(hit.seriesKey, role: gt.typeHeadline),
                      GlassLabel('Ch ${hit.chapterKey} · paragraph ${hit.para + 1}', role: gt.typeFootnote, color: gt.colorLabel2),
                      const SizedBox(height: 4),
                      RichText(maxLines: 3, overflow: TextOverflow.ellipsis, text: TextSpan(style: style, children: spans)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
