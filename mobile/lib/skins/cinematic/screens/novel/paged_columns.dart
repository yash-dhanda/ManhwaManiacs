import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paginator.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart' show novelParagraphIndents;
import 'package:manhwamaniacs/features/novels/utils/novel_tap_zones.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_page_physics.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Top padding of a page: the column ignores system insets, so toggling the bars never reflows.
const double kNovelPageTopPad = 32;

/// The paged layout (cinematic 8.15.4): one text page per `PageView` page, the opener on the
/// first, the end matter as its own last page. `Cut` turns at once, `Slide` moves 280 ms `settle`
/// (a swipe always tracks the finger through [CinePagePhysics]), `Fade` cross-fades 160 ms; under
/// reduced motion every turn is a 150 ms cross-fade.
class NovelPagedColumns extends StatefulWidget {
  const NovelPagedColumns({
    super.key,
    required this.paragraphs,
    required this.pages,
    required this.type,
    required this.width,
    required this.stock,
    required this.turn,
    required this.tapZones,
    required this.initialPage,
    required this.opener,
    required this.endMatter,
    required this.onPage,
    required this.onMenu,
    this.decorations = const {},
    this.onSpeakerPress,
  });

  final List<String> paragraphs;
  final List<List<NovelPageSlice>> pages;
  final NovelType type;
  final double width;
  final CineStockColors stock;

  /// `cut`, `slide` or `fade`.
  final String turn;
  final String tapZones;
  final int initialPage;
  final Widget opener, endMatter;

  /// The page shown changed (0-based; `pages.length` is the end-matter page).
  final ValueChanged<int> onPage;
  final VoidCallback onMenu;

  /// Tints by paragraph index, in paragraph offsets.
  final Map<int, List<NovelDecoration>> decorations;
  final void Function(String speaker, Offset globalPosition)? onSpeakerPress;

  @override
  State<NovelPagedColumns> createState() => NovelPagedColumnsState();
}

class NovelPagedColumnsState extends State<NovelPagedColumns> with SingleTickerProviderStateMixin {
  late PageController _pages = PageController(initialPage: widget.initialPage.clamp(0, widget.pages.length));
  late final AnimationController _fade = AnimationController(vsync: this, value: 1);
  int _page = 0;

  int get page => _page;
  int get count => widget.pages.length + 1;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, widget.pages.length);
  }

  @override
  void didUpdateWidget(NovelPagedColumns old) {
    super.didUpdateWidget(old);
    if (old.pages != widget.pages) {
      // Re-pagination (size, Type change): keep the current page's paragraph on screen.
      final target = widget.initialPage.clamp(0, widget.pages.length);
      if (target != _page) {
        _page = target;
        _pages.jumpToPage(target);
      }
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _fade.dispose();
    super.dispose();
  }

  bool get _reduced => CineMotion.reduced(context);

  /// Turns [delta] pages by the chosen turn, from a tap or a key.
  void turnBy(int delta) {
    final to = (_page + delta).clamp(0, widget.pages.length);
    if (to == _page) return;
    cineFeedback(context, HapticEvent.pageTurn, sound: SoundEvent.pageTurn);
    if (_reduced) {
      unawaited(_crossFade(to, const Duration(milliseconds: 150)));
      return;
    }
    switch (widget.turn) {
      case 'slide':
        unawaited(_pages.animateToPage(to, duration: context.cine.durPageturn, curve: CineCurves.settle));
      case 'fade':
        unawaited(_crossFade(to, context.cine.durBeat));
      default:
        _pages.jumpToPage(to);
    }
  }

  void jumpTo(int page) => _pages.jumpToPage(page.clamp(0, widget.pages.length));

  Future<void> _crossFade(int to, Duration total) async {
    final half = Duration(milliseconds: total.inMilliseconds ~/ 2);
    await _fade.animateTo(0, duration: half);
    if (!mounted) return;
    _pages.jumpToPage(to);
    await _fade.animateTo(1, duration: half);
  }

  void _tap(TapUpDetails d, Size size) {
    switch (novelTapAction(widget.tapZones, d.localPosition, size)) {
      case NovelTapAction.back:
        turnBy(-1);
      case NovelTapAction.forward:
        turnBy(1);
      case NovelTapAction.menu:
        widget.onMenu();
    }
  }

  List<NovelDecoration> _clip(int paragraph, int start, int end) => [
        for (final d in widget.decorations[paragraph] ?? const <NovelDecoration>[])
          if (d.end > start && d.start < end)
            NovelDecoration(
              start: (d.start - start).clamp(0, end - start),
              end: (d.end - start).clamp(0, end - start),
              fill: d.fill,
              underline: d.underline,
              dotted: d.dotted,
              speaker: d.speaker,
            ),
      ];

  Widget _textPage(BuildContext context, int index) {
    final slices = widget.pages[index];
    final gap = widget.type.paragraphSpacing * widget.type.fontSize;
    final children = <Widget>[];
    if (index == 0) children.add(widget.opener);
    for (final s in slices) {
      final text = widget.paragraphs[s.paragraphIndex];
      if (s.sceneBreak) {
        children.add(NovelSceneBreak(stock: widget.stock));
        continue;
      }
      final start = s.startChar, end = s.endChar;
      children.add(
        NovelParagraph(
          key: ValueKey('p-${s.paragraphIndex}-$start'),
          text: text.substring(start, end),
          type: widget.type.copyWith(paragraphSpacing: 0),
          width: widget.width,
          stock: widget.stock,
          indent: start == 0 && novelParagraphIndents(widget.paragraphs, s.paragraphIndex),
          dropCap: start == 0 && s.paragraphIndex == 0,
          decorations: _clip(s.paragraphIndex, start, end),
          onSpeakerPress: widget.onSpeakerPress,
        ),
      );
      if (gap > 0) children.add(SizedBox(height: gap));
    }
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(top: kNovelPageTopPad),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: widget.width, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (d) => _tap(d, size),
          child: FadeTransition(
            opacity: _fade,
            child: PageView.builder(
              controller: _pages,
              physics: const CinePagePhysics(),
              itemCount: count,
              onPageChanged: (i) {
                if (i != _page) {
                  // A finger-tracked swipe: the haptic fires once it lands.
                  cineFeedback(context, HapticEvent.pageTurn, sound: SoundEvent.pageTurn);
                }
                setState(() => _page = i);
                widget.onPage(i);
              },
              itemBuilder: (context, i) {
                if (i >= widget.pages.length) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: kNovelPageTopPad, bottom: 40),
                    child: Align(alignment: Alignment.topCenter, child: SizedBox(width: widget.width, child: widget.endMatter)),
                  );
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _textPage(context, i),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: kNovelFolioBand,
                      child: Center(
                        child: Semantics(
                          label: 'page ${i + 1} of ${widget.pages.length}',
                          excludeSemantics: true,
                          child: CineRoleText('p. ${i + 1} of ${widget.pages.length}', c.typeFolio, color: widget.stock.muted),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
