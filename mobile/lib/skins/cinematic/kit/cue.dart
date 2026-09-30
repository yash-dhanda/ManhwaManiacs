import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// Fires a haptic event and, when the profile has sound on, its cue.
/// Never throws: a device without the plugin just stays silent.
void cinematicCue(WidgetRef ref, HapticEvent haptic, [SoundEvent? sound]) {
  try {
    ref.read(skinHapticsProvider).fire(haptic);
  } catch (_) {}
  if (sound != null) {
    try {
      ref.read(skinAudioProvider).play(sound);
    } catch (_) {}
  }
}
