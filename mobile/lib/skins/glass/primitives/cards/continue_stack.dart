import 'dart:math' as math;

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';

/// The Continue stack (glass 7.7): 280 x 132 on phones, 320 x 148 on desktop frames. The cover (88 x 132) on
/// the left with the next page's thumbnail peeking 8 px right and 6 px down, rotated 2 degrees, like a
/// deck; on the right the title, "Ch 142 - p. 18 of 40", a 24 px progress ring around the chapter number
/// and a plain "Continue". An unopened next chapter ([pageCount] 0) reads "Up next - Ch 143", the ring
/// shows its track only, the button reads "Start", and no ratio is computed. No horizontal swipe (it sits
/// in a rail). "Previously on" is a trailing menu row, the `P` key on a focused stack, and [onPreviouslyOn].
class GlassContinueStack extends StatelessWidget {
  const GlassContinueStack({
    super.key,
    required this.cover,
    required this.title,
    required this.chapter,
    required this.page,
    required this.pageCount,
    this.nextThumb,
    this.onOpen,
    this.onContinue,
    this.onMore,
    this.onPreviouslyOn,
  });

  final Widget cover;
  final Widget? nextThumb;
  final String title;

  /// The chapter number as printed (12.5 stays 12.5); null when the source does not number it.
  final num? chapter;

  String get _ch => chapter == null ? '' : (chapter! % 1 == 0 ? '${chapter!.toInt()}' : '$chapter');

  /// The 1-based current page; ignored when [pageCount] is 0.
  final int page;
  final int pageCount;
  final VoidCallback? onOpen;
  final VoidCallback? onContinue;

  /// The trailing ⋯: opens the context menu (`mobile/27`), whose first row is "Previously on".
  final VoidCallback? onMore;
  final VoidCallback? onPreviouslyOn;

  bool get unopened => pageCount == 0;

  @override
  Widget build(BuildContext context) {
    final wide = GlassFrame.of(context).index >= GlassFrameKind.desktop.index;
    final w = wide ? 320.0 : 280.0;
    // The text grows to 1.5 x: the card grows with it so nothing is clipped at the largest text sizes.
    final h = (wide ? 148.0 : 132.0) * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    const coverW = 88.0;
    final ratio = unopened ? 0.0 : (page / pageCount).clamp(0.0, 1.0);
    final ch = chapter == null ? null : 'Ch $_ch';
    final meta = unopened ? (ch == null ? 'Up next' : 'Up next · $ch') : '${ch == null ? '' : '$ch · '}p. $page of $pageCount';
    return SizedBox(
      width: w,
      height: h,
      child: GlassSlab(
        padding: EdgeInsets.zero,
        onTap: onOpen,
        semanticsLabel: '$title, $meta',
        customActions: {
          if (onPreviouslyOn != null) const CustomSemanticsAction(label: 'Previously on'): onPreviouslyOn!,
        },
        onKey: (node, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.keyP && onPreviouslyOn != null) {
            onPreviouslyOn!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The deck: the next page peeks behind the cover.
            if (nextThumb != null)
              Positioned(
                left: 8 + 8,
                top: 0 + 6,
                width: coverW,
                height: h,
                child: Transform.rotate(angle: 2 * math.pi / 180, child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusMd), child: nextThumb)),
              ),
            Positioned(left: 8, top: 0, bottom: 0, width: coverW, child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusMd), child: cover)),
            Positioned(
              left: coverW + 8 + 12,
              right: 8,
              top: 12,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(right: 36), child: GlassLabel(title, role: gt.typeHeadline, maxLines: 2)),
                  const SizedBox(height: 2),
                  GlassLabel(meta, role: gt.typeFootnote, color: gt.colorLabel2),
                  const Spacer(),
                  Row(
                    children: [
                      GlassRingProgress(value: ratio, child: GlassLabel(_ch, role: gt.typeMono, size: 9, height: 12, color: gt.colorLabel1, maxScale: 1.2)),
                      const Spacer(),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: GlassButton(label: unopened ? 'Start' : 'Continue', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onContinue))),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GlassIconButton(icon: GlassButtonIcon.glyph(GlassGlyph.dotsThree), label: 'More for $title', onPressed: onMore),
            ),
          ],
        ),
      ),
    );
  }
}
