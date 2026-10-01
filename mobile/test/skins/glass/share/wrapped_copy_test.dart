import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_copy.dart';

import '../../../support/numbers_fixtures.dart';

void main() {
  final a = Annual.fromJson({
    ...annualJson(partial: false),
    'busiest_day': {'date': '2026-03-14', 'chapters': 42, 'series': <Object?>[]},
    'firsts_lasts': {
      'first': {'series': {'title': 'Tower of God'}, 'read_at': '2026-01-05T10:00:00Z'},
      'last': {'series': {'title': 'Lookism'}, 'read_at': '2026-09-01T10:00:00Z'},
    },
  });

  test('the copy follows the card table', () {
    expect(wrappedCopy(WrappedCard.cover, a, profileName: 'Yash').headline, 'Your 2026 in chapters');
    expect(wrappedCopy(WrappedCard.cover, a, profileName: 'Yash').footnote, 'Yash');
    expect(wrappedCopy(WrappedCard.time, a).footnote, 'Counted while a chapter was open.');
    final v = wrappedCopy(WrappedCard.volume, a);
    expect(v.headline, '4,812 chapters · 96,000 pages');
    expect(v.footnote, 'Busiest month: August');
    expect(wrappedCopy(WrappedCard.topFive, a).footnote, '12 h with Solo Leveling');
    expect(wrappedCopy(WrappedCard.genres, a).headline, 'Mostly fantasy and romance');
    expect(wrappedCopy(WrappedCard.genres, a).footnote, 'Fantasy 50 % · Romance 30 % · Action 20 %');
    expect(wrappedCopy(WrappedCard.when, a).headline, "You're a night reader");
    expect(wrappedCopy(WrappedCard.streak, a).headline, '31 days in a row');
    expect(wrappedCopy(WrappedCard.streak, a).footnote, 'From 1 Mar to 31 Mar');
    expect(wrappedCopy(WrappedCard.busiestDay, a).headline, 'Saturday 14 March');
    expect(wrappedCopy(WrappedCard.firstsLasts, a).headline, 'From Tower of God to Lookism');
    expect(firstsLastsTitles(a).firstMonth, 'January');
    expect(wrappedCopy(WrappedCard.topSource, a).headline, 'Most of it came from MangaDex');
    expect(wrappedCopy(WrappedCard.together, a, togetherName: 'Riya', togetherTitle: 'Solo Leveling').headline, 'You and Riya both read Solo Leveling');
    expect(wrappedCopy(WrappedCard.summary, a).headline, 'Your year');
    expect(wrappedDays(a), 9);
    expect(wrappedHours(a), 212);
    expect(cardLabel(WrappedCard.volume, 2, 12), 'Card 3 of 12: Volume');
    expect(busiestChapters(a), 42);
  });
}
