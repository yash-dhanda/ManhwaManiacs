import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/raised_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// An H3 of The Numbers (`CineSectionHeader`: the section rule draws 120 ms before the letters of
/// the `SetHeading` in `type.section`), with an optional raised footnote mark.
class SectionHead extends StatelessWidget {
  const SectionHead(this.text, {super.key, this.footnote});
  final String text;
  final int? footnote;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 16),
        child: CineSectionHeader(
            headingId: 'numbers-${text.toLowerCase().replaceAll(' ', '-')}',
            heading: text,
            footnote: footnote,),
      );
}

/// "812 pages · 9 h · 41 %".
String sourceFolio(SourceActivity s, int totalSeconds) =>
    '${fmt(s.pagesRead)} pages · ${hoursLower(s.secondsRead)} · ${totalSeconds == 0 ? 0 : (s.secondsRead / totalSeconds * 100).round()} %';

/// Sources ranked by time, each with a 2 px determinate rule of its share.
class WhereYouRead extends StatelessWidget {
  const WhereYouRead({super.key, required this.sources});
  final List<SourceActivity> sources;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final ranked = [...sources]
      ..sort((a, b) => b.secondsRead.compareTo(a.secondsRead));
    final total = ranked.fold<int>(0, (a, s) => a + s.secondsRead);
    return Column(
      children: [
        for (final s in ranked)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(
              container: true,
              label: '${s.name}, ${sourceFolio(s, total)}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: CineRoleText(s.name, t.typeUi,
                              maxLines: 1, overflow: TextOverflow.ellipsis,),),
                      CineRoleText(sourceFolio(s, total), t.typeFolio,
                          color: CineColors.ink60,),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CineRuleProgress(
                      value: total == 0 ? 0 : s.secondsRead / total,),
                ],
              ),
            ),
          ),
      ],
    );
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

