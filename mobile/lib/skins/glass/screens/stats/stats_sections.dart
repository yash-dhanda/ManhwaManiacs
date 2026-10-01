import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/reading_stats.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart' show GenreWeight;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/share/share_side.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart' show GlassStatus;
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart' hide heatLevel;
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show globalRectOf;
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// A titled slab (radius 26, padding 16) holding one chart or list.
class StatsPanel extends StatelessWidget {
  const StatsPanel({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GlassSlab(
        padding: const EdgeInsets.all(16),
        sink: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [Expanded(child: Semantics(header: true, headingLevel: 2, child: GlassLabel(title, role: gt.typeHeadline, color: gt.colorLabel1))), if (trailing != null) trailing!]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// -- totals -----------------------------------------------------------------------------------------------------

/// One of the four total cards: the window figure, its range caption, the all-time figure and a 7-point sparkline.
class StatTotalCard extends ConsumerWidget {
  const StatTotalCard({super.key, required this.icon, required this.label, required this.value, required this.caption, required this.allTime, required this.spark, required this.shareSpec});
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final String allTime;
  final List<double> spark;
  final ShareSpec shareSpec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void menu() => unawaited(showGlassMenu(
          context,
          anchor: globalRectOf(context),
          title: '$label actions',
          entries: [GlassMenuEntry(label: 'Share this card', icon: PhosphorRegular.export, onSelected: () => unawaited(openShare(context, ref, shareSpec)))],
        ),);
    return GlassSlab(
      padding: const EdgeInsets.all(16),
      semanticsLabel: '$label, $value, $caption, $allTime',
      onLongPress: menu,
      onKey: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.period) {
          menu();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: gt.colorIris400),
          const SizedBox(height: 8),
          GlassLabel(value, role: gt.typeNumeral, color: gt.colorLabel1),
          GlassLabel(label, role: gt.typeFootnote, color: gt.colorLabel2),
          GlassLabel(caption, role: gt.typeCaption1, color: gt.colorLabel3),
          GlassLabel(allTime, role: gt.typeCaption1, color: gt.colorLabel3),
          const SizedBox(height: 8),
          SizedBox(height: 24, width: double.infinity, child: CustomPaint(painter: SparkPainter(spark))),
        ],
      ),
    );
  }
}

class SparkPainter extends CustomPainter {
  const SparkPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final hi = values.reduce((a, b) => a > b ? a : b);
    final lo = values.reduce((a, b) => a < b ? a : b);
    final range = hi - lo == 0 ? 1.0 : hi - lo;
    final p = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - lo) / range * (size.height - 2) - 1;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = gt.colorIris500,);
  }

  @override
  bool shouldRepaint(SparkPainter old) => old.values != values;
}

// -- charts -----------------------------------------------------------------------------------------------------

/// The chapters-per-day bars with minutes as the second axis; the Year range shows weekly totals.
class ChaptersPerDay extends StatelessWidget {
  const ChaptersPerDay({super.key, required this.daily, required this.days, required this.now});
  final List<DailyActivity> daily;
  final int days;
  final DateTime now;

