import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/voice_picker.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart' show speakerColor;
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One character's line count in the cast sheet: the server's `line_count` when it sends it, else
/// the chapter's own attributed spans.
Map<String, int> lineCounts(NovelAttribution a) {
  final counts = <String, int>{};
  for (final m in a.cast) {
    if (m.lineCount != null) counts[m.name] = m.lineCount!;
  }
  if (counts.isEmpty) {
    for (final s in a.spans) {
      final n = s.speaker;
      if (n != null && n.isNotEmpty) counts[n] = (counts[n] ?? 0) + 1;
    }
  }
  return counts;
}

/// The cast rows in order of line count (busiest first), each with its share of lines in percent.
List<({NovelCastMember member, int? share})> castRows(NovelAttribution a) {
  final counts = lineCounts(a);
  final total = counts.values.fold<int>(0, (x, y) => x + y);
  final rows = [for (final m in a.cast) (member: m, share: total == 0 ? null : (100 * (counts[m.name] ?? 0) / total).round())];
  rows.sort((x, y) => (counts[y.member.name] ?? 0).compareTo(counts[x.member.name] ?? 0));
  return rows;
}

/// The cast sheet (cinematic 8.16.5): credits rows with dot leaders, the narrator pinned first.
/// Owner-only overflow per row (`Same character as…`, `Set gender`); non-owners read it. Opens
/// from the voices button, the voices line and the `VOICES` tile.
Future<void> showCastSheet(BuildContext context, {required NovelChapterKey chapter, CineStockColors? stock, VoidCallback? onReNarrate}) => showListenSheet<void>(
      context,
      kicker: 'THE CAST',
      title: 'Voices in this chapter',
      stock: stock,
      builder: (_) => CastList(chapter: chapter, stock: stock, onReNarrate: onReNarrate),
    );

/// The cast list, in the sheet and inline in the tablet Margins panel's `VOICES` tab.
class CastList extends ConsumerStatefulWidget {
  const CastList({super.key, required this.chapter, this.stock, this.onReNarrate});

  final NovelChapterKey chapter;
  final CineStockColors? stock;

  /// Opens the Audiobook sheet with RE-VOICE selected.
  final VoidCallback? onReNarrate;

  @override
  ConsumerState<CastList> createState() => _CastListState();
}

class _CastListState extends ConsumerState<CastList> {
  /// When this device last changed each character (or the narrator), for `RE-VOICING`.
  final Map<String, DateTime> _changed = {};

  Future<void> _setGender(String name, String gender) async {
    final err = await ref.read(novelCastingWriterProvider).setGender(widget.chapter, name, gender);
    if (err != null && mounted) ref.read(cineToastsProvider.notifier).error("That change couldn't be saved. ${err.userMessage}");
  }

  Future<void> _alias(NovelAttribution a, String alias) async {
    final others = [for (final m in a.cast) if (m.name != alias) m.name];
    final pick = await showCineMenu<String>(
      context,
      anchor: anchorRect(context),
      entries: [for (final o in others) CineMenuEntry<String>(label: o, value: o)],
    );
    if (pick == null || !mounted) return;
    final err = await ref.read(novelCastingWriterProvider).mergeAlias(widget.chapter, alias, pick);
    if (err != null && mounted) ref.read(cineToastsProvider.notifier).error("That change couldn't be saved. ${err.userMessage}");
  }

