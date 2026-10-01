import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/utils/check_series.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/at_a_glance.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/repoint_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/series_sheets.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:share_plus/share_plus.dart';

/// The overflow menu (D8) as a menu sheet. An override change re-stamps the local rows
/// (`LibrarySeriesActions.setMatureOverride`).
Future<void> showFeatureOverflow(
  BuildContext context,
  WidgetRef ref,
  FeatureData d, {
  required VoidCallback onCover,
  bool sourceIsDown = false,
  bool book = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cineOf(context).colorPaper2,
    builder: (ctx) => Consumer(
      // `sheetRef` only watches: the actions outlive the sheet (they pop it first), so they use the page's [ref].
      builder: (ctx, sheetRef, _) {
        final f = d.followed;
        final online = isOnline(sheetRef);
        final current = f?.matureOverride;
        void toast(String m) => featureToast(context, m);

        Future<void> setOverride({bool? value, bool clear = false}) async {
          Navigator.pop(ctx);
          final err = await ref
              .read(librarySeriesActionsProvider)
              .setMatureOverride(f!, value: value, clear: clear);
          if (err != null) return toast("Couldn't update this series.");
          ref.invalidate(updatesProvider);
          toast(
            clear
                ? "Using the source's rating."
                : value!
                    ? 'Treating ${d.title} as 18+.'
                    : 'Treating ${d.title} as not 18+.',
          );
        }

        Widget item(String label, VoidCallback? onTap, {Color? color, String? disabledHint}) =>
            Tooltip(
              message: onTap == null ? (disabledHint ?? '') : '',
              child: ListTile(
                minVerticalPadding: 14,
                enabled: onTap != null,
                title: Text(label, style: TextStyle(color: color)),
                onTap: onTap,
              ),
            );
        Widget radio(String label, bool selected, VoidCallback? onTap) => Tooltip(
              message: onTap == null ? kNeedsConnection : '',
              child: ListTile(
                minVerticalPadding: 14,
                enabled: onTap != null,
                leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                title: Text(label),
                onTap: onTap,
              ),
            );

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sourceIsDown && f != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: cineOf(context).colorPaper3,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: 'NOTE  ',
                          style: kickerStyle(context, color: cineOf(context).colorSpot),),
                      const TextSpan(
                        text: 'This source is down. Move the series to another source to keep reading.',
                      ),
                    ],),),
                  ),
                if (sourceIsDown && f != null)
                  item('Move to another source…', online
                      ? () {
                          Navigator.pop(ctx);
                          unawaited(showRepointSheet(context, d, sourceIsDown: true));
                        }
                      : null, disabledHint: 'Moving needs a connection.',),
                item('View cover', () {
                  Navigator.pop(ctx);
                  onCover();
                }),
                item('Add to shelf', () {
                  Navigator.pop(ctx);
                  unawaited(showAddToShelfSheet(context, d));
                }),
                if (f != null && !book)
                  ExpansionTile(
                    title: const Text('Set reading status'),
                    children: [
                      for (final (wire, label) in statusOptions)
                        radio(label, f.readingStatus == wire, online
                            ? () async {
                                Navigator.pop(ctx);
                                final r = await ref
                                    .read(libraryRepositoryProvider)
                                    .patchSeries(f.id, readingStatus: wire);
                                if (r.isErr) toast("Couldn't change the reading status.");
                                ref.invalidate(updatesProvider);
                              }
                            : null,),
                    ],
                  ),
                if (f != null)
                  item('Tags…', () {
                    Navigator.pop(ctx);
                    unawaited(showSeriesTagSheet(context, d));
                  }),
                if (f != null) ...[
                  radio('Treat as 18+', current ?? false,
                      online ? () => setOverride(value: true) : null,),
                  radio('Treat as not 18+', current == false,
                      online ? () => setOverride(value: false) : null,),
                  radio("Use the source's rating", current == null,
                      online ? () => setOverride(clear: true) : null,),
                  item('Check for new chapters', online
                      ? () async {
                          Navigator.pop(ctx);
                          toast('Checking ${d.title}.');
                          final r = await checkSeriesForNew(ref, followedId: f.id, sourceId: d.sourceId, seriesKey: d.seriesKey);
                          final n = r.isOk ? r.value : 0;
                          toast(r.isErr ? r.error.userMessage : n > 0 ? 'Found $n new chapter${n == 1 ? '' : 's'}.' : 'No new chapters.');
                        }
                      : null, disabledHint: kNeedsConnection,),
                ],
                item('Find it on another source', () {
                  Navigator.pop(ctx);
                  context.push('${ScreenId.discover.path}?q=${Uri.encodeQueryComponent(d.title)}');
                }),
                if (f != null && !sourceIsDown)
                  item('Move to another source…', online
                      ? () {
                          Navigator.pop(ctx);
                          unawaited(showRepointSheet(context, d, sourceIsDown: false));
                        }
                      : null, disabledHint: 'Moving needs a connection.',),
                item('Share link', () async {
                  Navigator.pop(ctx);
                  final base = ref.read(apiBaseUrlProvider);
                  final url = '$base${Routes.feature(d.sourceId, d.seriesKey)}';
                  try {
                    await SharePlus.instance.share(ShareParams(text: url));
                  } catch (_) {
                    await Clipboard.setData(ClipboardData(text: url));
                    toast('Link copied.');
                  }
                }),
                if (f != null)
                  item(
                    'Unfollow',
                    online
                        ? () async {
                            Navigator.pop(ctx);
                            final actions = ref.read(librarySeriesActionsProvider);
                            final r = await actions.remove(f);
                            if (!context.mounted) return;
                            if (r.error != null) return toast(r.error!.userMessage);
                            featureToast(context, 'Removed ${d.title}.', onUndo: () => unawaited(actions.restore(f, slots: r.slots)));
                          }
                        : null,
                    color: cineOf(context).colorProof,
                    disabledHint: kNeedsConnection,
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
