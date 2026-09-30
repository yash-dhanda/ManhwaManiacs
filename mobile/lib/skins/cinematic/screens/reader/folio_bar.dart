import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/jump_to_page_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ruler.dart';
import 'package:manhwamaniacs/skins/cinematic/scrim_head.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The folio bar of the manga reader (cinematic 8.14.3): previous chapter, the ruler, next chapter
/// and auto-scroll on one row; the page counter and the time left under the ruler. Over a sole
/// scrim; at text scale 1.5 and up the time left moves to a second line and the bar grows.
class ReaderFolioBar extends StatelessWidget {
  const ReaderFolioBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.rtl,
    required this.bookmarkPages,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
    required this.onJump,
    required this.counterKey,
    required this.autoScrolling,
    required this.speedLabel,
    required this.onToggleAutoScroll,
    this.minutesLeft,
    this.showAutoScroll = true,
    this.returnFocus,
  });

  final int page, pageCount;
  final bool rtl;
  final List<int> bookmarkPages;

  /// The neighbour's folio number (`141`), or null when there is none.
  final String? previousLabel, nextLabel;
  final VoidCallback? onPrevious, onNext;
  final ValueChanged<int> onSeek, onJump;
  final GlobalKey<PageCounterFieldState> counterKey;
  final bool autoScrolling, showAutoScroll;
  final String speedLabel;
  final VoidCallback onToggleAutoScroll;
  final int? minutesLeft;
  final FocusNode? returnFocus;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final side = MediaQuery.viewPaddingOf(context);
    final gutter = MediaQuery.sizeOf(context).width >= 600 ? c.space8 : c.space4;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final stacked = scale >= 1.5;
    final caption = minutesLeft == null ? null : '$minutesLeft MIN LEFT';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        scrimSoleLayer(fade: 64),
        Padding(
          padding: EdgeInsets.only(left: side.left + gutter - 8, right: side.right + gutter - 8, bottom: bottom),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _ChapterStep(previous: true, label: previousLabel, onTap: onPrevious),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ReaderRuler(page: page, pageCount: pageCount, rtl: rtl, bookmarkPages: bookmarkPages, onSeek: onSeek),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ChapterStep(previous: false, label: nextLabel, onTap: onNext),
                    if (showAutoScroll) ...[
                      const SizedBox(width: 8),
                      _AutoScrollButton(on: autoScrolling, speedLabel: speedLabel, onTap: onToggleAutoScroll),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PageCounterField(key: counterKey, page: page, pageCount: pageCount, onJump: onJump, returnFocus: returnFocus),
                            if (caption != null) CineRoleText(caption, c.typeCaption, color: c.colorInk60),
                          ],
                        )
                      : Row(
                          children: [
                            PageCounterField(key: counterKey, page: page, pageCount: pageCount, onJump: onJump, returnFocus: returnFocus),
                            if (caption != null) ...[
                              const SizedBox(width: 8),
                              ExcludeSemantics(child: CineRoleText('·', c.typeCaption, color: c.colorInk45)),
                              const SizedBox(width: 8),
                              CineRoleText(caption, c.typeCaption, color: c.colorInk60),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChapterStep extends StatelessWidget {
  const _ChapterStep({required this.previous, required this.label, required this.onTap});
  final bool previous;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final enabled = onTap != null && label != null;
    final glyph = CineGlyphIcon(previous ? ReaderCp.skipBack : ReaderCp.skipForward, color: enabled ? c.colorInk100 : c.colorInk30);
    final text = CineRoleText(label ?? '', c.typeFolio, color: enabled ? c.colorInk100 : c.colorInk30);
    final tip = enabled ? (previous ? 'Previous chapter' : 'Next chapter') : (previous ? 'This is the first chapter' : 'This is the latest chapter');
    return Tooltip(
      message: tip,
      excludeFromSemantics: true,
      child: CinePressable(
        enabled: enabled,
        onTap: onTap,
        builder: (context, st) => Semantics(
          button: true,
          enabled: enabled,
          label: enabled ? '${previous ? 'Previous' : 'Next'} chapter, $label' : tip,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: cineHitMin(context), minWidth: cineHitMin(context)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: previous ? [glyph, const SizedBox(width: 4), text] : [text, const SizedBox(width: 4), glyph],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoScrollButton extends StatelessWidget {
  const _AutoScrollButton({required this.on, required this.speedLabel, required this.onTap});
  final bool on;
  final String speedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CineIconButton(label: on ? 'Stop auto-scroll' : 'Auto-scroll', role: CineIconRole.autoScroll, selected: on, onPressed: onTap),
        if (on)
          Positioned(
            top: -6,
            child: IgnorePointer(child: CineRoleText(speedLabel, c.typeFolio, color: c.colorSpot)),
          ),
      ],
    );
  }
}
