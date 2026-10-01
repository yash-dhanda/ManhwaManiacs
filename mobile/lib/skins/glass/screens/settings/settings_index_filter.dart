import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/core/utils/text_fold.dart';
import 'package:manhwamaniacs/skins/glass/copy/settings_index.dart';

/// Every-word, case- and diacritic-insensitive match over the label and keywords, minus what is hidden on this platform, for this
/// role, by the server, by the gate or by the flag (glass 8.25).
List<SettingsIndexEntry> filterSettingsIndex(
  String query, {
  required TargetPlatform platform,
  required bool admin,
  Set<String> offeredSections = const {},
  bool matureGateOpen = false,
  bool glassAvailable = false,
}) {
  String norm(String s) => foldDiacritics(s).toLowerCase();
  final words = norm(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  bool visible(SettingsIndexEntry e) {
    switch (e.platforms) {
      case SettingsPlatforms.web:
        return false;
      case SettingsPlatforms.android:
        if (platform != TargetPlatform.android) return false;
      case SettingsPlatforms.apps:
        if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) return false;
      case SettingsPlatforms.all:
        break;
    }
    if (e.admin && !admin) return false;
    if (offeredSections.isNotEmpty && !offeredSections.contains(e.section)) return false;
    if (e.id == 'include-mature-activity' && !matureGateOpen) return false;
    if (e.id == 'app-icon-follows-skin' && !glassAvailable) return false;
    return true;
  }

  return [
    for (final e in kSettingsIndex)
      if (visible(e) && _matches(norm('${e.label} ${e.keywords.join(' ')}'), words)) e,
  ];
}

bool _matches(String hay, List<String> words) => words.every(hay.contains);

/// The entries grouped by section, in index order.
Map<String, List<SettingsIndexEntry>> groupBySection(Iterable<SettingsIndexEntry> entries) {
  final out = <String, List<SettingsIndexEntry>>{};
  for (final e in entries) {
    (out[e.section] ??= []).add(e);
  }
  return out;
}

/// The name a search result shows for [slug].
String settingsSectionTitle(String slug) => switch (slug) {
      'appearance' => 'Appearance and skin',
      'reading-manga' => 'Reader',
      'reading-novels' => 'Reader · Novels',
      'listen' => 'Reader · Listen',
      'ambient' => 'Reader · Ambient',
      'content' => 'Content (18+)',
      'feedback' => 'Sound and haptics',
      'circle' => 'Circle and privacy',
      'ai' => 'AI and recaps',
      'notifications' => 'Notifications',
      'security' => 'Security',
      'members' => 'Members',
      'storage' => 'Storage',
      'backup' => 'Backup',
      'server' => 'Server',
      'diagnostics' => 'Diagnostics',
      'keyboard' => 'Shortcuts',
      'profile' => 'Account',
      'about' => 'About',
      _ => slug,
    };

/// Where a search hit opens: its section's route (the Reader groups live on one page, so they keep their own slugs).
String settingsLocationFor(SettingsIndexEntry e) {
  if (e.id == 'licences') return '/settings/about?sheet=licenses';
  return '/settings/${e.section}?row=${e.id}';
}
