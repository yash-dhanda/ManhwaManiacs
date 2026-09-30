import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_failures.dart';

/// "Server unreachable": true after [threshold] network or timeout failures within [window], false on the next success.
class RequestFailureTracker {
  RequestFailureTracker({this.threshold = 3, this.window = const Duration(seconds: 10)});
  final int threshold;
  final Duration window;
  final List<DateTime> _failures = [];
  bool unreachable = false;

  bool failure(DateTime now) {
    _failures
      ..removeWhere((t) => now.difference(t) > window)
      ..add(now);
    if (_failures.length >= threshold) unreachable = true;
    return unreachable;
  }

  bool success() {
    _failures.clear();
    unreachable = false;
    return false;
  }
}

class RequestFailures extends Notifier<bool> {
  final RequestFailureTracker _tracker = RequestFailureTracker();

  @override
  bool build() {
    final f = networkFailures.listen((_) => state = _tracker.failure(DateTime.now()));
    final s = networkSuccesses.listen((_) => state = _tracker.success());
    ref.onDispose(() {
      unawaited(f.cancel());
      unawaited(s.cancel());
    });
    return false;
  }
}

final requestFailuresProvider = NotifierProvider<RequestFailures, bool>(RequestFailures.new);
