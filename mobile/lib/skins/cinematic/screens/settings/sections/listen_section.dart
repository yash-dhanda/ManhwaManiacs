import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/utils/settings_search.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const _sleepLabels = {
  'off': 'Off',
  '5': '5 min',
  '10': '10 min',
  '15': '15 min',
  '30': '30 min',
  '45': '45 min',
  '60': '60 min',
  'chapter': 'End of chapter',
  'nextChapter': 'End of next chapter',
};

String sleepDefaultLabel(String v) => _sleepLabels[v] ?? 'Off';

/// Listen (cinematic 8.30.2 row 5).
class ListenSection extends ConsumerWidget {
  const ListenSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(listenSettingsProvider);
    final n = ref.read(listenSettingsProvider.notifier);
    const profile = 'Saved for this profile';
    const presets = [0.8, 1.0, 1.25, 1.5, 2.0];
    String x(double v) => '${(v * 100).round() % 10 == 0 ? v.toStringAsFixed(v * 10 == (v * 10).round() ? 1 : 2) : v.toStringAsFixed(2)}×';
    final speed = r.speed;

    Future<void> pickSleep() async {
      final picked = await showCineSheet<String>(
        context,
        kicker: 'SLEEP TIMER',
        title: 'Default sleep timer',
        builder: (ctx) => _SleepList(current: r.sleepDefault),
      );
      if (picked != null) await n.put({'sleepDefault': picked});
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SettingsLinkRow(id: 'voices', label: 'Voices', value: 'BROWSE', onTap: () => unawaited(showCineSheet<void>(context, kicker: 'THE VOICES', title: 'Voices', builder: (_) => const VoiceBrowseList()))),
      sliderRow('speed', 'Default speed', speed, (v) => n.put({'speed': (v * 20).round() / 20}), min: 0.5, max: 3.0, divisions: 50, flag: x, description: profile),
      SettingsBlock(
        id: 'speed-presets',
        label: 'Presets',
        child: CineSlugLines(
          items: [for (final p in presets) CineSlug('$p', x(p).replaceAll('×', ''))],
          selected: {'$speed'},
          onChanged: (v) => n.put({'speed': double.parse(v)}),
        ),
      ),
      SettingsLinkRow(id: 'sleep-default', label: 'Sleep timer default', value: sleepDefaultLabel(r.sleepDefault).toUpperCase(), onTap: () => unawaited(pickSleep())),
      switchRow('shake', 'Shake to extend', r.shakeToExtend, (v) => n.put({'shakeToExtend': v}),
          description: 'Shake the phone in the last minute of the sleep timer to add five minutes.',),
      switchRow('autoplay', 'Auto-play the next chapter', r.autoPlayNext, (v) => n.put({'autoPlayNext': v}), description: profile),
      switchRow('keep-player', 'Keep the player visible', r.keepPlayerVisible, (v) => n.put({'keepPlayerVisible': v}), description: profile),
    ],);
  }
}

class _SleepList extends StatelessWidget {
  const _SleepList({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final e in _sleepLabels.entries)
          CineRadio<String>(value: e.key, groupValue: current, label: e.value, onChanged: (v) => Navigator.of(context).pop(v)),
      ],),
    );
  }
}

/// The voice list in browse mode (kicker `THE VOICES`, filters, search; no casting).
// TODO(mobile/15): replace with the Listen step's voice picker in browse mode (with `Hear`).
class VoiceBrowseList extends ConsumerStatefulWidget {
  const VoiceBrowseList({super.key});

  @override
  ConsumerState<VoiceBrowseList> createState() => _VoiceBrowseListState();
}

class _VoiceBrowseListState extends ConsumerState<VoiceBrowseList> {
  String _filter = 'all', _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final voices = ref.watch(novelVoicesProvider);
    return voices.when(
      loading: () => Padding(padding: EdgeInsets.all(c.space6), child: CineRoleText('LOADING', c.typeKicker, color: c.colorInk60)),
      error: (_, __) => Padding(padding: EdgeInsets.all(c.space6), child: CineRoleText("The voices didn't load.", c.typeUi)),
      data: (all) {
        int count(String g) => all.where((v) => g == 'all' || v.gender.toLowerCase().startsWith(g[0])).length;
        final shown = [
          for (final v in all)
            if ((_filter == 'all' || v.gender.toLowerCase().startsWith(_filter[0])) &&
                (_q.isEmpty || matchSettings(_q, [SettingsRowRef(id: v.voiceId, section: '', label: v.name, keywords: [v.character])]).isNotEmpty))
              v,
        ];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: c.space4),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CineSlugLines(
              items: [CineSlug('all', 'ALL', count: count('all')), CineSlug('female', 'FEMALE', count: count('female')), CineSlug('male', 'MALE', count: count('male'))],
              selected: {_filter},
              onChanged: (v) => setState(() => _filter = v),
            ),
            SizedBox(height: c.space2),
            CineSearchField(semanticLabel: 'Search voices', placeholder: 'Search voices', variant: CineSearchVariant.compact, onChanged: (v) => setState(() => _q = v)),
            SizedBox(height: c.space2),
            for (final NovelVoice v in shown)
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
                alignment: Alignment.centerLeft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  CineRoleText(v.name, c.typeUi),
                  if (v.character.isNotEmpty) CineRoleText(v.character, c.typeCaption, color: c.colorInk60),
                ],),
              ),
          ],),
        );
      },
    );
  }
}
