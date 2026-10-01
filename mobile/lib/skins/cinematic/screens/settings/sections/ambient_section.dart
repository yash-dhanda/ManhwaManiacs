import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/soundscape_picker.dart';

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

/// Ambient (cinematic 8.30.2 row 6). The picker (`Hear` included) is the shared
/// `SoundscapePicker`; a choice here plays only through `Hear`, the readers start the loop.
class AmbientSection extends ConsumerWidget {
  const AmbientSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(readerSettingsProvider);
    final n = ref.read(readerSettingsProvider.notifier);
    final d = r.seriesDefaults;
    final g = r.guidedAutoAdvance;
    const profile = 'Saved for this profile';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('SOUNDSCAPE'),
      const SoundscapePicker(),
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
          // Half-second steps over the stored milliseconds: 4..20 is 2-10 s.
          stepperRow('guided-fixed', 'Hold each panel', (g.fixedMs / 500).round(), (i) => n.setGuided(fixedMs: i * 500),
              min: 4, max: 20, format: (i) => '${(i / 2).toStringAsFixed(1)} s',),
      ],
    ],);
  }
}
