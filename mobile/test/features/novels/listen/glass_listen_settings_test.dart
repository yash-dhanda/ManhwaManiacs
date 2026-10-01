import 'package:audio_service/audio_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/listen_settings.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/skins/skin.dart';

AccelSample peak(DateTime t, int ms) => (x: 25, y: 0, z: 0, at: t.add(Duration(milliseconds: ms)));
AccelSample calm(DateTime t, int ms) => (x: 0, y: 0, z: 0, at: t.add(Duration(milliseconds: ms)));

void main() {
  test('A3: notification colour is Glass iris600 only when the boot skin is Glass', () {
    expect(narrationAudioServiceConfig(SkinId.glass).notificationColor, const Color(0xFF7563F2));
    expect(narrationAudioServiceConfig(SkinId.cinematic).notificationColor, const Color(0xFFF4D03F));
    final c = narrationAudioServiceConfig(SkinId.glass);
    expect(c.androidNotificationIcon, 'drawable/ic_stat_mm');
    expect(c.androidNotificationChannelName, 'Listen');
    expect(c.fastForwardInterval, const Duration(seconds: 15));
  });

  test('A5: glassShakeToExtend defaults off and is not Cinematic shakeToExtend', () {
    final s = ListenSettings.fromRecord(const JsonRecord());
    expect(s.glassShakeToExtend, false);
    expect(s.shakeToExtend, true);
    expect(ListenSettings.fromRecord(const JsonRecord({'glassShakeToExtend': true})).glassShakeToExtend, true);
  });

  test('A5: Glass counter: two peaks 280 ms apart shake, 320 ms do not', () {
    final t = DateTime(2026);
    bool run(int gap) {
      final c = ShakeCounter(threshold: kGlassShakeThresholdMs2, window: kGlassShakeWindow);
      c.add(peak(t, 0));
      c.add(calm(t, 100));
      return c.add(peak(t, gap));
    }

    expect(run(280), true);
    expect(run(320), false);
    // 2.2 g is 21.57 m/s2: a 20 reading is not a peak.
    final c = ShakeCounter(threshold: kGlassShakeThresholdMs2, window: kGlassShakeWindow);
    expect(c.add((x: 20, y: 0, z: 0, at: t)), false);
  });

  test('A2: the Cinematic control set is unchanged', () {
    expect(NarrationControlSet.cinematic.controls(playing: false), [MediaControl.rewind, MediaControl.play, MediaControl.fastForward, MediaControl.skipToNext]);
    expect(NarrationControlSet.cinematic.compactIndices, [0, 1, 2]);
  });
}
