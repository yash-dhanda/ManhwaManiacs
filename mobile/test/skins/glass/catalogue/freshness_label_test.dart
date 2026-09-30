import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/freshness_label.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 12);
  String at(Duration ago) => now.subtract(ago).toIso8601String();

  test('live copy reads "Updated 12 min ago"', () {
    final f = glassFreshness({'fetched_at': at(const Duration(minutes: 12))}, now)!;
    expect(f.text, 'Updated 12 min ago');
    expect(f.stale, isFalse);
  });

  test('stale copy reads "Saved copy · 2 h"', () {
    final f = glassFreshness({'stale': true, 'fetched_at': at(const Duration(hours: 2))}, now)!;
    expect(f.text, 'Saved copy · 2 h');
    expect(f.stale, isTrue);
  });

  test('offline copy names the age', () {
    final f = glassFreshness({'fetched_at': at(const Duration(hours: 2))}, now, offline: true)!;
    expect(f.text, 'Offline · saved copy from 2 h ago');
  });

  test('just now, days, and no block', () {
    expect(glassFreshness({'fetched_at': at(const Duration(seconds: 5))}, now)!.text, 'Updated just now');
    expect(glassFreshness({'fetched_at': at(const Duration(days: 3))}, now)!.text, 'Updated 3 d ago');
    expect(glassFreshness(null, now), isNull);
  });
}
