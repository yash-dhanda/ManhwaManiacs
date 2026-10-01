import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One recognised speech region and where it sits on its page (fractions 0-1, top-left origin).
@immutable
class DialogueBox {
  const DialogueBox(this.page, this.text, this.rect);
  final int page;
  final String text;
  final Rect rect;
}

/// Every box of [pages] with a full geometry.
List<DialogueBox> dialogueBoxes(List<PageText> pages) => [
      for (final p in pages)
        for (final b in p.boxes)
          if (b.x != null && b.y != null && b.width != null && b.height != null && b.text.trim().isNotEmpty)
            DialogueBox(p.page, b.text, Rect.fromLTWH(b.x!, b.y!, b.width!, b.height!)),
    ];

/// The boxes whose text contains [q] (case-insensitive), in reading order: the hit lens's matches.
List<DialogueBox> dialogueMatches(List<PageText> pages, String q) {
  final needle = q.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final out = dialogueBoxes(pages).where((b) => b.text.toLowerCase().contains(needle)).toList()
    ..sort((a, b) => a.page != b.page ? a.page.compareTo(b.page) : a.rect.top.compareTo(b.rect.top));
  return out;
}

/// Viewport px of [box] through the engine's `pageToViewport`; null while its page is not laid out.
Rect? boxInViewport(ReaderEngine engine, DialogueBox box) {
  final a = engine.pageToViewport(box.page, box.rect.left, box.rect.top);
  final b = engine.pageToViewport(box.page, box.rect.right, box.rect.bottom);
  if (a == Offset.zero && b == Offset.zero) return null;
  return Rect.fromPoints(a, b);
}

/// The dialogue overlay (glass 8.14.9): the page dimmed to 50 % and every recognised region as a content-twin box (radius 6,
/// `twinDense` with a 0.5 px rim, no backdrop read) holding its text in `callout` `label1`. One `CustomPaint` repainted on every
/// scroll frame; its semantics expose each box as a button that copies the text.
class DialoguePainter extends CustomPainter {
  DialoguePainter({required this.engine, required this.boxes, required this.onCopy, this.matches = const [], this.dim = true, required this.textStyle})
      : super(repaint: Listenable.merge([engine, engine.live.scrollVelocity, engine.live.seamProgress]));

  final ReaderEngine engine;
  final List<DialogueBox> boxes;
  final List<DialogueBox> matches;
  final ValueChanged<String> onCopy;
  final bool dim;
  final TextStyle textStyle;

  List<(Rect, DialogueBox)> _laid(Size size) => [
        for (final b in boxes)
          if (boxInViewport(engine, b) case final r? when r.overlaps(Offset.zero & size)) (r, b),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    if (dim) canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x80000000));
    for (final (r, b) in _laid(size)) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
      canvas.drawRRect(rr, Paint()..color = const Color(0xD1131317));
      canvas.drawRRect(rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = const Color(0x38FFFFFF),);
      final tp = TextPainter(text: TextSpan(text: b.text, style: textStyle), textDirection: TextDirection.ltr, maxLines: 6, ellipsis: '…')
        ..layout(maxWidth: math.max(8, r.width - 12));
      tp.paint(canvas, Offset(r.left + 6, r.top + math.max(2, (r.height - tp.height) / 2)));
      tp.dispose();
    }
    for (final m in matches) {
      final r = boxInViewport(engine, m);
      if (r == null) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(6)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = gt.colorIris400,);
    }
  }

  /// The box under [p], for the tap that copies it.
  DialogueBox? hit(Offset p, Size size) {
    for (final (r, b) in _laid(size)) {
      if (r.contains(p)) return b;
    }
    return null;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
        for (final (r, b) in _laid(size))
          CustomPainterSemantics(
            rect: r,
            properties: SemanticsProperties(button: true, label: b.text, hint: 'Copies the text', onTap: () => onCopy(b.text), textDirection: TextDirection.ltr),
          ),
      ];

  @override
  bool shouldRepaint(DialoguePainter old) => old.boxes != boxes || old.matches != matches || old.dim != dim;

  @override
  bool shouldRebuildSemantics(DialoguePainter oldDelegate) => true;
}

/// The overlay's layer: the painter and the tap that copies a box; when the chapter has no text, the notice and Extract text.
class DialogueOverlayLayer extends StatelessWidget {
  const DialogueOverlayLayer({
    super.key,
    required this.engine,
    required this.pages,
    required this.onCopy,
    required this.onClose,
    this.canExtract = false,
    this.onExtract,
    this.extracting,
  });

  final ReaderEngine engine;

  /// The chapter's recognised pages; empty when nothing was extracted.
  final List<PageText> pages;
  final ValueChanged<String> onCopy;
  final VoidCallback onClose;
  final bool canExtract;
  final VoidCallback? onExtract;