  bool _today(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;

  @override
  Widget build(BuildContext context) {
    final year = days >= 365;
    final weeks = year ? weeklyTotals(daily) : const <WeekTotal>[];
    final byDay = {for (final d in daily) d.date: d};
    final byWeek = {for (final w in weeks) w.start: w};
    final data = year
        ? [for (final w in weeks) ChartDatum(day: w.start, label: 'Week of ${w.start.day} ${monthShort(w.start)}', value: w.chapters.toDouble(), second: (w.seconds / 60).roundToDouble())]
        : [for (final d in daily) ChartDatum(day: d.date, value: d.chaptersRead.toDouble(), second: (d.secondsRead / 60).roundToDouble(), partial: _today(d.date))];
    final best = bestPagesDay(daily);
    final active = daily.any((d) => d.pagesRead > 0 || d.chaptersRead > 0);
    return StatsPanel(
      title: year ? 'Chapters per week' : 'Chapters per day',
      trailing: best == null ? null : Flexible(child: GlassLabel('Best day: ${shortDay(best.date)} · ${plural(best.pagesRead, 'page')}', role: gt.typeCaption1, color: gt.colorLabel2, maxLines: 2)),
      child: GlassChart(
        kind: GlassChartKind.bars,
        chartId: year ? 'chapters-week' : 'chapters-day',
        title: year ? 'Chapters per week' : 'Chapters per day',
        data: active ? data : const [],
        summary: chapterSummary(daily, days),
        emptyText: 'Nothing read in the last ${plural(days, 'day')}',
        valueHeader: 'Chapters',
        secondHeader: 'Minutes',
        readout: (d) {
          if (year) return weekReadout(byWeek[d.day]!);
          final a = byDay[d.day]!;
          return dayReadout(a, today: d.partial);
        },
      ),
    );
  }
}

/// The 53 x 7 year heatmap by `heatLevel(pages)`.
class YearHeatmap extends StatelessWidget {
  const YearHeatmap({super.key, required this.daily, required this.now, required this.onPlayYear});
  final List<DailyActivity> daily;
  final DateTime now;
  final VoidCallback? onPlayYear;

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final d in daily) d.date: d};
    return StatsPanel(
      title: 'Your year',
      trailing: onPlayYear == null ? null : GlassButton(label: 'Play your year', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onPlayYear),
      child: GlassChart(
        kind: GlassChartKind.heatmap,
        chartId: 'heatmap',
        title: 'Reading heatmap',
        data: [for (final d in daily) ChartDatum(day: d.date, value: d.pagesRead.toDouble(), partial: d.date.year == now.year && d.date.month == now.month && d.date.day == now.day)],
        summary: 'You read on ${daysRead(daily)} of the last ${daily.length} days.',
        today: now,
        heatLevelOf: (v) => heatLevel(v.round()),
        emptyText: 'Nothing read in the last 365 days',
        valueHeader: 'Pages',
        readout: (d) => dayReadout(byDay[d.day]!, today: d.partial),
      ),
    );
  }
}

class ClockCard extends StatelessWidget {
  const ClockCard({super.key, required this.hours});
  final List<HourActivity> hours;

  @override
  Widget build(BuildContext context) {
    final reading = clockBand(hours);
    final byHour = {for (final h in hours) h.hour: h};
    final data = [for (var h = 0; h < 24; h++) ChartDatum(label: hourLabel(h), value: (byHour[h]?.pagesRead ?? 0).toDouble())];
    return StatsPanel(
      title: 'When you read',
      child: GlassChart(
        kind: GlassChartKind.clock,
        chartId: 'clock',
        title: 'When you read',
        data: reading == null ? const [] : data,
        summary: reading == null ? 'No reading recorded yet.' : '${peakLine(reading.peakHour)} · ${bandTitle(reading.band)}',
        emptyText: 'Nothing read yet',
        valueHeader: 'Pages',
        readout: (d) => '${d.label} · ${plural(d.value.round(), 'page')}',
      ),
    );
  }
}

class GenreRadarCard extends ConsumerWidget {
  const GenreRadarCard({super.key, required this.genres});
  final List<GenreWeight> genres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = genres.take(8).toList();
    if (top.length < 3) {
      return StatsPanel(
        title: 'Genres',
        child: top.isEmpty
            ? GlassLabel('Read a few series and your genres show up here.', role: gt.typeCallout, color: gt.colorLabel2, maxLines: 3)
            : Column(
                children: [for (final g in top) Align(alignment: Alignment.centerLeft, child: GlassLabel('${g.genre} · ${(g.weight * 100).round()} %', role: gt.typeBody, color: gt.colorLabel1))],),
      );
    }
    final a = top.first.genre, b = top[1].genre;
    return StatsPanel(
      title: 'Genres',
      child: GlassChart(
        kind: GlassChartKind.radar,
        chartId: 'genres',
        title: 'Genres',
        data: [for (final g in top) ChartDatum(label: g.genre, value: g.weight * 100)],
        summary: '$a is your top genre, then $b.',
        valueHeader: 'Share',
        readout: (d) => '${d.label} · ${d.value.round()} %',
        onLabel: (g) => unawaited(ref.read(skinRouterProvider).push<void>(Routes.picks({'genre': g}))),
      ),
    );
  }
}

// -- lists ------------------------------------------------------------------------------------------------------

class SourcesCard extends StatelessWidget {
  const SourcesCard({super.key, required this.sources});
  final List<SourceActivity> sources;

