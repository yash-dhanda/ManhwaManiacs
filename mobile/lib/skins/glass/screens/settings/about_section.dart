import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The Android update row's wording (glass 8.25.14). Pure.
String androidUpdateLine({required bool checking, required bool failed, AppVersionInfo? info, String? localVersion}) {
  if (checking) return 'Checking…';
  if (failed || info == null) return 'Server unreachable';
  if (info.hasUpdate) return 'Update available · ${info.localVersion} → ${info.remoteVersion}';
  return 'Up to date · ${info.localVersion}';
}

/// Settings -> About (glass 8.25.14): the app card, updates (APK channel on Android, SideStore on iOS), What's New and the
/// licences row (its sheet is `mobile/40`).
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key, this.platform});
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = platform ?? defaultTargetPlatform;
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final update = ref.watch(appUpdateProvider);
    final router = GoRouter.of(context);
    final version = info == null ? '' : 'Version ${info.version} (${info.buildNumber})';
    return Column(children: [
      SettingsGroup(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GlassText('ManhwaManiacs', role: gt.typeTitle2),
            GlassText('A self-hosted manga, manhwa and web-novel reader', role: gt.typeFootnote, color: gt.colorLabel2),
            const SizedBox(height: 4),
            GlassText(version, role: gt.typeMono, color: gt.colorLabel2),
          ],),
        ),
      ],),
      SettingsGroup(children: [
        if (p == TargetPlatform.iOS) const _SideStoreRow() else _AndroidUpdateRow(update: update, onOpen: () => router.go('/settings/about?sheet=app-update')),
        SettingsRow(id: 'whats-new', title: "What's New", caret: true, onTap: () => router.go('/settings/about?sheet=whats-new')),
        SettingsRow(id: 'licences', title: 'Open-source licences', caret: true, onTap: () => router.go('/settings/about?sheet=licenses')),
        SettingsRow(id: 'reader-reset', title: 'Reset reader settings', caret: true, onTap: () => router.go('/settings/reading-manga?row=reader-reset')),
      ],),
    ],);
  }
}

class _AndroidUpdateRow extends ConsumerWidget {
  const _AndroidUpdateRow({required this.update, required this.onOpen});
  final AsyncValue<AppVersionInfo?> update;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = update.valueOrNull;
    final line = androidUpdateLine(checking: update.isLoading, failed: update.hasError || (!update.isLoading && v == null), info: v);
    final canDownload = v?.hasUpdate ?? false;
    return SettingsRow(
      id: 'app-updates',
      title: 'Updates',
      caption: line,
      loading: update.isLoading,
      trailing: canDownload
          ? GlassButton(label: 'Download update', size: GlassButtonSize.small, onPressed: onOpen)
          : (!update.isLoading && v == null ? GlassButton(label: 'Retry', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: () => ref.invalidate(appUpdateProvider)) : null),
    );
  }
}

class _SideStoreRow extends ConsumerWidget {
  const _SideStoreRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = AppVersionInfo.sourceUrlFor(AppUpdateChannel.sideStore, ref.watch(apiBaseUrlProvider));
    return SettingsAnchor(
      id: 'app-updates',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GlassText('Managed by SideStore', role: gt.typeHeadline),
          const SizedBox(height: 4),
          GlassText('This build is installed through SideStore. It updates when SideStore refreshes this source.', role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 8),
          GlassText(url, role: gt.typeMono, color: gt.colorLabel2),
          const SizedBox(height: 8),
          GlassButton(
            label: 'Copy source URL',
            size: GlassButtonSize.small,
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: url)));
              settingsToast(ref, 'Source URL copied');
            },
          ),
          const SizedBox(height: 8),
          GlassText('SideStore re-signs the app every 7 days. Open SideStore once a week so it keeps launching.', role: gt.typeCaption1, color: gt.colorLabel2),
        ],),
      ),
    );
  }
}
