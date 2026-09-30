import 'package:manhwamaniacs/features/auth/utils/route_guard.dart';

export 'package:manhwamaniacs/features/auth/utils/route_guard.dart' show kSplashHoldPath;

/// The pure route guard moved to `features/auth/utils/route_guard.dart` (both new skins share it); Cinematic keeps its names.
typedef CineAuth = GateAuth;
typedef CineGateState = GateState;

/// The redirect, or null to stay.
String? cineRedirect(GateState s, Uri location) => gateRedirect(s, location);