  /// `(done, total)` while Extract text runs.
  final (int, int)? extracting;

  @override
  Widget build(BuildContext context) {
    final boxes = dialogueBoxes(pages);
    final painter = DialoguePainter(
      engine: engine,
      boxes: boxes,
      onCopy: onCopy,
      textStyle: roleStyle(context, gt.typeCallout).copyWith(color: gt.colorLabel1),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, c) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final b = painter.hit(d.localPosition, c.biggest);
              if (b != null) onCopy(b.text);
            },
            child: CustomPaint(key: const ValueKey('reader-dialogue-paint'), painter: painter, size: c.biggest),
          ),
        ),
        if (boxes.isEmpty || extracting != null)
          Align(
            alignment: const Alignment(0, 0.6),
            child: _NoticeCapsule(
              text: extracting != null ? 'Extracting text · page ${extracting!.$1} of ${extracting!.$2}' : 'No dialogue has been extracted for this chapter',
              action: extracting == null && canExtract ? GlassButton(label: 'Extract text', onPressed: onExtract, variant: GlassButtonVariant.primary, size: GlassButtonSize.small) : null,
            ),
          ),
      ],
    );
  }
}

class _NoticeCapsule extends StatelessWidget {
  const _NoticeCapsule({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.sizeOf(context).width - 32, 360.0);
    return SkinGlass(
      size: Size(w, action == null ? 56 : 112),
      tier: GlassTierId.t3,
      shape: const GlassShape.superellipse(28),
      layer: GlassLayerKind.overlays,
      debugLabel: 'reader dialogue notice',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassText(text, role: gt.typeFootnote, wght: 600, onGlass: true, textAlign: TextAlign.center, maxLines: 2),
            if (action != null) ...[const SizedBox(height: 10), action!],
          ],
        ),
      ),
    );
  }
}

/// The T1 hit lens (glass 8.14.9): `glassFilm`, radius 6, a 2 px specular rim over the current match; the page layer itself is
/// magnified 1.12x by the engine's `pageLayerTransform`, never by the skin.
class HitLens extends StatelessWidget {
  const HitLens({super.key, required this.rect, this.opacity = 1});
  final Rect rect;

  /// Reduced motion: the 120 ms fade at the new bubble.
  final double opacity;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: rect,
        child: IgnorePointer(
          child: Opacity(
          opacity: opacity,
          child: SkinGlass(
            size: rect.size,
            tier: GlassTierId.t1,
            shape: const GlassShape.superellipse(6),
            layer: GlassLayerKind.overlays,
            debugLabel: 'reader hit lens',
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xCCFFFFFF), width: 2), borderRadius: BorderRadius.circular(6)),
              child: const SizedBox.expand(),
            ),
          ),
          ),
        ),
      );
}

/// The lens rect for a match box: the box with 6 px of air, grown 1.12x about its centre.
Rect hitLensRect(Rect box) {
  final r = box.inflate(6);
  return Rect.fromCenter(center: r.center, width: r.width * 1.12, height: r.height * 1.12);
}

/// "Match 1 of 3" with previous and next (glass 8.14.9); a horizontal swipe on the capsule steps too; x removes the lens.
class MatchCapsule extends StatelessWidget {
  const MatchCapsule({super.key, required this.index, required this.count, required this.onStep, required this.onClose, this.tint});
  final int index, count;
  final ValueChanged<int> onStep;
  final VoidCallback onClose;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final side = math.max(44.0, GlassFrame.hitMin(context));
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.velocity.pixelsPerSecond.dx;
        if (v.abs() > 200) onStep(v < 0 ? 1 : -1);
      },
      child: SkinGlass(
        size: Size(side * 3 + 140, 56),
        tier: GlassTierId.t3,
        tint: tint,
        layer: GlassLayerKind.overlays,
        debugLabel: 'reader match capsule',
        child: Row(
          children: [
            _IconTap(icon: GlassGlyph28.caretUp.regular, label: 'Previous match', onTap: () => onStep(-1), side: side),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Center(child: GlassText('Match ${index + 1} of $count', role: gt.typeFootnote, wght: 600, onGlass: true)),
              ),
            ),
            _IconTap(icon: GlassGlyph28.caretDown.regular, label: 'Next match', onTap: () => onStep(1), side: side),
            _IconTap(icon: GlassGlyph.x.regular, label: 'Close the matches', onTap: onClose, side: side),
          ],
        ),
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.label, required this.onTap, required this.side});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double side;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(width: side, height: side, child: Center(child: Icon(icon, size: 20, color: gt.colorOnGlass))),
        ),
      );
}
