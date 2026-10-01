import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroine/heroine.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/collapse_feed.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/skins/glass/copy/reactions.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/activity_list.dart' show ActivitySkeletonRow;
import 'package:manhwamaniacs/skins/glass/screens/circle/activity_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/shelves_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassHost;
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart' show glassZoomMotion;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A friend's name before their page loads (or after it 404s), from the members list.
String friendName(WidgetRef ref, int id) =>
    (ref.watch(circleMembersProvider).valueOrNull ?? const <CircleMember>[]).where((m) => m.profileId == id).map((m) => m.name).firstOrNull ?? 'This reader';

/// The friend's content (glass 9.3.5) as slivers: the header (orb 112 with the bloom ring, the orb flight's target), Reading
/// (posters only, never progress), Shelves, Recent (their feed, infinite) and Their reactions (spoiler-guarded), and "Recommend
/// something to {name}". States: not sharing any more (404), loading, offline, error.
List<Widget> friendSlivers(BuildContext context, WidgetRef ref, int profileId) {
  final page = ref.watch(circleMemberProvider(profileId));
  final m = GlassFrame.screenMargin(context);
  Widget box(Widget w) => SliverToBoxAdapter(child: w);
  final err = page.error;
  if (err is ApiError && (err.code == 'circle_member_not_sharing' || err.statusCode == 404)) {
    final name = friendName(ref, profileId);
    final member = (ref.watch(circleMembersProvider).valueOrNull ?? const <CircleMember>[]).where((x) => x.profileId == profileId).firstOrNull;
    return [
      box(Padding(
        padding: EdgeInsets.fromLTRB(m, 24, m, 24),
        child: Column(children: [
          Opacity(opacity: 0.4, child: _HeaderOrb(profileId: profileId, avatarKey: member?.avatarKey, name: name)),
          const SizedBox(height: 16),
          GlassText("$name isn't sharing right now.", role: gt.typeHeadline, textAlign: TextAlign.center),
        ],),
      ),),
    ];
  }
  if (page.hasError && !page.hasValue) {
    if (ref.watch(glassOfflineProvider) || err is NetworkError) {
      return [box(CircleOffline(title: 'This page needs a connection', onRetry: () async {
        ref.invalidate(circleMemberProvider(profileId));
        return true;
      },),),];
    }
    return [box(CircleError(title: "Couldn't load this page", onRetry: () => ref.invalidate(circleMemberProvider(profileId))))];
  }
  if (!page.hasValue) {
    return [
      box(GlassSkeletonGroup(
        child: Padding(
          padding: EdgeInsets.fromLTRB(m, 16, m, 16),
          child: Column(children: [
            const GlassSkeleton(width: 112, height: 112, circle: true),
            const SizedBox(height: 12),
            const GlassSkeleton(width: 160, height: 22, radius: 6),
            const SizedBox(height: 24),
            for (var i = 0; i < 2; i++) Padding(padding: const EdgeInsets.only(bottom: 16), child: GlassSkeleton(height: 140, radius: 20, index: i)),
          ],),
        ),
      ),),
    ];
  }
  final p = page.value!;
  final name = p.profile.name;
  final feed = ref.watch(memberFeedProvider(profileId));
  final host = GlassHost.of(context);
  final sub = host ? gt.colorOnGlass : gt.colorLabel2;
  Widget title(String t) => Padding(padding: EdgeInsets.fromLTRB(m, 24, m, 12), child: Semantics(header: true, child: GlassText(t, role: gt.typeTitle3)));
  final out = <Widget>[
    box(Padding(
      padding: EdgeInsets.fromLTRB(m, 8, m, 0),
      child: Column(children: [
        _HeaderOrb(profileId: profileId, avatarKey: p.profile.avatarKey, name: name),
        const SizedBox(height: 12),
        GlassText(name, role: gt.typeTitle2, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (p.profile.username != null) GlassText('$name · @${p.profile.username}', role: gt.typeFootnote, color: sub, onGlass: host, textAlign: TextAlign.center),
        if (p.now != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(children: [const TextSpan(text: 'Reading now: '), TextSpan(text: p.now!.title, style: const TextStyle(fontStyle: FontStyle.italic))]),
              textAlign: TextAlign.center,
              style: roleStyle(context, gt.typeFootnote).copyWith(color: gt.colorBloom),
            ),
          ),
        const SizedBox(height: 16),
        GlassButton(label: 'Recommend something to $name', onPressed: () => openRecommendSheet(ref, toProfileId: profileId)),
      ],),
    ),),
  ];
  if (p.reading.isNotEmpty) {
    out
      ..add(box(title('Reading')))
      ..add(box(SizedBox(
        height: 252,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: m),
          itemCount: p.reading.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _ReadingPoster(series: p.reading[i]),
        ),
      ),),);
  }
  if (p.shelves.isNotEmpty) {
    out
      ..add(box(title('Shelves')))
      ..add(box(Padding(padding: EdgeInsets.symmetric(horizontal: m), child: Wrap(spacing: 16, runSpacing: 16, children: [for (final s in p.shelves) SharedShelfCard(shelf: s, width: 300)]))));
  }
  out.add(box(title('Recent')));
  final f = feed.valueOrNull;
  if (f == null) {
    out.add(box(feed.hasError ? CircleError(onRetry: () => ref.invalidate(memberFeedProvider(profileId))) : const ActivitySkeletonRow(index: 0)));
  } else if (f.items.isEmpty) {
    out.add(box(const CircleEmpty(CircleEmpty.activity)));
  } else {
    out.add(SliverList.list(children: [for (final e in collapseReads(f.items, utcOffset: DateTime.now().timeZoneOffset)) ActivityRow(key: ValueKey('m${e.item.id}'), entry: e)]));
    if (f.hasMore) out.add(box(_MoreOnBuild(onBuild: () => unawaited(ref.read(memberFeedProvider(profileId).notifier).loadMore()))));
  }
  if (p.reactions.isNotEmpty) {
    out
      ..add(box(title('Their reactions')))
      ..add(SliverList.list(children: [for (final r in p.reactions) _TheirReaction(series: r, name: name)]));
  }
  out.add(box(const SizedBox(height: 32)));
  return out;
}

