import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show HttpExceptionWithStatus;

/// How long a cover that failed to load waits before its one automatic reload.
const Duration kCoverAutoRetryDelay = Duration(seconds: 2);

/// One automatic reload for a cover that failed to load: a failure that is not the server's
/// answer about the cover (a dropped socket, a 429 or 502 from the proxy) is usually gone within
/// seconds, so a grid should not keep its broken placeholder until something rebuilds it.
///
/// Owned by a cover widget's `State`, which calls [failed] from its error builder (that runs on
/// every rebuild, so it is idempotent), [reset] when its URL changes and [dispose] in its own
/// dispose. Nothing exists but this object until a load has failed: no timer for a cover that
/// loads, none after the one retry (a retry that fails shows the placeholder for good).
class CoverAutoRetry {
  CoverAutoRetry(this._onRetry, {this.delay = kCoverAutoRetryDelay});

  final VoidCallback _onRetry;
  final Duration delay;
  Timer? _timer;
  Object? _spentFor;

  /// Whether a reload is waiting to fire.
  bool get pending => _timer != null;

  /// A load of the cover identified by [key] (its URL) failed with [error]; arms the one reload
  /// unless this key had its retry already or the server said the cover does not exist (404 or
  /// 410), which no wait fixes.
  void failed(Object key, Object? error) {
    if (_spentFor == key) return;
    if (error is HttpExceptionWithStatus && (error.statusCode == 404 || error.statusCode == 410)) return;
    _spentFor = key;
    _timer = Timer(delay, () {
      _timer = null;
      _onRetry();
    });
  }

  /// The widget shows another cover: drops a waiting reload and forgets the spent retry.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _spentFor = null;
  }

  void dispose() => reset();
}
