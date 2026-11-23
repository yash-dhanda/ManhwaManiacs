import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/time/lock_countdown.dart';
import 'package:manhwamaniacs/core/time/locked_until.dart';

/// A chapter that answered `chapter_locked` (HTTP 423): early access, listed
/// for everyone and opened to paying members first.
typedef ChapterLock = ({DateTime? lockedUntil, String message, String? sourceId});

/// The lock an error carries, or null for any other failure. It is its own
/// case on purpose: the chapter exists (not a 404), the session is fine (not a
/// 401) and asking again before [ChapterLock.lockedUntil] cannot help.
ChapterLock? chapterLockOf(Object? error) {
  if (error is! ApiError || !error.isChapterLocked) return null;
  final d = error.details;
  return (lockedUntil: error.lockedUntil, message: error.message, sourceId: d is Map ? d['source_id'] as String? : null);
}

/// What the locked state is showing.
enum ChapterLockPhase {
  /// The instant is ahead: tick it down.
  counting,

  /// It has just passed: one automatic retry is on its way (or in flight).
  opening,

  /// It has passed (or was unknown, or the retry came back locked again): show the server's message and let the reader ask
  /// again themselves.
  expired,
}

/// The behaviour of the early-access state, with no skin in it: counts down to
/// [lockedUntil], retries ONCE after [grace] when the count reaches zero, and
/// settles on [ChapterLockPhase.expired] if the chapter is still shut.
///
/// A skin supplies [builder] and draws the phases in its own type. The retry
/// is only ever triggered by a countdown that ticked down to zero in front of
/// the reader. An instant that was already past when this was built (the
/// retry itself came back locked, the device clock ahead of the server's)
/// goes straight to [ChapterLockPhase.expired] — otherwise two clocks that
/// disagree would ask the source again every few seconds for good.
class ChapterLockedFlow extends ConsumerStatefulWidget {
  const ChapterLockedFlow({
    super.key,
    required this.lockedUntil,
    required this.retry,
    required this.builder,
    this.grace = kLockRetryGrace,
    this.clock,
  });

  final DateTime? lockedUntil;
  final VoidCallback retry;
  final Duration grace;
  final DateTime Function()? clock;
  final Widget Function(BuildContext context, ChapterLockPhase phase, Duration remaining) builder;

  @override
  ConsumerState<ChapterLockedFlow> createState() => _ChapterLockedFlowState();
}

class _ChapterLockedFlowState extends ConsumerState<ChapterLockedFlow> {
  Timer? _grace;
  late ChapterLockPhase _phase;

  DateTime _now() => widget.clock != null ? widget.clock!() : ref.read(clockProvider)();

  bool get _future => isLockedAt(widget.lockedUntil, _now());

  @override
  void initState() {
    super.initState();
    _phase = _future ? ChapterLockPhase.counting : ChapterLockPhase.expired;
  }

  @override
  void didUpdateWidget(ChapterLockedFlow old) {
    super.didUpdateWidget(old);
    if (old.lockedUntil != widget.lockedUntil) {
      // A new answer from the server (the retry came back locked with a later time): a new count.
      _grace?.cancel();
      _phase = _future ? ChapterLockPhase.counting : ChapterLockPhase.expired;
    }
  }

  void _unlocked() {
    if (!mounted || _phase != ChapterLockPhase.counting) return;
    setState(() => _phase = ChapterLockPhase.opening);
    _grace = Timer(widget.grace, () {
      if (!mounted) return;
      widget.retry();
      // The retry either replaces this screen with the chapter or hands back a fresh error; if neither has happened soon the
      // chapter is still shut and the message is the honest answer.
      _grace = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _phase = ChapterLockPhase.expired);
      });
    });
  }

  @override
  void dispose() {
    _grace?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final until = widget.lockedUntil;
    if (_phase == ChapterLockPhase.counting && until != null) {
      return LockCountdown(
        lockedUntil: until,
        clock: widget.clock,
        onUnlocked: _unlocked,
        builder: (context, left) => widget.builder(context, ChapterLockPhase.counting, left),
      );
    }
    return widget.builder(context, _phase, Duration.zero);
  }
}
