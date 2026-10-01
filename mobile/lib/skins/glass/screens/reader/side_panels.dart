import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_tint_chrome.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/panel_fit.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The desktop frame (glass 8.14.11): a window at least 1024 wide whose shorter side is at least 600.
bool isReaderDesktopFrame(Size s) => s.width >= 1024 && s.shortestSide >= 600;

/// The tablet frame: shorter side at least 600, narrower than 1024.
bool isReaderTabletFrame(Size s) => s.shortestSide >= 600 && s.width < 1024;

/// A side panel: content-layer `materialThick` (`#131317` at 0.84, blur 36), radius 26, 12 px from the window edges, never Liquid
/// Glass; its rim takes the page tint.
class ReaderPanelSurface extends StatelessWidget {
  const ReaderPanelSurface({super.key, required this.label, required this.child, this.tint});
  final String label;
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: label,
        explicitChildNodes: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xD6131317),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: tint == null ? const Color(0x38FFFFFF) : rimTint(tint!).withValues(alpha: PageTint.rim)),
              ),
              // Controls on the panel material are on-glass twins: no glass reads the backdrop inside a panel.
              child: GlassHost(child: child),
            ),
          ),
        ),
      );
}

enum RightPanelTab { settings, dialogue }

/// The right panel's body: tabs Settings and Dialogue (the Circle tab joins in mobile/43).
class ReaderRightPanel extends StatelessWidget {
  const ReaderRightPanel({super.key, required this.tab, required this.onTab, required this.settings, required this.pageText});
  final RightPanelTab tab;
  final ValueChanged<RightPanelTab> onTab;
  final Widget settings;

  /// The overlay's text list for the current page (null while it has none).
  final PageText? pageText;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: GlassSegmented<RightPanelTab>(
              asTabs: true,
              segments: const [GlassSegment(value: RightPanelTab.settings, label: 'Settings'), GlassSegment(value: RightPanelTab.dialogue, label: 'Dialogue')],
              selected: tab,
              onSelected: onTab,
            ),
          ),
          Expanded(
            child: tab == RightPanelTab.settings
                ? SingleChildScrollView(child: settings)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (pageText == null || pageText!.boxes.isEmpty)
                        GlassText('No dialogue has been extracted for this page', role: gt.typeFootnote, onGlass: true)
                      else
                        for (final b in pageText!.boxes)
                          Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassText(b.text, role: gt.typeCallout, onGlass: true)),
                    ],
                  ),
          ),
        ],
      );
}

/// Lays the strip and the two panels out (glass 8.14.11): panels push the strip, never cover it; the strip's centre travels to the
/// middle of the remaining width while a panel slides in from its edge, both on `springSheet` (the duration of its settle).
class ReaderPanelLayout extends StatelessWidget {
  const ReaderPanelLayout({
    super.key,
    required this.left,
    required this.right,
    required this.leftOpen,
    required this.rightOpen,
    required this.strip,
    required this.duration,
    this.tint,
  });

  final Widget left, right, strip;
  final bool leftOpen, rightOpen;
  final Duration duration;
  final Color? tint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        const curve = Cubic(0.2, 0.9, 0.3, 1);
        // The strip region is what the panels leave; the engine centres its column (`stripWithPanels`) inside it.
        return Stack(
          children: [
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              left: leftOpen ? kReaderLeftPanel + 24 : 0,
              right: rightOpen ? kReaderRightPanel + 24 : 0,
              top: 0,
              bottom: 0,
              child: strip,
            ),
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              left: leftOpen ? 12 : -kReaderLeftPanel - 24,
              top: 12,
              bottom: 12,
              width: kReaderLeftPanel,
              child: ReaderPanelSurface(label: 'Chapters', tint: tint, child: left),
            ),
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              left: rightOpen ? w - kReaderRightPanel - 12 : w + 24,
              top: 12,
              bottom: 12,
              width: kReaderRightPanel,
              child: ReaderPanelSurface(label: 'Reader settings', tint: tint, child: right),
            ),
          ],
        );
      },);
}

/// The page-lit gutters (glass 8.14.11): with both panels closed, the gutters beside the strip are `g25` wells in which the
/// sample's top colour glows in the top half and its bottom colour in the bottom half, at 10 %, radial with a 120 px soft edge.
/// One `CustomPaint`, no filter; cross-fades over `curveTintShift`. Off (tint off or Reduce Transparency): plain black.
class PageLitGutters extends StatelessWidget {
  const PageLitGutters({super.key, required this.strip, required this.top, required this.bottom, required this.lit});
  final Rect strip;
  final Color? top, bottom;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    if (!lit) return const ColoredBox(color: Color(0xFF000000));
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: top ?? const Color(0x00000000)),
      duration: gt.curveTintShift.duration,
      curve: gt.curveTintShift.curve,
      builder: (context, t, _) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: bottom ?? const Color(0x00000000)),
        duration: gt.curveTintShift.duration,
        curve: gt.curveTintShift.curve,
        builder: (context, b, _) => CustomPaint(painter: _GutterPainter(strip: strip, top: t, bottom: b), child: const SizedBox.expand()),
      ),
    );
  }
}

class _GutterPainter extends CustomPainter {
  _GutterPainter({required this.strip, required this.top, required this.bottom});
  final Rect strip;
  final Color? top, bottom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF060608));
    void glow(Rect gutter) {
      if (gutter.width <= 0) return;
      for (final (half, c) in [(Rect.fromLTRB(gutter.left, 0, gutter.right, size.height / 2), top), (Rect.fromLTRB(gutter.left, size.height / 2, gutter.right, size.height), bottom)]) {
        if (c == null) continue;
        final r = half.shortestSide / 2 + 120;
        canvas.save();
        canvas.clipRect(half);
        canvas.drawCircle(
          half.center,
          r,
          Paint()..shader = RadialGradient(colors: [c.withValues(alpha: 0.10), c.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: half.center, radius: r)),
        );
        canvas.restore();
      }
    }

    glow(Rect.fromLTRB(0, 0, strip.left, size.height));
    glow(Rect.fromLTRB(strip.right, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(_GutterPainter old) => old.strip != strip || old.top != top || old.bottom != bottom;
}
