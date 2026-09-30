import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_guard.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_poll_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_pick_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart' show reactionGlyph;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart' show CineLeaderDial;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rail.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/shelves_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// "Reading 4 series · shares activity and reactions" (cinematic 9.3.7).
String memberDeck(MemberPage p) {
  final shares = [if (p.shares.activity) 'activity', if (p.shares.reactions) 'reactions', if (p.shares.shelves) 'shelves', if (p.shares.recommendations) 'recommendations'];
  final joined = shares.length <= 1 ? shares.join() : '${shares.sublist(0, shares.length - 1).join(', ')} and ${shares.last}';
  final n = p.reading.length;
  final reading = n == 0 ? 'Not reading anything right now' : 'Reading $n ${n == 1 ? 'series' : 'series'}';
  return joined.isEmpty ? reading : '$reading · shares $joined';
}

/// A member's page (ScreenId `circleMember`, `/circle/:profileId`; cinematic 9.3.7): what they share,
/// as rails, and `Recommend something to {name}`.
class CircleMemberScreen extends ConsumerWidget {
  const CircleMemberScreen({super.key, required this.profileId});
  final int profileId;

  Future<void> _reprint(WidgetRef ref) async {
    ref.invalidate(circleMemberProvider(profileId));
    try {
      await ref.read(circleMemberProvider(profileId).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(circleMemberProvider(profileId));
    final page = async.valueOrNull;
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final name = page?.profile.name;
    final known = ref.watch(circleMembersProvider).valueOrNull;
    final knownName = known?.where((m) => m.profileId == profileId).firstOrNull?.name;
    return CineScaffold(
      runningTitle: name == null ? 'No. 11 · CIRCLE' : 'No. 11 · CIRCLE / ${name.toUpperCase()}',
      firstRunNote: false,
      body: CirclePollScope(
        child: CinePullToReprint(
          onRefresh: () => _reprint(ref),
          child: page != null
              ? _Body(page: page, online: online)
              : _State(
                  name: knownName,
                  error: async.error,
                  loading: async.isLoading,
                  online: online,
                  onRetry: () => ref.invalidate(circleMemberProvider(profileId)),
                ),
        ),
      ),
    );
  }
}

class _State extends StatelessWidget {
  const _State({required this.name, required this.error, required this.loading, required this.online, required this.onRetry});
  final String? name;
  final Object? error;
  final bool loading, online;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    Widget notice;
    final e = error;
    if (e is ApiError && e.code == 'circle_member_not_sharing') {
      notice = CircleNoticeBox(
        notice: CineNotice(
          key: const Key('member-not-sharing'),
          tone: CineNoticeTone.caution,
          kicker: 'NOTE',
          headline: "${name ?? 'This reader'} isn't sharing right now.",
          primary: CineNoticeAction('Back to the Circle', () => context.go(Routes.circle())),
        ),
      );
    } else if (e is NetworkError || (!online && e != null)) {
      notice = CircleNoticeBox(
        notice: CineNotice(key: const Key('member-offline'), tone: CineNoticeTone.offline, kicker: 'OFFLINE EDITION', headline: 'The circle needs a connection.', primary: CineNoticeAction('Try again', onRetry)),
      );
    } else if (e != null) {
      notice = CircleNoticeBox(notice: CineNotice(key: const Key('member-error'), tone: CineNoticeTone.error, kicker: 'CORRECTION', headline: "The circle didn't load.", primary: CineNoticeAction('Try again', onRetry)));
    } else {
      notice = Padding(
        padding: EdgeInsets.fromLTRB(grid.left, c.space6, grid.right, 0),
        child: Row(children: [const CineLeaderDial(size: 24), SizedBox(width: c.space3), CineRoleText('Loading', c.typeKicker, color: c.colorInk45)]),
      );
    }
    return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: notice);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.page, required this.online});
  final MemberPage page;
  final bool online;

  Widget _poster(BuildContext context, WidgetRef ref, MemberSeries s, {required String tag, FocusNode? node, int index = 0, bool reaction = false}) {
    final c = context.cine;
    final base = ref.watch(apiBaseUrlProvider);
    var folio = '';
    var badges = const <Widget>[];
    if (reaction) {
      final guarded = circleGuarded(ref, sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: s.chapterKey, sealed: s.sealed);
      final n = s.chapterNumber;
      final ch = n == null ? 'a chapter' : 'Ch. ${n == n.roundToDouble() ? n.toInt() : n}';
      if (guarded || s.reaction == null) {
        folio = 'reacted to $ch';
      } else {
        folio = '${reactionSpec(s.reaction!).label} · $ch';
        badges = [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorHairlineArt)),
            child: Semantics(label: reactionSpec(s.reaction!).label, child: reactionGlyph(s.reaction!, size: 16, color: c.colorInk100)),
          ),
        ];
      }
    } else if (s.chapterNumber != null) {
      folio = 'CH ${s.chapterNumber! == s.chapterNumber!.roundToDouble() ? s.chapterNumber!.toInt() : s.chapterNumber}';
    }
    return CinePoster(
      title: s.title,
      url: historyCoverUrl(base, s.coverUrl),
      folio: folio.isEmpty ? null : folio,
      badges: badges,
      heroTag: (tag, '${s.sourceId}:${s.seriesKey}:$index'),
      duo: s.ambient?.duo,
      focusNode: node,
      flickerIndex: index,
      onTap: () => unawaited(context.push(Routes.feature(s.sourceId, s.seriesKey))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    final p = page;
    final now = p.now;
    final rails = <Widget>[];
    var folio = 1;
    String next() => (folio++).toString().padLeft(2, '0');
    void rail(String id, String heading, List<MemberSeries> items, {bool reaction = false}) {
      if (items.isEmpty) return;
      rails.add(
        Padding(
          padding: EdgeInsets.only(bottom: 40, left: grid.left, right: grid.right),
          child: CineRail(headingId: 'member.$id', heading: heading, folio: next(), itemCount: items.length, itemBuilder: (context, i, w, node) => _poster(context, ref, items[i], tag: 'member-$id', node: node, index: i, reaction: reaction)),
        ),
      );
    }

    if (p.shares.activity) {
      rail('reading', 'Now reading', p.reading);
      rail('finished', 'Recently finished', p.finished);
    }
    if (p.shares.reactions) rail('reactions', 'Their reactions', p.reactions, reaction: true);
    if (p.shelves.isNotEmpty) {
      rails.add(
        Padding(
          padding: EdgeInsets.only(bottom: 40, left: grid.left, right: grid.right),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CineRuleDraw(),
            SizedBox(height: c.space3),
            Row(children: [
              CineRoleText(next(), c.typeFolio, color: c.colorInk45),
              SizedBox(width: c.space3),
              Flexible(child: SetHeading('Shared shelves', id: 'member.shelves', style: CineText.style(context, c.typeSection).copyWith(color: c.colorInk100), cap: c.typeSection.cap, level: 2)),
            ],),
            SizedBox(height: c.space3),
            Wrap(spacing: grid.gutter, runSpacing: c.space4, children: [
              for (final s in p.shelves) SizedBox(width: MediaQuery.sizeOf(context).width >= 600 ? (MediaQuery.sizeOf(context).width - grid.left - grid.right - 2 * grid.gutter) / 3 : double.infinity, child: AspectRatio(aspectRatio: 16 / 10, child: SharedShelfPlate(shelf: s))),
            ],),
          ],),
        ),
      );
    }
    final canRecommend = p.shares.recommendations;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CineRoleText('No. 11 — THE CIRCLE', c.typeKicker, color: c.colorInk45),
              SizedBox(height: c.space3),
              Row(children: [
                CineReadingNowRing(duo: now == null ? null : ringColour(now), child: CineAvatar(avatarKey: p.profile.avatarKey, size: 96, semanticName: now == null ? p.profile.name : '${p.profile.name}, reading now')),
                SizedBox(width: c.space4),
                Expanded(
                  child: SetHeading(
                    p.profile.name,
                    id: 'masthead-member-${p.profile.profileId}',
                    style: CineText.style(context, c.typeMasthead).copyWith(color: c.colorInk100, fontStyle: FontStyle.italic),
                    cap: c.typeMasthead.cap,
                    level: 1,
                    trigger: SetTrigger.mount,
                  ),
                ),
              ],),
              SizedBox(height: c.space2),
              CineRoleText(memberDeck(p), c.typeDeck, color: c.colorInk60),
              SizedBox(height: c.space4),
              const CineRuleDraw(kind: CineRuleKind.heavy, delay: Duration(milliseconds: 1200)),
              if (canRecommend)
                Padding(
                  padding: EdgeInsets.only(top: c.space4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CineButton(
                      label: 'Recommend something to ${p.profile.name}',
                      variant: CineButtonVariant.secondary,
                      onPressed: online ? () => unawaited(_recommend(context, ref)) : null,
                      disabledReason: online ? null : 'Sending needs a connection.',
                    ),
                  ),
                ),
              SizedBox(height: c.space6),
            ],),
          ),
        ),
        SliverList(delegate: SliverChildListDelegate(rails)),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  Future<void> _recommend(BuildContext context, WidgetRef ref) async {
    final pick = await showLibraryPickSheet(context, title: 'Recommend', kicker: 'PASS IT ON');
    if (pick == null || !context.mounted) return;
    await showPassItOnSheet(context, sourceId: pick.sourceId, seriesKey: pick.seriesKey, title: pick.title, coverUrl: pick.coverUrl, preselectProfileId: page.profile.profileId);
  }
}
