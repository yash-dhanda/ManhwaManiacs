import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/greeting.dart';

void main() {
  test('the four buckets at their edges', () {
    String g(int h, int m) => greetingFor(DateTime(2026, 9, 30, h, m), 'Yash');
    expect(g(4, 59), 'Good night, Yash');
    expect(g(5, 0), 'Good morning, Yash');
    expect(g(11, 59), 'Good morning, Yash');
    expect(g(12, 0), 'Good afternoon, Yash');
    expect(g(16, 59), 'Good afternoon, Yash');
    expect(g(17, 0), 'Good evening, Yash');
    expect(g(21, 59), 'Good evening, Yash');
    expect(g(22, 0), 'Good night, Yash');
    expect(g(0, 0), 'Good night, Yash');
  });

  final noon = DateTime(2026, 9, 30, 12);
  test('pieces, plurals and joining', () {
    expect(greetingSubline(unread: 3, streak: const HomeStreak(currentDays: 12), now: noon).text, '3 new chapters · 12-day streak');
    expect(greetingSubline(unread: 1, streak: const HomeStreak(currentDays: 1), now: noon).text, '1 new chapter · 1-day streak');
    expect(greetingSubline(unread: 0, streak: const HomeStreak(currentDays: 4), now: noon).text, '4-day streak');
    expect(greetingSubline(unread: 2, streak: const HomeStreak(), now: noon).text, '2 new chapters');
    expect(greetingSubline(unread: 0, streak: const HomeStreak(), now: noon).isEmpty, isTrue);
  });

  test('at risk after 20:00 with two days and nothing read today', () {
    final night = DateTime(2026, 9, 30, 20, 30);
    final s = greetingSubline(unread: 5, streak: HomeStreak(currentDays: 7, lastActiveDate: DateTime(2026, 9, 29)), now: night);
    expect(s.atRisk, isTrue);
    expect(s.text, 'Read one chapter to keep your 7-day streak');
    final read = greetingSubline(unread: 0, streak: HomeStreak(currentDays: 7, lastActiveDate: DateTime(2026, 9, 30)), now: night);
    expect(read.atRisk, isFalse);
    final short = greetingSubline(unread: 0, streak: HomeStreak(currentDays: 1, lastActiveDate: DateTime(2026, 9, 29)), now: night);
    expect(short.atRisk, isFalse);
    // Read today on this device, before the feed's lastActiveDate catches up.
    final justRead = greetingSubline(unread: 0, streak: HomeStreak(currentDays: 7, lastActiveDate: DateTime(2026, 9, 29)), now: night, readToday: true);
    expect((justRead.atRisk, justRead.riskLine), (false, null));
  });
}
