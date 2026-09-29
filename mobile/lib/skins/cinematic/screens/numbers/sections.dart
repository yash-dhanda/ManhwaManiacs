import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cover.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/letter_reveal.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/rules.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// An H3 of The Numbers: its section rule draws 120 ms before the letters
/// (`SetHeading`, `type.section`), with an optional raised footnote mark.
class SectionHead extends StatelessWidget {
  const SectionHead(this.text, {super.key, this.footnote});
  final String text;
  final int? footnote;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const DrawnRule(height: 1, color: CineColors.rule2),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(child: SetHeading(text, role: t.typeSection, trigger: SetTrigger.inView, delay: const Duration(milliseconds: 120))),
          if (footnote != null) Padding(padding: const EdgeInsets.only(left: 2), child: Text.rich(TextSpan(children: [footnoteMark(footnote!, (cineStyle(context, t.typeSection).fontSize ?? 24) * 0.6)]))),
        ],),
      ],),
    );
  }
}

/// "812 pages · 9 h · 41 %".
String sourceFolio(SourceActivity s, int totalSeconds) => '${fmt(s.pagesRead)} pages · ${hoursLower(s.secondsRead)} · ${totalSeconds == 0 ? 0 : (s.secondsRead / totalSeconds * 100).round()} %';

/// Sources ranked by time, each with a 2 px determinate rule of its share.
class WhereYouRead extends StatelessWidget {
  const WhereYouRead({super.key, required this.sources});
  final List<SourceActivity> sources;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final ranked = [...sources]..sort((a, b) => b.secondsRead.compareTo(a.secondsRead));
    final total = ranked.fold<int>(0, (a, s) => a + s.secondsRead);
    return Column(children: [
      for (final s in ranked)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Semantics(
            container: true,
            label: '${s.name}, ${sourceFolio(s, total)}',
            excludeSemantics: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: CineText(s.name, t.typeUi, maxLines: 1, overflow: TextOverflow.ellipsis)),
                CineText(sourceFolio(s, total), t.typeFolio, color: CineColors.ink60),
              ],),
              const SizedBox(height: 8),
              ShareRule(value: total == 0 ? 0 : s.secondsRead / total),
            ],),
          ),
        ),
    ],);
  }
}

/// `2 D AGO`, `5 H AGO`, `3 W AGO`, `4 MO AGO` (a folio).
String agoFolio(DateTime last, DateTime now) {
  final d = now.difference(last);
  if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)} M AGO';
  if (d.inHours < 24) return '${d.inHours} H AGO';
  if (d.inDays < 14) return '${d.inDays} D AGO';
  if (d.inDays < 60) return '${d.inDays ~/ 7} W AGO';
  return '${d.inDays ~/ 30} MO AGO';
}

class _PressRow extends StatefulWidget {
  const _PressRow({required this.onTap, required this.child, required this.label});
  final VoidCallback onTap;
  final Widget child;
  final String label;

  @override
  State<_PressRow> createState() => _PressRowState();
}

class _PressRowState extends State<_PressRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        excludeSemantics: true,
        onTap: widget.onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: ConstrainedBox(constraints: BoxConstraints(minHeight: minHit(context)), child: ColoredBox(color: _down ? CineColors.paper3 : Colors.transparent, child: widget.child)),
        ),
      );
}

/// Up to five rows of the most-read series: a Bodoni numeral, a 40 x 60 cover
/// (a `Hero` match cut to the feature page), title, pages, chapters, time.
class MostRead extends ConsumerWidget {
  const MostRead({super.key, required this.series, required this.now});
  final List<SeriesActivity> series;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final cover = ref.watch(coverImageProvider);
    final rows = series.take(5).toList();
    return Column(children: [
      for (var i = 0; i < rows.length; i++)
        _PressRow(
          label: '${i + 1}. ${rows[i].title ?? rows[i].seriesKey}',
          onTap: () => context.push(Routes.feature(rows[i].sourceId, rows[i].seriesKey)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 28, child: Text('${i + 1}', style: cineStyle(context, t.typeNumeral, color: CineColors.ink45, size: 24, features: kNumeralFeatures))),
              Hero(
                tag: 'cover:${rows[i].sourceId}:${rows[i].seriesKey}',
                child: SizedBox(
                  width: 40,
                  height: 60,
                  child: rows[i].coverUrl == null
                      ? const ColoredBox(color: CineColors.paper2)
                      : Image(image: cover(rows[i].coverUrl!, width: 40), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: CineColors.paper2)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CineText(rows[i].title ?? rows[i].seriesKey, t.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  CineText('${fmt(rows[i].pagesRead)} pages · ${rows[i].chaptersRead} chapters · ${hoursLower(rows[i].secondsRead)}', t.typeCaption, color: CineColors.ink60),
                  if (rows[i].lastReadAt != null)
                    Builder(builder: (context) {
                      final folio = 'Last read ${agoFolio(rows[i].lastReadAt!.toLocal(), now)}';
                      return CineText(folio, t.typeCaption, color: CineColors.ink60, semanticsLabel: spokenFolio(folio));
                    },),
                ],),
              ),
            ],),
          ),
        ),
    ],);
  }
}

/// `21:04`.
String sessionTime(DateTime t) => DateFormat('HH:mm').format(t.toLocal());

