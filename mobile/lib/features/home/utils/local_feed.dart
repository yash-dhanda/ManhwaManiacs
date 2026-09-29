import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/headline.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

/// What `composeLocalFeed` reads. A null list or object means that input failed (its sections come
/// out `unavailable`); an empty one means it answered with nothing.
class LocalFeedInputs {
  const LocalFeedInputs({
    this.continueRows,
    this.recentlyUpdated,
    this.world,
    this.worldReason,
    this.followed,
    this.stats,
    this.pins,
    this.recaps = const {},
    this.contentKind = 'manga',
    this.inMode,
  });

  final List<ContinueReadingItem>? continueRows;
  final List<FollowedSeries>? recentlyUpdated;
  final WorldRecommendations? world;

  /// Why the world recommendations are missing (`ai.reason`).
  final String? worldReason;
  final List<FollowedSeries>? followed;
  final LibraryStatistics? stats;
  final List<SourcePin>? pins;

  /// `recap.available` per `'$sourceId|$seriesKey'`, where known (case 3 needs it).
  final Map<String, RecapAvailability> recaps;
  final String contentKind;

  /// Whether a source belongs to the active reading mode; null keeps every row.
  final bool Function(String sourceId)? inMode;

  /// Every input failed.
  bool get allFailed => continueRows == null && recentlyUpdated == null && world == null && followed == null && stats == null && pins == null;
}

String _id(String s, String k) => '$s|$k';

int _daysBetween(DateTime later, DateTime earlier) => later.difference(earlier).inDays;

String _num(double? n) {
  if (n == null) return '';
  return n == n.roundToDouble() ? '${n.round()}' : '$n';
}

/// A followed series' next chapter after the furthest one read, where the known list has it.
KnownNext? _nextOf(FollowedSeries s) {
  final rs = s.readState;
  final pos = rs?.position;
  if (pos != null && pos < s.knownChapters.length) {
    final k = s.knownChapters[pos];
    return (key: k.key, number: k.number);
  }
  return null;
}

typedef KnownNext = ({String key, double? number});

