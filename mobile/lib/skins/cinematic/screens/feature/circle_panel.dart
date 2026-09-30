import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart' show chapterLabel;
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart' show CineLeaderDial;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Whether the series page's circle surface is usable for this profile.
enum CircleTabState { on, sharingOff, absent }

CircleTabState circleTabState(WidgetRef ref) {
  final members = ref.watch(circleMembersProvider);
  final err = members.error;
  if (err is ApiError && err.statusCode == 404) return CircleTabState.absent;
  final pid = ref.watch(activeProfileProvider)?.id;
  final sharing = pid == null ? null : ref.watch(sharingProvider(pid)).valueOrNull;
  return sharing != null && !sharing.activity ? CircleTabState.sharingOff : CircleTabState.on;
}

/// The copy of a disabled `04 CIRCLE` tab (cinematic 8.17).
const String kCircleTabOffHint = 'Turn on sharing in Settings → Circle & privacy to see the circle here.';

/// `04 CIRCLE` (cinematic 8.17, 9.3.3): who follows or reads the series, the reactions per chapter
/// (each guarded on its own) and `Recommend to…`.
class FeatureCircleContent extends ConsumerWidget {
  const FeatureCircleContent({super.key, required this.sourceId, required this.seriesKey, required this.title, this.coverUrl});
  final String sourceId, seriesKey, title;
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final key = (sourceId: sourceId, seriesKey: seriesKey);
    final async = ref.watch(circleSeriesProvider(key));
    final data = async.valueOrNull;
    final chapters = ref.watch(chapterReactionsProvider(key)).valueOrNull ?? data?.chapters ?? const <ChapterReactions>[];
    final members = ref.watch(circleMembersProvider).valueOrNull ?? const <CircleMember>[];
    if (data == null) {
      if (async.hasError) {
        return Padding(
          padding: EdgeInsets.all(c.space4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CineRoleText('CORRECTION', c.typeKicker, color: c.colorProof),
            CineRoleText("This didn't load.", c.typeUi),
            CineButton(label: 'Try again', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(circleSeriesProvider(key))),
          ],),
        );
      }
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: CineLeaderDial(size: 24)));
    }
    final ordered = [...chapters]..sort((a, b) => (b.chapterNumber ?? -1).compareTo(a.chapterNumber ?? -1));
    final empty = data.followers.isEmpty && data.readers.isEmpty && ordered.isEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (empty) CineRoleText('Nobody in your circle has read this yet.', c.typeBody, color: c.colorInk60),
      if (data.followers.isNotEmpty) ...[
        CineRoleText('FOLLOWING', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space2),
        Wrap(spacing: c.space4, runSpacing: c.space3, children: [
          for (final f in data.followers)
            Row(mainAxisSize: MainAxisSize.min, children: [
              CineAvatar(avatarKey: f.avatarKey, size: 32),
              SizedBox(width: c.space2),
              CineRoleText(f.name, c.typeUi),
            ],),
        ],),
        SizedBox(height: c.space5),
      ],
      if (data.readers.isNotEmpty) ...[
        CineRoleText('READING', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space2),
        for (final r in data.readers)
          Semantics(
            container: true,
            label: r.chapterNumber == null ? '${r.member.name} is reading' : '${r.member.name} is on Ch. ${chapterLabel(r.chapterNumber!)}',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(children: [
                CineAvatar(avatarKey: r.member.avatarKey, size: 20),
                SizedBox(width: c.space2),
                CineRoleText(r.chapterNumber == null ? '${r.member.name} is reading' : '${r.member.name} is on Ch. ${chapterLabel(r.chapterNumber!)}', c.typeUi),
              ],),
            ),
          ),
        SizedBox(height: c.space5),
      ],
      if (ordered.isNotEmpty) ...[
        CineRoleText('REACTIONS', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space3),
        for (final ch in ordered) ...[
          CineRoleText(ch.chapterNumber == null ? 'A CHAPTER' : 'CH ${chapterLabel(ch.chapterNumber!)}', c.typeFolio, color: c.colorInk60),
          SizedBox(height: c.space2),
          ReactionStamps(sourceId: sourceId, seriesKey: seriesKey, chapterKey: ch.chapterKey, chapterNumber: ch.chapterNumber),
          SizedBox(height: c.space4),
        ],
      ],
      if (members.isNotEmpty)
        CineButton(label: 'Recommend to…', variant: CineButtonVariant.secondary, onPressed: () => unawaited(showPassItOnSheet(context, sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: coverUrl))),
    ],);
  }
}

/// The tab panel on the manga Feature page.
class FeatureCirclePanel extends StatelessWidget {
  const FeatureCirclePanel({super.key, required this.sourceId, required this.seriesKey, required this.title, this.coverUrl});
  final String sourceId, seriesKey, title;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        key: const PageStorageKey('circle'),
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            sliver: SliverToBoxAdapter(child: FeatureCircleContent(sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: coverUrl)),
          ),
        ],
      );
}

/// The book page's circle section (a book has no tabs): the same content under a `CIRCLE` slug, or
/// the disabled hint while this profile does not share.
class BookCircleSection extends ConsumerWidget {
  const BookCircleSection({super.key, required this.sourceId, required this.seriesKey, required this.title, this.coverUrl});
  final String sourceId, seriesKey, title;
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final state = circleTabState(ref);
    if (state == CircleTabState.absent) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: c.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CineRoleText('04 CIRCLE', c.typeNav, color: state == CircleTabState.on ? c.colorInk100 : c.colorInk30),
        SizedBox(height: c.space3),
        if (state == CircleTabState.sharingOff)
          CineRoleText(kCircleTabOffHint, c.typeCaption, color: c.colorInk45)
        else
          FeatureCircleContent(sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: coverUrl),
      ],),
    );
  }
}
