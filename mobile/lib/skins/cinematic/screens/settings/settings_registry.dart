import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/admin/providers/members_provider.dart';
import 'package:manhwamaniacs/features/auth/providers/sessions_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/backup_provider.dart';
import 'package:manhwamaniacs/features/settings/utils/settings_search.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/backup_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/members_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/security_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/about_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/admin_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/ambient_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/appearance_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/content_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/diagnostics_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/feedback_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/keyboard_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/listen_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/notifications_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/profile_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/reading_manga_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/reading_novels_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/server_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/storage_section.dart';

/// Where a row exists (a row that is not rendered must not be searchable).
enum RowGate { always, android, admin, novels, tablet }

class SettingsRowSpec {
  const SettingsRowSpec(this.id, this.label, {this.keywords = const [], this.gate = RowGate.always});
  final String id, label;
  final List<String> keywords;
  final RowGate gate;
}

/// One section of Settings (cinematic 8.30.1): a stable slug, its title, its body and the rows the
/// search reaches.
class SettingsSectionDef {
  const SettingsSectionDef(this.slug, this.title, this.body, this.rows, {this.perProfile = false});
  final String slug, title;
  final WidgetBuilder body;
  final List<SettingsRowSpec> rows;

  /// Stores values for the active reading profile, so it shows the no-profile banner without one.
  final bool perProfile;
}

/// The pushed pages: `slug` -> (title, parent section, body).
class SettingsPageDef {
  const SettingsPageDef(this.slug, this.title, this.parent, this.body, {this.adminOnly = false});
  final String slug, title, parent;
  final WidgetBuilder body;
  final bool adminOnly;
}

final List<SettingsPageDef> settingsPages = [
  SettingsPageDef('security', 'Password & security', 'profile', (_) => const SecurityPage()),
  SettingsPageDef('members', 'Members', 'admin', (_) => const MembersPage(), adminOnly: true),
  SettingsPageDef('backup', 'Backup & restore', 'admin', (_) => const BackupPage(), adminOnly: true),
];

/// Pull to reprint on a pushed page: refetches what the page shows.
Future<void> refreshSettingsPage(WidgetRef ref, String slug) async {
  try {
    switch (slug) {
      case 'security':
        ref.invalidate(authSessionsProvider);
        await ref.read(authSessionsProvider.future);
      case 'members':
        ref.invalidate(membersProvider);
        await ref.read(membersProvider.future);
      case 'backup':
        ref.invalidate(backupStatusProvider);
        await ref.read(backupStatusProvider.future);
    }
  } catch (_) {
    // The page shows its own error strip.
  }
}

SettingsPageDef? settingsPageOf(String slug) => settingsPages.where((p) => p.slug == slug).firstOrNull;

