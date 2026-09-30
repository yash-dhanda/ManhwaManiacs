import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_phase.dart';

void main() {
  test('picks step through the timers 0, 1.5, 4 and 15 s', () {
    fakeAsync((t) {
      final c = AiPhaseClock(active: true, kind: AiPhaseKind.picks);
      expect(c.line, 'Reading your library');
      t.elapse(const Duration(milliseconds: 1400));
      expect(c.line, 'Reading your library');
      t.elapse(const Duration(milliseconds: 200));
      expect(c.line, 'Asking for ideas');
      t.elapse(const Duration(milliseconds: 2500));
      expect(c.line, 'Checking which of your sources have them');
      t.elapse(const Duration(seconds: 11));
      expect(c.line, 'Still working. This can take up to a minute.');
      expect(c.abandoned, isFalse);
      c.dispose();
    });
  });

  test('a recap writes, and after 40 s the request is abandoned', () {
    fakeAsync((t) {
      final c = AiPhaseClock(active: true, kind: AiPhaseKind.recap);
      var notified = 0;
      c.addListener(() => notified++);
      expect(c.line, 'Writing your recap');
      t.elapse(const Duration(seconds: 39));
      expect(c.abandoned, isFalse);
      t.elapse(const Duration(seconds: 2));
      expect(c.abandoned, isTrue);
      expect(c.line, 'That took too long. Try again.');
      expect(notified, 1);
      c.dispose();
    });
  });

  test('the server phase wins while present and the timers resume without it', () {
    fakeAsync((t) {
      final c = AiPhaseClock(active: true, kind: AiPhaseKind.picks);
      c.setServerPhase('Ranking candidates');
      t.elapse(const Duration(seconds: 5));
      expect(c.line, 'Ranking candidates');
      c.setServerPhase(null);
      expect(c.line, 'Checking which of your sources have them');
      c.dispose();
    });
  });

  test('an inactive clock says nothing until started', () {
    fakeAsync((t) {
      final c = AiPhaseClock(active: false, kind: AiPhaseKind.picks);
      expect(c.line, '');
      c.start();
      expect(c.line, 'Reading your library');
      c.stop();
      t.elapse(const Duration(seconds: 60));
      expect(c.abandoned, isFalse);
      c.dispose();
    });
  });
}
