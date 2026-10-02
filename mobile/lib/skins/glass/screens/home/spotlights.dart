import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';

/// Which of the glass 8.8 candidates a spotlight card is.
enum SpotlightKind { nextUp, because, letter, newest, previouslyOn, wrapped, caughtUp, start, offline }

/// What the lit primary action does.
enum SpotlightAction { continueReading, openSeries, searchSources, openWrapped, previouslyOn }

/// One spotlight card (glass 8.8): everything the card, its stage and its actions need.
@immutable
class SpotlightSpec {
  const SpotlightSpec({
    required this.kind,
    required this.title,
    required this.meta,
    required this.primaryLabel,
    required this.primary,
    this.secondaryLabel = 'Details',
    this.sourceId,
    this.seriesKey,
    this.coverUrl,
    this.palette,
    this.ambient,
    this.why,
    this.aiWhy = false,
    this.from,
    this.target,
    this.world,
    this.recap,
    this.year,
  });

  final SpotlightKind kind;
  final String title, meta, primaryLabel;
  final SpotlightAction primary;

  /// "Details", "Previously on", or null (Wrapped has none).
  final String? secondaryLabel;
  final String? sourceId, seriesKey, coverUrl, why;
  final CoverPalette? palette;
  final Ambient? ambient;

  /// The `why` line is AI's (it carries the machine sparkle).
  final bool aiWhy;

  /// The friend behind a letter (the `bloom` chip "{name} thinks you'd like this").
  final ProfileRef? from;

  /// What Continue continues, for a series the reader has progress in.
  final HomeContinueTarget? target;
  final WorldItem? world;
  final RecapAvailability? recap;
  final int? year;

  String? get key => sourceId == null ? null : '$sourceId:$seriesKey';
  bool get hasSeries => sourceId != null && seriesKey != null;
  bool get secondaryIsRecap => secondaryLabel == 'Previously on';
  bool get isWrapped => kind == SpotlightKind.wrapped;
}

String _n(num? n) => n == null ? '' : (n == n.roundToDouble() ? '${n.round()}' : '$n');

String _kind(bool novel) => novel ? 'Novel' : 'Manhwa';

