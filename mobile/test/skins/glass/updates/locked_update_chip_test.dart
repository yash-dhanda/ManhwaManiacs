import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/skins/glass/screens/updates/notification_list.dart';

import '../primitives/support.dart';

void main() {
  final open = DateTime.utc(2026, 11, 23, 14);
  late DateTime now;
  setUp(() => now = open.subtract(const Duration(hours: 3, minutes: 27, seconds: 14)));

  UpdateChapter chapter({DateTime? until}) =>
      (notificationId: 2, chapterKey: 'c370', chapterNumber: 370, title: 'Chapter 370', read: false, lockedUntil: until);

  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(primHost(child, overrides: [clockProvider.overrideWithValue(() => now)]));

  testWidgets('a locked chapter chip says when it opens and goes back to plain once it has', (t) async {
    await pump(t, UpdateChapterChip(chapter: chapter(until: open), onPressed: () {}));
    expect(find.text('Ch 370 · 3 h 28 min'), findsOneWidget);
    now = open;
    await t.pump(const Duration(hours: 3, minutes: 27, seconds: 14));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Ch 370'), findsOneWidget);
  });

  testWidgets('an open chapter chip is untouched', (t) async {
    await pump(t, UpdateChapterChip(chapter: chapter(), onPressed: () {}));
    expect(find.text('Ch 370'), findsOneWidget);
  });

  testWidgets('the status line ticks and disappears at zero with no refetch', (t) async {
    await pump(t, LockedOpensIn(lockedUntil: open));
    expect(find.text('Opens in 3:27:14'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    now = now.add(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Opens in 3:27:13'), findsOneWidget);
    now = open;
    await t.pump(const Duration(seconds: 1));
    expect(find.textContaining('Opens in'), findsNothing);
  });
}
