import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/listen_settings.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';

void main() {
  test('defaults', () {
    const s = ListenSettings();
    expect(s.speed, 1.0);
    expect(s.sleepDefault, 'off');
    expect(s.shakeToExtend, isTrue);
    expect(s.autoPlayNext, isTrue);
    expect(s.keepPlayerVisible, isFalse);
    expect(ListenSettings.fromRecord(const JsonRecord()), s);
  });

  test('normalisers clamp, snap and reject garbage', () {
    final s = ListenSettings.fromRecord(const JsonRecord({'speed': 7, 'sleepDefault': 'soon', 'shakeToExtend': 'yes'}));
    expect(s.speed, 3.0);
    expect(s.sleepDefault, 'off');
    expect(s.shakeToExtend, isTrue);
    expect(normaliseListenSpeed(0.1), 0.5);
    expect(normaliseListenSpeed(1.27), 1.25);
    expect(normaliseListenSpeed(1.28), 1.30);
  });

  test('unknown fields survive a merge', () {
    final r = const JsonRecord({'speed': 1.5, 'future': 'kept'}).merge({'speed': 2});
    expect(r.data['future'], 'kept');
    expect(ListenSettings.fromRecord(r).speed, 2.0);
  });

  test('sleepChoice parses the stored default', () {
    expect(ListenSettings.fromRecord(const JsonRecord({'sleepDefault': '30'})).sleepChoice, SleepChoice.minutes(30));
    expect(ListenSettings.fromRecord(const JsonRecord({'sleepDefault': 'chapter'})).sleepChoice, SleepChoice.endOfChapter);
  });
}
