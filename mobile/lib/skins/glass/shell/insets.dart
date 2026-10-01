import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// Scroll insets of Glass content (glass 2.2). Pure so the numbers are unit tests.
@immutable
class GlassInsets {
  const GlassInsets({required this.top, required this.bottom});
  final double top;
  final double bottom;

  static GlassInsets compute({
    required GlassFrameKind frame,
    required EdgeInsets safe,
    required double keyboard,
    required bool accessory,
  }) {
    final phone = frame == GlassFrameKind.phone;
    // Wider frames clear the status bar too (an iPad's 24 px).
    final top = phone ? safe.top + 60 : safe.top + 76;
    double bottom = phone ? safe.bottom + 85 + (accessory ? 56 : 0) : 24;
    if (keyboard > 0) bottom = safe.bottom + 16;
    return GlassInsets(top: top, bottom: bottom);
  }

  /// The plateau of the top `GlassScrollEdge`: safe-top + 52 (+ 104 while a toast shows) on phones, safe-top + 60 on wider frames.
  static double topPlateau({required GlassFrameKind frame, required double safeTop, required bool toast}) =>
      frame == GlassFrameKind.phone ? safeTop + 52 + (toast ? 104 : 0) : safeTop + 60;

  static double bottomPlateau({required GlassFrameKind frame, required double safeBottom, required bool accessory}) =>
      frame == GlassFrameKind.phone ? safeBottom + 85 + (accessory ? 56 : 0) : 24;

  static GlassInsets of(BuildContext context, {bool accessory = false}) => compute(
        frame: GlassFrame.of(context),
        safe: MediaQuery.paddingOf(context),
        keyboard: MediaQuery.viewInsetsOf(context).bottom,
        accessory: accessory,
      );

  /// Reads the accessory state from the providers.
  static GlassInsets watch(BuildContext context, WidgetRef ref) =>
      of(context, accessory: ref.watch(glassAccessoryVisibleProvider));
}