  @override
  Widget build(BuildContext context) {
    final total = sources.fold<int>(0, (a, s) => a + s.secondsRead);
    return StatsPanel(
      title: 'Where you read',
      child: sources.isEmpty
          ? GlassLabel('Nothing read in this range.', role: gt.typeCallout, color: gt.colorLabel2)
          : Column(children: [
              for (final s in sources.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Semantics(
                    container: true,
                    label: '${s.name}, ${fmtDuration(s.secondsRead)}, ${plural(s.pagesRead, 'page')}, ${_pct(s.secondsRead, total)}',
                    child: ExcludeSemantics(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Expanded(child: GlassLabel(s.name, role: gt.typeHeadline, color: gt.colorLabel1)),
                          GlassLabel(_pct(s.secondsRead, total), role: gt.typeMono, color: gt.colorLabel2),
                        ],),
                        GlassLabel('${fmtDuration(s.secondsRead)} · ${plural(s.pagesRead, 'page')}', role: gt.typeFootnote, color: gt.colorLabel2),
                        const SizedBox(height: 6),
                        _Bar(total == 0 ? 0 : s.secondsRead / total),
                      ],),
                    ),
                  ),
                ),
            ],),
    );
  }

  static String _pct(int part, int total) => total <= 0 ? '0 %' : '${(part * 100 / total).round()} %';
}

class _Bar extends StatelessWidget {
  const _Bar(this.share);
  final double share;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(color: gt.colorFill1, borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
              alignment: Alignment.centerLeft, widthFactor: share.clamp(0.0, 1.0), child: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris500, borderRadius: BorderRadius.circular(2))),),
        ),
      );
}

class MostRead extends ConsumerWidget {
  const MostRead({super.key, required this.series});
  final List<SeriesActivity> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StatsPanel(
        title: 'Most read',
        child: series.isEmpty
            ? GlassLabel('Nothing read in this range.', role: gt.typeCallout, color: gt.colorLabel2)
            : Column(children: [
                for (final s in series.take(5))
                  _Row(
                    label: '${s.title ?? s.seriesKey}, ${fmtDuration(s.secondsRead)}, ${plural(s.chaptersRead, 'chapter')}',
                    onTap: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.feature(s.sourceId, s.seriesKey))),
                    leading: SizedBox(
                        width: 40,
                        height: 60,
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: s.coverUrl == null ? ColoredBox(color: gt.colorSurface2) : GlassCoverImage(url: s.coverUrl!, width: 40)),),
                    title: s.title ?? s.seriesKey,
                    subtitle: '${fmtDuration(s.secondsRead)} · ${plural(s.chaptersRead, 'chapter')}',
                  ),
              ],),
      );
}

class RecentSessions extends ConsumerWidget {
  const RecentSessions({super.key, required this.sessions});
  final List<RecentSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StatsPanel(
        title: 'Recent sessions',
        child: sessions.isEmpty
            ? GlassLabel('Nothing read yet.', role: gt.typeCallout, color: gt.colorLabel2)
            : Column(children: [
                for (final s in sessions.take(6))
                  _Row(
                    label: '${s.title ?? s.seriesKey}, chapter ${_ch(s)}, ${plural(s.pagesRead, 'page')}, ${fmtDuration(s.secondsRead)}',
                    onTap: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.reader(s.sourceId, s.seriesKey, s.chapterKey))),
                    leading: SizedBox(width: 48, child: GlassLabel(_time(s.startedAt), role: gt.typeMono, color: gt.colorLabel2)),
                    title: s.title ?? s.seriesKey,
                    subtitle: 'Ch ${_ch(s)} · ${plural(s.pagesRead, 'page')} · ${fmtDuration(s.secondsRead)}',
                  ),
              ],),
      );

  static String _ch(RecentSession s) => s.chapterNumber == null ? '?' : (s.chapterNumber! == s.chapterNumber!.roundToDouble() ? '${s.chapterNumber!.round()}' : '${s.chapterNumber}');
  static String _time(DateTime? t) => t == null ? '--:--' : '${t.toLocal().hour.toString().padLeft(2, '0')}:${t.toLocal().minute.toString().padLeft(2, '0')}';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.onTap, required this.leading, required this.title, required this.subtitle});
  final String label;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GlassPressable(
          material: GlassMaterial.content,
          onTap: onTap,
          semanticsLabel: label,
          builder: (context, info) => Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassLabel(title, role: gt.typeHeadline, color: gt.colorLabel1),
                    GlassLabel(subtitle, role: gt.typeFootnote, color: gt.colorLabel2),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class LibraryCard extends StatelessWidget {
  const LibraryCard({super.key, required this.stats});
  final LibraryStatistics stats;

  @override
  Widget build(BuildContext context) {
    final by = stats.byReadingStatus;
    final data = [
      for (final s in GlassStatus.values) ChartDatum(label: s.name, value: (by[_wire(s)] ?? 0).toDouble()),
    ];
    return StatsPanel(
      title: 'Your library',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassLabel('${stats.followedTotal} followed · ${plural(stats.favorites, 'favourite')} · ${groupThousands(stats.chaptersCompleted)} chapters finished',
              role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 3,),
          const SizedBox(height: 8),
          GlassChart(
            kind: GlassChartKind.statusBars,
            chartId: 'status',
            title: 'Your library by status',
            data: data,
            summary: '${stats.followedTotal} series across six statuses.',
            valueHeader: 'Series',
            readout: (d) => '${StatusNames.spoken(d.label)} · ${d.value.round()}',
          ),
        ],
      ),
    );
  }

  static String _wire(GlassStatus s) => switch (s) {
        GlassStatus.onHold => 'on_hold',
        GlassStatus.planToRead => 'plan_to_read',
        _ => s.name,
      };
}

