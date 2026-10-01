import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/arrival_toast.dart';

/// glass 8.25.2 step 7: "Switched to Glass" + Undo shows only for a fresh arrival from Cinematic.
void main() {
  group('arrival toast condition', () {
    final now = DateTime(2026, 10, 1, 12);
    int ago(int ms) => now.millisecondsSinceEpoch - ms;
    test('fresh', () => expect(glassArrivalToastDue('cinematic', ago(3000), now), isTrue));
    test('stale', () => expect(glassArrivalToastDue('cinematic', ago(10000), now), isFalse));
    test('wrong previous skin', () {
      expect(glassArrivalToastDue('glass', ago(10), now), isFalse);
      expect(glassArrivalToastDue(null, ago(10), now), isFalse);
    });
    test('t0 already consumed by the boot timing log is fresh', () => expect(glassArrivalToastDue('cinematic', null, now), isTrue));
  });
}