/// Up to six spotlight cards for [view], in the glass 8.8 order, de-duplicated by `sourceId:seriesKey`.
List<SpotlightSpec> composeSpotlights(HomeFeedView view, {required DateTime now, List<HomeContinueItem>? continueRows}) {
  final feed = view.feed;
  if (feed == null) return const [];
  final cover = feed.cover;

  if (view.offline) {
    if (cover == null) return const [];
    return [_fromCover(cover, SpotlightKind.offline, meta: _coverMeta(cover))];
  }

  List<Object> items(HomeSectionType t) => feed.section(t)?.items ?? const [];
  final cont = continueRows ?? items(HomeSectionType.continueReading).whereType<HomeContinueItem>().toList();
  final fresh = items(HomeSectionType.newThisWeek).whereType<HomeSeriesItem>().toList();
  final lost = items(HomeSectionType.whereWereWe).whereType<HomeSeriesItem>().toList();
  final because = feed.sections.where((s) => s.type == HomeSectionType.because && s.items.isNotEmpty).firstOrNull;
  final letters = items(HomeSectionType.sentToYou).whereType<Letter>().toList();

  final noHistory = cont.isEmpty && fresh.isEmpty && lost.isEmpty && items(HomeSectionType.almostThere).isEmpty && (cover == null || cover.reason == HomeCoverReason.firstPick || cover.reason == HomeCoverReason.popular);
  if (view.state == HomeFeedState.empty || noHistory) {
    final pick = (items(HomeSectionType.firstPicks).followedBy(items(HomeSectionType.popular)).whereType<HomePickItem>()).firstOrNull;
    if (pick != null) return [_fromPick(pick, SpotlightKind.start, meta: 'Start here')];
    if (cover != null) return [_fromCover(cover, SpotlightKind.start, meta: 'Start here', action: SpotlightAction.openSeries, label: 'Start reading')];
    return const [];
  }

  final caughtUp = cover?.reason == HomeCoverReason.caughtUp;
  final out = <SpotlightSpec>[];
  final seen = <String>{};
  void add(SpotlightSpec? s) {
    if (s == null || out.length >= 6) return;
    final k = s.key ?? (s.world != null ? 'w:${s.world!.title}' : null);
    if (k != null && !seen.add(k)) return;
    out.add(s);
  }

  // 5 first (it is built early so a caught-up card can borrow it), but placed in order below.
  SpotlightSpec? previous() {
    final l = lost.firstOrNull;
    if (l != null) {
      final rs = l.series.readState;
      final days = l.lastReadAt == null ? 7 : now.difference(l.lastReadAt!).inDays;
      final ch = rs?.resumeNumber;
      return SpotlightSpec(
        kind: SpotlightKind.previouslyOn,
        title: l.series.title,
        meta: 'Paused ${days < 1 ? 7 : days} days',
        primaryLabel: ch == null ? 'Continue' : 'Continue Ch ${_n(ch)}',
        primary: SpotlightAction.continueReading,
        // Only a recap that exists: an unavailable one opens on a dead-end notice.
        secondaryLabel: (l.recap?.available ?? false) ? 'Previously on' : null,
        sourceId: l.series.sourceId,
        seriesKey: l.series.seriesKey,
        coverUrl: l.series.coverUrl,
        palette: l.palette,
        ambient: l.ambient,
        recap: l.recap,
        target: rs?.resumeKey == null
            ? null
            : HomeContinueTarget(sourceId: l.series.sourceId, seriesKey: l.series.seriesKey, chapterKey: rs!.resumeKey!, chapterNumber: ch, recap: l.recap, lastReadAt: l.lastReadAt),
      );
    }
    for (final c in cont) {
      if (c.pausedDays >= 7 && (c.recap?.available ?? false)) {
        return SpotlightSpec(
          kind: SpotlightKind.previouslyOn,
          title: c.row.title ?? c.row.seriesKey,
          meta: 'Paused ${c.pausedDays} days',
          primaryLabel: c.row.chapterNumber == null ? 'Continue' : 'Continue Ch ${_n(c.row.chapterNumber)}',
          primary: SpotlightAction.continueReading,
          secondaryLabel: 'Previously on',
          sourceId: c.row.sourceId,
          seriesKey: c.row.seriesKey,
          coverUrl: c.row.coverUrl,
          palette: c.palette,
          ambient: c.ambient,
          recap: c.recap,
          target: HomeContinueTarget.fromContinue(c),
        );
      }
    }
    return null;
  }

  final prev = previous();
  final because0 = because?.items.whereType<HomePickItem>().firstOrNull;
  final aiSpec = because0 == null ? null : _fromPick(because0, SpotlightKind.because, meta: _worldMeta(because0), why: because0.why);

  if (caughtUp || (!cont.any((c) => c.newCount >= 1) && fresh.isEmpty && !(cover != null && (cover.reason == HomeCoverReason.inProgress || cover.reason == HomeCoverReason.newChapters)))) {
    final picked0 = items(HomeSectionType.picked).whereType<HomePickItem>().firstOrNull;
    final base = prev ?? aiSpec ?? (picked0 == null ? null : _fromPick(picked0, SpotlightKind.because, meta: _worldMeta(picked0))) ?? (cover == null ? null : _fromCover(cover, SpotlightKind.caughtUp, meta: '', action: SpotlightAction.openSeries, label: 'Start reading'));
    final recapOk = prev?.recap?.available ?? false;
    if (base != null) {
      add(SpotlightSpec(
        kind: SpotlightKind.caughtUp,
        title: "You're caught up",
        meta: 'Nothing new on your shelf',
        primaryLabel: recapOk ? 'Previously on' : (prev?.primaryLabel ?? 'Start reading'),
        primary: recapOk ? SpotlightAction.previouslyOn : base.primary,
        sourceId: base.sourceId,
        seriesKey: base.seriesKey,
        coverUrl: base.coverUrl,
        palette: base.palette,
        ambient: base.ambient,
        target: base.target,
        world: base.world,
        recap: base.recap,
        why: base.why,
        aiWhy: base.aiWhy,
      ),);
    }
  }

  // 1. Next up.
  if (!caughtUp) {
    final n = cont.where((c) => c.newCount >= 1).firstOrNull;
    if (n != null && cover != null && cover.reason == HomeCoverReason.newChapters && cover.sourceId == n.row.sourceId && cover.seriesKey == n.row.seriesKey) {
      // The server's cover story is this row's new chapter: it knows the chapter key to open.
      add(_fromCover(cover, SpotlightKind.nextUp, meta: _coverMeta(cover)));
    } else if (n != null) {
      // The row is the chapter Continue opens (the server already moves it past a finished one).
      final ch = n.row.chapterNumber;
      add(SpotlightSpec(
        kind: SpotlightKind.nextUp,
        title: n.row.title ?? n.row.seriesKey,
        meta: '${n.newCount == 1 ? '1 new chapter' : '${n.newCount} new chapters'} · ${_kind(false)}',
        primaryLabel: ch == null ? 'Continue' : 'Continue Ch ${_n(ch)}',
        primary: SpotlightAction.continueReading,
        sourceId: n.row.sourceId,
        seriesKey: n.row.seriesKey,
        coverUrl: n.row.coverUrl,
        palette: n.palette,
        ambient: n.ambient,
        recap: n.recap,
        target: HomeContinueTarget.fromContinue(n),
      ),);
    } else if (cover != null && (cover.reason == HomeCoverReason.newChapters || cover.reason == HomeCoverReason.inProgress)) {
      add(_fromCover(cover, SpotlightKind.nextUp, meta: _coverMeta(cover)));
    }
  }
  // 2. Because you read.
  add(aiSpec);
  // 3. A letter.
  final l = letters.firstOrNull;
  if (l != null) {
    add(SpotlightSpec(
      kind: SpotlightKind.letter,
      title: l.title,
      meta: 'From your Circle',
      primaryLabel: 'Start reading',
      primary: SpotlightAction.openSeries,
      sourceId: l.sourceId,
      seriesKey: l.seriesKey,
      coverUrl: l.coverUrl,
      ambient: l.ambient,
      from: l.from,
    ),);
  }
  // 4. Newest update.
  if (!caughtUp) {
    final u = fresh.where((f) => !seen.contains('${f.series.sourceId}:${f.series.seriesKey}')).firstOrNull;
    if (u != null) {
      final rs = u.series.readState;
      final n = rs?.newCount ?? 0;
      final next = rs?.resumeNumber;
      add(SpotlightSpec(
        kind: SpotlightKind.newest,
        title: u.series.title,
        meta: n == 1 ? '1 new chapter' : '$n new chapters',
        primaryLabel: next == null ? 'Continue' : 'Continue Ch ${_n(next)}',
        primary: SpotlightAction.continueReading,
        sourceId: u.series.sourceId,
        seriesKey: u.series.seriesKey,
        coverUrl: u.series.coverUrl,
        palette: u.palette,
        ambient: u.ambient,
        recap: u.recap,
        target: rs?.resumeKey == null
            ? null
            : HomeContinueTarget(sourceId: u.series.sourceId, seriesKey: u.series.seriesKey, chapterKey: rs!.resumeKey!, chapterNumber: next, recap: u.recap, lastReadAt: rs.lastReadAt),
      ),);
    }
  }
  // 5. Previously on candidate.
  add(prev);
  // 6. Wrapped, in December.
  if (now.month == 12) {
    add(SpotlightSpec(
      kind: SpotlightKind.wrapped,
      title: 'Your ${now.year} in chapters',
      meta: 'Wrapped',
      primaryLabel: 'Open Wrapped',
      primary: SpotlightAction.openWrapped,
      secondaryLabel: null,
      year: now.year,
    ),);
  }
  return out;
}

