import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/providers/soundscape_defaults_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/skin.dart' show SkinId;
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart' show skinIdProvider;

/// The "Feel it" sequence (glass 5.3): five feels 400 ms apart.
const List<String> kFeelItNames = ['selection', 'soft 0.5', 'rigid 0.6', 'droplet', 'success'];
const Duration kFeelItGap = Duration(milliseconds: 400);

/// The "Hear it" sequence (glass 6): seven cues 300 ms apart.
const List<({SoundEvent event, int depth})> kHearItCues = [
  (event: SoundEvent.tapPrimary, depth: 1),
  (event: SoundEvent.navPush, depth: 1),
  (event: SoundEvent.navPush, depth: 2),
  (event: SoundEvent.navPush, depth: 3),
  (event: SoundEvent.navPush, depth: 4),
  (event: SoundEvent.navPop, depth: 1),
  (event: SoundEvent.followAdd, depth: 1),
];
const Duration kHearItGap = Duration(milliseconds: 300);

typedef FeelPlayer = Future<void> Function(int index);
typedef HearPlayer = Future<void> Function(int index, double levelDb);

/// Settings -> Sound and haptics (glass 8.25.5). Haptics and UI sounds are per device; the soundscape defaults are per profile and
/// saved on this device (`mm.soundscape.defaults`).
class FeedbackSection extends ConsumerStatefulWidget {
  const FeedbackSection({super.key, this.feelPlayer, this.hearPlayer, this.showHaptics});
  final FeelPlayer? feelPlayer;
  final HearPlayer? hearPlayer;

  /// Defaults to apps (iOS and Android).
  final bool? showHaptics;

