import 'package:flutter_riverpod/flutter_riverpod.dart';

/// While true the Glass router's redirect returns null, so Setup, Login and Register can finish their success choreography before the
/// skin-neutral guard moves them. Each screen sets it just before its success call, clears it after it navigates, and resets it on dispose.
final glassRedirectHoldProvider = StateProvider<bool>((ref) => false, name: 'glassRedirectHold');