class _PressRow extends StatelessWidget {
  const _PressRow(
      {required this.onTap, required this.child, required this.label,});
  final VoidCallback onTap;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: CinePressable(
          onTap: onTap,
          expand: true,
          builder: (context, st) => ConstrainedBox(
            constraints: BoxConstraints(minHeight: cineHitMin(context)),
            child: ColoredBox(
                color: st.pressed ? CineColors.paper3 : Colors.transparent,
                child: child,),
          ),
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
    final rows = series.take(5).toList();
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _PressRow(
            label: '${i + 1}. ${rows[i].title ?? rows[i].seriesKey}',
            onTap: () => context
                .push(Routes.feature(rows[i].sourceId, rows[i].seriesKey)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 28,
                      child: Text('${i + 1}',
                          style: CineText.style(context, t.typeNumeral)
                              .copyWith(
                                  color: CineColors.ink45,
                                  fontSize: 24,
                                  height: 1,
                                  fontFeatures: const [
                                FontFeature.liningFigures(),
                                FontFeature.tabularFigures(),
                              ],),),),
                  CineHero(
                    tag: (rows[i].sourceId, rows[i].seriesKey),
                    child: SizedBox(
                        width: 40,
                        height: 60,
                        child: CineImage(
                            url: rows[i].coverUrl,
                            title: rows[i].title,
                            width: 40,),),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CineRoleText(
                            rows[i].title ?? rows[i].seriesKey, t.typeTitle,
                            maxLines: 2, overflow: TextOverflow.ellipsis,),
                        const SizedBox(height: 2),
                        CineRoleText(
                            '${fmt(rows[i].pagesRead)} pages · ${rows[i].chaptersRead} chapters · ${hoursLower(rows[i].secondsRead)}',
                            t.typeCaption,
                            color: CineColors.ink60,),
                        if (rows[i].lastReadAt != null)
                          Builder(
                            builder: (context) {
                              final folio =
                                  'Last read ${agoFolio(rows[i].lastReadAt!.toLocal(), now)}';
                              return Semantics(
                                  label: folioLabel(folio),
                                  excludeSemantics: true,
                                  child: CineRoleText(folio, t.typeCaption,
                                      color: CineColors.ink60,),);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// `21:04`.
String sessionTime(DateTime t) => DateFormat('HH:mm').format(t.toLocal());

void _open(BuildContext context, WidgetRef ref, ContentModeScope scope,
    RecentSession s,) {
  final novel =
      scope.novelsEnabled && scope.modeOf(s.sourceId) == ContentMode.novel;
  final target = novel
      ? ReaderTarget.novel(s.sourceId, s.seriesKey, s.chapterKey)
      : ReaderTarget.manifest(s.sourceId, s.seriesKey, s.chapterKey);
  readerPrefetchOf(ref).onPress(target);
  // The Numbers is not a Column-wipe origin: Dip.
  enterReader(context, target, entry: ReaderEntry.dip);
}

/// Recent sessions: §7.16 standard rows, 56 px minimum, built lazily.
class RecentSessionsSliver extends ConsumerWidget {
  const RecentSessionsSliver({super.key, required this.sessions});
  final List<RecentSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final scope = ref.watch(contentModeScopeProvider);
    return SliverList.builder(
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        final chapter = s.chapterNumber == null
            ? null
            : 'CH ${s.chapterNumber! % 1 == 0 ? s.chapterNumber!.toInt() : s.chapterNumber}';
        final minutes = (s.secondsRead / 60).round();
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 52,
                    child: s.startedAt == null
                        ? null
                        : CineRoleText(sessionTime(s.startedAt!), t.typeFolio,
                            color: CineColors.ink45,),),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CineRoleText(s.title ?? s.seriesKey, t.typeUi,
                          maxLines: 1, overflow: TextOverflow.ellipsis,),
                      CineRoleText(
                          '${s.pagesRead} pages · $minutes min', t.typeCaption,
                          color: CineColors.ink60,),
                    ],
                  ),
                ),
                if (chapter != null)
                  Semantics(
                    button: true,
                    label: 'Open ${folioLabel(chapter)}',
                    excludeSemantics: true,
                    onTap: () => _open(context, ref, scope, s),
                    child: CinePressable(
                      onTap: () => _open(context, ref, scope, s),
                      builder: (context, st) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CineRoleText(chapter, t.typeFolio,
                              color: st.hovered
                                  ? CineColors.ink100
                                  : CineColors.spot,),),
                    ),
                  ),
              ],
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CineRoleText(
            '${fmt(stats.followedTotal)} FOLLOWED · ${fmt(stats.favorites)} ${stats.favorites == 1 ? 'FAVOURITE' : 'FAVOURITES'} · ${fmt(stats.chaptersCompleted)} CHAPTERS FINISHED',
            t.typeCredit,
            color: CineColors.ink60,),
        const SizedBox(height: 12),
        for (final (key, label) in kStatusRows)
          if ((stats.byReadingStatus[key] ?? 0) > 0) ...[
            const CineRuleDraw(draw: false),
            Semantics(
              container: true,
              label: '$label, ${stats.byReadingStatus[key]}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: CineRoleText(label, t.typeKicker,
                                color: CineColors.ink60,),),
                        CineRoleText(
                            fmt(stats.byReadingStatus[key]!), t.typeUi,),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CineRuleProgress(
                        value: total == 0
                            ? 0
                            : stats.byReadingStatus[key]! / total,),
                  ],
                ),
              ),
            ),
          ],
      ],
    );
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
    final style = CineText.style(context, t.typeCaption)
        .copyWith(color: CineColors.ink60);
    final first = stats.totals.firstSessionAt;
    final since = first == null
        ? null
        : DateFormat('d MMMM y', 'en_US').format(first.toLocal());
    final cap = stats.sessionCapSeconds ~/ 60;
    InlineSpan mark(int n) => raisedFolio(n, style.fontSize ?? 13);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            mark(1),
            TextSpan(
                text:
                    ' Days start at ${offsetLabel(stats.timezoneOffsetMinutes)}. ',),
            mark(2),
            TextSpan(
                text:
                    ' Each session counts up to $cap minutes of reading time. ',),
            if (since != null) ...[
              mark(3),
              TextSpan(text: ' Recording since $since. '),
            ],
            if (novels)
              const TextSpan(
                  text:
                      'Totals cover manga and novels; the lists below follow the reading mode.',),
          ],
        ),
        textScaler: CineType.scaler(context, t.typeCaption),
      ),
    );
  }
}

/// The Annual banner strip (7.29): `paper.0` with a 2 px `spot` left rule.
class AnnualBanner extends StatelessWidget {
  const AnnualBanner(
      {super.key,
      required this.year,
      required this.december,
      required this.years,
      required this.onOpen,});

  final int year;
  final bool december;
  final List<int> years;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: const BoxDecoration(
          color: CineColors.paper0,
          border: Border(left: BorderSide(color: CineColors.spot, width: 2)),),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CineRoleText(
                        december
                            ? 'THE ANNUAL $year IS OUT'
                            : 'THE ANNUAL $year',
                        t.typeKicker,
                        color: CineColors.ink60,),
                    if (!december) CineRoleText('Your year so far.', t.typeUi),
                  ],
                ),
              ),
              CineButton(
                  label: 'Open',
                  size: CineButtonSize.sm,
                  variant: CineButtonVariant.secondary,
                  onPressed: () => onOpen(year),),
            ],
          ),
          if (years.length > 1) ...[
            const SizedBox(height: 4),
            CineSlugLines(
              items: [for (final y in years) CineSlug('$y', '$y')],
              selected: {'$year'},
              onChanged: (id) => onOpen(int.parse(id)),
            ),
          ],
        ],
      ),
    );
  }
}