/// Every section in app order. `circle` (mobile/22) registers itself when it lands.
final List<SettingsSectionDef> allSettingsSections = [
  SettingsSectionDef('profile', 'Profile & account', (_) => const ProfileSection(), const [
    SettingsRowSpec('switch-profile', 'Switch profile', keywords: ['persona', 'who is reading']),
    SettingsRowSpec('manage-profiles', 'Manage profiles', keywords: ['avatar', 'mood', 'edit profile']),
    SettingsRowSpec('history', 'Reading history', keywords: ['recently read']),
    SettingsRowSpec('status', 'System status', keywords: ['server health'], gate: RowGate.admin),
    SettingsRowSpec('security', 'Password & security', keywords: ['change password', 'sessions', 'devices', 'sign out everywhere']),
    SettingsRowSpec('members', 'Members', keywords: ['accounts', 'users'], gate: RowGate.admin),
    SettingsRowSpec('sign-out', 'Sign out', keywords: ['log out']),
  ]),
  SettingsSectionDef('appearance', 'Appearance', (_) => const AppearanceSection(), const [
    SettingsRowSpec('edition', 'Edition', keywords: ['cinematic', 'glass', 'skin', 'theme', 'restart']),
    SettingsRowSpec('reduce-motion', 'Reduce motion in the app', keywords: ['animation', 'accessibility']),
    SettingsRowSpec('hyperlegible', 'Hyperlegible text', keywords: ['dyslexia', 'atkinson', 'accessibility', 'easier to read']),
    SettingsRowSpec('reading-mode', 'Reading mode', keywords: ['manga', 'novels'], gate: RowGate.novels),
  ], perProfile: true,),
  SettingsSectionDef('reading-manga', 'Reading: manga', (_) => const ReadingMangaSection(), const [
    SettingsRowSpec('layout', 'Layout', keywords: ['strip', 'single', 'double', 'guided']),
    SettingsRowSpec('direction', 'Direction', keywords: ['left to right', 'right to left', 'webtoon']),
    SettingsRowSpec('fit', 'Fit', keywords: ['width', 'height', 'original']),
    SettingsRowSpec('zoom', 'Zoom'),
    SettingsRowSpec('side-margin', 'Side margin'),
    SettingsRowSpec('strip-width', 'Strip width', keywords: ['tablet'], gate: RowGate.tablet),
    SettingsRowSpec('gap', 'Gap between pages'),
    SettingsRowSpec('page-turn', 'Page turn', keywords: ['cut', 'slide', 'fade']),
    SettingsRowSpec('brightness', 'Brightness', keywords: ['dim']),
    SettingsRowSpec('warmth', 'Warmth', keywords: ['night', 'blue light']),
    SettingsRowSpec('colour', 'Colour', keywords: ['sepia', 'grey', 'gray']),
    SettingsRowSpec('ground', 'Ground', keywords: ['black', 'ink', 'slate', 'background']),
    SettingsRowSpec('tap-zones', 'Tap zones', keywords: ['left handed', 'previous', 'next']),
    SettingsRowSpec('strip-taps', 'Strip taps', keywords: ['tap to scroll']),
    SettingsRowSpec('swipe-sideways', 'Swipe sideways to change chapter'),
    SettingsRowSpec('cinema', 'Cinema mode'),
    SettingsRowSpec('auto-next', 'Auto next chapter'),
    SettingsRowSpec('keep-awake', 'Keep screen awake', keywords: ['sleep', 'screen timeout']),
    SettingsRowSpec('lock-controls', 'Lock controls'),
    SettingsRowSpec('volume-keys', 'Volume keys turn pages', gate: RowGate.android),
    SettingsRowSpec('refresh-rate', 'Refresh rate', keywords: ['fps', '120', '90'], gate: RowGate.android),
    SettingsRowSpec('recap', 'Previously on', keywords: ['recap', 'summary']),
    SettingsRowSpec('recap-auto', 'Continue automatically after a recap'),
    SettingsRowSpec('reset-reader', 'Reset reader settings', keywords: ['defaults']),
  ], perProfile: true,),
  SettingsSectionDef('reading-novels', 'Reading: novels', (_) => const ReadingNovelsSection(), const [
    SettingsRowSpec('face', 'Default face', keywords: ['font', 'newsreader', 'literata', 'atkinson', 'archivo']),
    SettingsRowSpec('size', 'Size', keywords: ['font size', 'text size']),
    SettingsRowSpec('line-spacing', 'Line spacing', keywords: ['leading']),
    SettingsRowSpec('measure', 'Measure', keywords: ['column width', 'line length']),
    SettingsRowSpec('n-layout', 'Layout', keywords: ['scroll', 'paged']),
    SettingsRowSpec('n-page-turn', 'Page turn', keywords: ['cut', 'slide', 'fade']),
    SettingsRowSpec('stock', 'Stock', keywords: ['paper', 'sepia', 'dusk', 'moss', 'rosewood', 'nitrate']),
    SettingsRowSpec('bold', 'Bold text'),
    SettingsRowSpec('justify', 'Justify and hyphenate'),
    SettingsRowSpec('n-auto-next', 'Auto next chapter'),
    SettingsRowSpec('n-recap', 'Previously on', keywords: ['recap']),
    SettingsRowSpec('n-recap-auto', 'Continue automatically after a recap'),
  ], perProfile: true,),
  SettingsSectionDef('listen', 'Listen', (_) => const ListenSection(), const [
    SettingsRowSpec('voices', 'Voices', keywords: ['narrator', 'cast', 'text to speech']),
    SettingsRowSpec('speed', 'Default speed', keywords: ['playback', 'rate']),
    SettingsRowSpec('sleep-default', 'Sleep timer', keywords: ['timer', 'bedtime']),
    SettingsRowSpec('shake', 'Shake to extend'),
    SettingsRowSpec('autoplay', 'Auto-play the next chapter'),
    SettingsRowSpec('keep-player', 'Keep the player visible'),
  ], perProfile: true,),
  SettingsSectionDef('ambient', 'Ambient', (_) => const AmbientSection(), const [
    SettingsRowSpec('soundscape', 'Soundscape default', keywords: ['rain', 'cafe', 'ambient', 'loop', 'sound']),
    SettingsRowSpec('soundscape-volume', 'Soundscape volume'),
    SettingsRowSpec('pause-narration', 'Pause the soundscape during narration'),
    SettingsRowSpec('page-tint', 'Page-tinted chrome'),
    SettingsRowSpec('autoscroll-speed', 'Auto-scroll default speed', keywords: ['scroll']),
    SettingsRowSpec('resume-after', 'Resume after I let go'),
    SettingsRowSpec('pace-dialogue', 'Pace by dialogue'),
    SettingsRowSpec('guided-advance', 'Guided view auto-advance', keywords: ['pace by words', 'fixed']),
  ], perProfile: true,),
  SettingsSectionDef('storage', 'Downloads & storage', (_) => const StorageSection(), const [
    SettingsRowSpec('storage-panel', 'Storage', keywords: ['cap', 'retention', 'wi-fi only', 'downloads', 'free up space', 'cache']),
  ]),
  SettingsSectionDef('content', 'Content', (_) => const ContentSection(), const [
    SettingsRowSpec('mature', 'Show mature content (18+)', keywords: ['adult', 'nsfw', 'certificate']),
    SettingsRowSpec('pinned-sources', 'Manage pinned sources', keywords: ['sources']),
  ], perProfile: true,),
  SettingsSectionDef('feedback', 'Feedback', (_) => const FeedbackSection(), const [
    SettingsRowSpec('haptics', 'Haptic feedback', keywords: ['vibration']),
    SettingsRowSpec('feel-it', 'Feel it'),
    SettingsRowSpec('ui-sounds', 'UI sounds', keywords: ['clicks', 'audio']),
    SettingsRowSpec('sound-volume', 'UI sound volume'),
    SettingsRowSpec('play-sample', 'Play a sample'),
  ], perProfile: true,),
  SettingsSectionDef('notifications', 'Notifications', (_) => const NotificationsSection(), const [
    SettingsRowSpec('notify', 'Notify me about new chapters', keywords: ['bell', 'updates']),
    SettingsRowSpec('check-auto', 'Check automatically', keywords: ['schedule'], gate: RowGate.admin),
    SettingsRowSpec('check-startup', 'Check on startup', gate: RowGate.admin),
    SettingsRowSpec('check-interval', 'Check interval', keywords: ['minutes'], gate: RowGate.admin),
    SettingsRowSpec('notify-master', 'Notify about new chapters (instance)', gate: RowGate.admin),
    SettingsRowSpec('cache-ttl', 'Source cache lifetime', keywords: ['minutes'], gate: RowGate.admin),
  ], perProfile: true,),
  SettingsSectionDef('keyboard', 'Keyboard', (_) => const KeyboardSection(), const [
    SettingsRowSpec('single-key', 'Single-key shortcuts', keywords: ['hardware keyboard', 'keys'], gate: RowGate.tablet),
  ]),
  SettingsSectionDef('server', 'Server', (_) => const ServerSection(), const [
    SettingsRowSpec('api-url', 'API base URL', keywords: ['address', 'host', 'connection']),
  ]),
  SettingsSectionDef('admin', 'Admin', (_) => const AdminSection(), const [
    SettingsRowSpec('backup', 'Backup & restore', keywords: ['export', 'import', 'database']),
    SettingsRowSpec('admin-members', 'Members', keywords: ['accounts']),
    SettingsRowSpec('admin-status', 'System status'),
  ]),
  SettingsSectionDef('diagnostics', 'Diagnostics', (_) => const DiagnosticsSection(), const [
    SettingsRowSpec('rendering', 'Rendering', keywords: ['fps', 'jank', 'frames']),
    SettingsRowSpec('high-refresh', 'Use the highest refresh rate everywhere', gate: RowGate.android),
    SettingsRowSpec('grid', 'Show the layout grid'),
    SettingsRowSpec('timings', 'Show motion timings'),
    SettingsRowSpec('edition-debug', 'Edition (debug)'),
  ]),
  SettingsSectionDef('about', 'About', (_) => const AboutSection(), const [
    SettingsRowSpec('app-version', 'App version', keywords: ['build']),
    SettingsRowSpec('server-version', 'Server version'),
    SettingsRowSpec('whats-new', "What's new", keywords: ['changelog', 'release notes']),
    SettingsRowSpec('licenses', 'Licenses', keywords: ['open source']),
  ]),
];

