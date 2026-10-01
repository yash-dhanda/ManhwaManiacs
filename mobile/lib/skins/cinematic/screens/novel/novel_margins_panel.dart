import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/circle_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// One tab of the panel: its label and the body it builds. The tab list is ordered; `mobile/15`
/// appends `VOICES`.
class NovelMarginsTab {
  const NovelMarginsTab(this.label, this.builder);
  final String label;
  final WidgetBuilder builder;
}

/// The right "Margins" column panel of the tablet novel reader (cinematic 8.15.3, 8.14.12): tabs
/// `NOTES · CIRCLE` over the chapter being read, in the stock colours (the tokens of the stock
/// scope). The CIRCLE tab is absent while the Circle answers 404.
class NovelMarginsPanel extends ConsumerStatefulWidget {
  const NovelMarginsPanel({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.chapterNumber,
    required this.completedOpen,
    required this.onClose,
    required this.onAddNote,
    required this.onJumpToParagraph,
    this.extraTabs = const [],
  });

  final String sourceId, seriesKey, chapterKey;
  final double? chapterNumber;

  /// The chapter is complete: the Circle tab's spoilers unseal.
  final bool completedOpen;
  final VoidCallback onClose;

  /// Saves a bookmark at the reading line and returns it (the screen owns the controller).
  final Future<Bookmark?> Function() onAddNote;

  /// A note's paragraph (1-based) was tapped.
  final ValueChanged<int> onJumpToParagraph;
  final List<NovelMarginsTab> extraTabs;

  @override
  ConsumerState<NovelMarginsPanel> createState() => _NovelMarginsPanelState();
}

class _NovelMarginsPanelState extends ConsumerState<NovelMarginsPanel> with TickerProviderStateMixin {
  TabController? _tc;
  int _length = 0;

  void _changed() {
    if (mounted) setState(() {});
  }

  void _resize(int length) {
    if (length == _length && _tc != null) return;
    final old = _tc;
    _length = length;
    _tc = TabController(length: length, vsync: this, initialIndex: (old?.index ?? 0).clamp(0, length - 1))..addListener(_changed);
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _tc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final circle = ref.watch(circleSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
    final hasCircle = !(circle.hasValue && circle.valueOrNull == null);
    final tabs = <NovelMarginsTab>[
      NovelMarginsTab(
        'NOTES',
        (context) => NovelNotesTab(
          sourceId: widget.sourceId,
          seriesKey: widget.seriesKey,
          chapterKey: widget.chapterKey,
          onAdd: widget.onAddNote,
          onJump: widget.onJumpToParagraph,
        ),
      ),
      if (hasCircle)
        NovelMarginsTab(
          'CIRCLE',
          (context) => CircleTab(
            sourceId: widget.sourceId,
            seriesKey: widget.seriesKey,
            chapterKey: widget.chapterKey,
            chapterNumber: widget.chapterNumber,
            completedOpen: widget.completedOpen,
          ),
        ),
      ...widget.extraTabs,
    ];
    _resize(tabs.length);
    final tc = _tc!;
    return Material(
      color: c.colorPaper0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space2, 0),
              child: Row(children: [
                Expanded(child: CineRoleText('MARGINS', c.typeKicker, color: c.colorInk60)),
                SizedBox(height: cineHitMin(context)),
                CineIconButton(label: 'Close Margins', role: CineIconRole.close, onPressed: widget.onClose),
              ],),
            ),
            CineContentsTabs(controller: tc, tabs: [for (var i = 0; i < tabs.length; i++) CineTab(folio: '0${i + 1}', label: tabs[i].label)]),
            Expanded(child: tabs[tc.index.clamp(0, tabs.length - 1)].builder(context)),
          ],
        ),
      ),
    );
  }
}

/// NOTES: this chapter's bookmarks as `¶ 12` and the note; a tap scrolls there; `Add a note to
/// this paragraph` saves a bookmark at the reading line and opens its note field.
class NovelNotesTab extends ConsumerStatefulWidget {
  const NovelNotesTab({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, required this.onAdd, required this.onJump});

  final String sourceId, seriesKey, chapterKey;
  final Future<Bookmark?> Function() onAdd;
  final ValueChanged<int> onJump;

  @override
  ConsumerState<NovelNotesTab> createState() => _NovelNotesTabState();
}

class _NovelNotesTabState extends ConsumerState<NovelNotesTab> {
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
    final container = ProviderScope.containerOf(context, listen: false);
    final b = await widget.onAdd();
    container.invalidate(bookmarksProvider);
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
        if (b.sourceId == widget.sourceId && b.seriesKey == widget.seriesKey && b.chapterKey == widget.chapterKey && !b.deleted && b.mediaType == BookmarkMedia.novel) b,
    ]..sort((a, b) => a.anchorIndex.compareTo(b.anchorIndex));
    return ListView(
      padding: EdgeInsets.all(c.space4),
      children: [
        if (all.isLoading && rows.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: CineLeaderDial(size: 24))),
        if (all.hasError && rows.isEmpty) CineRoleText("This didn't load.", c.typeCaption, color: c.colorProof),
        if (rows.isEmpty && !all.isLoading) Padding(padding: EdgeInsets.only(bottom: c.space3), child: CineRoleText('No bookmarks in this chapter yet.', c.typeCaption, color: c.colorInk60)),
        for (final b in rows)
          CinePressable(
            onTap: () => widget.onJump(b.anchorIndex),
            builder: (context, st) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: cineHitMin(context)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: c.space2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 56, child: CineRoleText('¶ ${b.anchorIndex}', c.typeFolio, color: c.colorSpot)),
                  Expanded(
                    child: b.note == null || b.note!.isEmpty
                        ? CineRoleText(b.snippet ?? 'No note', c.typeCaption, color: c.colorInk45, maxLines: 3, overflow: TextOverflow.ellipsis)
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
              label: 'Note for ¶ ${_editing!.anchorIndex}',
              controller: _text,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => unawaited(_save(v)),
            ),
          )
        else
          Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Add a note to this paragraph', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => unawaited(_add()))),
      ],
    );
  }
}
