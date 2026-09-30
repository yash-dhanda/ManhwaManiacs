import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The eight soundscape loops and their lines (cinematic 9.4.2).
const kSoundscapeLoops = <(String, String, String)>[
  ('projector-room', 'Projector room', 'A soft hum with distant reel ticks.'),
  ('rain-on-glass', 'Rain on glass', 'Steady rain on a window.'),
  ('night-city', 'Night city', 'Distant traffic after dark.'),
  ('cafe', 'Café', 'Low voices and cups.'),
  ('night-wind', 'Night wind', 'Wind across an empty street.'),
  ('low-drone', 'Low drone', 'A deep, even hum.'),
  ('afternoon-park', 'Afternoon park', 'Birds and far-off voices.'),
  ('temple-bells', 'Temple bells', 'Slow bells over a quiet courtyard.'),
];

/// Ambient (cinematic 8.30.2 row 6). No sound plays here: the loops, the player and `Hear` are
/// mobile/23's (it fills the trailing slot of each loop row).
class AmbientSection extends ConsumerWidget {
  const AmbientSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final r = ref.watch(readerSettingsProvider);
    final n = ref.read(readerSettingsProvider.notifier);
    final novels = ref.read(novelSettingsProvider.notifier);
    final vol = ref.watch(soundscapeVolumeProvider);
    final d = r.seriesDefaults;
    final g = r.guidedAutoAdvance;
    const profile = 'Saved for this profile';
    final sc = r.soundscape;

    Future<void> choose(String v) async {
      await n.put({'soundscape': v});
      await novels.put({'soundscape': v});
    }

    Widget option(String id, String label, {String? line}) => Padding(
          padding: EdgeInsets.symmetric(vertical: c.space1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CineRadio<String>(value: id, groupValue: sc, label: label, onChanged: choose),
                if (line != null) Padding(padding: const EdgeInsets.only(left: 36), child: CineRoleText(line, c.typeCaption, color: c.colorInk60)),
              ],),
            ),
            // mobile/23 puts `Hear` (secondary sm) here.
            SizedBox(key: Key('hear-slot-$id'), width: 0),
          ],),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('SOUNDSCAPE'),
      SettingsBlock(
        id: 'soundscape',
        label: 'Soundscape default',
        description: 'Used by manga and novels. $profile.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          option('off', 'OFF'),
          option('match', 'MATCH THE MOOD'),
          for (final (id, label, line) in kSoundscapeLoops) option(id, label, line: line),
        ],),
      ),
      sliderRow('soundscape-volume', 'Soundscape volume', vol * 100, (v) => ref.read(soundscapeVolumeProvider.notifier).set(v.round() / 100),
          min: 0, max: 100, divisions: 100, flag: (v) => '${v.round()} %', description: 'Saved on this device.',),
      switchRow('pause-narration', 'Pause the soundscape during narration', r.pauseSoundscapeForNarration, (v) => n.put({'pauseSoundscapeForNarration': v}),
          description: 'Otherwise it drops to 30 % while a chapter is read aloud.',),
      const SettingsKicker('THE PAGE'),
      switchRow('page-tint', 'Page-tinted chrome', r.pageTint, (v) => n.put({'pageTint': v}), description: profile),
      sliderRow('autoscroll-speed', 'Auto-scroll default speed', d.autoScrollSpeed, (v) => n.setSeriesDefaults(d.copyWith(autoScrollSpeed: (v * 20).round() / 20)),
          min: 0.5, max: 3.0, divisions: 50, flag: (v) => '${v.toStringAsFixed(2)}×',),
      switchRow('resume-after', 'Resume after I let go', r.resumeAfterRelease, (v) => n.put({'resumeAfterRelease': v}), description: profile),
      switchRow('pace-dialogue', 'Pace by dialogue', r.paceByDialogue, (v) => n.put({'paceByDialogue': v}), description: profile),
      switchRow('guided-advance', 'Guided view auto-advance', g.on, (v) => n.setGuided(on: v), description: profile),
      if (g.on) ...[
        segmentedRow('guided-mode', 'Advance', const ['PACE BY WORDS', 'FIXED'], g.mode == 'FIXED' ? 1 : 0, (i) => n.setGuided(mode: i == 1 ? 'FIXED' : 'PACE_BY_WORDS')),
        if (g.mode == 'FIXED')
          sliderRow('guided-fixed', 'Hold each panel', g.fixedMs / 1000, (v) => n.setGuided(fixedMs: (v * 2).round() * 500), min: 2, max: 10, divisions: 16, flag: (v) => '${v.toStringAsFixed(1)} s'),
      ],
    ],);
  }
}