/// The Tonight feed composed on the device from the library endpoints, by the rules the backend
/// uses (cinematic 9.1.2, 9.1.6). `ai` is always unavailable.
HomeFeed composeLocalFeed(LocalFeedInputs inputs, DateTime now) {
  bool ok(String sourceId) => inputs.inMode?.call(sourceId) ?? true;
  final followed = [...?inputs.followed?.where((f) => ok(f.sourceId))];
  final rows = [...?inputs.continueRows?.where((r) => ok(r.sourceId))]
    ..sort((a, b) => (b.lastReadAt ?? DateTime(0)).compareTo(a.lastReadAt ?? DateTime(0)));
  final recent = [...?inputs.recentlyUpdated?.where((f) => ok(f.sourceId))];
  final byId = {for (final f in [...recent, ...followed]) _id(f.sourceId, f.seriesKey): f};
  FollowedSeries? followOf(ContinueReadingItem r) => byId[_id(r.sourceId, r.seriesKey)];
  final hasHistory = rows.isNotEmpty || followed.any((f) => f.readState?.started ?? false);

  // ---- cover story --------------------------------------------------------------------------
  HomeCover? cover;
  HeadlineInput? hi;

  HomeCover coverFromRow(ContinueReadingItem r, String reason, {int newCount = 0, int pausedDays = 0}) {
    final f = followOf(r);
    return HomeCover(
      sourceId: r.sourceId,
      seriesKey: r.seriesKey,
      chapterKey: r.chapterKey,
      reason: reason,
      ambient: r.ambient ?? f?.ambient,
      contentKind: inputs.contentKind,
      recap: inputs.recaps[_id(r.sourceId, r.seriesKey)],
      title: r.title ?? f?.title ?? '',
      coverUrl: r.coverUrl ?? f?.coverUrl,
      chapterNumber: r.chapterNumber,
      lastPage: r.lastPage,
      pageCount: r.pageCount,
      newCount: newCount,
      pausedDays: pausedDays,
    );
  }

  bool finished(ContinueReadingItem r) => r.pageCount > 0 && r.lastPage >= r.pageCount;

  // 1: in progress with new chapters since the last read.
  for (final r in rows) {
    final f = followOf(r);
    final n = f?.readState?.newCount ?? 0;
    if (f == null || n <= 0 || (f.readingStatus == 'completed')) continue;
    final next = _nextOf(f);
    final chapterKey = finished(r) ? next?.key ?? r.chapterKey : r.chapterKey;
    final number = finished(r) ? next?.number ?? r.chapterNumber : r.chapterNumber;
    cover = HomeCover(
      sourceId: r.sourceId,
      seriesKey: r.seriesKey,
      chapterKey: chapterKey,
      reason: HomeCoverReason.newChapters,
      ambient: r.ambient ?? f.ambient,
      contentKind: inputs.contentKind,
      recap: inputs.recaps[_id(r.sourceId, r.seriesKey)],
      title: r.title ?? f.title,
      coverUrl: r.coverUrl ?? f.coverUrl,
      chapterNumber: number,
      lastPage: finished(r) ? 1 : r.lastPage,
      pageCount: finished(r) ? 0 : r.pageCount,
      newCount: n,
    );
    hi = HeadlineInput(kind: HeadlineCase.newChapters, now: now, title: cover.title, chapter: _num(number));
    break;
  }
  // 2: a chapter in progress, unfinished, read within 21 days.
  if (cover == null) {
    for (final r in rows) {
      final at = r.lastReadAt;
      if (at == null || finished(r) || r.pageCount <= 0 || _daysBetween(now, at) > 21) continue;
      cover = coverFromRow(r, HomeCoverReason.inProgress);
      hi = HeadlineInput(
        kind: HeadlineCase.inProgress,
        now: now,
        title: cover.title,
        chapter: _num(r.chapterNumber),
        page: r.lastPage,
        pageCount: r.pageCount,
        daysAgo: _daysBetween(now, at),
      );
      break;
    }
  }
  // 3: paused 7-60 days with a recap ready.
  if (cover == null) {
    for (final r in rows) {
      final at = r.lastReadAt;
      if (at == null) continue;
      final d = _daysBetween(now, at);
      final recap = inputs.recaps[_id(r.sourceId, r.seriesKey)];
      if (d < 7 || d > 60 || recap == null || !recap.available) continue;
      cover = coverFromRow(r, HomeCoverReason.paused, pausedDays: d);
      hi = HeadlineInput(kind: HeadlineCase.paused, now: now, title: cover.title, chapter: _num(r.chapterNumber), pausedDays: d, recapReady: true);
      break;
    }
  }
  // 4: the top AI pick with an available source (needs history).
  final worldTop = inputs.world?.forYou.where((w) => w.available.isNotEmpty).firstOrNull;
  if (cover == null && hasHistory && worldTop != null) {
    final a = worldTop.available.first;
    cover = HomeCover(
      sourceId: a.sourceId,
      seriesKey: a.seriesKey,
      reason: HomeCoverReason.aiPick,
      ambient: worldTop.ambient,
      contentKind: inputs.contentKind,
      title: worldTop.title,
      coverUrl: worldTop.coverUrl,
      why: worldTop.why,
    );
    hi = HeadlineInput(kind: HeadlineCase.aiPick, now: now, title: worldTop.title, deck: worldTop.why ?? _firstLine(worldTop));
  }
  // 4b / caught up: a followed series (§9.1.6): the first pick, else the most recently updated.
  if (cover == null && followed.isNotEmpty) {
    if (!hasHistory) {
      final f = ([...followed]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))).first;
      cover = _followCover(f, HomeCoverReason.firstPick, inputs.contentKind);
      hi = HeadlineInput(kind: HeadlineCase.firstPick, now: now, title: f.title);
    } else {
      final f = recent.isNotEmpty ? recent.first : followed.first;
      cover = _followCover(f, HomeCoverReason.caughtUp, inputs.contentKind);
      hi = HeadlineInput(kind: HeadlineCase.caughtUp, now: now);
    }
  }
  hi ??= HeadlineInput(kind: HeadlineCase.newProfile, now: now);
  final head = composeHeadline(hi);

  // ---- also in this issue -------------------------------------------------------------------
  final coverKey = cover == null ? null : _id(cover.sourceId, cover.seriesKey);
  final used = <String>{if (coverKey != null) coverKey};
  final also = <HomeAlso>[];
  // newChapters: the followed series with the most unread new chapters.
  final withNew = [...followed]..sort((a, b) => (b.readState?.newCount ?? 0).compareTo(a.readState?.newCount ?? 0));
  for (final f in withNew) {
    final n = f.readState?.newCount ?? 0;
    if (n <= 0) break;
    if (used.contains(_id(f.sourceId, f.seriesKey))) continue;
    used.add(_id(f.sourceId, f.seriesKey));
    also.add(HomeAlso(
      kind: HomeAlsoKind.newChapters,
      sourceId: f.sourceId,
      seriesKey: f.seriesKey,
      title: f.title,
      headline: '${f.title}: $n new ${n == 1 ? 'chapter' : 'chapters'}.',
      ambient: f.ambient,
      coverUrl: f.coverUrl.isEmpty ? null : f.coverUrl,
    ),);
    break;
  }
  // because: the top world rec on the reader's sources.
  for (final w in inputs.world?.forYou ?? const <WorldItem>[]) {
    final a = w.available.firstOrNull;
    if (a == null || used.contains(_id(a.sourceId, a.seriesKey))) continue;
    used.add(_id(a.sourceId, a.seriesKey));
    also.add(HomeAlso(
      kind: HomeAlsoKind.because,
      sourceId: a.sourceId,
      seriesKey: a.seriesKey,
      title: w.title,
      headline: w.title,
      deck: w.why ?? _firstLine(w),
      ambient: w.ambient,
      coverUrl: w.coverUrl,
    ),);
    break;
  }
  // letter: never locally (letters need the server). almostThere: fewest chapters left.
  final almost = _almostThere(followed);
  for (final e in almost) {
    final f = e.$1;
    if (used.contains(_id(f.sourceId, f.seriesKey))) continue;
    used.add(_id(f.sourceId, f.seriesKey));
    final left = e.$2;
    also.add(HomeAlso(
      kind: HomeAlsoKind.almostThere,
      sourceId: f.sourceId,
      seriesKey: f.seriesKey,
      title: f.title,
      headline: '${spellCount(left)} ${left == 1 ? 'chapter' : 'chapters'} left in ${f.title}.',
      ambient: f.ambient,
      coverUrl: f.coverUrl.isEmpty ? null : f.coverUrl,
    ),);
    break;
  }

  // ---- sections -----------------------------------------------------------------------------
  final sections = <HomeSection>[];
  HomeSection section(HomeSectionType t, String title, List<Object>? items, {HomeSectionState? state, HomeSeed? seed, String? note, String? fallback}) =>
      HomeSection(
        type: t,
        title: title,
        items: items ?? const [],
        state: state ?? (items == null ? HomeSectionState.unavailable : (items.isEmpty ? HomeSectionState.empty : HomeSectionState.ready)),
        seed: seed,
        note: note,
        fallback: fallback,
        generatedAt: now,
      );

  if (inputs.continueRows != null || inputs.followed != null) {
    final cont = <Object>[];
    for (final r in rows) {
      final f = followOf(r);
      if (f?.readingStatus == 'completed') continue;
      final n = f?.readState?.newCount ?? 0;
      final at = r.lastReadAt;
      final days = at == null ? 0 : _daysBetween(now, at);
      final nudge = n > 0
          ? ContinueNudge.newChapters
          : (r.pageCount > 0 && r.progressPct >= 0.85 && r.lastPage < r.pageCount)
              ? ContinueNudge.almostDone
              : days >= 7
                  ? ContinueNudge.paused
                  : null;
      cont.add(HomeContinueItem(row: r, nudge: nudge, newCount: n, pausedDays: days >= 7 ? days : 0, recap: inputs.recaps[_id(r.sourceId, r.seriesKey)]));
      if (cont.length == 12) break;
    }
    sections.add(section(HomeSectionType.continueReading, 'Continue reading', inputs.continueRows == null ? null : cont));
  }
  if (inputs.recentlyUpdated != null) {
    final week = [
      for (final f in recent)
        if (((f.updatedAt ?? f.lastCheckedAt) ?? DateTime(0)).isAfter(now.subtract(const Duration(days: 7)))) HomeSeriesItem(series: f),
    ].take(12).toList();
    sections.add(section(HomeSectionType.newThisWeek, 'New this week', week));
  }
  if (inputs.followed != null) {
    sections.add(section(HomeSectionType.almostThere, 'Almost there', [for (final e in almost.take(12)) HomeSeriesItem(series: e.$1, chaptersLeft: e.$2)]));
    final lost = <Object>[];
    for (final r in rows) {
      final at = r.lastReadAt, f = followOf(r);
      if (at == null || f == null || f.readingStatus == 'completed' || finished(r)) continue;
      final d = _daysBetween(now, at);
      if (d < 21 || d > 120) continue;
      lost.add(HomeSeriesItem(series: f, recap: inputs.recaps[_id(r.sourceId, r.seriesKey)]));
      if (lost.length == 12) break;
    }
    sections.add(section(HomeSectionType.whereWereWe, 'Where were we?', lost));
  }
  // picked -> From your shelf (favourites, then plan to read).
  if (inputs.followed != null) {
    final shelf = [
      ...followed.where((f) => f.isFavorite),
      ...followed.where((f) => !f.isFavorite && f.readingStatus == 'plan_to_read'),
    ];
    sections.add(section(
      HomeSectionType.picked,
      'From your shelf',
      [for (final f in shelf.take(12)) HomePickItem(source: _summary(f))],
      state: HomeSectionState.unavailable,
      note: inputs.worldReason ?? 'not_configured',
      fallback: 'shelf',
    ),);
  }
  for (final s in inputs.world?.sections ?? const <WorldSection>[]) {
    if (s.items.isEmpty) continue;
    sections.add(section(
      HomeSectionType.because,
      'Because you read ${s.becauseTitle}',
      [for (final w in s.items) HomePickItem(world: w, why: w.why)],
      seed: HomeSeed(title: s.becauseTitle),
    ),);
  }
  if (inputs.pins != null) {
    sections.add(section(
      HomeSectionType.sources,
      'Sources',
      [for (final p in inputs.pins!) HomeSourceItem(sourceId: p.sourceId, name: p.name, iconUrl: p.iconUrl, mature: p.mature, available: p.available)],
    ),);
  }
  final st = inputs.stats;
  final streak = st == null
      ? const HomeStreak()
      : HomeStreak(currentDays: st.streak.currentDays, longestDays: st.streak.longestDays, lastActiveDate: st.streak.lastActiveDate);
  if (st != null) {
    final week = st.daily.length > 7 ? st.daily.sublist(st.daily.length - 7) : st.daily;
    sections.add(section(HomeSectionType.numbers, 'This week in numbers', [
      HomeNumbersItem(
        streak: streak,
        chaptersWeek: week.fold(0, (a, d) => a + d.chaptersRead),
        secondsWeek: week.fold(0, (a, d) => a + d.secondsRead),
      ),
    ]),);
  } else if (inputs.stats == null && !inputs.allFailed) {
    sections.add(section(HomeSectionType.numbers, 'This week in numbers', null));
  }

  return HomeFeed(
    issueNo: st == null ? 1 : _issueNo(st, now),
    headline: head.headline,
    deck: head.deck,
    kickerTitle: head.titleInKicker ? cover?.title : null,
    streak: streak,
    cover: cover,
    also: also.length >= 2 ? also : const [],
    sections: sections,
    ai: AiState(reason: inputs.worldReason ?? 'not_configured'),
    generatedAt: now,
  );
}