  Future<void> _rowMenu(NovelAttribution a, NovelCastMember m) async {
    final pick = await showCineMenu<String>(
      context,
      anchor: anchorRect(context),
      entries: const [
        CineMenuEntry<String>(label: 'Same character as…', value: 'alias'),
        CineMenuEntry<String>(label: 'Set gender', value: 'gender'),
      ],
    );
    if (pick == null || !mounted) return;
    if (pick == 'alias') {
      await _alias(a, m.name);
    } else {
      final g = await showCineMenu<String>(
        context,
        anchor: anchorRect(context),
        entries: [
          CineMenuEntry<String>(label: 'MALE', value: 'male', checked: m.gender == 'male'),
          CineMenuEntry<String>(label: 'FEMALE', value: 'female', checked: m.gender == 'female'),
          CineMenuEntry<String>(label: 'UNKNOWN', value: 'unknown', checked: m.gender == 'unknown'),
        ],
      );
      if (g != null) await _setGender(m.name, g);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final owner = ref.watch(isOwnerProvider);
    final attr = ref.watch(novelAttributionProvider(widget.chapter));
    final voices = ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
    final byId = {for (final v in voices) v.voiceId: v};
    final detail = ref.watch(seriesAudioDetailProvider((sourceId: widget.chapter.sourceId, seriesKey: widget.chapter.seriesKey))).valueOrNull;
    final activeJobs = ref.watch(activeAudioJobsProvider).valueOrNull?.where((j) => j.isActive).toList() ?? const <NovelAudioJob>[];
    final stale = detail == null ? 0 : chaptersToRevoice(detail).length;

    if (attr.valueOrNull == null && attr.isLoading) {
      return Padding(padding: EdgeInsets.all(c.space6), child: CineRoleText('Looking up who speaks here…', c.typeUi, color: c.colorInk60));
    }
    final a = attr.valueOrNull ?? NovelAttribution.none;
    final slots = speakerSlots(a);
    final rows = castRows(a);
    final narratorName = a.narratorVoiceId == null ? 'Automatic' : (byId[a.narratorVoiceId]?.name ?? 'Automatic');

    bool revoicing(String name) {
      final at = _changed[name];
      if (at == null || activeJobs.isEmpty) return false;
      return activeJobs.any((j) => j.createdAt == null || j.createdAt!.isAfter(at));
    }

    Widget leader(Widget label, String value, {Color? tint, VoidCallback? onTap, Widget? trailing, String? semantics, bool showRevoicing = false}) {
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: label),
          if (tint != null) ...[SizedBox(width: c.space2), Padding(padding: const EdgeInsets.only(bottom: 4), child: SizedBox(width: 10, height: 10, child: ColoredBox(color: tint)))],
          SizedBox(width: c.space2),
          const Expanded(child: Padding(padding: EdgeInsets.only(bottom: 2), child: CineDotLeader())),
          SizedBox(width: c.space2),
          if (showRevoicing) Padding(padding: EdgeInsets.only(right: c.space2), child: CineRoleText('RE-VOICING', c.typeMicro, color: c.colorSpot)),
          Flexible(child: CineRoleText(value, c.typeUi, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (trailing != null) trailing,
        ],
      );
      return Semantics(
        container: true,
        label: semantics ?? value,
        button: onTap != null,
        excludeSemantics: true,
        onTap: onTap,
        child: CinePressable(
          onTap: onTap,
          hit: false,
          builder: (context, st) => ConstrainedBox(constraints: BoxConstraints(minHeight: cineHitMinFor(context)), child: Align(child: row)),
        ),
      );
    }

    final status = <String>[
      if (!a.attributed || (rows.isEmpty && a.attributed)) 'Nobody else was identified with enough confidence, so the narrator reads every line.',
      if (a.attributed && a.narrator != null) 'Narrated by ${a.narrator}: their own lines use the narrator\'s voice.',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in status) Padding(padding: EdgeInsets.only(bottom: c.space2), child: CineRoleText(line, c.typeCaption, color: c.colorInk60)),
          leader(
            CineRoleText('Narrator', c.typeUi, color: c.colorInk60),
            narratorName,
            semantics: 'Narrator, $narratorName',
            showRevoicing: revoicing('\u0000narrator'),
            onTap: owner
                ? () => unawaited(showVoicePicker(
                      context,
                      chapter: widget.chapter,
                      stock: widget.stock,
                      subject: VoiceSubject.narrator,
                      currentVoiceId: a.narratorVoiceId,
                      onCast: (_) => setState(() => _changed['\u0000narrator'] = DateTime.now().toUtc()),
                    ),)
                : null,
          ),
          for (final r in rows)
            leader(
              CineRoleText(r.member.name, c.typeUi, maxLines: 1, overflow: TextOverflow.ellipsis),
              [
                r.member.voiceId == null ? 'Automatic' : (byId[r.member.voiceId]?.name ?? 'Automatic'),
                if (r.share != null) '${r.share} %',
              ].join(' · '),
              tint: speakerColor(c, (slots[r.member.name]?.slot ?? 1)),
              semantics: '${r.member.name}, ${r.member.voiceId == null ? 'automatic voice' : byId[r.member.voiceId]?.name ?? 'automatic voice'}${r.share == null ? '' : ', ${r.share} percent of the lines'}${r.member.locked ? ', set by hand' : ''}',
              showRevoicing: revoicing(r.member.name),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (r.member.locked)
                  Padding(padding: EdgeInsets.only(left: c.space2), child: Icon(Icons.lock_outline, size: 14, color: c.colorInk60, semanticLabel: 'Set by hand')),
                if (owner)
                  Semantics(
                    button: true,
                    label: 'More for ${r.member.name}',
                    excludeSemantics: true,
                    onTap: () => unawaited(_rowMenu(a, r.member)),
                    child: GestureDetector(
                      onTap: () => unawaited(_rowMenu(a, r.member)),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(width: cineHitMinFor(context), height: cineHitMinFor(context), child: Icon(Icons.more_horiz, size: 18, color: c.colorInk60)),
                    ),
                  ),
              ],),
              onTap: owner
                  ? () => unawaited(showVoicePicker(
                        context,
                        chapter: widget.chapter,
                        stock: widget.stock,
                        subjectName: r.member.name,
                        gender: r.member.gender,
                        currentVoiceId: r.member.voiceId,
                        onCast: (_) => setState(() => _changed[r.member.name] = DateTime.now().toUtc()),
                      ),)
                  : null,
            ),
          if (owner && stale > 0) ...[
            SizedBox(height: c.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: CineButton(
                label: 'Re-narrate $stale ${stale == 1 ? 'chapter' : 'chapters'}',
                variant: CineButtonVariant.quiet,
                size: CineButtonSize.sm,
                onPressed: () {
                  cineFeedback(context, HapticEvent.tapSecondary);
                  widget.onReNarrate?.call();
                },
              ),
            ),
          ],
          SizedBox(height: c.space4),
        ],
      ),
    );
  }
}

/// [cineHitMin] with the 40 px credits floor.
double cineHitMinFor(BuildContext context) => Theme.of(context).platform == TargetPlatform.android ? 48 : 44;