String _coverMeta(HomeCover c) {
  if (c.reason == HomeCoverReason.newChapters) return 'Ch ${_n(c.chapterNumber)} is new · ${_kind(c.isNovel)}';
  if (c.isNovel) return 'Ch ${_n(c.chapterNumber)} · ${c.pageCount > 0 ? (c.lastPage * 100 / c.pageCount).round() : 0} % in';
  if (c.pageCount == 0) return 'Ch ${_n(c.chapterNumber)} · ${_kind(false)}';
  return 'Ch ${_n(c.chapterNumber)} · p. ${c.lastPage} of ${c.pageCount}';
}

SpotlightSpec _fromCover(HomeCover c, SpotlightKind kind, {required String meta, SpotlightAction action = SpotlightAction.continueReading, String? label}) {
  final start = c.pageCount == 0 || c.isStart;
  return SpotlightSpec(
    kind: kind,
    title: c.title,
    meta: meta,
    primaryLabel: label ?? '${start ? 'Start' : 'Continue'} Ch ${_n(c.chapterNumber)}',
    primary: action,
    sourceId: c.sourceId,
    seriesKey: c.seriesKey,
    coverUrl: c.coverUrl,
    palette: c.palette,
    ambient: c.ambient,
    recap: c.recap,
    why: c.why,
    target: c.chapterKey == null || action != SpotlightAction.continueReading
        ? null
        : HomeContinueTarget(sourceId: c.sourceId, seriesKey: c.seriesKey, chapterKey: c.chapterKey!, isNovel: c.isNovel, recap: c.recap, chapterNumber: c.chapterNumber, page: c.lastPage),
  );
}

String _worldMeta(HomePickItem p) {
  final w = p.world;
  if (w == null) return p.source!.status ?? 'Series';
  return [if (w.format != null) w.format!, if (w.status != null) w.status!].join(' · ');
}

SpotlightSpec _fromPick(HomePickItem p, SpotlightKind kind, {required String meta, String? why}) {
  final w = p.world;
  final a = w?.available.firstOrNull;
  final s = p.source;
  final info = w != null && a == null;
  return SpotlightSpec(
    kind: kind,
    title: p.title,
    meta: meta,
    primaryLabel: info ? 'Search my sources' : 'Start reading',
    primary: info ? SpotlightAction.searchSources : SpotlightAction.openSeries,
    sourceId: a?.sourceId ?? s?.sourceId,
    seriesKey: a?.seriesKey ?? s?.id,
    coverUrl: w?.coverUrl ?? s?.coverUrl,
    palette: p.palette,
    ambient: p.ambient,
    why: why ?? p.why,
    aiWhy: kind == SpotlightKind.because,
    world: w,
  );
}
