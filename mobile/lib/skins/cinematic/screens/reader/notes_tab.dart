import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Saves a bookmark on [page] (with its note field opening after) and returns it; the reader's
/// own `bookmark()` measures the spot on screen, this one is for a page named by number.
Future<Bookmark?> addBookmarkAtPage(
  WidgetRef ref, {
  required String sourceId,
  required String seriesKey,
  required String chapterKey,
  required int page,
  required int pageCount,
  String? seriesTitle,
  double? chapterNumber,
}) async {
  final b = await ref.read(bookmarkOutboxControllerProvider).create(
        id: (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey),
        media: BookmarkMedia.manga,
        anchorIndex: page,
        anchorFraction: 0,
        anchorTotal: pageCount,
        seriesTitle: seriesTitle,
        chapterNumber: chapterNumber,
      );
  ref.invalidate(bookmarksProvider);
  return b;
}

/// NOTES (cinematic 8.14.12): this chapter's bookmarks as `p. 12` and the note, a tap scrolls
/// there, `Add a note to this page` saves a bookmark at the reading line and opens its note field.
class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key, required this.engine, required this.sourceId, required this.seriesKey, required this.chapterKey, this.seriesTitle, this.chapterNumber});

  final ReaderEngine engine;
  final String sourceId, seriesKey, chapterKey;
  final String? seriesTitle;
  final double? chapterNumber;

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  Bookmark? _editing;
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final s = widget.engine.value;
    final page = widget.engine.pageAtReadingLine();
    final b = await addBookmarkAtPage(
      ref,
      sourceId: widget.sourceId,
      seriesKey: widget.seriesKey,
      chapterKey: widget.chapterKey,
      page: page,
      pageCount: s.pageCount,
      seriesTitle: widget.seriesTitle,
      chapterNumber: widget.chapterNumber,
    );
    if (b == null || !mounted) return;
    setState(() => _editing = b);
    _text.clear();
    _focus.requestFocus();
  }

  Future<void> _save(String value) async {
    final b = _editing;
    setState(() => _editing = null);
    if (b == null) return;
    if (value.trim().isNotEmpty) await ref.read(bookmarkOutboxControllerProvider).setNote(b, value);
    ref.invalidate(bookmarksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final all = ref.watch(bookmarksProvider);
    final rows = [
      for (final b in all.valueOrNull?.bookmarks ?? const <Bookmark>[])
        if (b.sourceId == widget.sourceId && b.seriesKey == widget.seriesKey && b.chapterKey == widget.chapterKey && !b.deleted) b,
    ]..sort((a, b) => a.anchorIndex.compareTo(b.anchorIndex));
    return ListView(
      padding: EdgeInsets.all(c.space4),
      children: [
        if (all.isLoading && rows.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: CineLeaderDial(size: 24))),
        if (all.hasError && rows.isEmpty) CineRoleText("This didn't load.", c.typeCaption, color: c.colorProof),
        if (rows.isEmpty && !all.isLoading) Padding(padding: EdgeInsets.only(bottom: c.space3), child: CineRoleText('No bookmarks in this chapter yet.', c.typeCaption, color: c.colorInk60)),
        for (final b in rows)
          CinePressable(
            onTap: () => widget.engine.jumpToPage(b.anchorIndex),
            builder: (context, st) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: cineHitMin(context)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: c.space2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 56, child: CineRoleText('p. ${b.anchorIndex}', c.typeFolio, color: c.colorSpot)),
                  Expanded(
                    child: b.note == null || b.note!.isEmpty
                        ? CineRoleText('No note', c.typeCaption, color: c.colorInk45)
                        : CineRoleText(b.note!, c.typeBody, color: c.colorInk100),
                  ),
                ],),
              ),
            ),
          ),
        if (_editing != null)
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _editing = null);
            },
            child: CineTextField(
              label: 'Note for p. ${_editing!.anchorIndex}',
              controller: _text,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => unawaited(_save(v)),
            ),
          )
        else
          Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Add a note to this page', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => unawaited(_add()))),
      ],
    );
  }
}
