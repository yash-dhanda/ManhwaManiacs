import 'package:flutter/scheduler.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_math.dart';

/// The typing clock (one grapheme per 50 ms, timestamp based so dropped frames never slow it) for
/// visual layers that are not headlines (the search placeholder).
class TypedTextTicker {
  TypedTextTicker({required this.length, required TickerProvider vsync, required this.onCount}) {
    _ticker = vsync.createTicker(_tick);
  }

  final int length;
  final void Function(int count) onCount;
  late final Ticker _ticker;
  int _last = -1;

  bool get isActive => _ticker.isActive;

  void start() => _ticker.start();

  void _tick(Duration elapsed) {
    final n = typedCount(elapsed.inMilliseconds, length);
    if (n != _last) {
      _last = n;
      onCount(n);
    }
    if (n >= length) _ticker.stop();
  }

  /// Completes instantly and stops the ticker.
  void finish() {
    _ticker.stop();
    if (_last != length) {
      _last = length;
      onCount(length);
    }
  }

  void dispose() => _ticker.dispose();
}
