// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/utils/headline.dart';

DateTime at(int h, [int m = 0]) => DateTime(2026, 9, 30, h, m);

void main() {
  test('time words by local hour', () {
    expect(timeWord(at(4, 59)), 'Tonight');
    expect(timeWord(at(5)), 'This morning');
    expect(timeWord(at(11, 59)), 'This morning');
    expect(timeWord(at(12)), 'This afternoon');
    expect(timeWord(at(17, 59)), 'This afternoon');
    expect(timeWord(at(18)), 'Tonight');
  });

  test('case 1, 2, 3, 4, 4b, 5, caught up, verbatim', () {
    final now = at(21);
    var r = composeHeadline(HeadlineInput(kind: HeadlineCase.newChapters, now: now, title: 'Omniscient Reader', chapter: '143', deck: 'Dokja meets the author.'));
    expect((r.headline, r.deck, r.titleInKicker), ('Tonight: chapter 143 of Omniscient Reader.', 'Dokja meets the author.', false));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.inProgress, now: now, title: 'X', chapter: '142', page: 28, pageCount: 40, daysAgo: 2));
    expect((r.headline, r.deck), ('Tonight: finish chapter 142. Twelve pages left.', 'You were on page 28 of 40 two days ago.'));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.paused, now: now, title: 'Tower of God', chapter: '87', pausedDays: 23, recapReady: true));
    expect((r.headline, r.deck), ('Tonight: back to Tower of God.', 'You paused 23 days ago at chapter 87. Previously on is ready.'));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.aiPick, now: now, title: 'Lookism', deck: 'Because you like fights.'));
    expect((r.headline, r.deck), ('Tonight: start Lookism.', 'Because you like fights.'));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.firstPick, now: now, title: 'Omniscient Reader'));
    expect((r.headline, r.deck), ('Tonight: start Omniscient Reader.', 'Chapter 1 is waiting. The rest of your picks are below.'));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.newProfile, now: now));
    expect((r.headline, r.deck), ('Your first issue starts here.', 'Follow three series and this page fills itself in.'));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.caughtUp, now: now));
    expect((r.headline, r.deck), ("Tonight: you're caught up.", "Nothing new on your shelf. Here's something else."));
  });

  test('the 60-grapheme fallbacks move the title to the kicker', () {
    const long = 'The Extraordinarily Long Title of a Series Nobody Can Say';
    final now = at(21);
    var r = composeHeadline(HeadlineInput(kind: HeadlineCase.newChapters, now: now, title: long, chapter: '143'));
    expect((r.headline, r.titleInKicker), ('Tonight: chapter 143.', true));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.paused, now: now, title: long, chapter: '87', pausedDays: 30));
    expect((r.headline, r.titleInKicker), ('Tonight: back to chapter 87.', true));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.aiPick, now: now, title: long));
    expect((r.headline, r.titleInKicker), ('Tonight: start chapter 1.', true));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.firstPick, now: now, title: long));
    expect((r.headline, r.titleInKicker), ('Tonight: start chapter 1.', true));
    // Case 2 drops its second sentence.
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.inProgress, now: at(14), title: 'x', chapter: '1142.5', page: 1, pageCount: 40));
    expect(r.headline, 'This afternoon: finish chapter 1142.5.');
  });

  test('at risk overrides cases 1-4b, with the fallback line past 60 graphemes', () {
    var r = composeHeadline(HeadlineInput(kind: HeadlineCase.newChapters, now: at(20, 30), title: 'X', chapter: '1', atRisk: true, streakDays: 12));
    expect((r.headline, r.deck), ('Twelve days and counting. One chapter keeps it alive.', 'Open any chapter before midnight to keep your streak.'));
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.inProgress, now: at(20, 30), title: 'X', chapter: '1', page: 1, pageCount: 4, atRisk: true, streakDays: 101));
    expect(r.headline, 'Your 101-day streak ends at midnight.');
    r = composeHeadline(HeadlineInput(kind: HeadlineCase.caughtUp, now: at(21), atRisk: true, streakDays: 12));
    expect(r.headline, "Tonight: you're caught up.");
  });

  test('spellCount', () {
    expect(spellCount(2), 'Two');
    expect(spellCount(12), 'Twelve');
    expect(spellCount(31), 'Thirty-one');
    expect(spellCount(99), 'Ninety-nine');
    expect(spellCount(100), 'One hundred');
    expect(spellCount(101), 'One hundred and one');
    expect(spellCount(123), 'One hundred and twenty-three');
    expect(spellCount(12, capitalise: false), 'twelve');
  });
}
