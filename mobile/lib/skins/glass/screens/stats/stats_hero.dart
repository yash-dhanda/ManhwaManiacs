import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/utils/reading_stats.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/goal_ring.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show globalRectOf;

/// The hero of "Your reading" (glass 9.2.1): the 96 px streak flame inside the daily goal ring, the streak line, longest, days read,
/// the 14 dots of the last two weeks and when you last read. Everything comes from the server's streak object.
class StatsHero extends ConsumerWidget {
  const StatsHero({super.key, required this.stats, required this.now, required this.rangeDays, this.heroKey});
  final LibraryStatistics stats;
  final DateTime now;
  final int rangeDays;
  final Key? heroKey;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = stats.streak;
    final today = stats.daily.where((d) => _sameDay(d.date, now)).firstOrNull;
    final goal = ref.watch(dailyGoalProvider);
    final readToday = (today?.pagesRead ?? 0) > 0 || goal.todaySeconds > 0;
    final state = flameStateOf(days: s.currentDays, readToday: readToday, atRisk: s.atRisk);
    final ui = ref.watch(streakUiProvider);
    final last14 = stats.daily.length > 14 ? stats.daily.sublist(stats.daily.length - 14) : stats.daily;
    final flame = StreakFlame(size: 96, state: state, days: s.currentDays, flare: ui.flare, sparks: ui.sparks);
    final ringed = goal.goalMinutes == null
        ? SizedBox(width: 112, height: 112, child: Center(child: flame))
        : SizedBox(
            width: 112,
            height: 112,
            child: GlassGoalRing(orbSize: 112, minutes: goal.minutes, goal: goal.goalMinutes!, child: Center(child: flame)),
          );
    final caption = flameCaption(state, s.currentDays, longest: s.longestDays);
    final record = ui.recordDays;
    final lastRead = stats.totals.lastSessionAt;
    return Semantics(
      container: true,
      child: Column(
        key: heroKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          ringed,
          if (goal.goalMinutes != null) GlassLabel(goalLine(goal.minutes, goal.goalMinutes!), role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 8),
          if (s.currentDays > 0)
            LetterReveal('${s.currentDays}-day streak', role: gt.typeTitle1, screenId: 'numbers.hero', textAlign: TextAlign.center)
          else
            GlassLabel('No streak', role: gt.typeTitle1, color: gt.colorLabel1),
          if (record != null)
            GlassLabel('New longest streak: $record days', role: gt.typeFootnote, color: gt.colorStreakCore, maxLines: 2)
          else ...[
            GlassLabel('Longest: ${plural(s.longestDays, 'day')}', role: gt.typeFootnote, color: gt.colorLabel2),
          ],
          if (caption != null && state != FlameState.none) Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel(caption, role: gt.typeFootnote, color: gt.colorLabel1, maxLines: 2)),
          if (state == FlameState.none) Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel(caption ?? '', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2)),
          GlassLabel(daysReadLine(daysRead(stats.daily), rangeDays), role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 12),
          _Dots(days: last14),
          if (lastRead != null) ...[
            const SizedBox(height: 8),
            GlassLabel('Last read ${_ago(lastRead, now)}', role: gt.typeFootnote, color: gt.colorLabel2),
          ],
        ],
      ),
    );
  }

  static String _ago(DateTime at, DateTime now) {
    final d = now.difference(at);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.days});
  final List<DailyActivity> days;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < days.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: Semantics(
                label: dotLabel(days[i]),
                child: ExcludeSemantics(
                  child: GlassTooltip(
                    message: dotLabel(days[i]),
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: days[i].pagesRead > 0 ? gt.colorStreak : gt.colorFill3)),
                  ),
                ),
              ),
            ),
        ],
      );
}

/// The global rect of a keyed widget (the hero's share origin).
Rect rectOfKey(GlobalKey key) {
  final c = key.currentContext;
  return c == null ? Rect.zero : globalRectOf(c);
}
