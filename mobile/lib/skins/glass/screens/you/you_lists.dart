import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/listen/narrating_chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/security_section.dart' show glassConfirmSignOut;
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_sections.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The Android update row's line and tone (glass 8.24): "Update available · 3.5.1", "Up to date", "Checking…", `warning`
/// "Couldn't check for updates" (+ Retry), or "Server unreachable" when the APK channel's server does not answer. Pure.
({String line, bool warning, bool retry, bool open}) youUpdateLine(AsyncValue<AppVersionInfo?> u) {
  if (u.isLoading) return (line: 'Checking…', warning: false, retry: false, open: false);
  if (u.hasError) return (line: "Couldn't check for updates", warning: true, retry: true, open: false);
  final v = u.valueOrNull;
  if (v == null) return (line: 'Server unreachable', warning: false, retry: true, open: false);
  if (v.hasUpdate) return (line: 'Update available · ${v.remoteVersion}', warning: false, retry: false, open: true);
  return (line: 'Up to date', warning: false, retry: false, open: false);
}

/// A row whose label carries its badge ("Updates, 3 new", glass K).
Widget _row(String title, Glyph glyph, Color tile, VoidCallback onTap, {Widget? trailing, String? spoken, bool caret = true}) => Semantics(
      button: true,
      label: spoken ?? title,
      excludeSemantics: spoken != null,
      onTap: spoken != null ? onTap : null,
      child: GlassListRow(title: title, icon: glyph.regular, iconColor: tile, trailing: trailing, caret: caret, onTap: onTap),
    );

/// The You hub's grouped lists (glass 8.24): Library, Settings, Administration, About, Switch account and Sign out. One
/// `FocusTraversalGroup` per group, so the arrows move through a group's rows.
class YouLists extends ConsumerWidget {
  const YouLists({super.key, this.platform});
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = platform ?? defaultTargetPlatform;
    final r = GoRouter.of(context);
    final admin = glassIsAdmin(ref);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final caps = ref.watch(serverCapabilitiesProvider).valueOrNull ?? const ServerCapabilities();
    final mode = ref.watch(contentModeControllerProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final downloads = ref.watch(activeDownloadCountProvider);
    final narrating = ref.watch(activeNarrationJobsProvider);
    final dialogue = mode == ContentMode.manga && caps.ocr && ref.watch(ocrFeatureVisibleProvider);
    const lib = GlassColors.iris600, admTile = GlassColors.surface3;

    Widget group(String header, List<Widget> rows) => FocusTraversalGroup(child: GlassGroupedList(header: header, children: rows));

    final settings = [
      for (final s in kSettingsSections)
        if ((!s.admin || admin) &&
            (!s.appsOnly || p == TargetPlatform.android || p == TargetPlatform.iOS) &&
            (!s.needsKeyboard || !phone))
          s,
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      group('Library', [
        _row('Updates', YouGlyphs.bellSimple, lib, () => r.go(Routes.updates()), trailing: unread > 0 ? GlassBadge.count(unread) : null, spoken: unread > 0 ? 'Updates, $unread new' : null),
        _row('For you', YouGlyphs.sparkle, lib, () => r.go(Routes.picks())),
        if (dialogue) _row('Dialogue search', YouGlyphs.chatText, lib, () => r.go(Routes.dialogue())),
        if (caps.collections) _row('Collections', YouGlyphs.stack, lib, () => r.go(Routes.collections())),
        _row('History', YouGlyphs.clockCounterClockwise, lib, () => r.go(Routes.history())),
        if (caps.bookmarks) _row('Bookmarks', YouGlyphs.bookmarkSimple, lib, () => r.go(Routes.bookmarks())),
        if (caps.clientDownloads)
          _row(
            'Downloads',
            YouGlyphs.downloadSimple,
            lib,
            () => r.go(Routes.downloads()),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (narrating.isNotEmpty) const GlassNarratingChip(),
              if (narrating.isNotEmpty && downloads > 0) const SizedBox(width: 6),
              if (downloads > 0) GlassBadge.count(downloads),
            ],),
            spoken: [
              'Downloads',
              if (downloads > 0) '$downloads in the queue',
              if (narrating.isNotEmpty) narratingLabel(narrating.first.total),
            ].join(', '),
          ),
      ]),
      group('Settings', [
        for (final s in settings)
          _row(
            s.label,
            s.glyph,
            s.tile,
            () => s.section == SettingsSection.storage ? r.go(Routes.downloads({'tab': 'storage'})) : r.go(Routes.settings(s.section)),
          ),
      ]),
      if (admin)
        group('Administration', [
          _row('System status', YouGlyphs.pulse, admTile, () => r.go(Routes.status())),
          _row('Members', YouGlyphs.usersThree, admTile, () => r.go(Routes.settings(SettingsSection.members))),
        ]),
      group('About', [
        _row("What's New", YouGlyphs.sparkle, admTile, () => r.go(Routes.indexHub({'sheet': 'whats-new'}))),
        _VersionRow(),
        _UpdateRow(platform: p),
        _row('Licences', YouGlyphs.info, admTile, () => r.go(Routes.settings(SettingsSection.about, {'sheet': 'licenses'}))),
      ]),
      FocusTraversalGroup(
        child: GlassGroupedList(children: [
          GlassListRow(
            title: 'Switch account',
            icon: YouGlyphs.userSwitch.regular,
            iconColor: admTile,
            onTap: () => unawaited(() async {
              // The switcher's mechanism (mobile/29): sign out, then Login with the username empty.
              await ref.read(authControllerProvider.notifier).logout();
              r.go(Routes.login());
            }()),
          ),
          _DestructivePlainRow(label: 'Sign out', onTap: () => unawaited(glassConfirmSignOut(context, ref))),
        ],),
      ),
    ],);
  }
}

/// A destructive plain row: the label in `danger`, no tile (glass 8.24 "Sign out").
class _DestructivePlainRow extends StatelessWidget {
  const _DestructivePlainRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: FocusableActionDetector(
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onTap())},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: GlassFrame.hitMin(context) < 52 ? 52 : GlassFrame.hitMin(context)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(alignment: Alignment.centerLeft, child: GlassText(label, role: gt.typeBody, color: gt.colorDanger)),
              ),
            ),
          ),
        ),
      );
}

class _VersionRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).valueOrNull;
    return GlassListRow(title: info == null ? 'ManhwaManiacs' : 'ManhwaManiacs ${info.version} (${info.buildNumber})', icon: YouGlyphs.info.regular, iconColor: GlassColors.surface3);
  }
}

class _UpdateRow extends ConsumerWidget {
  const _UpdateRow({required this.platform});
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = GoRouter.of(context);
    if (platform == TargetPlatform.iOS) {
      return GlassListRow(title: 'Managed by SideStore', icon: YouGlyphs.cloudArrowUp.regular, iconColor: GlassColors.surface3, caret: true, onTap: () => r.go(Routes.settings(SettingsSection.about)));
    }
    final u = youUpdateLine(ref.watch(appUpdateProvider));
    return GlassListRow(
      title: u.line,
      icon: YouGlyphs.cloudArrowUp.regular,
      iconColor: u.warning ? gt.colorWarning : GlassColors.surface3,
      caret: u.open,
      loading: ref.watch(appUpdateProvider).isLoading,
      trailing: u.retry ? GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => ref.invalidate(appUpdateProvider)) : null,
      onTap: u.open ? () => r.go(Routes.indexHub({'sheet': 'app-update'})) : null,
    );
  }
}
