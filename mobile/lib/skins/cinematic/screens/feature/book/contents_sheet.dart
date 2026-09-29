import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/contents_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

/// N2: the contents sheet in search mode: the go-to field (autofocused), the
/// match list (up to 12 buttons, "and n more"), the captions, and the full
/// contents pre-scrolled to the current chapter. TODO(mobile/06): `CineSheetRoute`.
Future<SourceChapterSummary?> showContentsSheet(
  BuildContext context, {
  required List<SourceChapterSummary> chapters,
  String? currentKey,
  bool online = true,
}) =>
    showModalBottomSheet<SourceChapterSummary>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cineOf(context).colorPaper2,
      builder: (ctx) => ContentsSheet(chapters: chapters, currentKey: currentKey, online: online),
    );

class ContentsSheet extends StatefulWidget {
  const ContentsSheet({super.key, required this.chapters, this.currentKey, this.online = true});
  final List<SourceChapterSummary> chapters;
  final String? currentKey;
  final bool online;

  @override
  State<ContentsSheet> createState() => _ContentsSheetState();
}

class _ContentsSheetState extends State<ContentsSheet> {
  String _q = '';
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final i = widget.chapters.indexWhere((c) => c.id == widget.currentKey);
    _scroll = ScrollController(initialScrollOffset: i <= 0 ? 0 : i * kContentsRowExtent);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final matches = goToChapterMatches(widget.chapters, _q);
    final n = goToChapterQuery(_q);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('CONTENTS', style: kickerStyle(context)),
            ),
            if (!widget.online)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('The contents need a connection to load.'),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const Key('contents-go-to'),
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Chapter number'),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: n == null
                    ? const Text('Type a chapter number.')
                    : matches.isEmpty
                        ? Text('No chapter ${formatChapterNumber(n)} in this book.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final c in matches.take(12))
                                ListTile(
                                  key: Key('match-${c.id}'),
                                  minVerticalPadding: 12,
                                  title: Text(c.title),
                                  subtitle: Text(
                                      'row ${widget.chapters.indexWhere((x) => x.id == c.id) + 1}',),
                                  onTap: () => Navigator.pop(context, c),
                                ),
                              if (matches.length > 12) Text('and ${matches.length - 12} more'),
                            ],
                          ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  itemExtent: kContentsRowExtent,
                  itemCount: widget.chapters.length,
                  itemBuilder: (context, i) {
                    final c = widget.chapters[i];
                    final e = tocEntry(number: c.number, title: c.title);
                    final cur = c.id == widget.currentKey;
                    return InkWell(
                      onTap: () => Navigator.pop(context, c),
                      child: Container(
                        color: cur ? t.colorSpotWash : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text('${e.ordinal ?? '·'}  ${e.title ?? ''}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
