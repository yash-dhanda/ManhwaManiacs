import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_concurrency.dart';
import 'package:manhwamaniacs/features/downloads/models/retention_policy.dart';
import 'package:manhwamaniacs/features/downloads/models/series_storage_usage.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/services/metadata_cache.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/save_to_files_sheet.dart' show openFilesFromDocuments;
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/storage_meter.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The STORAGE tab's body; Settings → Downloads & storage (mobile/18) mounts the same widget.
class StoragePanel extends ConsumerWidget {
  const StoragePanel({super.key, this.platform});

  /// Test hook: the platform the note is written for.
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final cap = ref.watch(storageCapProvider);
    final concurrency = ref.watch(downloadConcurrencyProvider);
    final retention = ref.watch(retentionIntervalProvider);
    final toasts = ref.read(cineToastsProvider.notifier);
    final ios = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;

    Widget kicker(String s) => Padding(
          padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
          child: CineRoleText(s, c.typeKicker, color: c.colorInk60),
        );
    Widget caption(String s) => Padding(
          padding: EdgeInsets.only(top: c.space2),
          child: CineRoleText(s, c.typeCaption, color: c.colorInk60),
        );

    final breakdown = ref.watch(seriesStorageBreakdownProvider).valueOrNull ?? const <SeriesStorageUsage>[];

