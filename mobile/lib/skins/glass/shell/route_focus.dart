import 'package:flutter/widgets.dart';

/// Route focus (glass 8.0.8): after a location change (not a query change) focus moves to the new screen's large-title node; after a
/// pop it returns to the element that pushed. Pure, so the "did the location change" rule is a unit test.
bool locationChanged(Uri before, Uri after) => before.path != after.path;

/// Remembers who had focus when a route was pushed.
class GlassFocusMemory {
  final Map<String, FocusNode> _byRoute = {};

  void remember(String routeKey, FocusNode? node) {
    if (node != null) _byRoute[routeKey] = node;
  }

  /// The node to focus after [routeKey]'s child popped, or null.
  FocusNode? recall(String routeKey) {
    final n = _byRoute.remove(routeKey);
    return n != null && n.context != null && n.canRequestFocus ? n : null;
  }
}
