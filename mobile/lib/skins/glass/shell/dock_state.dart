import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `thresholdDockHide` 20 and `thresholdDockShow` 12 (glass 7.15): the dock minimises after 20 px of cumulative downward scroll and
/// restores after 12 px upward, at the top of a list, on a tap or when a tab takes focus. Never while a screen reader is on.
class DockMinimiseLogic {
  DockMinimiseLogic({this.hide = 20, this.show = 12});
  final double hide;
  final double show;
  double _down = 0;
  double _up = 0;
  bool minimised = false;

  /// [delta] is the scroll offset change (positive: the list scrolls down). Returns the new state.
  bool onScroll(double delta, {required bool atTop, bool assistive = false}) {
    if (assistive) {
      _down = _up = 0;
      minimised = false;
      return minimised;
    }
    if (atTop) {
      _down = _up = 0;
      minimised = false;
      return minimised;
    }
    if (delta > 0) {
      _up = 0;
      _down += delta;
      if (!minimised && _down >= hide) minimised = true;
    } else if (delta < 0) {
      _down = 0;
      _up += -delta;
      if (minimised && _up >= show) minimised = false;
    }
    return minimised;
  }

  void restore() {
    _down = _up = 0;
    minimised = false;
  }
}

class DockMinimised extends Notifier<bool> {
  final DockMinimiseLogic _logic = DockMinimiseLogic();

  @override
  bool build() => false;

  void onScroll(double delta, {required bool atTop, required bool assistive}) {
    final m = _logic.onScroll(delta, atTop: atTop, assistive: assistive);
    if (m != state) state = m;
  }

  void restore() {
    _logic.restore();
    if (state) state = false;
  }
}

final glassDockMinimisedProvider = NotifierProvider<DockMinimised, bool>(DockMinimised.new);

/// What a tap on the minimised capsule (or focus on a tab) calls.
final glassDockRestoreProvider = Provider<VoidCallback>((ref) => () => ref.read(glassDockMinimisedProvider.notifier).restore());
