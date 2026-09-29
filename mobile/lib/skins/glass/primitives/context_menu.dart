import 'dart:async';

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show DragUpdateDetails, kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_preview.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';

export 'package:manhwamaniacs/skins/glass/primitives/context_preview.dart';

/// The context menu (glass 7.8): `dimContext` (`Color(0x8C000000)` plus a blur of sigma 12, registered as a scrim) behind
/// a raised copy of the pressed object at [sourceRect] (poster 1.12, row 1.02, image 1.0), and a T4 menu blooming from the
/// object's nearest edge. The preview stays interactive: a drag on it is forwarded through [onPreviewDrag] and the menu
/// closes (the poster throw of `mobile/26` continues from it; `mobile/28` uses it for row reorder).
/// Called by `GlassPoster.onContextPreview` at 450 ms; `longpress.open` fires here.
Future<void> showGlassContextMenu(
  BuildContext context, {
  required Rect sourceRect,
  required Widget preview,
  required GlassPreviewKind kind,
  required List<GlassMenuEntry> entries,
  String title = 'Item',
  ValueChanged<DragUpdateDetails>? onPreviewDrag,
  VoidCallback? onClosed,
}) {
  final scale = glassPreviewScale(kind);
  final lifted = Rect.fromCenter(center: sourceRect.center, width: sourceRect.width * scale, height: sourceRect.height * scale);
  final screen = MediaQuery.sizeOf(context);
  final below = lifted.center.dy < screen.height * 0.55;
  // The menu blooms from the edge of the preview that faces the room.
  final edge = below ? Rect.fromLTWH(lifted.left, lifted.bottom, lifted.width, 0) : Rect.fromLTWH(lifted.left, lifted.top, lifted.width, 0);
  final menu = GlassMenuMetrics.sizeFor(context, entries);
  // `menuRectFor` opens below its anchor: for "above", the anchor sits a menu height above the preview's top edge.
  final anchor = below ? edge : Rect.fromLTWH(edge.left, edge.top - menu.height - 16, edge.width, 0);
  return presentGlassMenu(
    context,
    GlassMenuSpec(
      anchor: anchor,
      entries: entries,
      title: title,
      preview: preview,
      previewRect: sourceRect,
      previewScale: scale,
      onPreviewDrag: onPreviewDrag,
      onClosed: onClosed,
    ),
  );
}

/// Opens the context menu of a hover pointer and a hardware keyboard: a secondary click (right-click) on tablet and
/// desktop frames opens the menu at the pointer without the lift; `.` or `Shift+F10` on a focused item opens it
/// anchored to the item.
class GlassContextRegion extends StatelessWidget {
  const GlassContextRegion({super.key, required this.entries, required this.child, this.title = 'Item'});
  final List<GlassMenuEntry> entries;
  final Widget child;
  final String title;

  void _atPointer(BuildContext context, Offset p) => unawaited(showGlassMenu(context, anchor: Rect.fromLTWH(p.dx, p.dy, 0, 0), entries: entries, title: title, atPointer: true));

  void _anchored(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    unawaited(showGlassMenu(context, anchor: box.localToGlobal(Offset.zero) & box.size, entries: entries, title: title));
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.period): () => _anchored(context),
          const SingleActivator(LogicalKeyboardKey.f10, shift: true): () => _anchored(context),
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            if (e.kind == PointerDeviceKind.mouse && e.buttons == kSecondaryMouseButton && GlassFrame.of(context) != GlassFrameKind.phone) {
              _atPointer(context, e.position);
            }
          },
          child: child,
        ),
      );
}
