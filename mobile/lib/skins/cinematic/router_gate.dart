/// What the redirect needs to know (cinematic 8.2 outcomes, mirroring the legacy guards).
enum CineAuth { unknown, unauthenticated, authenticated }

class CineGateState {
  const CineGateState({required this.setupCompleted, required this.auth, required this.hasActiveProfile});
  final bool setupCompleted;
  final CineAuth auth;
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
String? cineRedirect(CineGateState s, Uri location) {
  final path = location.path;
  if (!s.setupCompleted) return path == '/setup' ? null : '/setup';
  switch (s.auth) {
    case CineAuth.unknown:
      if (path == kSplashHoldPath) return null;
      return Uri(path: kSplashHoldPath, queryParameters: {'from': location.toString()}).toString();
    case CineAuth.unauthenticated:
      return path == '/login' || path == '/register' ? null : '/login';
    case CineAuth.authenticated:
      if (!s.hasActiveProfile) return _isProfileRoute(path) ? null : '/profiles';
      if (_isAuthRoute(path)) {
        final from = path == kSplashHoldPath ? location.queryParameters['from'] : null;
        if (from != null && from.startsWith('/') && !_isAuthRoute(Uri.parse(from).path)) return from;
        return '/';
      }
      return null;
  }
}
