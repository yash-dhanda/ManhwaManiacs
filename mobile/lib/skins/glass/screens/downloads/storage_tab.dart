import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_concurrency.dart';
import 'package:manhwamaniacs/features/downloads/models/retention_policy.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/format_bytes.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/services/metadata_cache.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/radio_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/storage_meter_capsule.dart';

const String kEveryone = 'For everyone on this device';

/// The Storage tab (glass 8.22): the usage line, the cap, Chapters at once, Delete after reading, the three switches, the platform
/// note, by-series rows, Free up space and the two cache cards. Device-wide rows say "For everyone on this device".
class GlassStorageTab extends ConsumerWidget {
  const GlassStorageTab({super.key, this.platform});
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cap = ref.watch(storageCapProvider);
    final conc = ref.watch(downloadConcurrencyProvider);
    final ret = ref.watch(retentionIntervalProvider);
    final breakdown = ref.watch(seriesStorageBreakdownProvider).valueOrNull ?? const [];
    final ios = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;

    Widget title(String s, {bool device = false}) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, headingLevel: 2, child: GlassLabel(s, role: gt.typeHeadline)),
            if (device) GlassLabel(kEveryone, role: gt.typeFootnote, color: gt.colorLabel3),
          ],),
        );
    // The choice group draws the sliding selection capsule behind its chips (glass 7.5).
    // A group wider than the page scrolls to the screen edge under the row's trailing fade ("Unlimited" never cut at the gutter).
    // The options as choice chips while they all fit the column; when they don't (large text, a narrow phone) a radio list,
    // so every option ("Unlimited") stays in sight instead of scrolling off under a fade.
    Widget chips<T>(List<(T, String)> items, T selected, void Function(T) onPick) => LayoutBuilder(builder: (context, c) {
          final need = items.fold<double>(0, (w, i) => w + GlassChip.widthOf(context, label: i.$2, kind: GlassChipKind.choice, selected: i.$1 == selected) + 8) - 8;
          if (!c.hasBoundedWidth || need <= c.maxWidth) {
            return Align(
              alignment: Alignment.centerLeft,
              child: GlassChoiceChips<T>(
                options: [for (final i in items) i.$1],
                selected: selected,
                onSelected: onPick,
                labelOf: (v) => items.firstWhere((i) => i.$1 == v).$2,
              ),
            );
          }
          return GlassRadioList<T>(options: [for (final i in items) GlassRadioOption(value: i.$1, label: i.$2)], value: selected, onChanged: onPick);
        },);
    // 8 px above and below each switch row and 16 px before the switch, so rows never butt and text never runs into the track.
    Widget toggle(String label, String? hint, bool v, ValueChanged<bool> on) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GlassLabel(label, role: gt.typeBody, maxLines: 4),
                  if (hint != null) Padding(padding: const EdgeInsets.only(top: 2), child: GlassLabel(hint, role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 5)),
                ],),
              ),
              const SizedBox(width: 16),
              GlassSwitch(label: label, value: v, onChanged: on),
            ],),
          ),
        );

    // A readable column on wider frames: switches stay near their labels.
    return Align(alignment: Alignment.topLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const GlassDownloadsMeter(),
      title('Storage limit', device: true),
      chips<StorageCap>([for (final o in StorageCap.values) (o, o.label)], cap, (v) => unawaited(ref.read(storageCapProvider.notifier).setCap(v))),
      title('Chapters at once', device: true),
      chips<DownloadConcurrency>([for (final o in DownloadConcurrency.values) (o, '${o.chapters}')], conc, (v) => unawaited(ref.read(downloadConcurrencyProvider.notifier).setConcurrency(v))),
      title('Delete after reading'),
      chips<RetentionInterval>(const [(RetentionInterval.off, 'Off'), (RetentionInterval.hours24, '24 h'), (RetentionInterval.hours48, '48 h'), (RetentionInterval.days7, '7 days')], ret, (v) => unawaited(ref.read(retentionIntervalProvider.notifier).setInterval(v))),
      const SizedBox(height: 12),
      toggle('Download on Wi-Fi only', 'Automatic downloads wait for Wi-Fi. Chapters you pick yourself always download.', ref.watch(wifiOnlyDownloadsProvider), (v) => ref.read(wifiOnlyDownloadsProvider.notifier).setEnabled(v)),
      toggle('Save the next chapter while I read', null, ref.watch(saveNextProvider), (v) => ref.read(saveNextProvider.notifier).set(v)),
      toggle('Download new chapters of followed series automatically', null, ref.watch(autoNewProvider), (v) => ref.read(autoNewProvider.notifier).set(v)),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GlassLabel(ios ? 'Browse, copy or delete downloads in the Files app: On My iPhone → ManhwaManiacs' : 'Downloads live in the app’s private storage', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 3),
      ),
      title('By series'),
      if (breakdown.isEmpty)
        GlassLabel('Nothing saved yet', role: gt.typeFootnote, color: gt.colorLabel3)
      else
        for (final s in breakdown)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(children: [
              if (s.anyPinned) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(GlassGlyph.pushPin.fill, size: 14, color: gt.colorLabel2)),
              Expanded(child: GlassLabel(s.seriesTitle ?? s.seriesKey, role: gt.typeBody)),
              GlassLabel('${s.chapterCount} ch · ${formatDownloadBytes(s.bytes)}', role: gt.typeMono, color: gt.colorLabel2),
            ],),
          ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: GlassButton(label: 'Free up space', onPressed: () async {
          final n = await ref.read(downloadsStorageActionsProvider).freeUpSpace();
          if (context.mounted) showGlassToast(ref, GlassToastSpec(n > 0 ? 'Removed $n ${n == 1 ? 'chapter' : 'chapters'}' : 'Nothing to free up right now'));
        },),
      ),
      title('Image cache', device: true),
      const _ImageCache(),
      title('Metadata cache', device: true),
      GlassLabel('Series details and lists kept on this phone. Clearing it refetches them.', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 3),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerLeft, child: GlassButton(label: 'Clear metadata cache', variant: GlassButtonVariant.plain, hang: true, onPressed: () {
        clearMetadataCacheFromWidget(ref);
        showGlassToast(ref, const GlassToastSpec('Metadata cache cleared'));
      },),),
      const SizedBox(height: 24),
    ],),),);
  }
}

class _ImageCache extends ConsumerWidget {
  const _ImageCache();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(cacheUsageProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      usage.when(
        loading: () => GlassLabel('Measuring…', role: gt.typeFootnote, color: gt.colorLabel3),
        error: (_, __) => GlassLabel("Couldn't read the cache size", role: gt.typeFootnote, color: gt.colorDanger),
        data: (b) => GlassLabel(formatDownloadBytes(b), role: gt.typeBody),
      ),
      const SizedBox(height: 8),
      GlassButton(label: 'Clear image cache', variant: GlassButtonVariant.plain, hang: true, onPressed: () async {
        await ref.read(settingsActionsProvider).clearImageCache();
        if (context.mounted) showGlassToast(ref, const GlassToastSpec('Image cache cleared'));
      },),
    ],);
  }
}
