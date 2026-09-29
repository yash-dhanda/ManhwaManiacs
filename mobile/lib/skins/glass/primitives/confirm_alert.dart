import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';

/// The confirm alert (glass 7.11): an explicit Cancel and an explicit confirm, the destructive one solid `danger`.
/// It blooms from [sourceRect], the control that opened it. Resolves true only on the confirm button.
Future<bool> confirmAlert(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
  Rect? sourceRect,
}) async {
  final r = await showGlassAlert<bool>(
    context,
    title: title,
    body: body,
    sourceRect: sourceRect,
    actions: [
      const GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false),
      GlassAlertAction<bool>(confirmLabel, role: destructive ? GlassAlertRole.destructive : GlassAlertRole.normal, value: true),
    ],
  );
  return r ?? false;
}