SettingsSectionDef? settingsSectionOf(String slug) => allSettingsSections.where((s) => s.slug == slug).firstOrNull;

/// What decides which sections and rows exist.
class SettingsEnv {
  const SettingsEnv({required this.admin, required this.novels, required this.clientDownloads, required this.tablet, required this.android});
  final bool admin, novels, clientDownloads, tablet, android;

  bool allows(RowGate g) => switch (g) {
        RowGate.always => true,
        RowGate.android => android,
        RowGate.admin => admin,
        RowGate.novels => novels,
        RowGate.tablet => tablet,
      };
}

/// The sections this account and device get, in order.
List<SettingsSectionDef> visibleSettingsSections(SettingsEnv e) => [
      for (final s in allSettingsSections)
        if (switch (s.slug) {
          'reading-novels' || 'listen' => e.novels,
          'storage' => e.clientDownloads,
          'keyboard' => e.tablet,
          'admin' => e.admin,
          _ => true,
        })
          s,
    ];

/// `01`, `02` ... with no gaps over [visible].
String folioOf(List<SettingsSectionDef> visible, String slug) {
  final i = visible.indexWhere((s) => s.slug == slug);
  return (i + 1).toString().padLeft(2, '0');
}

/// The searchable rows of the visible sections.
List<SettingsRowRef> searchRows(SettingsEnv e) => [
      for (final s in visibleSettingsSections(e))
        for (final r in s.rows)
          if (e.allows(r.gate)) SettingsRowRef(id: r.id, section: s.slug, label: r.label, keywords: r.keywords),
    ];

/// The section a slug opens: itself, or a pushed page's parent.
String parentSectionOf(String slug) => settingsPageOf(slug)?.parent ?? slug;

@visibleForTesting
Set<String> get registeredSlugs => {for (final s in allSettingsSections) s.slug, for (final p in settingsPages) p.slug};
