import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_chart.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/genre_radar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Page 2: "You read for 212 hours." with the figure typed.
class AnnualTimePage extends StatelessWidget {
  const AnnualTimePage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final s = env.annual.secondsRead;
    final deck = timeDeck(s);
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnnualTitle(timeHeadline(s), t.typeHeadline,
              id: 'time', typedRange: timeFigureRange(s),),
          if (deck != null) ...[
            const SizedBox(height: 12),
            CineRoleText(deck, t.typeDeck, color: CineColors.ink80),
          ],
        ],
      ),
    );
  }
}

/// Page 3: "4,812 chapters." typed, with a strip of 12 month bars.
class AnnualChaptersPage extends StatelessWidget {
  const AnnualChaptersPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final a = env.annual;
    final months = a.chaptersByMonth;
    final maxV = months.fold<int>(1, (m, v) => v > m ? v : m);
    const initials = [
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ];
    final current = a.partial ? (a.until ?? env.now).month - 1 : -1;
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnnualTitle(chaptersHeadline(a.chaptersRead), t.typeHeadline,
              id: 'chapters',
              typedRange: (start: 0, end: fmt(a.chaptersRead).length),),
          const SizedBox(height: 24),
          Semantics(
            label: 'Chapters by month: ${[
              for (var i = 0; i < 12; i++)
                '${DateTimeMonth.name(i + 1)} ${months[i]}',
            ].join(', ')}',
            excludeSemantics: true,
            child: SizedBox(
              height: 80 + 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 12; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                              height: months[i] / maxV * 80,
                              color: i == current
                                  ? CineColors.spot
                                  : CineColors.ink100,),
                          const SizedBox(height: 4),
                          ExcludeSemantics(
                              child: CineRoleText(initials[i], t.typeMicro,
                                  color: CineColors.ink60,),),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Month names for the semantics label.
abstract final class DateTimeMonth {
  static const _n = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static String name(int m) => _n[m - 1];
}

/// Page 4: the No. 1 cover full-bleed, the credit line, then No. 2 to 5 as rows.
class AnnualNumberOnePage extends StatelessWidget {
  const AnnualNumberOnePage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final top = env.annual.topSeries;
    final first = top.first;
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnnualTitle(no1Headline(first.title), t.typeHeadline, id: 'no1'),
          const SizedBox(height: 8),
          CineRoleText(no1Credit(first), t.typeCredit, color: CineColors.ink80),
          const SizedBox(height: 16),
          for (var i = 1; i < top.length && i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Semantics(
                container: true,
                label: 'No. ${i + 1}: ${top[i].title}, ${rankFolio(top[i])}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(
                        width: 32,
                        child: Text('${i + 1}',
                            style: CineText.style(context, t.typeNumeral)
                                .copyWith(
                                    color: CineColors.ink60,
                                    fontSize: 24,
                                    height: 1,
                                    fontFeatures: const [
                                  FontFeature.liningFigures(),
                                  FontFeature.tabularFigures(),
                                ],),),),
                    Expanded(
                        child: CineRoleText(top[i].title, t.typeTitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis,),),
                    CineRoleText(rankFolio(top[i]), t.typeFolio,
                        color: CineColors.ink60,),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Page 5: the genre radar at 320 px and the line under it.
class AnnualGenresPage extends StatelessWidget {
  const AnnualGenresPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GenreRadar(genres: env.annual.genres),),),
          const SizedBox(height: 16),
          AnnualTitle(genresLine(env.annual.genres), t.typeHeadline,
              id: 'genres',),
        ],
      ),
    );
  }
}

/// Page 6: the 24-hour clock and the band line.
class AnnualClockPage extends StatelessWidget {
  const AnnualClockPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final line = annualClockLine(readClock(env.annual.byHour));
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ClockChart(byHour: env.annual.byHour, summary: line),),),
          const SizedBox(height: 8),
          AnnualTitle(line, t.typeHeadline, id: 'clock'),
        ],
      ),
    );
  }
}

/// Page 7: the flame at 96 px and the longest streak.
class AnnualStreakPage extends StatelessWidget {
  const AnnualStreakPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final s = env.annual.longestStreak;
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreakFlame(
            streak: HomeStreak(
                currentDays: s.days,
                longestDays: s.days,
                lastActiveDate:
                    DateTime(env.now.year, env.now.month, env.now.day),),
            size: 96,
            now: env.now,
            ignite: false,
          ),
          const SizedBox(height: 8),
          AnnualTitle(streakLine(s), t.typeHeadline, id: 'streak'),
        ],
      ),
    );
  }
}

/// Page 8: "MangaDex did the heavy lifting." and the top three sources.
class AnnualSourcesPage extends StatelessWidget {
  const AnnualSourcesPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final sources = env.annual.topSources.take(3).toList();
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnnualTitle(sourcesHeadline(sources.first.name), t.typeHeadline,
              id: 'sources',),
          const SizedBox(height: 20),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                container: true,
                label: '${s.name}, ${(s.share * 100).round()} percent',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: CineRoleText(s.name, t.typeUi)),
                      CineRoleText('${(s.share * 100).round()} %', t.typeFolio,
                          color: CineColors.ink80,),
                    ],),
                    const SizedBox(height: 8),
                    CineRuleProgress(value: s.share),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 56 px avatar (7.25): a square-cornered plate with the initial in the
/// profile's accent.
class AnnualAvatar extends StatelessWidget {
  const AnnualAvatar({super.key, required this.name, this.seed = 0});
  final String name;
  final int seed;

  static const _accents = [
    CineColors.avatarViolet,
    CineColors.avatarCyan,
    CineColors.avatarRose,
    CineColors.avatarAmber,
    CineColors.avatarEmerald,
    CineColors.avatarEmber,
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        color: _accents[seed.abs() % _accents.length],
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
            style: CineText.style(context, context.cine.typeSubhead),),
      );
}

/// Page 9: "You and Riya both finished Solo Leveling." with both avatars.
class AnnualCirclePage extends ConsumerWidget {
  const AnnualCirclePage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final member = circleShared(env.annual).first;
    return AnnualPageFrame(
      annual: env.annual,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AnnualAvatar(name: env.profileName),
            const SizedBox(width: 12),
            AnnualAvatar(name: member.name, seed: member.profileId),
          ],),
          const SizedBox(height: 16),
          AnnualTitle(circleLine(env.annual)!, t.typeHeadline, id: 'circle'),
        ],
      ),
    );
  }
}
