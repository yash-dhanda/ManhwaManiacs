import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart' show chapterLabel;
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart' show GlassToastKind;
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Others see: Ana finished chapter 12 of Solo Leveling." The three wordings of glass 8.25.15 (the last two are mobile/39's).
String circlePreviewLine({required bool sharing, required String name, ReadingHistoryItem? latest}) {
  if (!sharing) return 'Others see nothing from this profile.';
  if (latest == null) return 'Others see: $name started a series.';
  final title = latest.seriesTitle ?? 'a series';
  final n = latest.chapterNumber;
  if (latest.isCompleted && n != null) return 'Others see: $name finished chapter ${chapterLabel(n)} of $title.';
  return 'Others see: $name started $title.';
}

/// Settings -> Circle and privacy (glass 8.25.15). Every change is a partial `PATCH /profiles/{id}/sharing`.
class CirclePrivacySection extends ConsumerWidget {
  const CirclePrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProfileGate(builder: (context) {
        final profile = ref.watch(activeProfileProvider)!;
        final offline = settingsOffline(ref);
        final async = ref.watch(sharingProvider(profile.id));
        return async.when(
          loading: () => const SettingsSkeleton(),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(16),
            child: GlassInlineNotice(message: "Couldn't load sharing settings", variant: GlassNoticeVariant.warning, actionLabel: 'Try again', onAction: () => ref.invalidate(sharingProvider(profile.id))),
          ),
          data: (s) => _Body(profileId: profile.id, name: profile.name, sharing: s, offline: offline),
        );
      },);
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.profileId, required this.name, required this.sharing, required this.offline});
  final int profileId;
  final String name;
  final Sharing sharing;
  final bool offline;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> with SingleTickerProviderStateMixin {
  late final AnimationController _type = AnimationController(vsync: this);
  String _line = '', _full = '';

  @override
  void initState() {
    super.initState();
    _type.addListener(() => setState(() => _line = _full.substring(0, (_full.length * _type.value).round())));
  }

  @override
  void dispose() {
    _type.dispose();
    super.dispose();
  }

  Future<void> _patch(Sharing after) async {
    final ok = await ref.read(sharingProvider(widget.profileId).notifier).patch(after);
    if (!mounted) return;
    if (!ok) {
      settingsToast(ref, "Couldn't save. Try again.", kind: GlassToastKind.error);
      return;
    }
    ref
      ..invalidate(circleMembersProvider)
      ..invalidate(circleFeedProvider);
    _typeLine();
  }

  void _typeLine() {
    final latest = ref.read(readingHistoryProvider).valueOrNull?.firstOrNull;
    final s = ref.read(sharingProvider(widget.profileId)).valueOrNull ?? widget.sharing;
    final full = circlePreviewLine(sharing: s.activity, name: widget.name, latest: latest);
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _line = full);
      return;
    }
    _full = full;
    _type
      ..duration = Duration(milliseconds: 12 * full.length)
      ..forward(from: 0);
  }

  Future<void> _clear() async {
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Remove everything you\'ve shared so far?',
      body: 'Your reading stays; your Circle just won\'t see past activity.',
      actions: const [
        GlassAlertAction<bool>('Keep it', role: GlassAlertRole.cancel, value: false),
        GlassAlertAction<bool>('Clear', role: GlassAlertRole.destructive, value: true),
      ],
    );
    if (ok != true || !mounted) return;
    final done = await ref.read(circleActionsProvider).clearActivity();
    if (!mounted) return;
    if (done) unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.deleteConfirm));
    settingsToast(ref, done ? 'Your shared activity was cleared' : "Couldn't clear your activity.");
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sharingProvider(widget.profileId)).valueOrNull ?? widget.sharing;
    final off = !s.activity;
    final dis = widget.offline;
    final matureOpen = ref.watch(matureGateOpenProvider);
    final latest = ref.watch(readingHistoryProvider).valueOrNull?.firstOrNull;
    final shown = _line.isEmpty ? circlePreviewLine(sharing: s.activity, name: widget.name, latest: latest) : _line;
    Widget sw(String id, String title, String caption, bool v, Sharing Function(bool) apply, {bool gated = false}) =>
        SettingsSwitchRow(id: id, title: title, caption: caption, value: v, enabled: !dis && !gated, onChanged: (x) => unawaited(_patch(apply(x))));
    return Column(children: [
      if (dis) const OfflineSettingsNotice(message: 'Sharing settings need a connection'),
      SettingsGroup(footer: shown, children: [
        sw('share-reading', "Share what I'm reading", 'Other readers on this server see what this profile starts and finishes. Never your bookmarks, searches, reading time or downloads.', s.activity, (v) => s.copyWith(activity: v)),
        sw('show-reactions', 'Show my reactions', 'Your reactions to chapters appear to others.', s.reactions, (v) => s.copyWith(reactions: v), gated: off),
        sw('accept-recommendations', 'Accept recommendations', "Friends can send you series. Off: you won't appear in their Recommend list.", s.recommendations, (v) => s.copyWith(recommendations: v)),
        sw('show-presence', 'Show me in presence', 'Your orb moves to the front of the Circle while you\'re reading.', s.showPresence, (v) => s.copyWith(showPresence: v), gated: off),
        sw('shared-shelves', 'Let others add me to shared shelves', 'Others can invite you to shelves they share.', s.shelves, (v) => s.copyWith(shelves: v)),
        sw('share-streak', 'Share my streak', 'Your reading streak shows in the Circle.', s.shareStreak, (v) => s.copyWith(shareStreak: v), gated: off),
        if (matureOpen)
          sw('include-mature-activity', 'Include 18+ titles in my activity', 'Even when on, 18+ titles are shown only to readers whose own 18+ setting is on.', s.includeMature, (v) => s.copyWith(includeMature: v), gated: off),
      ],),
      SettingsGroup(id: 'hidden-from-circle', header: 'Hidden from my Circle', children: [
        if (s.excludedSeries.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: GlassText('Nothing hidden. Hide a series from its ⋯ menu.', role: gt.typeFootnote, color: gt.colorLabel2))
        else
          for (final e in s.excludedSeries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                SettingsSeriesThumb(coverUrl: settingsCachedSeries(ref, e.sourceId, e.seriesKey)?.coverUrl),
                const SizedBox(width: 12),
                Expanded(child: GlassText(e.title, role: gt.typeBody, maxLines: 2)),
                GlassButton(
                  label: 'Unhide',
                  size: GlassButtonSize.small,
                  variant: GlassButtonVariant.plain,
                  onPressed: dis ? null : () => unawaited(_patch(s.copyWith(excludedSeries: [for (final x in s.excludedSeries) if (x != e) x]))),
                ),
              ],),
            ),
      ],),
      SettingsGroup(children: [
        SettingsAnchor(
          id: 'clear-activity',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(alignment: Alignment.centerLeft, child: GlassButton(label: 'Clear my activity', variant: GlassButtonVariant.destructive, onPressed: dis ? null : () => unawaited(_clear()))),
          ),
        ),
      ],),
    ],);
  }
}
