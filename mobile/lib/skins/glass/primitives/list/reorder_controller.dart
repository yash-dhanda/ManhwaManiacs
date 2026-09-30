import 'package:flutter/widgets.dart';

/// Hands a row from the context preview to the reorder list (glass 7.35): a forwarded drag of more than 10 px calls
/// [beginFromPreview] with the finger's global position.
class GlassReorderController {
  GlassReorderHost? _host;

  void attach(GlassReorderHost host) => _host = host;

  void detach(GlassReorderHost host) {
    if (_host == host) _host = null;
  }

  /// Lifts row [index] at the finger. The context menu closes and the lift is drawn in an overlay at the finger.
  void beginFromPreview(int index, Offset globalPosition) => _host?.liftFromPreview(index, globalPosition);

  bool get active => _host?.lifted ?? false;
}

/// What the list state gives its controller.
abstract interface class GlassReorderHost {
  bool get lifted;
  void liftFromPreview(int index, Offset globalPosition);
}
