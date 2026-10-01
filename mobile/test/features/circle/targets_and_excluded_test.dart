import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/excluded_series.dart';
import 'package:manhwamaniacs/features/circle/utils/recommend_targets.dart';

CircleMember m(int id, {required bool rec, bool? can}) => CircleMember(profileId: id, name: 'M$id', shares: CircleShares(recommendations: rec), canReceive: can);

void main() {
  test('recommendTargets: selectable, disabled, and gated members omitted', () {
    final t = recommendTargets([m(1, rec: true, can: true), m(2, rec: false, can: false), m(3, rec: true, can: false), m(4, rec: true)]);
    expect(t.selectable.map((e) => e.profileId), [1]);
    expect(t.disabled.map((e) => e.profileId), [2]);
  });

  test('toggleExcluded adds and removes by series', () {
    const a = ExcludedSeries(sourceId: 's', seriesKey: 'a', title: 'A');
    const b = ExcludedSeries(sourceId: 's', seriesKey: 'b', title: 'B');
    var list = toggleExcluded(const [], a);
    list = toggleExcluded(list, b);
    expect(list, [a, b]);
    list = toggleExcluded(list, const ExcludedSeries(sourceId: 's', seriesKey: 'a'));
    expect(list, [b]);
    expect(isExcluded(list, 's', 'b'), isTrue);
    expect(isExcluded(list, 's', 'a'), isFalse);
  });
}
