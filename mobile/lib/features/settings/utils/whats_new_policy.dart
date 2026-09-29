import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';

/// Whether the release notes open by themselves: true only when a build was stored and the
/// running one is newer. A first run (nothing stored) stores the current build without opening.
bool shouldAutoOpenWhatsNew({required int currentBuild, required int? lastSeenBuild}) =>
    currentBuild > 0 && lastSeenBuild != null && lastSeenBuild > 0 && currentBuild > lastSeenBuild;

const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

/// `3.5.0 · BUILD 57 · 28 SEP 2026` (parts the server left out are dropped).
String formatReleaseFolio(ChangelogRelease e) {
  final d = DateTime.tryParse(e.date);
  final date = d != null ? '${d.day} ${_months[d.month - 1]} ${d.year}' : e.date.toUpperCase();
  return [
    if (e.version.isNotEmpty) e.version,
    if (e.build > 0) 'BUILD ${e.build}',
    if (date.isNotEmpty) date,
  ].join(' · ');
}
