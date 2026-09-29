import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/repoint_sheet.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The overflow menu (D8): cover, the `mature_override` radio group, share,
/// move, unfollow. TODO(mobile/07): MatureStamper re-stamp after a change.
Future<void> showFeatureOverflow(BuildContext context, WidgetRef ref, FeatureData d,
    {required VoidCallback onCover,}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: cineOf(context).colorPaper2,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final f = d.followed;
        final current = f?.matureOverride;
        void toast(String m) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
        Future<void> setOverride({bool? value, bool clear = false}) async {
          Navigator.pop(ctx);
          final r = await ref.read(libraryRepositoryProvider).patchSeries(
                f!.id,
                matureOverride: value,
                clearMatureOverride: clear,
              );
          if (r.isErr) return toast("Couldn't update this series.");
          ref.invalidate(updatesProvider);
          toast(
            clear
                ? "Using the source's rating."
                : value!
                    ? 'Treating ${d.title} as 18+.'
                    : 'Treating ${d.title} as not 18+.',
          );
        }

        Widget item(String label, VoidCallback onTap, {Color? color}) => ListTile(
              minVerticalPadding: 12,
              title: Text(label, style: TextStyle(color: color)),
              onTap: onTap,
            );
        Widget radio(String label, bool selected, VoidCallback onTap) => ListTile(
              minVerticalPadding: 12,
              leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
              title: Text(label),
              onTap: onTap,
            );
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                item('View cover', () {
                  Navigator.pop(ctx);
                  onCover();
                }),
                if (f != null) ...[
                  radio('Treat as 18+', current ?? false, () => setOverride(value: true)),
                  radio('Treat as not 18+', current == false, () => setOverride(value: false)),
                  radio("Use the source's rating", current == null, () => setOverride(clear: true)),
                ],
                item('Find it on another source', () {
                  Navigator.pop(ctx);
                  context.push('${ScreenId.discover.path}?q=${Uri.encodeQueryComponent(d.title)}');
                }),
                if (f != null)
                  item('Move to another source…', () {
                    Navigator.pop(ctx);
                    showRepointSheet(context, d, sourceIsDown: false);
                  }),
                item('Share link', () async {
                  Navigator.pop(ctx);
                  final base = ref.read(apiBaseUrlProvider);
                  await Clipboard.setData(
                      ClipboardData(text: '$base${Routes.feature(d.sourceId, d.seriesKey)}'),);
                  toast('Link copied.');
                }),
                if (f != null)
                  item(
                    'Unfollow',
                    () async {
                      Navigator.pop(ctx);
                      await ref.read(updatesProvider.notifier).unfollow(f.id);
                      toast('Removed ${d.title}.');
                    },
                    color: cineOf(context).colorProof,
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