  @override
  ConsumerState<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends ConsumerState<FeedbackSection> {
  late SoundPrefs _sounds = ref.read(skinAudioProvider).readSoundPrefs(SkinId.glass);
  bool _feeling = false, _hearing = false;

  bool get _apps => widget.showHaptics ?? (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _writeSounds(SoundPrefs p) async {
    setState(() => _sounds = p);
    await ref.read(skinAudioProvider).writeSoundPrefs(SkinId.glass, p);
  }

  Future<void> _defaultFeel(int i) => playFeelSample(i);

  Future<void> _defaultHear(int i, double level) async {
    final c = kHearItCues[i];
    await ref.read(skinAudioProvider).preview(SkinId.glass, c.event, depth: c.depth, level: level);
  }

  Future<void> _feel() async {
    if (_feeling) return;
    setState(() => _feeling = true);
    for (var i = 0; i < kFeelItNames.length; i++) {
      await (widget.feelPlayer ?? _defaultFeel)(i);
      if (i < kFeelItNames.length - 1) await Future<void>.delayed(kFeelItGap);
    }
    if (mounted) setState(() => _feeling = false);
  }

  Future<void> _hear() async {
    if (_hearing) return;
    setState(() => _hearing = true);
    for (var i = 0; i < kHearItCues.length; i++) {
      await (widget.hearPlayer ?? _defaultHear)(i, _sounds.level);
      if (i < kHearItCues.length - 1) await Future<void>.delayed(kHearItGap);
    }
    if (mounted) setState(() => _hearing = false);
  }

  @override
  Widget build(BuildContext context) {
    final haptics = ref.watch(hapticFeedbackProvider);
    final hapticsNotifier = ref.read(hapticFeedbackProvider.notifier);
    ref.watch(skinIdProvider);
    return Column(children: [
      if (_apps)
        SettingsGroup(header: 'Haptics', footer: 'Saved on this device.', children: [
          SettingsSwitchRow(id: 'haptics', title: 'Haptics', value: haptics, onChanged: (v) => unawaited(hapticsNotifier.setEnabled(v))),
          SettingsRow(
            id: 'haptics-feel',
            title: 'Feel it',
            caption: haptics ? null : 'Turn haptics on to feel them.',
            enabled: haptics && !_feeling,
            onTap: haptics ? () => unawaited(_feel()) : null,
            caret: true,
          ),
        ],),
      SettingsGroup(header: 'UI sounds', footer: 'Saved on this device.', children: [
        SettingsSwitchRow(id: 'ui-sounds', title: 'UI sounds', value: _sounds.on, onChanged: (v) => unawaited(_writeSounds(SoundPrefs(on: v, level: _sounds.level)))),
        SettingsSliderBlock(
          id: 'ui-sounds-volume',
          title: 'Volume',
          value: _sounds.level.clamp(-24, 0),
          min: -24,
          max: 0,
          divisions: 24,
          format: (v) => '${v.round()} dB',
          onChanged: (v) => unawaited(_writeSounds(SoundPrefs(on: _sounds.on, level: v.roundToDouble()))),
        ),
        SettingsRow(id: 'ui-sounds-hear', title: 'Hear it', enabled: !_hearing, onTap: () => unawaited(_hear()), caret: true),
      ],),
      const _SoundscapeGroup(),
    ],);
  }
}

class _SoundscapeGroup extends ConsumerWidget {
  const _SoundscapeGroup();

  static const _scenes = [
    ('off', 'Off', SettingsGlyphs.speakerSlash),
    ('rain', 'Rain', SettingsGlyphs.cloudRain),
    ('wind', 'Wind', SettingsGlyphs.wind),
    ('ocean', 'Ocean', SettingsGlyphs.waves),
    ('hearth', 'Hearth', SettingsGlyphs.campfire),
    ('stream', 'Stream', SettingsGlyphs.dropHalf),
    ('deep', 'Deep', SettingsGlyphs.moonStars),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(soundscapeDefaultsProvider);
    final n = ref.read(soundscapeDefaultsRecordProvider.notifier);
    String pct(double v) => '${(v * 100).round()}%';
    return SettingsGroup(id: 'soundscape', header: 'Soundscape defaults', footer: 'Saved on this device.', children: [
      SettingsBlock(
        id: 'soundscape-scene',
        title: 'Soundscape',
        child: Semantics(
          label: 'Soundscape',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in _scenes)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: d.scene == s.$1,
                label: s.$2,
                button: true,
                excludeSemantics: true,
                child: GestureDetector(behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(n.setScene(s.$1)),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gt.colorFill2,
                      border: d.scene == s.$1 ? Border.all(color: gt.colorIris500, width: 2) : null,
                    ),
                    child: GlyphIcon(s.$3, color: gt.colorLabel1),
                  ),
                ),
              ),
          ],),
        ),
      ),
      SettingsSwitchRow(id: 'soundscape-match', title: 'Match the story', value: d.matchStory, onChanged: (v) => unawaited(n.setMatchStory(v))),
      SettingsSliderBlock(id: 'soundscape-mix', title: 'Bed', value: d.bed, divisions: 10, format: pct, onChanged: (v) => unawaited(n.setMix('bed', v))),
      SettingsSliderBlock(id: 'soundscape-mix-detail', title: 'Detail', value: d.detail, divisions: 10, format: pct, onChanged: (v) => unawaited(n.setMix('detail', v))),
      SettingsSliderBlock(id: 'soundscape-mix-tone', title: 'Tone', value: d.tone, divisions: 10, format: pct, onChanged: (v) => unawaited(n.setMix('tone', v))),
      SettingsSliderBlock(
        id: 'soundscape-volume',
        title: 'Volume',
        value: d.volumeDb.toDouble(),
        min: -30,
        max: 0,
        divisions: 30,
        format: (v) => '${v.round()} dB',
        onChanged: (v) => unawaited(n.setVolumeDb(v.round())),
      ),
      SettingsSwitchRow(id: 'soundscape-lower', title: 'Lower under narration', value: d.lowerUnderNarration, onChanged: (v) => unawaited(n.setLowerUnderNarration(v))),
    ],);
  }
}
