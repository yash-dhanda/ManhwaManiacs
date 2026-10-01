import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "AI picks are on · 7 asks left today", or the reason's long line (glass 9.1.5). Pure, for the tests.
String aiStatusLine({required bool available, required String reason, required int remaining, bool offline = false}) {
  if (offline) return glassAiLines('offline').long;
  if (available) return 'AI picks are on · $remaining ${remaining == 1 ? 'ask' : 'asks'} left today';
  return glassAiLines(reason).long;
}

/// Settings -> AI and recaps (glass 8.25.16). The recap setting is device-local per profile (`mm.recap`, shared with Cinematic).
class AiRecapsSection extends ConsumerWidget {
  const AiRecapsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProfileGate(builder: (context) => const _Body());
}

class _Body extends ConsumerWidget {
  const _Body();

  static String _titleOf(String key) {
    final i = key.indexOf(':');
    final raw = i < 0 ? key : key.substring(i + 1);
    return raw.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(recapSettingProvider);
    final n = ref.read(recapSettingProvider.notifier);
    final offline = settingsOffline(ref);
    final avail = ref.watch(suggestAvailabilityProvider);
    return Column(children: [
      SettingsGroup(header: 'Previously on', footer: 'Saved on this device.', children: [
        SettingsSegmentedBlock<RecapMode>(
          id: 'previously-on',
          title: 'Previously on',
          caption: 'Ask: when you come back to a series after a week, we offer a quick recap. Always: the recap opens first. Chapter recaps are offered after 3 days away.',
          segments: const [
            GlassSegment(value: RecapMode.off, label: 'Off'),
            GlassSegment(value: RecapMode.ask, label: 'Ask'),
            GlassSegment(value: RecapMode.always, label: 'Always'),
          ],
          selected: s.mode,
          onSelected: (m) => unawaited(n.setMode(m)),
        ),
      ],),
      SettingsGroup(header: 'Series you asked not to recap', children: [
        SettingsAnchor(
          id: 'recap-skip',
          child: s.skipSeries.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: GlassText("You haven't turned recaps off for any series.", role: gt.typeFootnote, color: gt.colorLabel2))
              : Column(children: [
                  for (final k in s.skipSeries)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Builder(builder: (_) {
                        final i = k.indexOf(':');
                        final cached = i < 0 ? null : settingsCachedSeries(ref, k.substring(0, i), k.substring(i + 1));
                        return Row(children: [
                        SettingsSeriesThumb(coverUrl: cached?.coverUrl),
                        const SizedBox(width: 12),
                        Expanded(child: GlassText(cached?.title ?? _titleOf(k), role: gt.typeBody, maxLines: 2)),
                        GlassButton(label: 'Ask again', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: () => unawaited(n.allow(k))),
                      ],);
                      },),
                    ),
                ],),
        ),
      ],),
      SettingsGroup(children: [
        SettingsRow(
          id: 'clear-not-interested',
          title: 'Clear "Not interested"',
          caption: 'Series you dismissed from AI picks can appear again.',
          enabled: !offline,
          onTap: () async {
            final ok = await ref.read(aiFeedbackProvider).clear();
            settingsToast(ref, ok ? 'Your AI picks start fresh' : "Couldn't clear. Try again.");
          },
        ),
        SettingsRow(
          id: 'ai-status',
          title: 'AI status',
          caption: avail.when(
            data: (a) => aiStatusLine(available: a.available, reason: a.reason, remaining: a.remainingToday, offline: offline),
            loading: () => 'Checking…',
            error: (_, __) => glassAiLines('upstream_error').long,
          ),
        ),
      ],),
    ],);
  }
}
