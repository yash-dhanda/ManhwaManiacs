import 'dart:async';

import 'package:flutter/widgets.dart';

/// How long the reading menu stays up untouched before it hides itself.
const kReaderChromeIdle = Duration(seconds: 5);

/// The reading menu's idle countdown, one per reader (strip, paged, guided, both novel readers).
///
/// It does not care how the menu opened: whatever the open trigger (today a double tap in the menu
/// zone for manga, a tap for novels), the reader's show path calls [arm] and its hide path [hold].
///
/// [arm] starts the countdown again. A finger down anywhere on the reader ([wrap]) stops it and
/// lifting the last finger arms it again, so tapping a control or dragging the chapter slider
/// restarts the [after] time and a drag in progress never runs out. When it runs out the menu hides
/// ([hide]) unless:
/// - VoiceOver/TalkBack or Reduce Motion is on, or [off] says so (a skin's own reduce motion): the
///   menu never hides by itself;
/// - something opened from the menu is still up: a route over the reader (sheet, dialog) or [held]
///   (a skin's in-tree popover, scrub). It waits for that to close, then counts the full time again.
class ReaderChromeIdle {
  ReaderChromeIdle(this._host, {required this.visible, required this.hide, this.after, this.held, this.off});

  final State _host;
  final bool Function() visible;
  final VoidCallback hide;
  final Duration Function()? after;
  final bool Function()? held;
  final bool Function()? off;

  Timer? _timer;
  bool _waiting = false;
  int _down = 0;

  /// (Re)starts the countdown.
  void arm() {
    _timer?.cancel();
    _waiting = false;
    _timer = Timer(after?.call() ?? kReaderChromeIdle, _fire);
  }

  /// Stops the countdown until the next [arm].
  void hold() {
    _timer?.cancel();
    _waiting = false;
  }

  void dispose() => _timer?.cancel();

  void _fire() {
    if (!_host.mounted || !visible()) return;
    final context = _host.context;
    if (MediaQuery.accessibleNavigationOf(context) || MediaQuery.disableAnimationsOf(context) || (off?.call() ?? false)) return;
    if (_down > 0 || ModalRoute.isCurrentOf(context) == false || (held?.call() ?? false)) {
      _waiting = true;
      _timer = Timer(const Duration(milliseconds: 250), _fire);
      return;
    }
    if (_waiting) return arm();
    hide();
  }

  /// Every touch on [child] (the page and the menu over it) counts as interaction.
  Widget wrap(Widget child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _down++;
          hold();
        },
        onPointerUp: (_) => _lift(),
        onPointerCancel: (_) => _lift(),
        child: child,
      );

  void _lift() {
    if (_down > 0) _down--;
    if (_down == 0 && visible()) arm();
  }
}
