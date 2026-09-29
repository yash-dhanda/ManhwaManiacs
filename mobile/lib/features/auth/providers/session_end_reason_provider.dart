import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why the session or profile ended under the user. The Cinematic Login and picker read it once,
/// show a toast and clear it; legacy ignores it.
enum SessionEndReason { signedOut, profileGone }

final sessionEndReasonProvider =
    StateProvider<SessionEndReason?>((ref) => null, name: 'sessionEndReason');
