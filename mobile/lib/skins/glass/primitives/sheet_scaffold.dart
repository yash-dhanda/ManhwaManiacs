import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/type.dart' show GlassText;

/// What a sheet's body shows (glass 7.10 states): the header stays live in every one.
enum GlassSheetStatus { ready, loading, error, empty }

/// The `fill2` twin circle 32 with a x, hit `hitMin` (glass 7.10 close button). [glyphSize] 16 is the
/// toast and capsule variant.
class GlassCloseButton extends StatelessWidget {
  const GlassCloseButton({super.key, required this.onTap, this.label = 'Close', this.visual = 32, this.glyphSize = 18, this.filled = true});

  final VoidCallback? onTap;
  final String label;
  final double visual;
  final double glyphSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    return GlassPressable(
      material: GlassMaterial.content,
      growth: GlassGrowth.light,
      sink: 0.92,
      shape: const GlassShape.circle(),
      onTap: onTap,
      semanticsLabel: label,
      tooltip: label,
      builder: (context, info) => SizedBox.square(
        dimension: hit > visual ? hit : visual,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: filled ? gt.colorFill2 : const Color(0x00000000), shape: BoxShape.circle),
            child: SizedBox.square(
              dimension: visual,
              child: Center(child: Icon(PhosphorBold.x, size: glyphSize, color: gt.colorOnGlass)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 36 x 5 grabber inside a `hitMin` button labelled "Sheet size" (glass 7.10): a tap cycles the declared
/// detents, `Up` and `Down` from a hardware keyboard change the detent.
class GlassSheetGrabber extends StatelessWidget {
  const GlassSheetGrabber({super.key, required this.onCycle, required this.onStep});
  final VoidCallback onCycle;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    return Focus(
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
          onStep(1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
          onStep(-1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GlassPressable(
        material: GlassMaterial.content,
        growth: GlassGrowth.light,
        sink: 1,
        onTap: onCycle,
        semanticsLabel: 'Sheet size',
        minHit: false,
        builder: (context, info) => SizedBox(
          width: hit,
          height: hit,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(color: gt.colorFill1, borderRadius: BorderRadius.circular(3)),
                child: const SizedBox(width: 36, height: 5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's frame of content: grabber, the pinned 56 px header (title `title2`, leading action, close) and
/// the body in one of its four states. Focus moves to the title on open ([titleFocus]).
class GlassSheetScaffold extends ConsumerWidget {
  const GlassSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onClose,
    this.onCycle,
    this.onStepDetent,
    this.titleFocus,
    this.leading,
    this.centerTitle = false,
    this.showGrabber = true,
    this.status = GlassSheetStatus.ready,
    this.onRetry,
    this.errorText = "Couldn't load this",
    this.emptyText = 'Nothing here yet',
    this.shrink = false,
  });

  final String title;
  final Widget body;
  final VoidCallback? onClose;
  final VoidCallback? onCycle;
  final ValueChanged<int>? onStepDetent;
  final FocusNode? titleFocus;
  final Widget? leading;
  final bool centerTitle;
  final bool showGrabber;
  final GlassSheetStatus status;
  final VoidCallback? onRetry;
  final String errorText;
  final String emptyText;

  /// Windows and popovers size to their content (up to the max height the caller sets).
  final bool shrink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hit = GlassFrame.hitMin(context);
    final titleWidget = Focus(
      focusNode: titleFocus,
      child: Semantics(
        header: true,
        child: GlassText(title, role: gt.typeTitle2, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: centerTitle ? TextAlign.center : TextAlign.start, maxScale: 1.5),
      ),
    );
    final header = SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            if (centerTitle && leading == null) SizedBox(width: hit),
            Expanded(child: Align(alignment: centerTitle ? Alignment.center : Alignment.centerLeft, child: titleWidget)),
            GlassCloseButton(key: const ValueKey('glass-sheet-close'), onTap: onClose),
          ],
        ),
      ),
    );
    final Widget content = switch (status) {
      GlassSheetStatus.ready => body,
      GlassSheetStatus.loading => GlassSkeletonGroup(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 44, radius: 20, index: i))]),
          ),
        ),
      GlassSheetStatus.error => Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.warningCircle, color: gt.colorDanger)),
                const SizedBox(height: 8),
                GlassText(errorText, role: gt.typeCallout, onGlass: true, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GlassButton(label: 'Retry', onPressed: onRetry, size: GlassButtonSize.small),
              ],
            ),
          ),
        ),
      GlassSheetStatus.empty => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: GlassText(emptyText, role: gt.typeCallout, onGlass: true, textAlign: TextAlign.center)),
        ),
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: shrink ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            header,
            if (shrink) Flexible(child: content) else Expanded(child: content),
          ],
        ),
        if (showGrabber && onCycle != null)
          Positioned(top: 0, left: 0, right: 0, child: Center(child: GlassSheetGrabber(onCycle: onCycle!, onStep: onStepDetent ?? (_) {}))),
      ],
    );
  }
}
