import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/headline.dart';

/// The client-side at-risk rule (cinematic 9.1.2): after 20:00 local, at least 2 days, nothing read today.
bool computeAtRisk(HomeStreak s, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final last = s.lastActiveDate;
  return now.hour >= 20 && s.currentDays >= 2 && (last == null || last.isBefore(today));
}

String _num(double? n) => n == null ? '' : (n == n.roundToDouble() ? '${n.round()}' : '$n');

/// The headline input a cover story stands for, so the headline can be recomposed on the device.
HeadlineInput headlineInputFor(HomeCover? cover, DateTime now, {required bool atRisk, required int streakDays}) {
  HeadlineInput of(HeadlineCase k) => HeadlineInput(
        kind: k,
        now: now,
        title: cover?.title,
        chapter: _num(cover?.chapterNumber),
        page: cover?.lastPage,
        pageCount: cover?.pageCount,
        daysAgo: 0,
        pausedDays: cover?.pausedDays,
        recapReady: cover?.recap?.available ?? false,
        deck: cover?.why,
        atRisk: atRisk,
        streakDays: streakDays,
      );
  if (cover == null) return of(HeadlineCase.newProfile);
  return switch (cover.reason) {
    HomeCoverReason.newChapters => of(HeadlineCase.newChapters),
    HomeCoverReason.inProgress => of(HeadlineCase.inProgress),
    HomeCoverReason.paused => of(HeadlineCase.paused),
    HomeCoverReason.aiPick => of(HeadlineCase.aiPick),
    HomeCoverReason.firstPick => of(HeadlineCase.firstPick),
    HomeCoverReason.caughtUp => of(HeadlineCase.caughtUp),
    _ => of(HeadlineCase.newProfile),
  };
}

/// Runs after either origin: when the local at-risk value differs from the payload's flag, the
/// local one wins and the headline and deck are recomposed.
HomeFeed applyAtRisk(HomeFeed feed, DateTime now) {
  final local = computeAtRisk(feed.streak, now);
  if (local == feed.streak.atRisk) return feed;
  final streak = feed.streak.copyWith(atRisk: local);
  final r = composeHeadline(headlineInputFor(feed.cover, now, atRisk: local, streakDays: streak.currentDays));
  // Cases 5 and caught up ignore at-risk: keep the payload's own lines.
  final atRiskApplies = feed.cover != null && feed.cover!.reason != HomeCoverReason.popular && feed.cover!.reason != HomeCoverReason.caughtUp;
  if (!atRiskApplies) return feed.copyWith(streak: streak);
  return feed.copyWith(
    streak: streak,
    headline: r.headline,
    deck: local ? r.deck : (feed.deck.isEmpty ? r.deck : feed.deck),
    kickerTitle: r.titleInKicker ? feed.cover?.title : null,
    clearKicker: !r.titleInKicker,
  );
}
