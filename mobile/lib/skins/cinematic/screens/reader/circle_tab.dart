import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_poll_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart' show reactionGlyph;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/circle_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// CIRCLE (cinematic 8.14.12, 9.3.3): who in the circle read this chapter and how they took it,
/// behind the spoiler guard. When [completedOpen] turns true the guarded rows unseal, each label
/// fading in over 160 ms `settle`, 40 ms after the previous one.
class CircleTab extends ConsumerWidget {
  const CircleTab({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, required this.chapterNumber, required this.completedOpen});

  final String sourceId, seriesKey, chapterKey;
  final double? chapterNumber;
  final bool completedOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CirclePollScope(child: _build(context, ref));

  Widget _build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final key = (sourceId: sourceId, seriesKey: seriesKey);
    final data = ref.watch(circleSeriesProvider(key));
    final d = data.valueOrNull;
    final done = completedOpen || ref.watch(completedThisSessionProvider.select((s) => s.contains(chapterId(sourceId, seriesKey, chapterKey))));
    if (data.isLoading && d == null) return const Center(child: CineLeaderDial(size: 24));
    if (data.hasError) {
      return Padding(
        padding: EdgeInsets.all(c.space4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineRoleText('CORRECTION', c.typeKicker, color: c.colorProof),
          CineRoleText("This didn't load.", c.typeUi),
          CineButton(label: 'Try again', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(circleSeriesProvider(key))),
        ],),
      );
    }
    final rows = d == null ? const <CircleRow>[] : circleRows(d, openKey: chapterKey, openNumber: chapterNumber, completedOpen: done, selfId: ref.watch(activeProfileProvider)?.id);
    if (rows.isEmpty) {
      return Padding(padding: EdgeInsets.all(c.space4), child: CineRoleText('Nobody in your circle has read this yet.', c.typeCaption, color: c.colorInk60));
    }
    final title = ref.watch(readerSeriesProvider(key))?.title ?? '';
    return ListView(
      padding: EdgeInsets.all(c.space4),
      children: [
        for (var i = 0; i < rows.length; i++) _Row(row: rows[i], index: i, avatarKey: _avatarOf(d!, rows[i].member)),
        if ((ref.watch(circleMembersProvider).valueOrNull ?? const []).isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: c.space3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CineButton(label: 'Recommend this series…', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => unawaited(showPassItOnSheet(context, sourceId: sourceId, seriesKey: seriesKey, title: title))),
            ),
          ),
      ],
    );
  }

  String? _avatarOf(CircleSeriesData d, CircleMemberRef m) => m.avatarKey;
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.index, required this.avatarKey});
  final CircleRow row;
  final int index;
  final String? avatarKey;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final m = row.member;
    Widget detail() => switch (row.kind) {
          CircleRowKind.label => _FadeIn(
              key: ValueKey('circle-label-${m.profileId}'),
              delay: reduced ? Duration.zero : Duration(milliseconds: 40 * index),
              duration: reduced ? Duration.zero : const Duration(milliseconds: 160),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (row.reaction != null && reactionSpec(row.reaction!).stampText == null) ...[reactionGlyph(row.reaction!, size: 16, color: c.colorSpot), SizedBox(width: c.space1)],
                CineRoleText(row.label ?? '', c.typeKicker, color: c.colorSpot),
              ],),
            ),
          CircleRowKind.guarded => CineRoleText('reacted to ${chapterShort(row.chapterNumber)}', c.typeCaption, color: c.colorInk45),
          CircleRowKind.further => CineRoleText('${m.name} is on ${chapterShort(row.chapterNumber)}', c.typeCaption, color: c.colorInk45),
          CircleRowKind.here => CineRoleText('is on ${chapterShort(row.chapterNumber)}', c.typeCaption, color: c.colorInk45),
        };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: c.space2),
      child: Semantics(
        container: true,
        label: '${m.name}, ${switch (row.kind) {
          CircleRowKind.label => row.label ?? '',
          CircleRowKind.guarded => 'reacted to ${chapterShort(row.chapterNumber)}',
          _ => 'is on ${chapterShort(row.chapterNumber)}',
        }}',
        excludeSemantics: true,
        child: Row(children: [
          CineAvatar(avatarKey: avatarKey, size: 20),
          SizedBox(width: c.space2),
          if (row.kind != CircleRowKind.further) ...[
            CineRoleText(m.name, c.typeUi),
            SizedBox(width: c.space2),
          ],
          Flexible(child: detail()),
        ],),
      ),
    );
  }
}

/// A label that fades in over [duration] `settle`, [delay] after it is built (the unseal).
class _FadeIn extends StatefulWidget {
  const _FadeIn({super.key, required this.delay, required this.duration, required this.child});
  final Duration delay, duration;
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  double _o = 0;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero && widget.duration == Duration.zero) {
      _o = 1;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _o = 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedOpacity(opacity: _o, duration: widget.duration, curve: CineCurves.settle, child: widget.child);
}
