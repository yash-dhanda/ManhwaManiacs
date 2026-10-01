import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/providers/genre_weights_provider.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/store/numbers_snapshot.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/share/share_side.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_30.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_hero.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_sections.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_origin.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show globalRectOf;
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// `?range=7|30|90|year` to days (365 for Year), null for anything else.
int? rangeFromParam(String? p) => switch (p) {
      '7' => 7,
      '30' => 30,
      '90' => 90,
      'year' => 365,
      _ => null,
    };

String rangeParam(int days) => days >= 365 ? 'year' : '$days';

const _segments = [
  GlassSegment<int>(value: 7, label: '7 d'),
  GlassSegment<int>(value: 30, label: '30 d'),
  GlassSegment<int>(value: 90, label: '90 d'),
  GlassSegment<int>(value: 365, label: 'Year'),
];

/// "Your reading" (`numbers`, glass 9.2.1): the streak flame and goal ring, totals, charts with summaries, lists and the Wrapped entry.
class GlassStatisticsScreen extends ConsumerStatefulWidget {
  const GlassStatisticsScreen({super.key, this.range, this.year});

  /// The `range` query parameter (the URL wins on open) and the `year` the Wrapped card shows.
  final String? range;
  final String? year;

  @override
  ConsumerState<GlassStatisticsScreen> createState() => _GlassStatisticsScreenState();
}

