import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 'android/app/src/main';
  test('MainActivity extends AudioServiceActivity', () {
    final src = File('$base/kotlin/com/manhwamaniacs/reader/MainActivity.kt').readAsStringSync();
    expect(src, contains('class MainActivity : AudioServiceActivity()'));
  });

  test('manifest declares the audio_service service, receiver and permissions', () {
    final m = File('$base/AndroidManifest.xml').readAsStringSync();
    expect(m, contains('com.ryanheise.audioservice.AudioService'));
    expect(m, contains('com.ryanheise.audioservice.MediaButtonReceiver'));
    expect(m, contains('android:foregroundServiceType="mediaPlayback"'));
    for (final p in ['WAKE_LOCK', 'FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MEDIA_PLAYBACK', 'VIBRATE']) {
      expect(m, contains('android.permission.$p"'));
    }
    expect(m, contains('android:enableOnBackInvokedCallback="true"'));
  });
}
