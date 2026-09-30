import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/notes_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The picture of [page] as the reader loads it: the saved file, else the proxied URL.
ImageProvider pageImageProvider(WidgetRef ref, ReaderPage page) {
  final file = page.localFile;
  if (file != null) return FileImage(file);
  return CachedNetworkImageProvider(
    page.imageUrl,
    headers: apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id),
  );
}

/// `PAGE 18 · 800 × 12400`, or `PAGE 18` when the size is not known.
String lightboxFolio(int page, int? width, int? height) => width != null && height != null ? 'PAGE $page · $width × $height' : 'PAGE $page';

/// What the page-actions sheet acts on.
class PageActionsTarget {
  const PageActionsTarget({
    required this.sourceId,
    required this.seriesKey,
    required this.chapter,
    required this.page,
    required this.saved,
    this.chapterNumber,
    this.hasDialogue = false,
    required this.onShowDialogue,
    required this.onRetry,
    required this.onOpenImage,
  });

  final String sourceId, seriesKey;
  final ReaderChapter chapter;
  final int page;

  /// The chapter is saved on this device.
  final bool saved;
  final double? chapterNumber;

  /// The chapter has OCR text for this page.
  final bool hasDialogue;
  final VoidCallback onShowDialogue, onRetry, onOpenImage;

  ChapterIdentity get id => (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapter.id);
}

/// Opens the page actions (cinematic 8.14.13): kicker `PAGE 18`, detents `[0.5, 0.92]`. Opened by a
/// 450 ms press, the phone setup footer, the tablet `dots-three` and `Shift+F10`.
Future<void> showPageActions(BuildContext context, PageActionsTarget target) => showCineSheet<void>(
      context,
      kicker: 'PAGE ${target.page}',
      title: target.chapter.title,
      livePreview: true,
      builder: (sheetContext) => Material(type: MaterialType.transparency, child: PageActionsBody(target: target, close: () => Navigator.of(sheetContext).maybePop())),
    );

class PageActionsBody extends ConsumerStatefulWidget {
  const PageActionsBody({super.key, required this.target, required this.close});
  final PageActionsTarget target;
  final VoidCallback close;

  @override
  ConsumerState<PageActionsBody> createState() => _PageActionsBodyState();
}

class _PageActionsBodyState extends ConsumerState<PageActionsBody> {
  Bookmark? _saved;
  bool _busy = false;
  final _note = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _note.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _bookmark() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = widget.target;
    final b = await addBookmarkAtPage(
      ref,
      sourceId: t.sourceId,
      seriesKey: t.seriesKey,
      chapterKey: t.chapter.id,
      page: t.page,
      pageCount: t.chapter.pages.length,
      seriesTitle: t.chapter.seriesTitle,
      chapterNumber: t.chapterNumber,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = b;
    });
    if (b != null) _focus.requestFocus();
  }

  Future<void> _saveNote(String v) async {
    final b = _saved;
    if (b != null && v.trim().isNotEmpty) await ref.read(bookmarkOutboxControllerProvider).setNote(b, v);
    ref.invalidate(bookmarksProvider);
    widget.close();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final t = widget.target;
    final run = ref.watch(ocrRunControllerProvider);
    final scanning = run.isBusy && run.chapter == t.id;
    final canScan = t.saved && ref.watch(ocrFeatureVisibleProvider);
    Widget item(String label, VoidCallback? onTap, {String? caption}) => CinePressable(
          enabled: onTap != null,
          onTap: onTap,
          builder: (context, st) => ConstrainedBox(
            constraints: BoxConstraints(minHeight: cineHitMin(context)),
            child: Semantics(
              button: true,
              enabled: onTap != null,
              label: label,
              excludeSemantics: true,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CineRoleText(label, c.typeUi, color: onTap == null ? c.colorInk30 : (st.hovered ? c.colorSpot : c.colorInk100)),
                  if (caption != null) CineRoleText(caption, c.typeCaption, color: c.colorInk60),
                ],),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        item('Bookmark this spot', _saved == null && !_busy ? () => unawaited(_bookmark()) : null, caption: _saved != null ? 'Saved on p. ${t.page}.' : null),
        if (_saved != null)
          Padding(
            padding: EdgeInsets.only(bottom: c.space3),
            child: CineTextField(
              label: 'Note for p. ${t.page}',
              controller: _note,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => unawaited(_saveNote(v)),
            ),
          ),
        if (t.hasDialogue)
          item('Show dialogue on this page', () {
            widget.close();
            t.onShowDialogue();
          }),
        item('Retry this page', () {
          widget.close();
          t.onRetry();
        }),
        item('Open page image', () {
          widget.close();
          t.onOpenImage();
        }),
        if (canScan)
          item(
            scanning ? 'SCANNING ${run.completedPages} OF ${run.totalPages}' : "Scan this chapter's dialogue",
            scanning || run.isBusy ? null : () => unawaited(ref.read(ocrRunControllerProvider.notifier).runChapter(id: t.id, chapterNumber: t.chapterNumber)),
          ),
        SizedBox(height: c.space6),
      ],
    );
  }
}

/// Opens the Lightbox on [page] (`Open page image`).
Future<void> openPageImage(BuildContext context, WidgetRef ref, {required ReaderChapter chapter, required ReaderPage page, required Object heroTag}) =>
    openCineLightbox(
      context,
      heroTag: heroTag,
      image: pageImageProvider(ref, page),
      title: '${chapter.title} · page ${page.number}',
      folio: lightboxFolio(page.number, page.width, page.height),
    );
