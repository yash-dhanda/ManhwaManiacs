import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// Fires a haptic event (and a cue) through the skin's single-sourced event map. Never throws:
/// a tree without a `ProviderScope`, or a device without a motor, is silent.
void cineFeedback(BuildContext context, HapticEvent haptic, {SoundEvent? sound}) {
  try {
    final c = ProviderScope.containerOf(context, listen: false);
    unawaited(c.read(skinHapticsProvider).fire(haptic).catchError((Object _) {}));
  } catch (_) {}
  if (sound != null) {
    try {
      unawaited(SkinAudio.instance.play(sound).catchError((Object _) {}));
    } catch (_) {}
  }
}
