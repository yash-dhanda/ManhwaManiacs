import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';

void main() {
  test('the ambient fields default as the prompt says', () {
    const r = JsonRecord();
    expect(r.soundscape, 'off');
    expect(r.pauseSoundscapeForNarration, isFalse);
    expect(r.paceByDialogue, isFalse);
    expect(r.pageTint, isTrue);
    expect(r.resumeAfterRelease, isTrue);
    expect(r.guidedAutoAdvance.on, isFalse);
    expect(r.guidedAutoAdvance.mode, 'PACE_BY_WORDS');
    expect(r.guidedAutoAdvance.fixedMs, 3500);
  });

  test('every field round trips and unknown fields survive', () {
    final r = const JsonRecord({'future': 7}).merge({
      'soundscape': 'temple-bells',
      'pauseSoundscapeForNarration': true,
      'paceByDialogue': true,
      'pageTint': false,
      'resumeAfterRelease': false,
      'guidedAutoAdvance': {'on': true, 'mode': 'FIXED', 'fixedMs': 5000},
    });
    final back = JsonRecord.decode(r.encode());
    expect(back.soundscape, 'temple-bells');
    expect(back.pauseSoundscapeForNarration, isTrue);
    expect(back.paceByDialogue, isTrue);
    expect(back.pageTint, isFalse);
    expect(back.resumeAfterRelease, isFalse);
    expect(back.guidedAutoAdvance.on, isTrue);
    expect(back.guidedAutoAdvance.mode, 'FIXED');
    expect(back.guidedAutoAdvance.fixedMs, 5000);
    expect(back.data['future'], 7);
  });

  test('the fixed hold clamps to 2-10 s', () {
    expect(const JsonRecord({'guidedAutoAdvance': {'fixedMs': 500}}).guidedAutoAdvance.fixedMs, 2000);
    expect(const JsonRecord({'guidedAutoAdvance': {'fixedMs': 99999}}).guidedAutoAdvance.fixedMs, 10000);
  });
}
