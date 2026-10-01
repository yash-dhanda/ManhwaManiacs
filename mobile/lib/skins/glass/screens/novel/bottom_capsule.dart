import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chrome_top.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "42 % · 6 min left"; minutes only once the pace is ready; paged "p. 7 of 22 · 42 %" (E4).
String novelReadout({required int percent, int? minutesLeft, int? page, int? pages}) {
  if (page != null && pages != null && pages > 0) return 'p. $page of $pages · $percent %';
  return minutesLeft == null ? '$percent %' : '$percent % · $minutesLeft min left';
}

/// The bottom capsule (E4): `glassRegular`, 56 tall, at most 520 wide: previous chapter (30 % and disabled without one), the readout
/// (a button: Go to a percentage), the ordered [slots] (`mobile/44`'s cruise button, scroll mode only), next chapter.
class NovelBottomCapsule extends StatelessWidget {
  const NovelBottomCapsule({
    super.key,
    required this.width,
    required this.readout,
    required this.percent,
    required this.onGoTo,
    required this.lb,
    this.tint,
    this.onPrevious,
    this.onNext,
    this.nextLabel,
    this.slots = const [],
    this.readoutKey,
    this.listenRow,
    this.listenRowWidth,
    this.listenRowAlign = Alignment.center,
  });

  final double width;
  final String readout;
  final int percent;
  final VoidCallback onGoTo;
  final double lb;
  final Color? tint;
  final VoidCallback? onPrevious, onNext;
  final String? nextLabel;
  final List<Widget> slots;
  final GlobalKey? readoutKey;

  /// `mobile/37`'s listen row (glass 8.16.1): a 48 px shape of this capsule's group, 8 px above it ([listenRowWidth] wide, aligned by
  /// [listenRowAlign]; 320 floating bottom-right on a landscape phone).
  final Widget? listenRow;
  final double? listenRowWidth;
  final Alignment listenRowAlign;

  @override
  Widget build(BuildContext context) {
    Widget icon(GlassIconRole role, String label, VoidCallback? onTap) => Opacity(
          opacity: onTap == null ? 0.3 : 1,
          child: GlassBarIcon(icon: roleIcon(role), label: label, onPressed: onTap),
        );
    final content = NovelTintedShape(
      tint: tint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            icon(GlassIconRole.chapterPrevious, 'Previous chapter', onPrevious),
            Expanded(
              child: Semantics(
                button: true,
                label: '$percent percent, go to a percentage',
                excludeSemantics: true,
                onTap: onGoTo,
                child: GestureDetector(
                  key: readoutKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: onGoTo,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Center(child: GlassText(readout, role: gt.typeMono, size: 13, onGlass: true, maxScale: 1.3, maxLines: 1)),
                  ),
                ),
              ),
            ),
            ...slots,
            GlassTooltip(
              message: nextLabel ?? 'No next chapter',
              child: icon(GlassIconRole.chapterNext, 'Next chapter', onNext),
            ),
          ],
        ),
      ),
    );
    final row = listenRow;
    if (row == null) {
      return SkinGlass(size: Size(width, 56), tier: GlassTierId.t3, lb: lb, debugLabel: 'novel bottom capsule', child: content);
    }
    // The listen row and the capsule are two shapes of one group: one layer (glass 15.7, the novel reader row).
    final rowW = listenRowWidth ?? width;
    return SizedBox(
      width: width,
      height: 48 + 8 + 56,
      child: SkinGlassGroup(
        shapes: [
          SkinGlassShape(size: Size(rowW, 48), child: row),
          SkinGlassShape(size: Size(width, 56), child: content),
        ],
        axis: Axis.vertical,
        offsets: [Offset(listenRowAlign.x * (width - rowW) / 2, 0), Offset.zero],
        lb: lb,
        debugLabel: 'novel bottom capsule and listen row',
      ),
    );
  }
}

/// The capsule's width in a window [screenWidth] wide.
double novelCapsuleWidth(double screenWidth) => math.min(520, screenWidth - 32);
