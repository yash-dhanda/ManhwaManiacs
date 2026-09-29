import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 21, 16);

  test('ago', () {
    expect(agoLabel(DateTime.utc(2026, 9, 30, 21, 4), now), '12 MIN AGO');
    expect(agoLabel(DateTime.utc(2026, 9, 30, 21, 15, 40), now), 'JUST NOW');
    expect(agoLabel(DateTime.utc(2026, 9, 30, 18, 16), now), '3 H AGO');
    expect(agoLabel(DateTime.utc(2026, 9, 25, 21, 16), now), '5 D AGO');
  });

  test('in', () {
    expect(inLabel(DateTime.utc(2026, 9, 30, 21, 34), now), 'IN 18 MIN');
    expect(inLabel(DateTime.utc(2026, 9, 30, 21, 10), now), 'DUE NOW');
  });

  test('interval and counts', () {
    expect(intervalLabel(30), '30 MIN');
    expect(intervalLabel(120), '2 H');
    expect(intervalLabel(1440), '1 D');
    expect(intervalLabel(90), '90 MIN');
    expect(runCountsLabel(212, 3), '212 SERIES · 3 NEW');
  });

  test('clock is two digits', () {
    expect(clockLabel(DateTime(2026, 9, 30, 9, 4)), '09:04');
  });
}
