import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Feedback (cinematic 8.30.2 row 9): haptics with `Feel it`, and the per-profile UI sounds.
class FeedbackSection extends ConsumerStatefulWidget {
  const FeedbackSection({super.key});

  @override
  ConsumerState<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends ConsumerState<FeedbackSection> {
  SoundPrefs _read() => ref.read(skinAudioProvider).readSoundPrefs(ref.read(skinIdProvider));

  Future<void> _write(SoundPrefs p) async {
    await ref.read(skinAudioProvider).writeSoundPrefs(ref.read(skinIdProvider), p);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final haptics = ref.watch(hapticFeedbackProvider);
    final s = _read();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('TOUCH'),
      switchRow('haptics', 'Haptic feedback', haptics, ref.read(hapticFeedbackProvider.notifier).setEnabled, description: 'Saved on this device.'),
      JumpRow(
        id: 'feel-it',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          quietAction('Feel it', haptics ? () => cineFeedback(context, HapticEvent.followAdd) : null),
          if (!haptics) const SettingsCaption('Turn haptics on to feel them.'),
        ],),
      ),
      const SettingsKicker('SOUND'),
      switchRow('ui-sounds', 'UI sounds', s.on, (v) => _write(SoundPrefs(on: v, level: s.level)), description: 'Off by default. Saved for this profile.'),
      sliderRow('sound-volume', 'UI sound volume', s.level, (v) => _write(SoundPrefs(on: s.on, level: v.roundToDouble())),
          min: 0, max: 100, divisions: 100, flag: (v) => '${v.round()} %', disabled: !s.on,),
      JumpRow(
        id: 'play-sample',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          quietAction('Play a sample', s.on ? () => ref.read(skinAudioProvider).play(SoundEvent.tapPrimary) : null),
          if (!s.on) const SettingsCaption('Turn UI sounds on to hear them.'),
        ],),
      ),
    ],);
  }
}