    return Column(
      key: const Key('storage-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DownloadsStorageMeter(),
        kicker('STORAGE CAP'),
        CineSlugLines(
          items: [for (final o in StorageCap.values) CineSlug(o.name, o.label.toUpperCase())],
          selected: {cap.name},
          onChanged: (id) => unawaited(ref.read(storageCapProvider.notifier).setCap(StorageCap.fromWire(id))),
        ),
        kicker('CHAPTERS AT ONCE'),
        CineSlugLines(
          items: [for (final o in DownloadConcurrency.values) CineSlug(o.name, '${o.chapters}')],
          selected: {concurrency.name},
          onChanged: (id) => unawaited(ref.read(downloadConcurrencyProvider.notifier).setConcurrency(DownloadConcurrency.fromWire(id))),
        ),
        caption('How many chapters download side by side. More is faster on good connections.'),
        kicker('DELETE AFTER READING'),
        CineSlugLines(
          items: const [
            CineSlug('off', 'OFF'),
            CineSlug('hours24', '24 H'),
            CineSlug('hours48', '48 H'),
            CineSlug('days7', '7 D'),
          ],
          selected: {retention.name},
          onChanged: (id) => unawaited(ref.read(retentionIntervalProvider.notifier).setInterval(RetentionInterval.fromWire(id))),
        ),
        caption("Finished chapters older than this are removed; pinned series and the chapter you're reading never are."),
        SizedBox(height: c.space4),
        CineSettingsRow(
          label: 'Download on Wi-Fi only',
          onTap: () => ref.read(wifiOnlyDownloadsProvider.notifier).setEnabled(!ref.read(wifiOnlyDownloadsProvider)),
          description: 'Automatic downloads wait for Wi-Fi. Chapters you pick yourself always download.',
          control: CineSwitch(
            value: ref.watch(wifiOnlyDownloadsProvider),
            onChanged: (v) => ref.read(wifiOnlyDownloadsProvider.notifier).setEnabled(v),
            label: 'Download on Wi-Fi only',
          ),
        ),
        CineSettingsRow(
          label: 'Save the next chapter while I read',
          onTap: () => ref.read(saveNextProvider.notifier).set(!ref.read(saveNextProvider)),
          description: "The chapter after the one you're reading is saved in the background.",
          control: CineSwitch(
            value: ref.watch(saveNextProvider),
            onChanged: (v) => ref.read(saveNextProvider.notifier).set(v),
            label: 'Save the next chapter while I read',
          ),
        ),
        CineSettingsRow(
          label: 'Download new chapters of followed series automatically',
          onTap: () => ref.read(autoNewProvider.notifier).set(!ref.read(autoNewProvider)),
          description: 'When you open the app, new chapters from series with notifications on are saved, up to 20 at a time.',
          control: CineSwitch(
            value: ref.watch(autoNewProvider),
            onChanged: (v) => ref.read(autoNewProvider.notifier).set(v),
            label: 'Download new chapters of followed series automatically',
          ),
        ),
        kicker('BY SERIES'),
        if (breakdown.isEmpty)
          CineRoleText('Nothing saved yet.', c.typeCaption, color: c.colorInk60)
        else
          for (final s in breakdown) _SeriesRow(usage: s),
        SizedBox(height: c.space4),
        Align(
          alignment: Alignment.centerLeft,
          child: CineButton(
            label: 'Free up space',
            variant: CineButtonVariant.secondary,
            onPressed: () async {
              final n = await ref.read(downloadsStorageActionsProvider).freeUpSpace();
              toasts.info(n > 0 ? 'Removed $n ${n == 1 ? 'chapter' : 'chapters'}.' : 'Nothing to free up right now.');
            },
          ),
        ),
        kicker('IMAGE CACHE'),
        const _ImageCache(),
        kicker('METADATA CACHE'),
        CineRoleText('Series details and lists kept in memory. Clearing it refetches them.', c.typeCaption, color: c.colorInk60),
        SizedBox(height: c.space2),
        Align(
          alignment: Alignment.centerLeft,
          child: CineButton(
            label: 'Clear metadata cache',
            variant: CineButtonVariant.quiet,
            onPressed: () {
              clearMetadataCacheFromWidget(ref);
              toasts.info('Metadata cache cleared.');
            },
          ),
        ),
        SizedBox(height: c.space6),
        if (ios) ...[
          CineRoleText(
            'Browse, copy or delete saved chapters in the Files app: On My iPhone › ManhwaManiacs.',
            c.typeCaption,
            color: c.colorInk60,
          ),
          SizedBox(height: c.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: CineButton(label: 'Open Files', variant: CineButtonVariant.secondary, onPressed: () => unawaited(openFilesFromDocuments())),
          ),
        ] else
          CineRoleText("Files live in the app's private storage.", c.typeCaption, color: c.colorInk60),
        SizedBox(height: c.space12),
      ],
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.usage});
  final SeriesStorageUsage usage;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final title = usage.seriesTitle ?? usage.seriesKey;
    final value = '${usage.chapterCount} CH · ${formatMb(usage.bytes)}';
    return Semantics(
      container: true,
      label: '${usage.anyPinned ? 'Pinned, ' : ''}$title, ${folioLabel(value)}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (usage.anyPinned)
              Padding(
                padding: EdgeInsets.only(right: c.space1, bottom: 2),
                child: CineIcon(CineIconRole.pin, size: 16, weight: CineIconWeight.fill, color: c.colorInk100),
              ),
            Expanded(
              child: CineLeaderRow(
                label: CineRoleText(title, c.typeUi, color: c.colorInk80, maxLines: 1, overflow: TextOverflow.ellipsis),
                value: CineRoleText(value, c.typeFolio, color: c.colorInk60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCache extends ConsumerWidget {
  const _ImageCache();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final usage = ref.watch(cacheUsageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        usage.when(
          loading: () => Container(key: const Key('cache-greek'), width: 96, height: 20, color: c.colorPaper3),
          error: (_, __) => CineRoleText("Couldn't read the cache size.", c.typeCaption, color: c.colorProof),
          data: (b) => CineRoleText(formatMb(b), c.typeFolioLg, color: c.colorInk80),
        ),
        SizedBox(height: c.space2),
        CineButton(
          label: 'Clear image cache',
          variant: CineButtonVariant.quiet,
          onPressed: () async {
            await ref.read(settingsActionsProvider).clearImageCache();
            ref.read(cineToastsProvider.notifier).info('Image cache cleared.');
          },
        ),
      ],
    );
  }
}
