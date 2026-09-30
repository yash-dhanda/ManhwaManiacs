import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart' show chapterLabel;
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_pick_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The runs of the privacy preview line (cinematic 9.3.6): what others see of the latest history row.
List<TypedRun> circlePreviewRuns({required bool sharing, required String name, ReadingHistoryItem? latest}) {
  if (!sharing) return const [TypedRun("Others see nothing. You're reading privately.")];
  if (latest == null) return const [TypedRun('Others see nothing yet. Read a chapter and it appears here.')];
  final title = latest.seriesTitle ?? 'a series';
  final n = latest.chapterNumber;
  if (latest.isCompleted) {
    return [
      const TypedRun('Others see: '),
      TypedRun(name, italic: true),
      TypedRun(n == null ? ' finished a chapter of ' : ' finished chapter ${chapterLabel(n)} of '),
      TypedRun(title, italic: true),
      const TypedRun('.'),
    ];
  }
  return [const TypedRun('Others see: '), TypedRun(name, italic: true), const TypedRun(' started '), TypedRun(title, italic: true), const TypedRun('.')];
}

/// Settings, `Circle & privacy` (cinematic 8.30.2 row 09, 9.3.6): the master switch, what else to
/// share, 18+ titles, hidden series and `Clear my shared activity`. Server-backed: greeked while
/// loading, a `CORRECTION` on error, last values and "Needs a connection." offline. Every `PATCH`
/// sends only the keys that changed (never `show_presence` or `share_streak`).
class CircleSection extends ConsumerWidget {
  const CircleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) return const SizedBox.shrink();
    final async = ref.watch(sharingProvider(profile.id));
    return SettingsAsync<Sharing>(
      value: async,
      rows: 7,
      onRetry: () => ref.invalidate(sharingProvider(profile.id)),
      builder: (context, s, offline) => _Body(profileId: profile.id, name: profile.name, sharing: s),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profileId, required this.name, required this.sharing});
  final int profileId;
  final String name;
  final Sharing sharing;

  Future<void> _patch(WidgetRef ref, Sharing after) async {
    final ok = await ref.read(sharingProvider(profileId).notifier).patch(after);
    if (!ok) throw Exception("Couldn't save. Try again.");
    ref
      ..invalidate(circleMembersProvider)
      ..invalidate(circleFeedProvider);
  }

  Widget _switch(WidgetRef ref, String id, String label, String description, bool value, Sharing Function(bool) apply, {bool disabled = false, String? caption}) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        JumpRow(
          id: id,
          child: CineSettingsRow(
            label: label,
            description: description,
            disabled: disabled,
            control: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: CineSwitch(label: label, value: value, errorLine: "Couldn't save. Try again.", onChanged: disabled ? null : (v) => _patch(ref, apply(v))),
            ),
          ),
        ),
        if (caption != null) SettingsCaption(caption),
      ],);

  Future<void> _addHidden(BuildContext context, WidgetRef ref) async {
    final pick = await showLibraryPickSheet(context, kicker: 'HIDE A SERIES', title: 'Hide a series', exclude: {for (final e in sharing.excludedSeries) '${e.sourceId}\u0000${e.seriesKey}'});
    if (pick == null || !context.mounted) return;
    try {
      await _patch(ref, sharing.copyWith(excludedSeries: [...sharing.excludedSeries, ExcludedSeries(sourceId: pick.sourceId, seriesKey: pick.seriesKey, title: pick.title)]));
    } catch (_) {
      ref.read(cineToastsProvider.notifier).error("Couldn't save. Try again.");
    }
  }

  Future<void> _removeHidden(WidgetRef ref, ExcludedSeries e) async {
    try {
      await _patch(ref, sharing.copyWith(excludedSeries: [for (final x in sharing.excludedSeries) if (x != e) x]));
    } catch (_) {
      ref.read(cineToastsProvider.notifier).error("Couldn't save. Try again.");
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final toasts = ref.read(cineToastsProvider.notifier);
    final ok = await showCineConfirm(
      context,
      title: "Clear everything you've shared? Others stop seeing your past activity. Your library isn't touched.",
      confirmLabel: 'Clear',
      destructive: true,
      filled: true,
    );
    if (!ok || !context.mounted) return;
    final done = await ref.read(circleActionsProvider).clearActivity();
    toasts.info(done ? 'Cleared your shared activity.' : "Couldn't clear your activity.");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final s = sharing;
    final latest = ref.watch(readingHistoryProvider).valueOrNull?.firstOrNull;
    final matureOpen = ref.watch(matureGateOpenProvider);
    final off = !s.activity;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: EdgeInsets.only(top: c.space3, bottom: c.space2),
        child: TypedText(
          circlePreviewRuns(sharing: s.activity, name: name, latest: latest),
          key: ValueKey('preview-${s.activity}-${latest?.id}-${latest?.isCompleted}'),
          style: CineText.style(context, c.typeBody).copyWith(color: c.colorInk100),
        ),
      ),
      _switch(ref, 'share-activity', "Share what I'm reading", 'Others on this server see what you start and finish.', s.activity, (v) => s.copyWith(activity: v)),
      _switch(ref, 'share-reactions', 'Show my reactions', 'Your stamps on chapters appear to others.', s.reactions, (v) => s.copyWith(reactions: v), disabled: off, caption: off ? 'Turn on sharing first.' : null),
      _switch(ref, 'share-shelves', 'Let others add me to shared shelves', 'Others can invite you to shelves they share.', s.shelves, (v) => s.copyWith(shelves: v), disabled: off, caption: off ? 'Turn on sharing first.' : null),
      _switch(ref, 'share-recommendations', 'Receive recommendations', 'Others can pass series to you.', s.recommendations, (v) => s.copyWith(recommendations: v), disabled: off, caption: off ? 'Turn on sharing first.' : null),
      if (matureOpen)
        _switch(ref, 'share-mature', 'Include 18+ titles in my activity', 'Only readers whose own 18+ setting is on can see these.', s.includeMature, (v) => s.copyWith(includeMature: v), disabled: off, caption: off ? 'Turn on sharing first.' : null),
      const JumpRow(
        id: 'hide-series',
        child: CineSettingsRow(label: 'Hide this series from my activity', description: 'Hidden series never appear in your shared activity.'),
      ),
      for (final e in s.excludedSeries)
        Padding(
          key: ValueKey('hidden-${e.sourceId}-${e.seriesKey}'),
          padding: EdgeInsets.only(bottom: c.space2),
          child: Row(children: [
            SizedBox(width: 40, height: 60, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: null, title: e.title))),
            SizedBox(width: c.space3),
            Expanded(child: CineRoleText(e.title, c.typeUi, maxLines: 2, overflow: TextOverflow.ellipsis)),
            CineButton(label: 'Remove', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => unawaited(_removeHidden(ref, e))),
          ],),
        ),
      quietAction('Add a series', () => unawaited(_addHidden(context, ref))),
      SizedBox(height: c.space4),
      JumpRow(
        id: 'clear-activity',
        child: CineSettingsRow(
          label: 'Clear my shared activity',
          description: "Removes everything you've shared so far.",
          control: CineButton(label: 'Clear my shared activity', variant: CineButtonVariant.destructive, size: CineButtonSize.sm, onPressed: () => unawaited(_clear(context, ref))),
        ),
      ),
    ],);
  }
}
