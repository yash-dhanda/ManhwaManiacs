/// The route guard's decision (cinematic 8.2 outcomes, glass 8.0.3): pure, skin-neutral, shared by both editions' routers.
enum GateAuth { unknown, unauthenticated, authenticated }

class GateState {
  const GateState({required this.setupCompleted, required this.auth, required this.hasActiveProfile});
  final bool setupCompleted;
  final GateAuth auth;
  final bool hasActiveProfile;
}

/// The private hold route: a black ground under the splash while the session is unknown.
const String kSplashHoldPath = '/splash';

bool _isAuthRoute(String path) => path == '/setup' || path == '/login' || path == '/register' || path == kSplashHoldPath;

bool _isProfileRoute(String path) =>
    path == '/profiles' ||
    path == '/profiles/new' ||
    path == '/profiles/create' ||
    RegExp(r'^/profiles/[^/]+/edit$').hasMatch(path) ||
    RegExp(r'^/profiles/edit/[^/]+$').hasMatch(path);

/// The redirect, or null to stay. Pure: `router.dart` wraps it with the one side effect (a
/// remembered profile opens the legacy session gate).
String? gateRedirect(GateState s, Uri location) {
  final path = location.path;
  if (!s.setupCompleted) return path == '/setup' ? null : '/setup';
  switch (s.auth) {
    case GateAuth.unknown:
      if (path == kSplashHoldPath) return null;
      return Uri(path: kSplashHoldPath, queryParameters: {'from': location.toString()}).toString();
    case GateAuth.unauthenticated:
      return path == '/login' || path == '/register' ? null : '/login';
    case GateAuth.authenticated:
      if (!s.hasActiveProfile) return _isProfileRoute(path) ? null : '/profiles';
      if (_isAuthRoute(path)) {
        final from = path == kSplashHoldPath ? location.queryParameters['from'] : null;
        if (from != null && from.startsWith('/') && !_isAuthRoute(Uri.parse(from).path)) return from;
        return '/';
      }
      return null;
  }
}
