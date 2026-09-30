import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/genre_weights_provider.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart' show GenreWeight;
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_stat_block.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chapters_per_day.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_chart.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/genre_radar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/stat_blocks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/streak_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/year_heatmap.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// What a range panel tells its screen once its data is on screen.
typedef PanelReport = void Function(int days, LibraryStatistics stats, {required bool offline});

/// One range's scroll view (cinematic 9.2.1): the lead, the charts and the lists,
/// with the states of 9.2.1 (galley proof, nothing recorded, followed but never
/// read, offline, correction).
class RangePanel extends ConsumerStatefulWidget {
  const RangePanel({
    super.key,
    required this.days,
    required this.selection,
    required this.claimSignature,
    required this.report,
    required this.overlap,
  });

  final int days;
  final ValueNotifier<int?> selection;

  /// True once, for the first data paint of the visit.
  final bool Function() claimSignature;
  final PanelReport report;
  final SliverOverlapAbsorberHandle overlap;

  @override
  ConsumerState<RangePanel> createState() => _RangePanelState();
}

class _RangePanelState extends ConsumerState<RangePanel> {
  bool? _signature;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(numbersStatisticsProvider(widget.days));
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final pad = CineGrid.of(context).left;
    Widget body(List<Widget> slivers) => CinePullToReprint(
          onRefresh: () async {
            ref.invalidate(numbersStatisticsProvider(widget.days));
            try {
              await ref.read(numbersStatisticsProvider(widget.days).future);
            } catch (_) {}
          },
          child: CustomScrollView(
            key: PageStorageKey<int>(widget.days),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverOverlapInjector(handle: widget.overlap),
              ...slivers,
              const SliverToBoxAdapter(child: SizedBox(height: 64)),
            ],
          ),
        );
    return async.when(
      loading: () => body([SliverPadding(padding: EdgeInsets.fromLTRB(pad, 24, pad, 0), sliver: SliverToBoxAdapter(child: _Galley(wide: wide)))]),
      error: (e, _) => body([
        SliverToBoxAdapter(
          child: CineNotice(
            tone: CineNoticeTone.error,
            kicker: 'CORRECTION',
            headline: "The numbers didn't load.",
            deck: e is AppError ? e.userMessage : null,
            primary: CineNoticeAction('Try again', () => ref.invalidate(numbersStatisticsProvider(widget.days))),
          ),
        ),
      ]),
      data: (load) {
        final stats = load.data;
        _signature ??= widget.claimSignature();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.report(widget.days, stats, offline: load.offline);
        });
        return body(_content(context, stats, pad, wide));
      },
    );
  }

  List<Widget> _content(BuildContext context, LibraryStatistics stats, double pad, bool wide) {
    final scope = ref.watch(contentModeScopeProvider);
    final novels = ref.watch(novelsEnabledProvider);
    final now = ref.watch(clockProvider)();
    final sig = _signature ?? false;
    Widget padded(Widget w) => SliverPadding(padding: EdgeInsets.symmetric(horizontal: pad), sliver: SliverToBoxAdapter(child: Align(alignment: Alignment.topLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960), child: w))));

    if (!stats.hasReadingHistory) {
      if (stats.followedTotal == 0) {
        return [
          SliverToBoxAdapter(
            child: CineNotice(
              tone: CineNoticeTone.empty,
              kicker: 'NOTHING RECORDED YET',
              headline: 'Read a chapter and your numbers start here.',
              primary: CineNoticeAction('Go to library', () => context.go(Routes.library())),
            ),
          ),
        ];
      }
      return [
        SliverToBoxAdapter(
          child: CineNotice(
            tone: CineNoticeTone.empty,
            kicker: 'NOTHING RECORDED YET',
            headline: 'Read a chapter and your numbers start here.',
            primary: CineNoticeAction('Go to library', () => context.go(Routes.library())),
          ),
        ),
        padded(const SectionHead('Your library')),
        padded(YourLibrary(stats: stats)),
      ];
    }

    final w = stats.window;
    final stat = <Widget>[
      CineStatBlock(kicker: 'CHAPTERS', value: fmt(w.chaptersRead), caption: '${fmt(stats.totals.chaptersRead)} all time', footnote: 3, signature: sig),
      CineStatBlock(kicker: 'TIME', value: hoursValue(w.secondsRead), caption: '${hoursLower(stats.totals.secondsRead)} all time', footnote: 2, signature: sig, ruleDelay: const Duration(milliseconds: 32)),
      CineStatBlock(kicker: 'PAGES', value: fmt(w.pagesRead), caption: '${fmt(stats.totals.pagesRead)} all time', signature: sig, ruleDelay: const Duration(milliseconds: 64)),
      CineStatBlock(kicker: 'SERIES', value: fmt(w.seriesRead), caption: '${fmt(stats.followedTotal)} followed', signature: sig, ruleDelay: const Duration(milliseconds: 96)),
    ];
    final selection = widget.selection;
    final daily = stats.daily;
    final byHour = [for (var h = 0; h < 24; h++) stats.byHour.where((x) => x.hour == h).fold<int>(0, (a, x) => a + x.secondsRead)];
    final clock = readClock(byHour);
    final genres = ref.watch(genreWeightsProvider(8)).valueOrNull ?? const <GenreWeight>[];
    final sources = scope.filter(stats.bySource, (s) => s.sourceId);
    final series = scope.filter(stats.bySeries, (s) => s.sourceId);
    final sessions = scope.filter(stats.recentSessions, (s) => s.sourceId);

    final clockBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClockChart(byHour: byHour),
      const SizedBox(height: 12),
      if (byHour.any((s) => s > 0)) TypedSentence(numbersClockSentence(clock)),
    ],);
    final radarBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (genres.isEmpty) CineRoleText('Genres appear once a few series are read.', context.cine.typeCaption, color: CineColors.ink60) else GenreRadar(genres: genres),
      if (genres.length >= 3) ...[const SizedBox(height: 8), CineRoleText(genreSummary(genres), context.cine.typeCaption, color: CineColors.ink60)],
    ],);

    return [
      padded(Padding(padding: const EdgeInsets.only(top: 8), child: StreakBlock(streak: stats.streak, daily: daily, signature: sig, wide: wide))),
      padded(Padding(padding: const EdgeInsets.only(top: 32), child: StatGrid(blocks: stat, wide: wide))),
      padded(const SectionHead('Chapters per day', footnote: 1)),
      padded(ValueListenableBuilder<int?>(
        valueListenable: selection,
        builder: (context, sel, _) => widget.days >= 365
            ? YearHeatmap(daily: daily, today: now, selected: sel, onSelect: (i) => selection.value = i)
            : ChaptersPerDay(daily: daily, days: widget.days, selected: sel, onSelect: (i) => selection.value = i, tablet: wide),
      ),),
      if (wide)
        padded(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHead('When you read'), clockBlock])),
          const SizedBox(width: 24),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHead('Your genres'), radarBlock])),
        ],),)
      else ...[
        padded(const SectionHead('When you read')),
        padded(clockBlock),
        padded(const SectionHead('Your genres')),
        padded(radarBlock),
      ],
      if (sources.isNotEmpty) ...[padded(const SectionHead('Where you read')), padded(WhereYouRead(sources: sources))],
      if (series.isNotEmpty) ...[padded(const SectionHead('Most read')), padded(MostRead(series: series, now: now))],
      if (sessions.isNotEmpty) ...[
        padded(const SectionHead('Recent sessions')),
        SliverPadding(padding: EdgeInsets.symmetric(horizontal: pad), sliver: RecentSessionsSliver(sessions: sessions)),
      ],
      padded(const SectionHead('Your library')),
      padded(YourLibrary(stats: stats)),
      padded(Padding(padding: const EdgeInsets.only(top: 32), child: Footnotes(stats: stats, novels: novels))),
    ];
  }
}

/// The clock sentence, typed at 50 ms per grapheme in `type.subhead`.
class TypedSentence extends StatelessWidget {
  const TypedSentence(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final role = context.cine.typeSubhead;
    return TypedHeadline(text, style: CineText.style(context, role).copyWith(color: CineColors.ink100), cap: role.cap);
  }
}

/// The galley proof (7.17): four numeral bars at the numeral height (40 % wide), a chart plate and
/// list bars, flickering after 120 ms.
class _Galley extends StatelessWidget {
  const _Galley({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final numeralH = wide ? 72.0 : 56.0;
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: CineDelayed(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < 4; i++)
            Padding(padding: const EdgeInsets.only(bottom: 24), child: Align(alignment: Alignment.centerLeft, child: CineGalleyNumeral(size: numeralH, index: i))),
          const SizedBox(height: 160, child: CineGalleyPlate(index: 4)),
          const SizedBox(height: 24),
          for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: CineGalleyLine(lineHeight: 20, index: 5 + i)),
        ],),
      ),
    );
  }
}
