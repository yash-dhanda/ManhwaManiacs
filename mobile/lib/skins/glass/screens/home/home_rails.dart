import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_with_recap.dart';

/// How a rail is drawn.
enum HomeRailKind { continueStack, posters, ai, circle, chips, sources, numbers }

/// A poster in a Glass rail (an item of a [HomeRailKind.posters] rail, or a friend's read).
@immutable
class HomePoster {
  const HomePoster({required this.sourceId, required this.seriesKey, required this.title, this.coverUrl, this.palette, this.ambient, this.badge, this.caption, this.friend, this.mature = false, this.hasProgress = false, this.target, this.readNumber});

  final String sourceId, seriesKey, title;
  final String? coverUrl, badge, caption;
  final CoverPalette? palette;
  final Ambient? ambient;

  /// "{name} is reading": the friend's 18 px orb sits at the bottom left.
  final ProfileRef? friend;
  final bool mature, hasProgress;

  /// What Continue and Previously on act on, for a series the reader has progress in.
  final HomeContinueTarget? target;
  final double? readNumber;

  String get key => '$sourceId:$seriesKey';
}

/// A card of "From your Circle": a letter or a friend's read.
@immutable
class HomeCircleCard {
  const HomeCircleCard.letter(Letter this.letter)
      : poster = null;
  const HomeCircleCard.read(HomePoster this.poster) : letter = null;

  final Letter? letter;
  final HomePoster? poster;

  String get key => letter != null ? '${letter!.sourceId}:${letter!.seriesKey}' : poster!.key;
}

/// One Glass Home rail. [items] holds [HomeContinueItem], [HomePoster], [HomePickItem], [HomeCircleCard], [HomeGenreItem],
/// [HomeSourceItem] or [HomeNumbersItem] by [kind].
@immutable
class HomeRailSpec {
  const HomeRailSpec({required this.id, required this.kind, required this.title, required this.items, this.subtitle, this.state = HomeSectionState.ready, this.ai = false, this.seeAll, this.generatedAt, this.fallbackNote, this.seedTitle, this.thinking = false});

  final String id;
  final HomeRailKind kind;
  final String title;
  final String? subtitle;
  final List<Object> items;
  final HomeSectionState state;
  final bool ai;
  final String? seeAll;
  final DateTime? generatedAt;

  /// The server's `fallback` note of an unavailable AI section (its `items` are the fallback items).
  final String? fallbackNote;
  final String? seedTitle;

  /// An AI rail whose answer is still being computed: the header with the orbit and four skeleton cards.
  final bool thinking;

  HomeRailSpec copyWith({List<Object>? items, bool? thinking}) => HomeRailSpec(id: id, kind: kind, title: title, items: items ?? this.items, subtitle: subtitle, state: state, ai: ai, seeAll: seeAll, generatedAt: generatedAt, fallbackNote: fallbackNote, seedTitle: seedTitle, thinking: thinking ?? this.thinking);

  bool get unavailable => state == HomeSectionState.unavailable;
}

HomePoster _fromSeries(HomeSeriesItem i, {String? badge, String? caption}) => HomePoster(
      sourceId: i.series.sourceId,
      seriesKey: i.series.seriesKey,
      title: i.series.title,
      coverUrl: i.series.coverUrl,
      palette: i.palette,
      ambient: i.ambient,
      badge: badge,
      caption: caption,
      hasProgress: i.series.readState?.started ?? false,
      readNumber: i.series.readState?.chapterNumber,
      target: i.series.readState?.chapterKey == null || !(i.series.readState?.started ?? false)
          ? null
          : HomeContinueTarget(sourceId: i.series.sourceId, seriesKey: i.series.seriesKey, chapterKey: i.series.readState!.chapterKey!, chapterNumber: i.series.readState!.chapterNumber, recap: i.recap, lastReadAt: i.series.readState!.lastReadAt),
    );

String? _topGenre(HomeRailSpec r) {
  if (!r.ai) return null;
  for (final i in r.items) {
    if (i is HomePickItem && i.world != null && i.world!.genres.isNotEmpty) return i.world!.genres.first;
  }
  return null;
}

