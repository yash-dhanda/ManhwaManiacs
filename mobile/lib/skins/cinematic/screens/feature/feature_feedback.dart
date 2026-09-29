import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// One haptic (and optionally one sound) for a moment; never throws, so a
/// missing platform channel (tests, desktop) never breaks a tap.
void feedback(WidgetRef ref, HapticEvent haptic, [SoundEvent? sound]) {
  try {
    unawaited(ref.read(skinHapticsProvider).fire(haptic).catchError((Object _) {}));
  } catch (_) {}
  if (sound != null) {
    try {
      unawaited(SkinAudio.instance.play(sound).catchError((Object _) {}));
    } catch (_) {}
  }
}
