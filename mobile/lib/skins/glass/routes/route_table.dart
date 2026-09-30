import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// Which tab a location belongs to (glass 8.0.3). Pure, so the classification is a unit test.
GlassTab tabOf(String path) {
  final p = _clean(path);
  if (p == '/' || p == '/updates' || p == '/library/recommendations') return GlassTab.home;
  if (p == '/library/statistics' || p.startsWith('/library/statistics/')) return GlassTab.you;
  if (p == '/library' || p.startsWith('/library/') || p == '/downloads' || p.startsWith('/collections')) return GlassTab.library;
  if (p.startsWith('/sources') || p == '/search' || p == '/ocr' || p.startsWith('/ocr/')) return GlassTab.sources;
  if (p == '/more' || p.startsWith('/settings') || p.startsWith('/circle') || p.startsWith('/admin') || p == '/profiles/manage') return GlassTab.you;
  return GlassTab.home;
}

String _clean(String path) {
  final q = path.indexOf(RegExp('[?#]'));
  var p = q < 0 ? path : path.substring(0, q);
  if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
  return p.isEmpty ? '/' : p;
}

final RegExp _feature = RegExp(r'^/sources/[^/]+/series/[^/]+$');
final RegExp _followed = RegExp(r'^/library/\d+$');
final RegExp _recap = RegExp(r'^/recap/[^/]+/[^/]+$');
final RegExp _circleMember = RegExp(r'^/circle/[^/]+$');
final RegExp _profileEdit = RegExp(r'^/profiles/[^/]+/edit$');

/// The sheet routes of glass 8.0.3 (they live on the root navigator, above the shell).
bool isSheetRoute(String path) {
  final p = _clean(path);
  return _feature.hasMatch(p) || _followed.hasMatch(p) || _recap.hasMatch(p) || _circleMember.hasMatch(p) || p == '/profiles/new' || _profileEdit.hasMatch(p);
}

/// Takeovers: no dock, no back swipe (glass 8.0.8).
bool isTakeover(String path) {
  final p = _clean(path);
  return p == '/welcome' || p.startsWith('/library/statistics/annual/') || p == '/setup' || p == '/login' || p == '/register' || p == '/profiles';
}

bool isReader(String path) {
  final p = _clean(path);
  return p.startsWith('/reader/') || p.startsWith('/read-all/') || p.startsWith('/novels/');
}

/// Routes that hide the dock (readers and takeovers).
bool hidesDock(String path) => isReader(path) || isTakeover(path);