int _issueNo(LibraryStatistics st, DateTime now) {
  final first = st.totals.firstSessionAt;
  return first == null ? 1 : now.difference(first).inDays + 1;
}

String? _firstLine(WorldItem w) => w.genres.isEmpty ? null : w.genres.take(3).join(' · ');

HomeCover _followCover(FollowedSeries f, String reason, String kind) => HomeCover(
      sourceId: f.sourceId,
      seriesKey: f.seriesKey,
      chapterKey: reason == HomeCoverReason.firstPick && f.knownChapters.isNotEmpty ? f.knownChapters.first.key : null,
      reason: reason,
      ambient: f.ambient,
      contentKind: kind,
      title: f.title,
      coverUrl: f.coverUrl.isEmpty ? null : f.coverUrl,
      chapterNumber: reason == HomeCoverReason.firstPick && f.knownChapters.isNotEmpty ? f.knownChapters.first.number : null,
    );

/// Reading, 1 to 3 chapters left, fewest first.
List<(FollowedSeries, int)> _almostThere(List<FollowedSeries> followed) {
  final out = <(FollowedSeries, int)>[];
  for (final f in followed) {
    final rs = f.readState;
    if (rs == null || !rs.started || f.readingStatus == 'completed') continue;
    final left = rs.newCount ?? (rs.position == null ? null : rs.total - rs.position!);
    if (left == null || left < 1 || left > 3) continue;
    out.add((f, left));
  }
  out.sort((a, b) => a.$2.compareTo(b.$2));
  return out;
}

SourceSeriesSummary _summary(FollowedSeries f) => SourceSeriesSummary(
      id: f.seriesKey,
      sourceId: f.sourceId,
      seriesIdentity: f.seriesIdentity,
      title: f.title,
      chapterCount: f.chapterCount,
      genres: const [],
      coverUrl: f.coverUrl,
      ambient: f.ambient,
    );