abstract final class StatusNames {
  static String spoken(String? name) => GlassStatus.values.where((s) => s.name == name).firstOrNull?.spoken ?? name ?? '';
}

// -- Wrapped entry and footnotes -----------------------------------------------------------------------------------

/// The tall Wrapped card (radius 26): the year in `display`, the title, how many days are recorded and a fan of three mini cards.
class WrappedEntryCard extends ConsumerWidget {
  const WrappedEntryCard({super.key, required this.annual, required this.year, required this.onOpen, required this.onYear});
  final Annual annual;
  final int year;
  final void Function(Rect origin) onOpen;
  final ValueChanged<int> onYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = wrappedTitle(annual) == WrappedTitle.soFar ? 'Your $year so far' : 'Your $year in chapters';
    final years = annual.availableYears;
    return Builder(
      builder: (context) => GlassSlab(
        padding: const EdgeInsets.all(20),
        semanticsLabel: title,
        onTap: () => onOpen(globalRectOf(context)),
        onLongPress: years.length < 2
            ? null
            : () => unawaited(showGlassMenu(
                  context,
                  anchor: globalRectOf(context),
                  title: 'Year',
                  entries: [for (final y in years) GlassMenuEntry(label: '$y', checked: y == year, onSelected: () => onYear(y))],
                ),),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassLabel('$year', role: gt.typeDisplay, color: gt.colorLabel1),
                  GlassLabel(title, role: gt.typeTitle3, color: gt.colorLabel1, maxLines: 2),
                  if (annual.recordedDays < 30) GlassLabel('${plural(annual.recordedDays, 'day')} recorded so far', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _Fan(),
          ],
        ),
      ),
    );
  }
}

class _Fan extends StatelessWidget {
  const _Fan();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        height: 160,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (i, a) in [-0.105, 0.0, 0.105].indexed)
              Positioned(
                left: i * 30.0,
                top: 0,
                child: Transform.rotate(
                  angle: a,
                  child: Container(
                      width: 54,
                      height: 96,
                      decoration:
                          BoxDecoration(color: [gt.colorIris800, gt.colorIris700, gt.colorIris600][i], borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x1FFFFFFF))),),
                ),
              ),
          ],
        ),
      );
}

class StatsFootnotes extends StatelessWidget {
  const StatsFootnotes({super.key, required this.stats});
  final LibraryStatistics stats;

  @override
  Widget build(BuildContext context) {
    final since = stats.totals.firstSessionAt;
    return GlassLabel(
      'Days start at ${utcOffsetLabel(stats.timezoneOffsetMinutes)} · Each session counts up to ${stats.sessionCapSeconds ~/ 60} min of idle${since == null ? '' : ' · Recording since ${dateLabel(since.toLocal())}'}',
      role: gt.typeFootnote,
      color: gt.colorLabel3,
      maxLines: 4,
    );
  }
}
