import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The caption of the streak block by state (cinematic 9.2.2).
String streakCaption(HomeStreak s, StreakLiveState state) {
  switch (state) {
    case StreakLiveState.aliveToday:
      return 'DAYS IN A ROW · LONGEST ${s.longestDays}';
    case StreakLiveState.aliveNotToday:
      return 'Read today to keep your ${s.currentDays}-day streak.';
    case StreakLiveState.atRisk:
      return '${capitalise(spell(s.currentDays))} ${s.currentDays == 1 ? 'day' : 'days'} and counting. One chapter keeps it alive.';
    case StreakLiveState.none:
      return s.longestDays > 0
          ? 'Longest: ${s.longestDays} ${s.longestDays == 1 ? 'day' : 'days'}. Start a new one today.'
          : 'Start your first streak today.';
  }
}

/// Monday to Sunday of the local week of [now]: which days were read.
List<bool> weekRead(List<DailyActivity> daily, DateTime now) {
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      daily.any((d) {
        final day = DateTime(monday.year, monday.month, monday.day + i);
        return d.date.year == day.year &&
            d.date.month == day.month &&
            d.date.day == day.day &&
            (d.chaptersRead > 0 || d.sessions > 0);
      }),
  ];
}

/// "Read on Monday, Tuesday and Thursday".
String weekSemantics(List<bool> read) {
  final names = [
    for (var i = 0; i < 7; i++)
      if (read[i]) weekdayName(i + 1),
  ];
  return names.isEmpty
      ? 'No reading yet this week'
      : 'Read on ${joinNames(names)}';
}

/// Seven 8 x 8 squares, 4 px apart, Monday to Sunday: `spot` for days read, a
/// 1 px `rule.2` outline otherwise, initials under them; one semantics label.
class WeekDots extends StatelessWidget {
  const WeekDots({super.key, required this.read});
  final List<bool> read;

  @override
  Widget build(BuildContext context) {
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final micro = context.cine.typeMicro;
    return Semantics(
      label: weekSemantics(read),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: read[i] ? CineColors.spot : null,
                        border: read[i]
                            ? null
                            : Border.all(color: CineColors.rule2),),),
                const SizedBox(height: 4),
                SizedBox(
                    width: 8,
                    height: 14,
                    child: OverflowBox(
                        maxWidth: 16,
                        maxHeight: 14,
                        child: ExcludeSemantics(
                            child: CineRoleText(initials[i], micro,
                                color: context.cine.colorInk45,
                                textAlign: TextAlign.center,),),),),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The streak block (cinematic 9.2.1): kicker, `StreakFlame` beside the day count, the caption by
/// state, the week dots. The flame plays Ignite (and its haptic and cue) itself when the last
/// active day has just flipped to today; the numeral then types its new value.
class StreakBlock extends ConsumerStatefulWidget {
  const StreakBlock(
      {super.key,
      required this.streak,
      required this.daily,
      this.signature = false,
      this.wide = false,});

  final ReadingStreak streak;
  final List<DailyActivity> daily;
  final bool signature;
  final bool wide;

  @override
  ConsumerState<StreakBlock> createState() => _StreakBlockState();
}

class _StreakBlockState extends ConsumerState<StreakBlock> {
  late HomeStreak _home = HomeStreak.fromReadingStreak(widget.streak);
  late final DateTime _now = ref.read(clockProvider)();

  @override
  void didUpdateWidget(StreakBlock old) {
    super.didUpdateWidget(old);
    if (old.streak != widget.streak) {
      _home = HomeStreak.fromReadingStreak(widget.streak);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final now = ref.watch(clockProvider)();
    // Watching keeps the one-shot value alive, so the flame below reads the same answer.
    final ignite =
        ref.watch(streakIgnitionProvider((streak: _home, now: _now)));
    final state = streakState(_home, now);
    final days = widget.streak.currentDays;
    final numeral = CineText.style(context, t.typeNumeral).copyWith(
        color: CineColors.ink100,
        fontFeatures: const [
          FontFeature.liningFigures(),
          FontFeature.tabularFigures(),
        ],);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CineRuleDraw(kind: CineRuleKind.heavy, draw: widget.signature),
        const SizedBox(height: 12),
        CineRoleText('STREAK', t.typeKicker, color: CineColors.ink60),
        const SizedBox(height: 4),
        Row(
          children: [
            StreakFlame(
                streak: _home,
                size: widget.wide ? 96 : 56,
                now: _now,
                ignite: ignite,),
            const SizedBox(width: 4),
            Flexible(
              child: Semantics(
                label: '$days days',
                excludeSemantics: true,
                child: ignite || widget.signature
                    ? TypedHeadline('$days',
                        style: numeral, cap: t.typeNumeral.cap,)
                    : Text('$days',
                        style: numeral,
                        textScaler: CineText.scaler(context, t.typeNumeral),
                        maxLines: 1,),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CineRoleText(streakCaption(_home, state),
            state == StreakLiveState.aliveToday ? t.typeCredit : t.typeCaption,
            color: CineColors.ink60,),
        const SizedBox(height: 16),
        WeekDots(read: weekRead(widget.daily, now)),
      ],
    );
  }
}