class _GlassStatisticsScreenState extends ConsumerState<GlassStatisticsScreen> {
  late int _days = rangeFromParam(widget.range) ?? ref.read(statsRangeProvider);
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  final GlobalKey _heroKey = GlobalKey();
  LibraryStatistics? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeShareIntent());
  }

  @override
  void didUpdateWidget(GlassStatisticsScreen old) {
    super.didUpdateWidget(old);
    final r = rangeFromParam(widget.range);
    if (r != null && r != _days && widget.range != old.range) setState(() => _days = r);
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  /// The "Your reading" keys (B15): dispatched while focus is inside the screen, listed in the `?` sheet.
  List<ShortcutEntry> _keys() {
    ShortcutEntry e(String d, ShortcutActivator a, VoidCallback f, List<String> keys) => ShortcutEntry(group: 'Your reading', activator: a, description: d, onInvoke: f, keys: keys, singleKey: a is SingleActivator && !a.shift);
    return [
      e('Previous range', const SingleActivator(LogicalKeyboardKey.bracketLeft), () => _step(-1), ['[']),
      e('Next range', const SingleActivator(LogicalKeyboardKey.bracketRight), () => _step(1), [']']),
      e('Scrub the focused chart', const SingleActivator(LogicalKeyboardKey.abort), () {}, ['←', '→']),
      e('Show as table', const SingleActivator(LogicalKeyboardKey.abort), () {}, ['T']),
      e('Share', const SingleActivator(LogicalKeyboardKey.keyS), () => unawaited(_shareRange()), ['S']),
      e('Daily goal', const SingleActivator(LogicalKeyboardKey.keyG, shift: true), () => unawaited(_goalMenu(context)), ['Shift', 'G']),
      e('Play your year', const SingleActivator(LogicalKeyboardKey.keyW), () => _openWrapped(null), ['W']),
      e('Refresh', const SingleActivator(LogicalKeyboardKey.keyR), () => unawaited(_refresh.refresh()), ['R']),
    ];
  }

  void _step(int d) {
    final i = (kNumbersRanges.indexOf(_days) + d).clamp(0, kNumbersRanges.length - 1);
    _setRange(kNumbersRanges[i]);
  }

  void _setRange(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    unawaited(ref.read(statsRangeProvider.notifier).set(days));
    context.replace(Routes.numbers({'range': rangeParam(days), if (widget.year != null) 'year': widget.year}));
  }

  Future<RefreshResult> _onRefresh() async {
    try {
      final fresh = await ref.refresh(numbersStatisticsProvider(_days).future);
      return fresh.offline ? RefreshResult.unchanged : RefreshResult.changed;
    } catch (e) {
      if (e is AppError) surfaceRefreshError(e);
      return RefreshResult.unchanged;
    }
  }

  void surfaceRefreshError(AppError e) => showGlassToast(ref, const GlassToastSpec("Couldn't load your reading", kind: GlassToastKind.error));

  Future<void> _goalMenu(BuildContext anchorContext) async {
    final goal = ref.read(dailyGoalProvider).goalMinutes;
    await showGlassMenu(
      anchorContext,
      anchor: globalRectOf(anchorContext),
      title: 'Daily goal',
      entries: [
        for (final m in kDailyGoalOptions)
          GlassMenuEntry(
            label: dailyGoalLabel(m),
            checked: m == goal,
            onSelected: () async {
              final err = await ref.read(dailyGoalProvider.notifier).setDailyGoal(m);
              if (err != null && mounted) showGlassToast(ref, const GlassToastSpec("Couldn't change this setting", kind: GlassToastKind.error));
            },
          ),
      ],
    );
  }

  void _openWrapped(Rect? origin) {
    final year = int.tryParse(widget.year ?? '') ?? annualDefaultYear(DateTime.now(), ref.read(annualIndexProvider).valueOrNull);
    ref.read(wrappedOriginProvider.notifier).state = origin;
    unawaited(ref.read(skinRouterProvider).push<void>(Routes.annual(year)));
  }

  ShareSpec _rangeSpec(LibraryStatistics s) => ShareSpec.stat(
        id: 'range-$_days',
        eyebrow: 'Your reading',
        numeral: groupThousands(s.window.chaptersRead),
        unit: 'chapters',
        contextLine: '${rangeCaption(_days)} · ${fmtDuration(s.window.secondsRead)}',
        bars: s.daily,
      );

  ShareSpec _streakSpec(LibraryStatistics s) => ShareSpec.stat(
        id: 'streak',
        eyebrow: 'Streak',
        numeral: '${s.streak.currentDays}',
        unit: 'day streak',
        contextLine: 'Longest: ${plural(s.streak.longestDays, 'day')}',
        flame: true,
      );

  Future<void> _shareRange() async {
    // The current range's own payload, gated like the bar button (not [_last], which may be another range's).
    final load = ref.read(numbersStatisticsProvider(_days)).valueOrNull;
    final s = load?.data;
    if (s == null || load!.offline || !s.hasReadingHistory || !mounted) return;
    await openShare(context, ref, _rangeSpec(s));
  }

  void _consumeShareIntent() {
    if (!mounted || ref.read(statsShareIntentProvider) != 'streak') return;
    final s = _last;
    if (s == null) return;
    ref.read(statsShareIntentProvider.notifier).state = null;
    unawaited(openShare(context, ref, _streakSpec(s)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(numbersStatisticsProvider(_days));
    final load = async.valueOrNull;
    final s = load?.data;
    if (s != null) _last = s;
    // The intent set before a fresh push lands while the payload is still loading: consume it once data is here.
    if (s != null && ref.read(statsShareIntentProvider) == 'streak') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _consumeShareIntent());
    }
    ref.listen(statsShareIntentProvider, (_, v) {
      if (v == 'streak') WidgetsBinding.instance.addPostFrameCallback((_) => _consumeShareIntent());
    });
    final now = ref.watch(clockProvider)();
    final hasHistory = s?.hasReadingHistory ?? false;
    final canShare = s != null && !(load?.offline ?? false) && hasHistory;
    final scaffold = GlassScaffold(
      title: 'Your reading',
      leading: GlassLeading.back,
      trailing: [
        if (canShare) GlassBarAction(id: 'share', label: 'Share', glyph: _exportGlyph, onPress: () => unawaited(_shareRange())),
      ],
      overflow: [
        GlassMenuEntry(label: 'Refresh', icon: PhosphorRegular.arrowClockwise, onSelected: () => unawaited(_refresh.refresh())),
        GlassMenuEntry(label: 'Daily goal', icon: GlassGlyph28.checkCircle.regular, onSelected: () => unawaited(_goalMenu(context))),
        GlassMenuEntry(label: 'Play your year', icon: GlassGlyph.play.regular, onSelected: () => _openWrapped(null)),
      ],
      refreshSliver: GlassPullToRefresh(controller: _refresh, onRefresh: _onRefresh),
      slivers: [
        SliverToBoxAdapter(
          // GlassScaffold insets the slivers by the screen margin.
          child: _Body(
            state: async,
            days: _days,
            now: now,
            heroKey: _heroKey,
            onRange: _setRange,
            onRetry: () => unawaited(_refresh.refresh()),
            rangeSpec: _rangeSpec,
            year: widget.year,
            onOpenWrapped: _openWrapped,
            onGoal: _goalMenu,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
    return RegisteredShortcuts(group: 'Your reading', entries: _keys(), child: Focus(autofocus: true, child: scaffold));
  }
}

const _exportGlyph = Glyph(regular: PhosphorRegular.export, fill: PhosphorFill.export, bold: PhosphorBold.export, light: PhosphorLight.export);

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.days, required this.now, required this.heroKey, required this.onRange, required this.onRetry, required this.rangeSpec, required this.year, required this.onOpenWrapped, required this.onGoal});
  final AsyncValue<NumbersLoad<LibraryStatistics>> state;
  final int days;
  final DateTime now;
  final GlobalKey heroKey;
  final ValueChanged<int> onRange;
  final VoidCallback onRetry;
  final ShareSpec Function(LibraryStatistics) rangeSpec;
  final String? year;
  final void Function(Rect? origin) onOpenWrapped;
  final Future<void> Function(BuildContext) onGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novels = ref.watch(novelsEnabledProvider);
    final selector = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSegmented<int>(segments: _segments, selected: days, onSelected: onRange),
    );
    final note = novels
        ? Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassLabel('Streak, totals and the clock count everything; the lists below follow Manga or Novels.', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 3))
        : const SizedBox.shrink();
    return state.when(
      loading: () => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [selector, const _Skeleton()]),
      error: (e, _) => Column(children: [
        selector,
        SizedBox(
          height: 420,
          child: GlassObjectLens(
            situation: e is NetworkError || e is TimeoutError ? LensSituation.offline : LensSituation.loadError,
            tone: e is NetworkError || e is TimeoutError ? GlassLensTone.offline : GlassLensTone.error,
            title: e is NetworkError || e is TimeoutError ? "You're offline" : "Couldn't load your reading",
            description: e is NetworkError || e is TimeoutError ? 'Your reading needs a connection the first time.' : null,
            primary: LensAction('Try again', onRetry),
          ),
        ),
      ],),
      data: (load) {
        final s = load.data;
        final neverRead = !s.hasReadingHistory;
        if (neverRead && s.followedTotal == 0) {
          return Column(children: [
            selector,
            SizedBox(
              height: 420,
              child: GlassObjectLens(
                situation: LensSituation.library,
                title: 'No reading recorded yet',
                description: 'Read a chapter and your streak and totals start here.',
                primary: LensAction('Browse sources', () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.sources()))),
              ),
            ),
          ],);
        }
        if (neverRead) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            selector,
            const SizedBox(height: 240, child: GlassObjectLens(situation: LensSituation.library, title: 'Nothing read on this profile yet', description: 'Read a chapter and your streak and totals start here.')),
            LibraryCard(stats: s),
          ],);
        }
        return _Content(load: load, days: days, now: now, heroKey: heroKey, selector: selector, note: note, rangeSpec: rangeSpec, year: year, onOpenWrapped: onOpenWrapped, onGoal: onGoal);
      },
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.load, required this.days, required this.now, required this.heroKey, required this.selector, required this.note, required this.rangeSpec, required this.year, required this.onOpenWrapped, required this.onGoal});
  final NumbersLoad<LibraryStatistics> load;
  final int days;
  final DateTime now;
  final GlobalKey heroKey;
  final Widget selector;
  final Widget note;
  final ShareSpec Function(LibraryStatistics) rangeSpec;
  final String? year;
  final void Function(Rect? origin) onOpenWrapped;
  final Future<void> Function(BuildContext) onGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = load.data;
    final genres = ref.watch(genreWeightsProvider(8)).valueOrNull ?? const [];
    final annual = ref.watch(annualIndexProvider).valueOrNull;
    final y = int.tryParse(year ?? '') ?? annualDefaultYear(now, annual);
    final coverUrl = s.shareable?.topSeries.firstOrNull?.coverUrl;
    final last7 = s.daily.length > 7 ? s.daily.sublist(s.daily.length - 7) : s.daily;
    ShareSpec stat(String id, String label, String numeral, String unit, String ctx) => ShareSpec.stat(id: id, eyebrow: label, numeral: numeral, unit: unit, contextLine: ctx, coverUrl: coverUrl);
    final cards = [
      StatTotalCard(
        icon: GlassGlyph28.clockCounterClockwise.regular,
        label: 'Time read',
        value: fmtDuration(s.window.secondsRead),
        caption: rangeCaption(days),
        allTime: '${fmtDuration(s.totals.secondsRead)} all time',
        spark: [for (final d in last7) d.secondsRead.toDouble()],
        shareSpec: stat('time', 'Time read', fmtDuration(s.window.secondsRead), '', rangeCaption(days)),
      ),
      StatTotalCard(
        icon: GlassGlyph28.stack.regular,
        label: 'Chapters',
        value: groupThousands(s.window.chaptersRead),
        caption: rangeCaption(days),
        allTime: '${groupThousands(s.totals.chaptersRead)} all time',
        spark: [for (final d in last7) d.chaptersRead.toDouble()],
        shareSpec: stat('chapters', 'Chapters', groupThousands(s.window.chaptersRead), 'chapters', rangeCaption(days)),
      ),
      StatTotalCard(
        icon: GlassGlyph30.bookOpenText.regular,
        label: 'Pages',
        value: groupThousands(s.window.pagesRead),
        caption: rangeCaption(days),
        allTime: '${groupThousands(s.totals.pagesRead)} all time',
        spark: [for (final d in last7) d.pagesRead.toDouble()],
        shareSpec: stat('pages', 'Pages', groupThousands(s.window.pagesRead), 'pages', rangeCaption(days)),
      ),
      StatTotalCard(
        icon: GlassGlyph28.books.regular,
        label: 'Series',
        value: groupThousands(s.window.seriesRead),
        caption: rangeCaption(days),
        allTime: '${groupThousands(s.totals.seriesRead)} all time',
        spark: [for (final d in last7) d.sessions.toDouble()],
        shareSpec: stat('series', 'Series', groupThousands(s.window.seriesRead), 'series', rangeCaption(days)),
      ),
    ];
    final wrapped = annual != null && annualAvailable(now, annual)
        ? WrappedEntryCard(
            annual: annual,
            year: y,
            onOpen: onOpenWrapped,
            onYear: (yy) => ref.read(skinRouterProvider).replace<Object?>(Routes.numbers({'range': rangeParam(days), 'year': yy})),
          )
        : null;
    // Lists follow Manga or Novels; the streak, totals and the clock count both (glass 8.0.8).
    final scope = ref.watch(contentModeScopeProvider);
    final bySeries = scope.filter(s.bySeries, (r) => r.sourceId);
    final bySource = scope.filter(s.bySource, (r) => r.sourceId);
    final sessions = scope.filter(s.recentSessions, (r) => r.sourceId);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final hero = StatsHero(stats: s, now: now, rangeDays: days, heroKey: heroKey);
        final perDay = ChaptersPerDay(daily: s.daily, days: days, now: now);
        final heat = days >= 365 ? YearHeatmap(daily: s.daily, now: now, onPlayYear: () => onOpenWrapped(null)) : null;
        final clock = ClockCard(hours: s.byHour);
        final radar = GenreRadarCard(genres: genres);
        Widget gap(double h) => SizedBox(height: h);
        Widget row(List<(int, Widget)> cells) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < cells.length; i++) ...[if (i > 0) const SizedBox(width: 20), Expanded(flex: cells[i].$1, child: cells[i].$2)],
            ],);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (load.offline) ...[
            GlassInlineNotice(message: 'Last updated ${snapshotAge(load.savedAt, now)}', variant: GlassNoticeVariant.warning),
            gap(12),
          ],
          selector,
          note,
          hero,
          gap(20),
          if (wide) row([for (final c in cards) (1, c)]) else ...[row([(1, cards[0]), (1, cards[1])]), gap(12), row([(1, cards[2]), (1, cards[3])])],
          gap(20),
          if (wide) row([(8, perDay), (4, clock)]) else ...[perDay, gap(20), clock],
          if (heat != null) ...[gap(20), heat],
          gap(20),
          if (wide) row([(4, radar), (8, MostRead(series: bySeries))]) else ...[radar, gap(20), MostRead(series: bySeries)],
          gap(20),
          if (wide) row([(6, SourcesCard(sources: bySource)), (6, RecentSessions(sessions: sessions))]) else ...[SourcesCard(sources: bySource), gap(20), RecentSessions(sessions: sessions)],
          gap(20),
          LibraryCard(stats: s),
          if (wrapped != null) ...[gap(20), wrapped],
          gap(20),
          StatsFootnotes(stats: s),
        ],);
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const GlassSkeletonGroup(
        label: 'Loading your reading',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: GlassSkeleton(width: 112, height: 112, circle: true)),
          SizedBox(height: 16),
          Row(children: [Expanded(child: GlassSkeleton(height: 120, radius: 26)), SizedBox(width: 12), Expanded(child: GlassSkeleton(height: 120, radius: 26))]),
          SizedBox(height: 12),
          Row(children: [Expanded(child: GlassSkeleton(height: 120, radius: 26)), SizedBox(width: 12), Expanded(child: GlassSkeleton(height: 120, radius: 26))]),
          SizedBox(height: 20),
          GlassSkeleton(height: 220, radius: 26),
          SizedBox(height: 20),
          GlassSkeleton(height: 160, radius: 26),
          SizedBox(height: 12),
          GlassSkeleton(height: 160, radius: 26),
        ],),
      );
}
