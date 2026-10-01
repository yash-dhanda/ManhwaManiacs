import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/excluded_series.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/copy/reactions.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart' show GlassChapterReactions, chLabel;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The series Circle row (glass 9.3.6, 8.12): the orbs of Circle members reading this series (32 px, `bloom` rings) and their
/// latest reactions, spoiler-guarded; nothing at all when no one in the Circle reads it (or the Circle is not deployed).
class SeriesCircleRow extends ConsumerWidget {
  const SeriesCircleRow({super.key, required this.sourceId, required this.seriesKey});
  final String sourceId, seriesKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (sourceId: sourceId, seriesKey: seriesKey);
    final data = ref.watch(circleSeriesProvider(key)).valueOrNull;
    if (data == null || data.readers.isEmpty) return const SizedBox.shrink();
    final fin = ref.watch(finishedChaptersProvider(key));
    // Each reader's latest reaction on this series, newest chapter first.
    final latest = <int, (ReactionBy, ChapterReactions)>{};
    for (final c in data.chapters) {
      for (final b in c.by) {
        latest.putIfAbsent(b.profileId, () => (b, c));
      }
    }
    final readers = data.readers.length == 1 ? '1 reader in your Circle' : '${data.readers.length} readers in your Circle';
    return Semantics(
      container: true,
      label: readers,
      child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final r in data.readers.take(5))
          Row(mainAxisSize: MainAxisSize.min, children: [
            CircleOrbButton(member: r.member, size: 32, semanticsLabel: '${r.member.name}, reading this'),
            if (latest[r.member.profileId] case (final b, final c)) ...[
              const SizedBox(width: 4),
              if (!guardedFor(fin, chapterKey: c.chapterKey, isOwn: false, sealed: c.sealed) && b.kind != null)
                Semantics(label: '${r.member.name} reacted ${glassReaction(b.kind!).name}', excludeSemantics: true, child: Icon(glassReaction(b.kind!).fill, size: 18, color: gt.colorBloom))
              else
                GlassText('reacted to ${chLabel(c.chapterNumber)}', role: gt.typeFootnote, color: gt.colorLabel2),
            ],
          ],),
      ],),
    );
  }
}

/// "Hide from my Circle" for a series' ⋯ menu (glass 8.12, 8.13): a checkbox row shown while this profile shares, toggling the
/// series in `excluded_series` (the whole list through `sharingPatch`) with "Hidden from your Circle" / "Shown to your Circle
/// again". Null when the profile does not share (or its sharing has not loaded).
GlassMenuEntry? hideFromCircleEntry(WidgetRef ref, {required String sourceId, required String seriesKey, required String title}) {
  final pid = ref.read(activeProfileProvider)?.id;
  final s = pid == null ? null : ref.read(sharingProvider(pid)).valueOrNull;
  if (pid == null || s == null || !s.activity) return null;
  final hidden = isExcluded(s.excludedSeries, sourceId, seriesKey);
  return GlassMenuEntry(
    label: 'Hide from my Circle',
    checked: hidden,
    onSelected: () async {
      final next = toggleExcluded(s.excludedSeries, ExcludedSeries(sourceId: sourceId, seriesKey: seriesKey, title: title));
      final ok = await ref.read(sharingProvider(pid).notifier).patch(s.copyWith(excludedSeries: next));
      ref.read(glassToastProvider.notifier).show(GlassToastSpec(
            !ok ? "Couldn't change that" : (hidden ? 'Shown to your Circle again' : 'Hidden from your Circle'),
            kind: ok ? GlassToastKind.success : GlassToastKind.error,
          ),);
    },
  );
}

/// The Circle block of the series detail and the book page (glass 8.12, 8.13, 9.3.2, 9.3.6): the reaction control for the latest
/// chapter this profile finished, then [SeriesCircleRow]. [readingOrder] is the series' chapters in reading order (ids are the
/// chapter keys). Nothing when neither has anything to show.
class SeriesCircleBlock extends ConsumerWidget {
  const SeriesCircleBlock({super.key, required this.sourceId, required this.seriesKey, required this.readingOrder, this.mature = false});
  final String sourceId, seriesKey;
  final List<({String key, double? number})> readingOrder;
  final bool mature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kept warm for the page's ⋯ menu: "Recommend to…" reads the members, "Hide from my Circle" this profile's sharing.
    ref.watch(circleMembersProvider);
    if (ref.watch(activeProfileProvider)?.id case final pid?) ref.watch(sharingProvider(pid));
    final fin = ref.watch(finishedChaptersProvider((sourceId: sourceId, seriesKey: seriesKey)));
    final latest = readingOrder.lastWhere((c) => fin.contains(c.key), orElse: () => (key: '', number: null));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (latest.key.isNotEmpty) ...[
        GlassChapterReactions(key: ValueKey('series-reactions-${latest.key}'), sourceId: sourceId, seriesKey: seriesKey, chapterKey: latest.key, chapterNumber: latest.number, mature: mature),
        const SizedBox(height: 8),
      ],
      SeriesCircleRow(sourceId: sourceId, seriesKey: seriesKey),
    ],);
  }
}
