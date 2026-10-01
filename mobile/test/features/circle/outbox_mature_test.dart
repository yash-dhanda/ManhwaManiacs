import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/store/reaction_outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dropMature removes only the 18+ entries, and the flag survives storage', () async {
    SharedPreferences.setMockInitialValues({});
    final box = ReactionOutbox(await SharedPreferences.getInstance(), 'u1p1');
    await box.enqueue(OutboxEntry(sourceId: 's', seriesKey: 'adult', chapterKey: '1', kind: ReactionKind.hype, at: DateTime.utc(2026), mature: true));
    await box.enqueue(OutboxEntry(sourceId: 's', seriesKey: 'safe', chapterKey: '1', kind: ReactionKind.loved, at: DateTime.utc(2026)));
    expect(box.entries().map((e) => (e.seriesKey, e.mature)), [('adult', true), ('safe', false)]);
    await box.dropMature();
    expect(box.entries().map((e) => e.seriesKey), ['safe']);
  });
}
