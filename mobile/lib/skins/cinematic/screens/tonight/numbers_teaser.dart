import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/headline.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/annual_entry_points.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_stat_block.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The streak block's caption by state (cinematic 9.2.2).
String streakCaption(HomeStreak s, DateTime now) => switch (streakState(s, now)) {
      StreakLiveState.aliveToday => 'DAYS IN A ROW · LONGEST ${s.longestDays}',
      StreakLiveState.aliveNotToday => 'Read today to keep your ${s.currentDays}-day streak.',
      StreakLiveState.atRisk => '${spellCount(s.currentDays)} days and counting. One chapter keeps it alive.',
      StreakLiveState.none => 'Longest: ${s.longestDays} days. Start a new one today.',
    };

/// `This week in numbers`: stat blocks (a 3 px rule, a kicker, a numeral, a caption) with the streak
/// flame, in a 2 x 2 grid on phones and 2 + 2 + 2 columns on tablets, then `Open The Numbers →`.
class NumbersTeaser extends ConsumerWidget {
  const NumbersTeaser({super.key, required this.plan, required this.env});
  final PlannedSection plan;
  final TonightEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final wide = tonightWide(context);
    final item = plan.section.items.whereType<HomeNumbersItem>().firstOrNull;
    final loading = plan.section.state == HomeSectionState.unavailable && item == null;
    final n = item ?? const HomeNumbersItem();
    final streak = env.feed.streak.currentDays > 0 || item == null ? env.feed.streak : n.streak;
    final ignite = ref.watch(streakIgnitionProvider((streak: streak, now: env.now)));

    final blocks = <Widget>[
      _StreakBlock(streak: streak, now: env.now, ignite: ignite, loading: loading),
      CineStatBlock(kicker: 'THIS WEEK', value: '${n.chaptersWeek}', caption: n.chaptersWeek == 1 ? 'chapter' : 'chapters', loading: loading),
      CineStatBlock(kicker: 'TIME READ', value: hoursMinutes(n.secondsWeek), caption: 'this week', loading: loading),
      Align(
        alignment: Alignment.bottomLeft,
        child: Wrap(children: [
          CineButton(label: 'Open The Numbers', variant: CineButtonVariant.quiet, onPressed: () => context.go(Routes.numbers())),
          if (env.now.month == 12) const AnnualOutLink(),
        ],),
      ),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: wide ? 64 : 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        CineSectionHeader(headingId: 'tonight.numbers', heading: plan.section.title, folio: plan.folio, onSeeAll: seeAllFor(context, plan.section.type)),
        SizedBox(height: c.space4),
        LayoutBuilder(builder: (context, box) {
          final gap = wide ? 16.0 : 12.0;
          final cols = wide ? 4 : 2;
          final w = (box.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: c.space5, children: [for (final b in blocks) SizedBox(width: w, child: b)]);
        },),
      ],),
    );
  }
}

class _StreakBlock extends StatelessWidget {
  const _StreakBlock({required this.streak, required this.now, required this.ignite, required this.loading});
  final HomeStreak streak;
  final DateTime now;
  final bool ignite, loading;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final numeral = CineText.style(context, c.typeNumeral);
    return Semantics(
      label: 'Streak, ${streakSemantics(streak, now)}. ${streakCaption(streak, now)}',
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(height: c.ruleHeavy.width, color: c.colorInk100),
        SizedBox(height: c.space2),
        CineRoleText('STREAK', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space1),
        if (loading)
          CineGalleyNumeral(size: (numeral.fontSize ?? 40) * (numeral.height ?? 1))
        else
          Row(children: [
            StreakFlame(streak: streak, size: 24, now: now, ignite: ignite),
            SizedBox(width: c.space3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ignite
                    ? TypedHeadline('${streak.currentDays}', style: numeral.copyWith(color: c.colorInk100), cap: c.typeNumeral.cap)
                    : CineRoleText('${streak.currentDays}', c.typeNumeral),
              ),
            ),
          ],),
        SizedBox(height: c.space1),
        CineRoleText(streakCaption(streak, now), c.typeCaption, color: c.colorInk60),
      ],),
    );
  }
}
