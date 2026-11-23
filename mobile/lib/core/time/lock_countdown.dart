import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/time/locked_until.dart';

/// The ticking half of an early-access countdown, with no skin in it: one
/// `Timer.periodic` that rebuilds [builder] once a second with the time left,
/// stops at zero and says so exactly once.
///
/// Each skin hands in a [builder] that sets the remaining time in its own
/// type and tokens, so the Updates row, the reader's locked state and the
/// end-of-strip band tick identically however they look. The timer is the
/// widget's own and dies with it; nothing here outlives its screen.
///
/// The clock is [clockProvider] (or [clock], for a widget outside a scope), so
/// a test moves time by moving the clock and pumping, not by waiting.
///
/// An instant already past when this is built shows no negative time: [builder]
/// is called once with [Duration.zero] and [onUnlocked] fires from a post-frame
/// callback (never from `build`, where a parent's `setState` would be illegal).
/// [unlocked], when given, replaces the countdown from then on, which is how a
/// "Read from 370" button comes back with no refetch.
class LockCountdown extends ConsumerStatefulWidget {
  const LockCountdown({
    super.key,
    required this.lockedUntil,
    required this.builder,
    this.unlocked,
    this.onUnlocked,
    this.clock,
    this.mergeSemantics = false,
  });

  final DateTime lockedUntil;

  /// Draws the countdown. [remaining] is never negative.
  final Widget Function(BuildContext context, Duration remaining) builder;

  /// Shown once the instant has passed instead of [builder].
  final WidgetBuilder? unlocked;

  /// Called once, when the countdown reaches zero (or at once, after the first frame, if it already had).
  final VoidCallback? onUnlocked;
  final DateTime Function()? clock;

  /// False (the default) for a status line the countdown replaces entirely ("Opens in 3:27:14"): its words are the whole label.
  /// True when [builder] draws something with semantics of its own (a chapter folio or chip, a button): those are kept, and the
  /// opens-in words are added to them rather than replacing them.
  final bool mergeSemantics;

  /// The words a screen reader gets: "Opens in 3 hours 27 minutes". It moves
  /// by the minute, not the second, so the reader is not interrupted by a
  /// timer.
  static String semanticsLabel(Duration remaining) => 'Opens in ${spokenRemaining(remaining)}';

  @override
  ConsumerState<LockCountdown> createState() => _LockCountdownState();
}

class _LockCountdownState extends ConsumerState<LockCountdown> {
  Timer? _timer;
  var _fired = false;

  DateTime _now() => widget.clock != null ? widget.clock!() : ref.read(clockProvider)();

  Duration get _remaining => lockRemaining(widget.lockedUntil, _now());

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(LockCountdown old) {
    super.didUpdateWidget(old);
    if (old.lockedUntil != widget.lockedUntil) {
      _fired = false;
      _timer?.cancel();
      _timer = null;
      _arm();
    }
  }

  void _arm() {
    if (_remaining == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fire());
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining == Duration.zero) {
        _timer?.cancel();
        _timer = null;
        _fire();
      }
      setState(() {});
    });
  }

  void _fire() {
    if (_fired || !mounted) return;
    _fired = true;
    widget.onUnlocked?.call();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    if (remaining == Duration.zero && widget.unlocked != null) return widget.unlocked!(context);
    final label = LockCountdown.semanticsLabel(remaining);
    if (widget.mergeSemantics) {
      return MergeSemantics(child: Semantics(label: label, child: widget.builder(context, remaining)));
    }
    return Semantics(label: label, excludeSemantics: true, child: widget.builder(context, remaining));
  }
}
