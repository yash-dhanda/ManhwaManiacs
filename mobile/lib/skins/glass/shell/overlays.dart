import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/utils/whats_new_policy.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/new_chapters_capsule.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/save_to_files_sheet.dart' show registerSaveToFilesSheet;
import 'package:manhwamaniacs/skins/glass/screens/library/library_sheets.dart' show registerLibrarySheets;
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_screen.dart' show SettingsPendingBody;
import 'package:manhwamaniacs/skins/glass/shell/app_update_sheet.dart';
import 'package:manhwamaniacs/skins/glass/shell/shortcuts_sheet.dart';
import 'package:manhwamaniacs/skins/glass/shell/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sheets this step registers for `?sheet=` (glass 8.0.3): `shortcuts`, `whats-new` and `app-update`.
void registerGlassGlobalSheets() {
  registerGlobalSheet('shortcuts', const GlassSheetSpec(title: 'Keyboard shortcuts', builder: _shortcuts));
  registerGlobalSheet('whats-new', const GlassSheetSpec(title: "What's new", builder: _whatsNew));
  // `licenses` renders the pending body until mobile/40 replaces this registration (glass 8.25.14).
  registerGlobalSheet('licenses', const GlassSheetSpec(title: 'Open-source licences', builder: _licencesPending));
  registerGlobalSheet('app-update', const GlassSheetSpec(title: 'Update available', builder: _appUpdate, detents: [GlassDetent.medium], opening: GlassDetent.medium));
  registerLibrarySheets();
  registerSaveToFilesSheet();
}

Widget _licencesPending(BuildContext _) => const SettingsPendingBody();
Widget _shortcuts(BuildContext _) => const GlassShortcutsBody();
Widget _whatsNew(BuildContext _) => const GlassWhatsNewBody();
Widget _appUpdate(BuildContext _) => const GlassAppUpdateBody();

/// The key of the dismissed new-chapters notification id, per profile.
String newChaptersDismissedKey(int? profileId) => 'mm.glass.newchapters.dismissed.p${profileId ?? 0}';

/// Whether the app-update probe re-runs on this resume: at most once every 15 minutes (glass 8.29).
bool shouldRecheckAppUpdate({required DateTime now, required DateTime? last}) => last == null || now.difference(last) >= const Duration(minutes: 15);

/// The global overlays (glass 8.29): the new-chapters capsule, the app-update capsule and the What's-new sheet after an update.
/// Placed once in the shell. [hidden] is true inside readers, on Updates and on takeovers.
class GlassOverlays extends ConsumerStatefulWidget {
  const GlassOverlays({super.key, required this.hideNewChapters, required this.bare, required this.child});
  final bool hideNewChapters;

  /// A reader or takeover: What's new never opens there.
  final bool bare;
  final Widget child;

  @override
  ConsumerState<GlassOverlays> createState() => _GlassOverlaysState();
}

class _GlassOverlaysState extends ConsumerState<GlassOverlays> with WidgetsBindingObserver {
  DateTime? _lastUpdateCheck;
  bool _whatsNewChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastUpdateCheck = DateTime.now();
    registerGlassGlobalSheets();
    final prefs = ref.read(sharedPrefsProvider);
    final pid = ref.read(activeProfileProvider)?.id;
    ref.read(glassNewChaptersDismissedProvider.notifier).state = prefs.getInt(newChaptersDismissedKey(pid)) ?? -1;
    ref.listenManual<int>(glassNewChaptersDismissedProvider, (_, v) => unawaited(_persistDismissed(v)));
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeWhatsNew());
  }

  Future<void> _persistDismissed(int v) async {
    final pid = ref.read(activeProfileProvider)?.id;
    await ref.read(sharedPrefsProvider).setInt(newChaptersDismissedKey(pid), v);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (shouldRecheckAppUpdate(now: now, last: _lastUpdateCheck)) {
      _lastUpdateCheck = now;
      ref.invalidate(appUpdateProvider);
    }
  }

  Future<void> _maybeWhatsNew() async {
    if (_whatsNewChecked || !mounted) return;
    if (widget.bare) {
      // Never in readers or takeovers: try again on the next frame after the route changes.
      return;
    }
    _whatsNewChecked = true;
    final prefs = ref.read(preferencesProvider);
    final info = await ref.read(packageInfoProvider.future);
    final build = int.tryParse(info.buildNumber) ?? 0;
    if (build <= 0) return;
    final last = prefs.lastSeenChangelogBuild;
    final isUpdate = prefs.setupCompleted && shouldAutoOpenWhatsNew(currentBuild: build, lastSeenBuild: last > 0 ? last : null);
    await prefs.setLastSeenChangelogBuild(build);
    if (isUpdate && mounted) {
      final router = ref.read(skinRouterProvider);
      final uri = router.routerDelegate.currentConfiguration.uri;
      router.go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': 'whats-new'}).toString());
    }
  }

  @override
  void didUpdateWidget(GlassOverlays old) {
    super.didUpdateWidget(old);
    if (old.bare && !widget.bare) unawaited(_maybeWhatsNew());
  }

  @override
  Widget build(BuildContext context) {
    // New chapters: hidden inside readers and on /updates; the dismissed id is per profile.
    final banner = ref.watch(newChaptersBannerProvider).valueOrNull;
    final spec = banner == null || widget.hideNewChapters
        ? null
        : GlassNewChaptersSpec(
            id: banner.maxId,
            chapters: banner.chapters,
            series: banner.series,
            onView: () => ref.read(skinRouterProvider).go('/updates'),
          );
    // App update (Android APK channel only; the capsule host hides it elsewhere).
    final update = ref.watch(appUpdateProvider).valueOrNull;
    final updateSpec = update != null && update.hasUpdate
        ? GlassAppUpdateSpec(
            onUpdate: () {
              final router = ref.read(skinRouterProvider);
              final uri = router.routerDelegate.currentConfiguration.uri;
              router.go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': 'app-update'}).toString());
            },
          )
        : null;
    Future.microtask(() {
      if (!mounted) return;
      final n = ref.read(glassNewChaptersProvider.notifier);
      if (n.state?.id != spec?.id || (n.state == null) != (spec == null)) n.state = spec;
      final u = ref.read(glassAppUpdateProvider.notifier);
      if ((u.state == null) != (updateSpec == null)) u.state = updateSpec;
    });
    return widget.child;
  }
}

/// Kept for callers that only need the prefs key.
Future<int?> readDismissedNewChapters(SharedPreferences prefs, int? profileId) async => prefs.getInt(newChaptersDismissedKey(profileId));
