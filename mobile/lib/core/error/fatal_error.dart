import 'package:flutter/foundation.dart';

class FatalErrorReport {
  FatalErrorReport(this.error, [this.stack]);
  final Object error;
  final StackTrace? stack;

  /// First 8 hex digits of a hash of the error text, for the `REF` keycap.
  String get ref {
    var h = 0x811c9dc5;
    for (final u in '$error'.codeUnits) {
      h = ((h ^ u) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}

/// Set by the Cinematic root's error hooks; only the Cinematic root listens.
final ValueNotifier<FatalErrorReport?> appFatalError = ValueNotifier<FatalErrorReport?>(null);