class _HeaderOrb extends StatelessWidget {
  const _HeaderOrb({required this.profileId, required this.avatarKey, required this.name});
  final int profileId;
  final String? avatarKey;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gt.colorBloom, width: 2)),
        child: Heroine(
          tag: circleOrbTag(profileId),
          motion: glassZoomMotion(),
          child: GlassProfileOrb(preset: glassPresetFor(avatarKey), size: 112, friend: true, name: name),
        ),
      );
}

/// A poster of their Reading list with "Add to library"; no progress line (the sharing copy promises starts and finishes only).
class _ReadingPoster extends ConsumerWidget {
  const _ReadingPoster({required this.series});
  final MemberSeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        width: 112,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Builder(
            builder: (c) => GlassPressable(
              material: GlassMaterial.content,
              shape: const GlassShape.superellipse(14),
              semanticsLabel: series.title,
              onTap: () => unawaited(openCircleSeries(ref, series.sourceId, series.seriesKey, from: rectOf(c))),
              builder: (_, __) => ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 112, height: 168, child: series.coverUrl == null ? ColoredBox(color: gt.colorSurface2) : GlassCoverImage(url: series.coverUrl!, width: 112))),
            ),
          ),
          const SizedBox(height: 4),
          GlassText(series.title, role: gt.typeFootnote, maxLines: 1, overflow: TextOverflow.ellipsis),
          GlassButton(label: 'Add to library', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => unawaited(followFromCircle(ref, sourceId: series.sourceId, seriesKey: series.seriesKey, title: series.title))),
        ],),
      );
}

/// One of their reactions; on a chapter the viewer has not finished only "reacted to Ch 212".
class _TheirReaction extends ConsumerWidget {
  const _TheirReaction({required this.series, required this.name});
  final MemberSeries series;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ck = series.chapterKey;
    final fin = ref.watch(finishedChaptersProvider((sourceId: series.sourceId, seriesKey: series.seriesKey)));
    final guarded = ck == null || guardedFor(fin, chapterKey: ck, isOwn: false, sealed: series.sealed);
    final k = series.reaction;
    final ch = series.chapterNumber == null ? 'a chapter' : 'Ch ${series.chapterNumber!.toStringAsFixed(series.chapterNumber! % 1 == 0 ? 0 : 1)}';
    final line = guarded || k == null ? 'reacted to $ch of ${series.title}' : 'reacted ${glassReaction(k).name} to $ch of ${series.title}';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: GlassFrame.screenMargin(context), vertical: 8),
      child: Semantics(
        label: '$name $line',
        excludeSemantics: true,
        child: Row(children: [
          if (!guarded && k != null) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(glassReaction(k).fill, size: 22, color: gt.colorBloom)),
          Expanded(child: GlassText(line, role: gt.typeBody, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],),
      ),
    );
  }
}

class _MoreOnBuild extends StatefulWidget {
  const _MoreOnBuild({required this.onBuild});
  final VoidCallback onBuild;
  @override
  State<_MoreOnBuild> createState() => _MoreOnBuildState();
}

class _MoreOnBuildState extends State<_MoreOnBuild> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(widget.onBuild);
  }

  @override
  Widget build(BuildContext context) => const ActivitySkeletonRow(index: 1);
}

/// A friend (`/circle/:profileId`, ScreenId `circleMember`) inside its sheet or 560 px window: one scroll view of
/// [friendSlivers], polling while visible.
class FriendSheet extends ConsumerWidget {
  const FriendSheet({super.key, required this.profileId});
  final int profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassCirclePollScope(child: CustomScrollView(slivers: friendSlivers(context, ref, profileId)));
}

/// The same friend as a full page (a cold deep link renders the sheet route as a page, glass 8.0.3).
class FriendScreen extends ConsumerWidget {
  const FriendScreen({super.key, required this.profileId});
  final int profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassCirclePollScope(
        child: GlassScaffold(title: friendName(ref, profileId), leading: GlassLeading.back, slivers: friendSlivers(context, ref, profileId)),
      );
}