/// The Glass rails of [view], in the glass 8.8 order (the thirteen of the spec), each omitted when it has no items except an AI rail
/// in the `unavailable` state. Offline: only "Ready offline" and "Continue reading".
List<HomeRailSpec> composeHomeRails(
  HomeFeedView view, {
  List<HiddenContinue> hidden = const [],
  List<DownloadedSeriesGroup> downloaded = const [],
  List<FollowedSeries> followed = const [],
  bool Function(FollowedSeries s)? inMode,
  List<String> noted = const [],
  bool aiThinking = false,
}) {
  final feed = view.feed;
  if (feed == null) return const [];
  List<Object> items(HomeSectionType t) => feed.section(t)?.items ?? const [];
  HomeSectionState st(HomeSectionType t) => feed.section(t)?.state ?? HomeSectionState.ready;

  final continueItems = [
    for (final c in items(HomeSectionType.continueReading).whereType<HomeContinueItem>())
      if (!hidden.any((h) => h.sourceId == c.row.sourceId && h.seriesKey == c.row.seriesKey && h.chapterKey == c.row.chapterKey)) c,
  ];
  final coverOf = <String, String?>{for (final f in followed) '${f.sourceId}:${f.seriesKey}': f.coverUrl};

  HomeRailSpec? readyOffline() {
    final saved = items(HomeSectionType.saved).whereType<HomeSavedItem>().toList();
    final posters = <HomePoster>[];
    if (saved.isNotEmpty) {
      for (final s in saved.take(12)) {
        posters.add(HomePoster(sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title, coverUrl: s.coverUrl ?? coverOf['${s.sourceId}:${s.seriesKey}'], caption: s.chapters == 1 ? '1 chapter' : '${s.chapters} chapters'));
      }
    } else {
      DateTime at(DownloadedSeriesGroup g) => g.chapters.map((c) => c.createdAt).fold(DateTime(0), (a, b) => a.isAfter(b) ? a : b);
      final gs = [for (final g in downloaded) if (g.chapters.any((c) => c.state == DownloadChapterState.complete)) g]..sort((a, b) => at(b).compareTo(at(a)));
      for (final g in gs.take(12)) {
        posters.add(HomePoster(sourceId: g.sourceId, seriesKey: g.seriesKey, title: g.seriesTitle ?? g.seriesKey, coverUrl: coverOf['${g.sourceId}:${g.seriesKey}'], caption: g.chapters.length == 1 ? '1 chapter' : '${g.chapters.length} chapters'));
      }
    }
    return posters.isEmpty ? null : HomeRailSpec(id: 'ready-offline', kind: HomeRailKind.posters, title: 'Ready offline', items: posters, seeAll: Routes.downloads());
  }

  HomeRailSpec? continueRail() => continueItems.isEmpty ? null : HomeRailSpec(id: 'continue', kind: HomeRailKind.continueStack, title: 'Continue reading', items: continueItems, seeAll: Routes.history(), state: st(HomeSectionType.continueReading));

  if (view.offline) {
    return [
      if (readyOffline() case final r?) r,
      if (continueRail() case final r?) r,
    ];
  }

  final out = <HomeRailSpec>[];
  void add(HomeRailSpec? r) {
    if (r != null) out.add(r);
  }

  HomeRailSpec? picks(HomeSectionType t, String id, String title, {String? subtitle, String? seeAll}) {
    final s = feed.section(t);
    if (s == null) return null;
    final unavailable = s.state == HomeSectionState.unavailable;
    if (s.items.isEmpty && !unavailable) return null;
    return HomeRailSpec(id: id, kind: HomeRailKind.ai, title: title, subtitle: subtitle, items: s.items.whereType<HomePickItem>().toList(), state: s.state, ai: true, seeAll: seeAll, generatedAt: s.generatedAt, fallbackNote: s.fallback, seedTitle: s.seed?.title);
  }

  // 1
  final first = items(HomeSectionType.firstPicks).whereType<HomePickItem>().toList();
  if (first.isNotEmpty) add(HomeRailSpec(id: 'first-picks', kind: HomeRailKind.ai, title: 'Start here', items: first));
  // 2
  add(continueRail());
  // 3
  final fresh = items(HomeSectionType.newThisWeek).whereType<HomeSeriesItem>().toList();
  if (fresh.isNotEmpty) {
    add(HomeRailSpec(
      id: 'new-this-week',
      kind: HomeRailKind.posters,
      title: 'Updated for you',
      items: [
        for (final f in fresh)
          _fromSeries(f, badge: (f.series.readState?.newCount ?? 0) > 0 ? '${f.series.readState!.newCount} NEW' : null),
      ],
      seeAll: Routes.updates(),
      state: st(HomeSectionType.newThisWeek),
    ),);
  }
  // 4
  var n = 0;
  for (final s in feed.sections.where((s) => s.type == HomeSectionType.because)) {
    if (n >= 3) break;
    final title = s.seed == null ? 'Because you read' : 'Because you read ${s.seed!.title}';
    final unavailable = s.state == HomeSectionState.unavailable;
    if (s.items.isEmpty && !unavailable) continue;
    n++;
    out.add(HomeRailSpec(id: 'because-$n', kind: HomeRailKind.ai, title: title, items: s.items.whereType<HomePickItem>().toList(), state: s.state, ai: true, seeAll: Routes.picks(), generatedAt: s.generatedAt, fallbackNote: s.fallback, seedTitle: s.seed?.title));
  }
  // 5
  var forYou = picks(HomeSectionType.picked, 'picked', 'For you', subtitle: 'Picked from what you read', seeAll: Routes.picks());
  if (forYou == null && !feed.ai.available) {
    forYou = const HomeRailSpec(id: 'picked', kind: HomeRailKind.ai, title: 'For you', subtitle: 'Picked from what you read', items: [], state: HomeSectionState.unavailable, ai: true);
  }
  add(forYou);
  // 6
  final almost = items(HomeSectionType.almostThere).whereType<HomeSeriesItem>().toList();
  if (almost.isNotEmpty) {
    add(HomeRailSpec(
      id: 'almost-there',
      kind: HomeRailKind.posters,
      title: 'Almost there',
      items: [
        for (final a in almost)
          _fromSeries(a, caption: a.chaptersLeft == null ? null : (a.chaptersLeft == 1 ? '1 chapter left' : '${a.chaptersLeft} chapters left')),
      ],
      seeAll: Routes.library({'reading_status': 'reading'}),
    ),);
  }
  // 7
  final letters = items(HomeSectionType.sentToYou).whereType<Letter>().toList();
  final reads = <HomePoster>[
    for (final c in items(HomeSectionType.circle).followedBy(items(HomeSectionType.circleTop)).whereType<HomeCircleItem>())
      HomePoster(sourceId: c.series.sourceId, seriesKey: c.series.seriesKey, title: c.series.title, coverUrl: c.series.coverUrl, ambient: c.series.ambient, friend: c.member, caption: '${c.member.name} is reading'),
  ];
  final seen = <String>{};
  final circle = <HomeCircleCard>[
    for (final l in letters)
      if (seen.add('${l.sourceId}:${l.seriesKey}')) HomeCircleCard.letter(l),
    for (final r in reads)
      if (seen.add(r.key)) HomeCircleCard.read(r),
  ];
  if (circle.isNotEmpty) add(HomeRailSpec(id: 'circle', kind: HomeRailKind.circle, title: 'From your Circle', items: circle, seeAll: '${Routes.circle()}?tab=letters'));
  // 8
  final genres = items(HomeSectionType.genres).whereType<HomeGenreItem>().toList();
  if (genres.isNotEmpty) add(HomeRailSpec(id: 'genres', kind: HomeRailKind.chips, title: 'Your genres', items: genres));
  // 9
  final popular = items(HomeSectionType.popular).whereType<HomePickItem>().toList();
  if (popular.isNotEmpty) add(HomeRailSpec(id: 'popular', kind: HomeRailKind.ai, title: 'Popular on your pinned sources', items: popular));
  // 10
  final sources = items(HomeSectionType.sources).whereType<HomeSourceItem>().toList();
  if (sources.isNotEmpty) {
    add(HomeRailSpec(
      id: 'sources',
      kind: HomeRailKind.sources,
      title: 'New in your pinned sources',
      items: sources,
      seeAll: Routes.sources(),
    ),);
  }
  // 11
  add(readyOffline());
  // 12
  final mine = [
    for (final f in followed)
      if (inMode == null || inMode(f)) f,
  ]..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  if (mine.isNotEmpty) {
    add(HomeRailSpec(
      id: 'recently-added',
      kind: HomeRailKind.posters,
      title: 'Recently added to your library',
      items: [for (final f in mine.take(12)) HomePoster(sourceId: f.sourceId, seriesKey: f.seriesKey, title: f.title, coverUrl: f.coverUrl, ambient: f.ambient, hasProgress: f.readState?.started ?? false)],
      seeAll: Routes.library({'sort': 'added'}),
    ),);
  }
  // 13
  final numbers = items(HomeSectionType.numbers).whereType<HomeNumbersItem>().toList();
  if (numbers.isNotEmpty) add(HomeRailSpec(id: 'numbers', kind: HomeRailKind.numbers, title: 'This week', items: numbers, seeAll: Routes.numbers()));

  // The in-session re-rank moves rails up one place at most and never above Continue.
  final ci = out.indexWhere((r) => r.id == 'continue');
  final ranked = rerankRails<HomeRailSpec>(out, noted, _topGenre, floor: ci < 0 ? 0 : ci + 1);
  return aiThinking ? [for (final r in ranked) r.ai && !r.unavailable ? r.copyWith(thinking: true) : r] : ranked;
}

/// The order Home shows after a re-rank (glass 8.8): rails move only when the rails that change place are outside the viewport, so nothing
/// moves under the finger. A different set of rails (new data) is adopted at once.
List<String> gatedRailOrder(List<String> shown, List<String> wanted, bool Function(String id) inViewport) {
  if (shown.length != wanted.length || !shown.toSet().containsAll(wanted)) return wanted;
  var moving = <String>[];
  for (var i = 0; i < shown.length; i++) {
    if (shown[i] != wanted[i]) moving = [...moving, shown[i], wanted[i]];
  }
  if (moving.isEmpty) return wanted;
  return moving.any(inViewport) ? shown : wanted;
}
