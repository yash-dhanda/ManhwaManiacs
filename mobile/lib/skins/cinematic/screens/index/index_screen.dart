import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_content_mode.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/index_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/index_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/profile_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/update_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Whether the leaders have drawn themselves this app session (a restart resets it).
final indexLeadersDrawnProvider = StateProvider<bool>((ref) => false, name: 'indexLeadersDrawn');

String _gb(int bytes) {
  const gb = 1024 * 1024 * 1024;
  const mb = 1024 * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  return '${(bytes / mb).round()} MB';
}

/// The Index (`/more`, cinematic 8.28): the phone hub set as a magazine index, with folios and
/// dot leaders that draw themselves the first time it opens in a session.
class IndexScreen extends ConsumerStatefulWidget {
  const IndexScreen({super.key});

  @override
  ConsumerState<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends ConsumerState<IndexScreen> {
  final GlobalKey _bannerKey = GlobalKey();
  final FocusNode _bannerButton = FocusNode(debugLabel: 'update-download');
  late final bool _play = !ref.read(indexLeadersDrawnProvider);

  @override
  void initState() {
    super.initState();
    if (_play) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(indexLeadersDrawnProvider.notifier).state = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerButton.dispose();
    super.dispose();
  }

  void _toBanner() {
    final ctx = _bannerKey.currentContext;
    if (ctx == null) return;
    unawaited(Scrollable.ensureVisible(ctx, duration: CineMotionSafe.of(context)).then((_) => _bannerButton.requestFocus()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.user.isAdmin;
    final scope = ref.watch(contentModeScopeProvider);
    final offline = ref.watch(sessionOfflineProvider) || !(ref.watch(deviceOnlineProvider).valueOrNull ?? true);
    final apk = AppUpdateChannel.forPlatform(Theme.of(context).platform) == AppUpdateChannel.apk;
    final AsyncValue<AppVersionInfo?> update = apk ? ref.watch(appUpdateProvider) : const AsyncValue<AppVersionInfo?>.data(null);
    final updateInfo = update.valueOrNull;
    final hasUpdate = apk && (updateInfo?.hasUpdate ?? false);
    final stats = ref.watch(statisticsProvider);
    final asks = ref.watch(suggestAvailabilityProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final collections = ref.watch(collectionsProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final bytes = ref.watch(totalDeviceDownloadBytesProvider);
    final AsyncValue<SourceHealthSummary> health =
        admin ? ref.watch(sourceHealthSummaryProvider) : const AsyncValue<SourceHealthSummary>.loading();
    final changelog = ref.watch(appChangelogProvider);
    final info = ref.watch(packageInfoProvider);
    final jobs = ref.watch(activeNarrationJobsProvider);
    final ocr = ref.watch(ocrFeatureVisibleProvider) && isOcrVisible(scope.mode, novelsEnabled: scope.novelsEnabled);
    final year = DateTime.now().year;
    var n = 0;
    Widget row(String label, {String? value, bool loading = false, VoidCallback? onTap, Widget? leading}) =>
        IndexRow(label: label, value: value, loading: loading, onTap: onTap, leading: leading, index: n++, playLeaders: _play);
    VoidCallback go(String path) => () => context.go(path);
    VoidCallback push(String path) => () => unawaited(context.push<void>(path));

    final streak = stats.valueOrNull?.streak.currentDays ?? 0;
    final you = IndexSection(
      label: 'YOU',
      rows: [
        row(
          'The Numbers',
          value: stats.hasError ? null : (streak > 0 ? '$streak-DAY STREAK' : null),
          loading: stats.isLoading && !stats.hasValue,
          onTap: push(Routes.numbers()),
          // TODO(mobile/08): the StreakFlame widget in its tier and state replaces this icon.
          leading: CineIcon(CineIconRole.flame, color: streak > 0 ? c.colorSpot : c.colorInk45),
        ),
        row('The Annual', value: '$year', onTap: () => unawaited(context.push<void>(Routes.annual(year), extra: const <String, String>{'transition': 'dip'}))),
        row('Circle', onTap: push(Routes.circle())),
        row(
          'Picks',
          value: (asks.valueOrNull?.available ?? false) ? '${asks.value!.remainingToday} ASKS LEFT' : null,
          loading: asks.isLoading && !asks.hasValue,
          onTap: go(Routes.picks()),
        ),
      ],
    );
    final reading = IndexSection(
      label: 'READING',
      rows: [
        row('Updates', value: '$unread', onTap: go(Routes.updates())),
        row(
          'Collections',
          value: collections.hasError ? null : (collections.hasValue ? '${collections.value!.length}' : null),
          loading: collections.isLoading && !collections.hasValue,
          onTap: go(Routes.collections()),
        ),
        row('History', onTap: go(Routes.history())),
        row(
          'Bookmarks',
          value: bookmarks.hasError ? null : (bookmarks.hasValue ? '${bookmarks.value!.bookmarks.length}' : null),
          loading: bookmarks.isLoading && !bookmarks.hasValue,
          onTap: go(Routes.bookmarks()),
        ),
        if (ocr) row('Dialogue search', onTap: go(Routes.dialogue())),
      ],
    );
    final house = IndexSection(
      label: 'THE HOUSE',
      rows: [
        row('Settings', onTap: push(Routes.settings())),
        row(
          'Storage',
          value: bytes.hasError ? null : (bytes.hasValue ? _gb(bytes.value!) : null),
          loading: bytes.isLoading && !bytes.hasValue,
          onTap: go(Routes.downloads({'tab': 'storage'})),
        ),
        if (admin) row('Backup & restore', onTap: push(Routes.settings(SettingsSection.backup))),
        if (admin) row('Members', onTap: push(Routes.settings(SettingsSection.members))),
        if (admin)
          row(
            'System status',
            value: health.hasValue ? '${health.value!.ok}/${health.value!.total} OK' : null,
            loading: health.isLoading,
            onTap: push(Routes.status()),
          ),
      ],
    );
    final about = IndexSection(
      label: 'ABOUT',
      rows: [
        row(
          "What's new",
          value: (changelog.valueOrNull ?? const []).isEmpty ? null : changelog.value!.first.version,
          loading: changelog.isLoading && !changelog.hasValue,
          onTap: () => unawaited(showWhatsNewSheet(context, ref)),
        ),
        if (hasUpdate) row('App update', value: 'AVAILABLE', onTap: _toBanner),
        row(
          'Version',
          value: info.hasValue ? '${info.value!.version} (${info.value!.buildNumber})' : null,
          loading: info.isLoading && !info.hasValue,
          onTap: () => unawaited(showWhatsNewSheet(context, ref)),
        ),
        row('Licenses', onTap: push('/settings/about?licenses=1')),
      ],
    );

    return CineScaffold(
      contentModeChip: true,
      tabletLayout: true,
      firstRunNote: false,
      body: Builder(
        builder: (context) {
          final wide = MediaQuery.sizeOf(context).width;
          final side = wide >= 600 ? c.space8 : c.space4;
          final two = wide >= 900;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, CineScaffoldScope.topExtentOf(context) + c.space6, side, c.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: CineMasthead(kicker: 'THE INDEX', title: 'Index', id: 'index')),
                    if (offline)
                      Padding(padding: EdgeInsets.only(top: c.space1), child: const CineBadge('OFFLINE EDITION', variant: CineBadgeVariant.text)),
                  ],
                ),
                const IndexProfileBlock(),
                SizedBox(height: c.space4),
                const Align(alignment: Alignment.centerLeft, child: CineContentModeToggle()),
                if (hasUpdate)
                  Padding(
                    padding: EdgeInsets.only(top: c.space4),
                    child: KeyedSubtree(key: _bannerKey, child: UpdateBanner(info: updateInfo!, buttonFocus: _bannerButton)),
                  ),
                if (jobs.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: c.space4),
                    child: IndexRow(
                      label: 'Narrating',
                      value: '${jobs.length} ${jobs.length == 1 ? 'BOOK' : 'BOOKS'}',
                      onTap: () => unawaited(context.push<void>(Routes.feature(jobs.first.sourceId, jobs.first.seriesKey, const {'sheet': 'audiobook'}))),
                    ),
                  ),
                if (two)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          key: const Key('index-column-rule'),
                          padding: EdgeInsets.only(right: c.space6),
                          decoration: BoxDecoration(border: Border(right: BorderSide(color: c.colorRule1))),
                          child: Column(children: [you, reading]),
                        ),
                      ),
                      Expanded(child: Padding(padding: EdgeInsets.only(left: c.space6), child: Column(children: [house, about]))),
                    ],
                  )
                else
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [you, reading, house, about]),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Programmatic scrolls jump under reduced motion.
abstract final class CineMotionSafe {
  static Duration of(BuildContext context) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : context.cine.durColumn;
}