/// Recent sessions: §7.16 standard rows, 56 px minimum, built lazily.
class RecentSessionsSliver extends StatelessWidget {
  const RecentSessionsSliver({super.key, required this.sessions});
  final List<RecentSession> sessions;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return SliverList.builder(
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        final chapter = s.chapterNumber == null ? null : 'CH ${s.chapterNumber! % 1 == 0 ? s.chapterNumber!.toInt() : s.chapterNumber}';
        final minutes = (s.secondsRead / 60).round();
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 52, child: s.startedAt == null ? null : CineText(sessionTime(s.startedAt!), t.typeFolio, color: CineColors.ink45)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CineText(s.title ?? s.seriesKey, t.typeUi, maxLines: 1, overflow: TextOverflow.ellipsis),
                  CineText('${s.pagesRead} pages · $minutes min', t.typeCaption, color: CineColors.ink60),
                ],),
              ),
              if (chapter != null)
                CineTap(
                  label: 'Open ${spokenFolio(chapter)}',
                  minWidth: false,
                  // TODO(mobile/06): `enterReader(context, target, entry: ReaderEntry.dip)`.
                  onTap: () => context.push(Routes.reader(s.sourceId, s.seriesKey, s.chapterKey)),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: CineText(chapter, t.typeFolio, color: CineColors.spot, excludeSemantics: true)),
                ),
            ],),
          ),
        );
      },
    );
  }
}

/// The library block: a credit line and one row per reading status.
class YourLibrary extends StatelessWidget {
  const YourLibrary({super.key, required this.stats});
  final LibraryStatistics stats;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final total = stats.byReadingStatus.values.fold<int>(0, (a, b) => a + b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CineText('${fmt(stats.followedTotal)} FOLLOWED · ${fmt(stats.favorites)} ${stats.favorites == 1 ? 'FAVOURITE' : 'FAVOURITES'} · ${fmt(stats.chaptersCompleted)} CHAPTERS FINISHED', t.typeCredit, color: CineColors.ink60),
      const SizedBox(height: 12),
      for (final (key, label) in kStatusRows)
        if ((stats.byReadingStatus[key] ?? 0) > 0) ...[
          const HairRule(),
          Semantics(
            container: true,
            label: '$label, ${stats.byReadingStatus[key]}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                Row(children: [
                  Expanded(child: CineText(label, t.typeKicker, color: CineColors.ink60)),
                  CineText(fmt(stats.byReadingStatus[key]!), t.typeUi),
                ],),
                const SizedBox(height: 8),
                ShareRule(value: total == 0 ? 0 : stats.byReadingStatus[key]! / total),
              ],),
            ),
          ),
        ],
    ],);
  }
}

/// The footnotes: raised folios 1, 2 and 3, the last sentence only when novels are on.
class Footnotes extends StatelessWidget {
  const Footnotes({super.key, required this.stats, required this.novels});
  final LibraryStatistics stats;
  final bool novels;

  static String offsetLabel(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final a = minutes.abs();
    return 'UTC$sign${(a ~/ 60).toString().padLeft(2, '0')}:${(a % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final style = cineStyle(context, t.typeCaption, color: CineColors.ink60);
    final first = stats.totals.firstSessionAt;
    final since = first == null ? null : DateFormat('d MMMM y', 'en_US').format(first.toLocal());
    final cap = stats.sessionCapSeconds ~/ 60;
    InlineSpan mark(int n) => footnoteMark(n, style.fontSize ?? 13);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Text.rich(
        TextSpan(style: style, children: [
          mark(1),
          TextSpan(text: ' Days start at ${offsetLabel(stats.timezoneOffsetMinutes)}. '),
          mark(2),
          TextSpan(text: ' Each session counts up to $cap minutes of reading time. '),
          if (since != null) ...[mark(3), TextSpan(text: ' Recording since $since. ')],
          if (novels) const TextSpan(text: 'Totals cover manga and novels; the lists below follow the reading mode.'),
        ],),
        textScaler: CineType.scaler(context, t.typeCaption),
      ),
    );
  }
}

/// The Annual banner strip (7.29): `paper.0` with a 2 px `spot` left rule.
class AnnualBanner extends StatelessWidget {
  const AnnualBanner({super.key, required this.year, required this.december, required this.years, required this.onOpen});

  final int year;
  final bool december;
  final List<int> years;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: const BoxDecoration(color: CineColors.paper0, border: Border(left: BorderSide(color: CineColors.spot, width: 2))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CineText(december ? 'THE ANNUAL $year IS OUT' : 'THE ANNUAL $year', t.typeKicker, color: CineColors.ink60),
              if (!december) CineText('Your year so far.', t.typeUi),
            ],),
          ),
          CineButton('Open', small: true, kind: CineButtonKind.secondary, onPressed: () => onOpen(year)),
        ],),
        if (years.length > 1) ...[
          const SizedBox(height: 4),
          Wrap(children: [
            for (var i = 0; i < years.length; i++) ...[
              if (i > 0) CineText(' · ', t.typeFolio, color: CineColors.ink45),
              CineTap(
                label: 'The Annual ${years[i]}',
                minWidth: false,
                onTap: () => onOpen(years[i]),
                child: CineText('${years[i]}', t.typeFolio, color: years[i] == year ? CineColors.ink100 : CineColors.ink60, excludeSemantics: true),
              ),
            ],
          ],),
        ],
      ],),
    );
  }
}
