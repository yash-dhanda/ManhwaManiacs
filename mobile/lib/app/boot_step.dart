import 'dart:async';

import 'package:manhwamaniacs/core/logging/app_logger.dart';

/// A boot step that may never answer (a stuck platform channel) or may throw (a keychain that is
/// locked until first unlock, a Keystore that fails to decrypt): past [limit], or on any error, it
/// is logged and [fallback] stands in, so launch always reaches the first frame.
Future<T> bootStep<T>(String what, Future<T> step, Duration limit, T Function() fallback) =>
    step.timeout(limit, onTimeout: () {
      appLogger.w('Boot: $what did not answer in ${limit.inSeconds} s; carrying on without it');
      return fallback();
    },).catchError((Object e) {
      appLogger.w('Boot: $what failed ($e); carrying on without it');
      return fallback();
    });
