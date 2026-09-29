import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/streak_state.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cue.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/rules.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/numbers_streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The caption of the streak block by state (cinematic 9.2.2).
String streakCaption(HomeStreak s, StreakState state) {
  switch (state) {
    case StreakState.readToday:
      return 'DAYS IN A ROW · LONGEST ${s.longestDays}';
    case StreakState.notYetToday:
      return 'Read today to keep your ${s.currentDays}-day streak.';
    case StreakState.atRisk:
      return '${capitalise(spell(s.currentDays))} ${s.currentDays == 1 ? 'day' : 'days'} and counting. One chapter keeps it alive.';
    case StreakState.broken:
      return s.longestDays > 0 ? 'Longest: ${s.longestDays} ${s.longestDays == 1 ? 'day' : 'days'}. Start a new one today.' : 'Start your first streak today.';
  }
}

/// Monday to Sunday of the local week of [now]: which days were read.
List<bool> weekRead(List<DailyActivity> daily, DateTime now) {
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      daily.any((d) {
        final day = DateTime(monday.year, monday.month, monday.day + i);
        return d.date.year == day.year && d.date.month == day.month && d.date.day == day.day && (d.chaptersRead > 0 || d.sessions > 0);
      }),
  ];
}

/// "Read on Monday, Tuesday and Thursday".
String weekSemantics(List<bool> read) {
  final names = [for (var i = 0; i < 7; i++) if (read[i]) weekdayName(i + 1)];
  return names.isEmpty ? 'No reading yet this week' : 'Read on ${joinNames(names)}';
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: read[i] ? CineColors.spot : null, border: read[i] ? null : Border.all(color: CineColors.rule2))),
            const SizedBox(height: 4),
            SizedBox(width: 8, child: OverflowBox(maxWidth: 16, child: CineText(initials[i], micro, color: CineColors.ink45, textAlign: TextAlign.center, excludeSemantics: true))),
          ],),
        ],
      ],),
    );
  }
}

/// The streak block (cinematic 9.2.1): kicker, flame beside the day count, the
/// caption by state, the week dots. Plays Ignite once when the last active day
/// has just flipped to today.
class StreakBlock extends ConsumerStatefulWidget {
  const StreakBlock({super.key, required this.streak, required this.daily, this.signature = false, this.wide = false});

  final ReadingStreak streak;
  final List<DailyActivity> daily;
  final bool signature;
  final bool wide;

  @override
  ConsumerState<StreakBlock> createState() => _StreakBlockState();
}

class _StreakBlockState extends ConsumerState<StreakBlock> {
  bool _ignite = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(numbersNowProvider)();
    final prefs = ref.read(sharedPrefsProvider);
    final key = ref.read(streakSeenKeyProvider);
    final home = HomeStreak.fromReadingStreak(widget.streak);
    if (justExtended(home, now, prefs.getString(key))) {
      _ignite = true;
      prefs.setString(key, todayKey(now));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) cinematicCue(ref, HapticEvent.streakExtend, SoundEvent.streakExtend);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final now = ref.watch(numbersNowProvider)();
    final home = HomeStreak.fromReadingStreak(widget.streak);
    final state = streakState(home, now);
    final days = widget.streak.currentDays;
    final caption = streakCaption(home, state);
    final capRole = state == StreakState.readToday ? t.typeCredit : t.typeCaption;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DrawnRule(animate: widget.signature),
      const SizedBox(height: 12),
      CineText('STREAK', t.typeKicker, color: CineColors.ink60),
      const SizedBox(height: 4),
      Row(children: [
        NumbersStreakFlame(days: days, state: state, size: widget.wide ? 96 : 56, ignite: _ignite, fromTier: _ignite ? streakTier(days - 1) : null),
        const SizedBox(width: 4),
        Flexible(child: TypedNumeral('$days', animate: _ignite || widget.signature, semanticsLabel: '$days days')),
      ],),
      const SizedBox(height: 4),
      CineText(caption, capRole, color: CineColors.ink60),
      const SizedBox(height: 16),
      WeekDots(read: weekRead(widget.daily, now)),
    ],);
  }
}
